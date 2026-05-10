# STORY-014 : Auth JWT Multi-tenant

**Epic :** EPIC-003 — Backend Foundation
**Priorité :** Must Have
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** STORY-013 (NestJS setup + Docker Compose 5 services)

---

## User Story

> **En tant qu'**utilisateur d'un tenant Scalario (Owner, Manager, Commercial),
> **je veux** me connecter avec email + password + tenant_slug et rester authentifié via un access token JWT (15 min) + un refresh token (7 jours) avec rotation automatique,
> **so that** mes actions sont tracées à mon identité et mon tenant, mes tokens sont révocables instantanément, et un token volé d'un tenant A est inutilisable sur les routes du tenant B.

---

## Description

### Background

Layer 1 de la chaîne sécurité Scalario (architecture line 628). Toutes les autres couches (RBAC STORY-015, ABAC STORY-019, RLS STORY-017, Audit STORY-020) dépendent d'un JWT contenant `tenant_id`, `user_id`, `roles[]`, `department_id`. Sans cette story, aucune route protégée n'est possible.

L'architecture impose plusieurs invariants critiques :

1. **Multi-tenant strict** : un token doit être inutilisable cross-tenant — un attaquant qui obtient un JWT d'Acme Corp ne peut pas l'utiliser sur les endpoints de Boulangerie Blandine.
2. **Refresh rotation** : chaque refresh consomme l'ancien token (one-time use) et émet une nouvelle paire — détection de réutilisation = révocation totale de la chaîne.
3. **Révocation instantanée** : logout met le hash du refresh token dans Redis blacklist (TTL = durée restante) — STORY-018 finalise cette intégration.
4. **OAuth2 préparé** : interface `AuthProvider` définie pour Google/Apple Phase 2 (FR-009 mention "OAuth2 préparé").

### Scope

**In scope :**

- Module `apps/nestjs/src/auth/` complet : `auth.module.ts`, `auth.controller.ts`, `auth.service.ts`, `auth.guard.ts`, `dto/`, `interfaces/`, `strategies/`, `__tests__/`.
- Endpoints : `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `GET /auth/me`.
- Passport.js avec 2 stratégies : `LocalStrategy` (email + password + tenant_slug pour login), `JwtStrategy` (Authorization Bearer pour routes protégées).
- `JwtAuthGuard` (`@nestjs/passport`) appliqué globalement sauf décorateur `@Public()` (login, refresh, health).
- Tables PostgreSQL : `tenants`, `users`, `refresh_tokens` (déjà documentées dans architecture line 705-754).
- Migration TypeORM `1700000000001-auth-tables.ts` créant tenants + users + refresh_tokens avec indexes.
- Hashing password : `bcrypt` (cost 12) — jamais de password en clair, ni en log.
- Hashing refresh token : SHA-256 avant stockage DB (le client a le token brut, le serveur a le hash).
- Rotation refresh : `POST /auth/refresh` invalide l'ancien token (set `revoked_at = now()`) avant d'émettre la nouvelle paire.
- Détection réutilisation refresh : si un client présente un refresh token déjà `revoked_at IS NOT NULL`, **toute la famille** de tokens du user est révoquée (token theft mitigation).
- Interface `AuthProvider` abstraite pour OAuth2 Phase 2 (Google, Apple).
- Endpoint admin `POST /tenants/provision` qui crée tenant + premier user OWNER en < 30 secondes (FR-009 AC).
- `@Public()` decorator + `@CurrentUser()` decorator pour extraction request context.
- Rate limiting `@nestjs/throttler` sur `/auth/login` (5 req/min/IP).

**Out of scope (autres stories) :**

- Redis blacklist refresh tokens → STORY-018 (cette story stocke `revoked_at` en DB ; l'optimisation Redis vient après).
- RBAC Guards (`@Roles()`) → STORY-015.
- ABAC CASL → STORY-019.
- RLS PostgreSQL sur les tables auth → STORY-017.
- Audit log auth events → STORY-020.
- OAuth2 Google/Apple implémentation → Phase 2.
- 2FA / MFA → Phase 3.

### User Flow (Authentication)

**Login :**
1. Client `POST /auth/login` avec body `{ email, password, tenant_slug }`.
2. `LocalStrategy` résout `tenant_slug → tenant_id`. 404 si tenant inexistant ou inactif.
3. Recherche `users WHERE tenant_id = ? AND email = ? AND is_active = true`.
4. `bcrypt.compare(password, user.password_hash)`. 401 si mismatch.
5. Génère `access_token` (JWT signé `JWT_SECRET`, expire 15 min, claims `sub=user_id, tenant_id, roles, department_id`).
6. Génère `refresh_token` (random 64 bytes hex). Hash SHA-256 inséré dans `refresh_tokens` avec `expires_at = now + 7d`.
7. Retourne `{ access_token, refresh_token, expires_in: 900 }`.

**Requête protégée :**
1. Client envoie header `Authorization: Bearer <access_token>`.
2. `JwtStrategy` vérifie signature + expiration + parse claims.
3. `req.user = { user_id, tenant_id, roles, department_id }`.
4. Layer 2 (RBAC, STORY-015) consomme `req.user.roles`.

**Refresh :**
1. Client `POST /auth/refresh` avec `{ refresh_token }`.
2. Hash SHA-256 du token reçu.
3. `SELECT * FROM refresh_tokens WHERE token_hash = ? AND expires_at > now()`.
4. **Si `revoked_at IS NOT NULL`** : token déjà utilisé = vol potentiel → révoque tous les refresh tokens du `user_id` (UPDATE all SET `revoked_at = now()`) → 401.
5. Sinon : `UPDATE refresh_tokens SET revoked_at = now() WHERE id = ?`.
6. Génère nouvelle paire (access + refresh) → retourne au client.

**Logout :**
1. Client `POST /auth/logout` avec header Authorization + body `{ refresh_token }`.
2. `UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = ?`.
3. (STORY-018 ajoutera l'insertion dans Redis blacklist avec TTL = expires_at - now()).

---

## Acceptance Criteria

### Migrations DB

- [ ] AC-01 — Migration `1700000000001-auth-tables.ts` crée les 3 tables `tenants`, `users`, `refresh_tokens` avec exactement le schéma de l'architecture (line 705-754) : colonnes, types, defaults, FK, indexes, unique constraints.
- [ ] AC-02 — `users.password_hash TEXT NOT NULL` ; aucune colonne `password` en clair n'existe.
- [ ] AC-03 — `refresh_tokens.token_hash TEXT NOT NULL UNIQUE` ; aucune colonne `token` en clair.
- [ ] AC-04 — Index `idx_users_tenant`, `idx_users_email`, `idx_refresh_tokens_hash`, `idx_refresh_tokens_user` créés.
- [ ] AC-05 — RLS active sur `users` (policy `user_tenant_isolation` — la policy compile mais ne sera testée qu'en STORY-017 ; ici on vérifie juste que la migration ne casse rien).

### Endpoints

- [ ] AC-06 — `POST /auth/login` avec body `{ email, password, tenant_slug }` retourne `200 { access_token, refresh_token, expires_in: 900, user: { id, email, roles, department_id } }`.
- [ ] AC-07 — `POST /auth/login` retourne `401` si email inconnu, password mismatch, ou user `is_active=false`. Message d'erreur uniformisé `Invalid credentials` (jamais "user not found" — éviter user enumeration).
- [ ] AC-08 — `POST /auth/login` retourne `404` si `tenant_slug` inexistant ou tenant `is_active=false`.
- [ ] AC-09 — `POST /auth/login` rate limited à 5 req/min/IP via `@nestjs/throttler` ; 6ème requête → `429 Too Many Requests`.
- [ ] AC-10 — `POST /auth/refresh` avec `{ refresh_token }` valide retourne nouvelle paire ; ancien refresh marqué `revoked_at`.
- [ ] AC-11 — `POST /auth/refresh` avec refresh token expiré → `401`.
- [ ] AC-12 — `POST /auth/refresh` avec refresh token déjà révoqué → révoque toute la famille de tokens du user (test : 5 refresh tokens en DB, présenter un révoqué → les 5 sont marqués `revoked_at`) + retourne `401`.
- [ ] AC-13 — `POST /auth/logout` invalide le refresh token fourni (`revoked_at = now()`) ; retourne `204 No Content`.
- [ ] AC-14 — `GET /auth/me` retourne `200 { user_id, tenant_id, email, roles, department_id }` extraits du JWT.

### JWT Claims

- [ ] AC-15 — Access token JWT contient les claims OBLIGATOIRES : `sub` (= user_id, UUID), `tenant_id` (UUID), `roles` (string[]), `department_id` (UUID nullable), `iat`, `exp`.
- [ ] AC-16 — Access token expire en exactement 15 minutes (`exp - iat = 900`).
- [ ] AC-17 — Refresh token expire en 7 jours (timestamp DB `expires_at = now + interval '7 days'`).
- [ ] AC-18 — JWT signé avec algorithme HS256 et `JWT_SECRET` (≥ 256 bits, validé au boot — l'app refuse de démarrer si JWT_SECRET < 32 chars).

### Multi-tenant isolation (test critique)

- [ ] AC-19 — **Test d'intrusion :** créer 2 tenants A et B, login user de A, utiliser le JWT pour appeler `GET /auth/me` → retourne user de A. **Modifier manuellement le claim `tenant_id` dans le JWT** (re-signer avec un autre secret) → `401` (signature invalide). Tenter avec le même secret mais tenant_id forgé → la requête passe Layer 1 mais Layer 4 RLS (STORY-017) bloquera. Documenter dans le test que Layer 1 seul ne protège PAS contre claim forgé si le JWT_SECRET est compromis — c'est pourquoi RLS existe.
- [ ] AC-20 — **Test d'isolation :** user du tenant A appelle un endpoint qui charge un user via `users WHERE id = ?` (sans filtre tenant_id) avec un user_id du tenant B → la requête doit échouer (RLS prendra le relais en STORY-017 ; ici on vérifie que `auth.service.findUserById()` ajoute toujours `AND tenant_id = ?` dans la query).

### Hashing & Sécurité crypto

- [ ] AC-21 — `bcrypt` avec cost = 12 utilisé pour `users.password_hash`. Aucun appel à `md5`, `sha1`, ou hashing custom dans le code auth.
- [ ] AC-22 — `crypto.createHash('sha256').update(token).digest('hex')` utilisé pour `refresh_tokens.token_hash`. Le refresh token brut est généré via `crypto.randomBytes(64).toString('hex')` (128 chars hex).
- [ ] AC-23 — `JWT_SECRET` et `JWT_REFRESH_SECRET` sont 2 secrets distincts (rotation indépendante possible).

### Provisioning tenant (FR-009 AC)

- [ ] AC-24 — `POST /tenants/provision` (endpoint protégé `@Roles('SUPER_ADMIN')` — sera implémenté en STORY-015, ici juste préparé) avec body `{ name, slug, owner_email, owner_password }` crée :
  - 1 row dans `tenants` (status `is_active=true`)
  - 1 row dans `users` avec `roles=['OWNER']`
  - durée totale de la transaction < 30 secondes (mesuré par test d'intégration)

### Code quality & tests

- [ ] AC-25 — Tests unitaires `auth.service.spec.ts` couvrent : login success/fail, refresh rotation, refresh reuse detection, logout, password hashing, refresh hashing.
- [ ] AC-26 — Tests d'intégration `auth.e2e-spec.ts` (supertest) : login → access protected → refresh → logout → access protected returns 401.
- [ ] AC-27 — Coverage du module `auth/` ≥ 90% (Architecture coverage target NestJS Auth + Security line 1736).
- [ ] AC-28 — Aucun `console.log` du password ou du token brut. Logger interceptor masque ces champs (`password`, `password_hash`, `refresh_token`, `access_token` → `[REDACTED]`).

---

## Technical Notes

### Composants concernés

- **Module Auth :** `apps/nestjs/src/auth/` (création complète).
- **Tables PostgreSQL :** `tenants`, `users`, `refresh_tokens`.
- **Common :** `apps/nestjs/src/common/decorators/{public.decorator.ts, current-user.decorator.ts}`.

### Structure de fichiers (cible)

```
apps/nestjs/src/auth/
├── auth.module.ts
├── auth.controller.ts                 # POST /login, /refresh, /logout, GET /me
├── auth.service.ts                    # business logic
├── strategies/
│   ├── local.strategy.ts              # Passport LocalStrategy
│   └── jwt.strategy.ts                # Passport JwtStrategy
├── guards/
│   └── jwt-auth.guard.ts              # appliqué globalement
├── dto/
│   ├── login.dto.ts                   # Zod-validated
│   ├── refresh.dto.ts
│   └── logout.dto.ts
├── interfaces/
│   ├── auth-provider.interface.ts     # abstraction OAuth2 Phase 2
│   ├── jwt-payload.interface.ts
│   └── auth-tokens.interface.ts
├── entities/
│   ├── tenant.entity.ts
│   ├── user.entity.ts
│   └── refresh-token.entity.ts
├── tenants/
│   └── tenants-provision.controller.ts  # POST /tenants/provision
└── __tests__/
    ├── auth.service.spec.ts
    ├── auth.controller.spec.ts
    └── auth.e2e-spec.ts

apps/nestjs/migrations/
└── 1700000000001-auth-tables.ts
```

### Pattern : JwtPayload + claims

```typescript
// apps/nestjs/src/auth/interfaces/jwt-payload.interface.ts
export interface JwtPayload {
  sub: string;            // user_id (UUID)
  tenant_id: string;      // UUID — Layer 1 isolation
  roles: string[];        // ['OWNER', 'MANAGER', ...] — Layer 2 (STORY-015)
  department_id: string | null;  // Layer 3 ABAC (STORY-019)
  iat: number;
  exp: number;
}
```

### Pattern : Login service

```typescript
// apps/nestjs/src/auth/auth.service.ts (extrait)
async login(dto: LoginDto): Promise<AuthTokens> {
  const tenant = await this.tenantRepo.findOne({
    where: { slug: dto.tenant_slug, is_active: true },
  });
  if (!tenant) throw new NotFoundException('Tenant not found');

  const user = await this.userRepo.findOne({
    where: { tenant_id: tenant.id, email: dto.email.toLowerCase(), is_active: true },
  });
  if (!user) throw new UnauthorizedException('Invalid credentials');

  const passwordOk = await bcrypt.compare(dto.password, user.password_hash);
  if (!passwordOk) throw new UnauthorizedException('Invalid credentials');

  return this.issueTokens(user, tenant);
}

private async issueTokens(user: User, tenant: Tenant): Promise<AuthTokens> {
  const payload: JwtPayload = {
    sub: user.id,
    tenant_id: tenant.id,
    roles: user.roles,
    department_id: user.department_id,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 900, // 15 min
  };
  const access_token = this.jwt.sign(payload, { secret: process.env.JWT_SECRET });

  const refresh_token = crypto.randomBytes(64).toString('hex');
  const token_hash = crypto.createHash('sha256').update(refresh_token).digest('hex');
  await this.refreshRepo.save({
    user_id: user.id,
    tenant_id: tenant.id,
    token_hash,
    expires_at: new Date(Date.now() + 7 * 24 * 3600 * 1000),
  });

  return { access_token, refresh_token, expires_in: 900 };
}
```

### Pattern : Refresh rotation + reuse detection

```typescript
async refresh(dto: RefreshDto): Promise<AuthTokens> {
  const token_hash = crypto.createHash('sha256').update(dto.refresh_token).digest('hex');
  const stored = await this.refreshRepo.findOne({ where: { token_hash } });

  if (!stored || stored.expires_at < new Date()) {
    throw new UnauthorizedException('Invalid refresh token');
  }

  if (stored.revoked_at !== null) {
    // Reuse detected — possible token theft. Revoke all tokens for this user.
    await this.refreshRepo.update(
      { user_id: stored.user_id, revoked_at: IsNull() },
      { revoked_at: new Date() },
    );
    this.audit.log({ action: 'REFRESH_REUSE_DETECTED', user_id: stored.user_id }); // STORY-020
    throw new UnauthorizedException('Token reuse detected');
  }

  await this.refreshRepo.update(stored.id, { revoked_at: new Date() });
  const user = await this.userRepo.findOneOrFail({ where: { id: stored.user_id } });
  const tenant = await this.tenantRepo.findOneOrFail({ where: { id: stored.tenant_id } });
  return this.issueTokens(user, tenant);
}
```

### Pattern : AuthProvider abstraction (OAuth2 prep)

```typescript
// apps/nestjs/src/auth/interfaces/auth-provider.interface.ts
export interface AuthProvider {
  name: 'local' | 'google' | 'apple' | 'azure-ad';
  authenticate(credentials: unknown): Promise<{ user: User; tenant: Tenant }>;
}
// Phase 1 : seul LocalAuthProvider implémenté.
// Phase 2 : GoogleAuthProvider (passport-google-oauth20) ajouté sans toucher AuthService.
```

### Edge cases

- **Email case-insensitivity :** `email.toLowerCase()` au login ET au signup. La colonne `users.email` est normalisée en minuscules par la migration (CHECK constraint `email = lower(email)`).
- **Tenant slug avec espaces / underscores / majuscules :** Slug normalisé en lowercase + tirets. Validation Zod regex `^[a-z0-9-]{3,63}$`.
- **Password vide / trop court :** Validation Zod min 8 chars + au moins 1 majuscule + 1 chiffre. Sera renforcé en STORY-029 (PWA password policy).
- **Refresh token soumis simultanément deux fois (race condition) :** TypeORM transaction `SERIALIZABLE` sur la fonction `refresh()` — un seul des deux passe, l'autre échoue.
- **JWT secret rotation :** Si `JWT_SECRET` change, tous les access tokens en cours sont invalidés (signature invalide). Les refresh tokens restent valides. Documenté dans runbook ops.
- **Clock skew :** Toléré ±30s sur `exp` (option `clockTolerance: 30` dans `jwtVerify`).
- **Logout sans refresh_token :** Si le client logout uniquement avec l'access token sans fournir refresh_token, on ne peut pas révoquer le refresh. Solution : exiger les deux dans le body, ou (alt.) révoquer TOUS les refresh tokens du user (logout-all-devices). Phase 1 : exiger refresh_token explicite ; logout-all = endpoint séparé Phase 2.

### Sécurité — première classe

| Menace | Layer | Mitigation |
|---|---|---|
| User enumeration via login | 1 | Message uniforme `Invalid credentials`, timing constant via bcrypt même si user inexistant (faux compare avec hash dummy) |
| Brute force password | 1 | Throttler 5 req/min/IP + cost bcrypt 12 (~250ms par tentative) |
| JWT theft (XSS) | 1 | Access token court (15 min) + refresh rotation = fenêtre d'exploitation réduite |
| JWT theft (réseau) | 1 | TLS 1.3 obligatoire en prod (cf. architecture line 1375) |
| Refresh token theft | 1 | Reuse detection révoque toute la famille — l'attaquant et la victime sont déconnectés simultanément, alerte ops |
| JWT_SECRET compromis | 1 | RLS Layer 4 (STORY-017) protège même avec claims forgés. JWT secret rotation documentée. |
| Cross-tenant token | 1 | `tenant_id` claim signé + RLS Layer 4 — défense en profondeur |
| Password leak en DB | 1 | bcrypt cost 12 — décryptage impossible en pratique |
| Refresh token leak en DB | 1 | SHA-256 hash uniquement — le serveur ne peut PAS reconstruire le token brut |
| Provisioning abuse | 1 | Endpoint `/tenants/provision` réservé `@Roles('SUPER_ADMIN')` (STORY-015) + audit log (STORY-020) |
| Replay attack JWT | 1 | `exp` court ; pas de mitigation supplémentaire Phase 1 (jti + Redis blacklist Phase 2 si requis) |

### Threat model — bypass scenarios

1. **Layer 1 bypass : JWT signé valide mais tenant_id forgé**
   Possible uniquement si `JWT_SECRET` est compromis. Mitigation : Layer 4 RLS (STORY-017) — même un JWT valide avec `tenant_id` d'un autre tenant ne peut pas lire les données de cet autre tenant car PostgreSQL filtre par `current_setting('app.current_tenant_id')`.

2. **Layer 1 bypass : refresh token volé sur un appareil**
   L'attaquant l'utilise → il fait un refresh → reuse detection plus tard quand le user légitime fait un refresh. Solution : ops alerté + user forcé de re-login. Phase 2 : push notification "Connexion suspecte détectée" via realtime gateway.

3. **Layer 1 bypass : login bot avec credentials valides (credential stuffing)**
   Throttler limite 5/min/IP, mais bot peut tourner sur 1000 IPs. Phase 2 : reCAPTCHA invisible + intégration HaveIBeenPwned pour bloquer passwords déjà fuités. Phase 1 : monitoring audit log STORY-020 + 2FA Phase 3.

### Conflit avec le PRD

PRD FR-009 ligne 349 mentionne rôles par défaut `OWNER, MANAGER, STAFF`. Sprint plan ligne 367 mentionne `OWNER, MANAGER, COMMERCIAL`. **Source de vérité retenue : sprint plan (`COMMERCIAL`)** car aligné avec les écrans de Sprint 1 (S21 BottomNav COMMERCIAL). Cette story ne hardcode aucun rôle (RBAC dynamique = STORY-015) — donc le conflit est non-bloquant.

---

## Dependencies

**Prérequis :**
- STORY-013 (NestJS setup, Docker Compose, TypeORM bootstrap, extensions PostgreSQL)

**Stories bloquées par celle-ci :**
- STORY-015 (RBAC Guards) — direct, consomme `req.user.roles`
- STORY-016 (Multi-tenant Isolation) — direct, consomme `req.user.tenant_id`
- STORY-018 (Redis blacklist refresh tokens) — étend la révocation DB en révocation Redis
- STORY-019 (ABAC CASL) — consomme `req.user.department_id`
- STORY-020 (Audit Log) — log auth events (login success/fail, refresh, logout)
- Indirectement, **toutes** les stories d'EPIC-004 et au-delà.

**Externes :**
- `bcrypt`, `passport`, `passport-jwt`, `passport-local`, `@nestjs/passport`, `@nestjs/jwt`, `@nestjs/throttler` (npm packages).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-014-auth-jwt`.
- [ ] `pnpm --filter @scalario/nestjs run lint` + `typecheck` + `test` verts.
- [ ] Coverage `auth/` ≥ 90% (vérifié par `jest --coverage`).
- [ ] Tests E2E `auth.e2e-spec.ts` : login → me → refresh → logout → me-401 vert.
- [ ] Test d'intrusion (AC-19, AC-20) documenté et passant.
- [ ] Test reuse detection (AC-12) explicitement testé : 5 tokens famille révoqués sur 1 reuse.
- [ ] Test rate limit (AC-09) : 5 login OK, 6ème → 429.
- [ ] Code review passé (`/review` + `/codex review` recommandé pour cette story sécurité).
- [ ] Aucun secret en dur dans le code (grep CI : `JWT_SECRET=`, `password.*=.*'`).
- [ ] `audit_logs.log()` invoqué aux 4 events critiques (login success, login fail, refresh success, refresh reuse) — dépend de STORY-020 si mergée avant ; sinon stub `console.log` avec TODO.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-014 status `completed`, completed_points sprint 2 += 5.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Migration tenants + users + refresh_tokens (avec indexes, FK, RLS placeholder) | 0.5 | Schema déjà spec'é dans architecture. |
| Entities TypeORM + DTOs Zod | 0.5 | Boilerplate. |
| LocalStrategy + JwtStrategy + JwtAuthGuard global + decorators `@Public`/`@CurrentUser` | 1.0 | Le pattern Passport NestJS prend du temps à câbler proprement avec `@Public()` global. |
| AuthService : login + issueTokens + refresh (rotation + reuse detection) + logout | 1.5 | Reuse detection avec révocation famille = logique critique, à tester rigoureusement. |
| AuthController + endpoints + ValidationPipe Zod + Throttler | 0.5 | Standard. |
| AuthProvider interface + LocalAuthProvider impl Phase 1 | 0.25 | Préparation OAuth2 ; pas de code OAuth implémenté ici. |
| Tenants provision endpoint (squelette, Roles guard ajouté STORY-015) | 0.25 | Endpoint + transaction TypeORM. |
| Tests unitaires + E2E + test d'intrusion (AC-19, AC-20) + couverture 90% | 1.0 | Point critique : la couverture sur auth est non-négociable (NestJS Auth + Security target 90%). |
| Logger interceptor (REDACTED password / token) | 0.25 | Petit mais essentiel pour ne pas leak en log. |
| Documentation runbook (rotation JWT_SECRET, force-logout-all, recovery) | 0.25 | Souvent oublié. |
| **Total** | **5** | Fibonacci 5 — significant. |

**Rationale :** C'est LA story sécurité fondatrice. La reuse detection seule + tests d'intrusion représentent 30% du coût. Sans cette discipline, la chaîne sécurité s'effondre.

---

## Notes additionnelles

- **Pourquoi pas refresh tokens en HttpOnly cookie ?** Architecture line 1328 mentionne "HttpOnly cookie OU header selon le client". Phase 1 : header (cohérent multi-plateforme : Flutter mobile, Flutter web, admin web). Phase 2 : cookie pour Admin Web si nécessaire (réduction surface XSS). Cette story implémente header only.
- **Pourquoi cost bcrypt 12 ?** Compromis sécurité/perf : ~250ms par compare sur VPS standard. Cost 14 = ~1s = trop pour UX login. Cost 10 = ~60ms = trop faible Phase 1. À monter à 14 quand login deviendra rare (post-onboarding).
- **OAuth2 Phase 2 :** L'interface `AuthProvider` permet d'ajouter `GoogleAuthProvider` sans toucher `AuthService.login()`. Le strategy Passport correspondant émet le même `JwtPayload`.
- **Logout-all-devices Phase 2 :** Endpoint `POST /auth/logout-all` qui set `revoked_at` sur tous les refresh tokens du user. Pas dans cette story.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
