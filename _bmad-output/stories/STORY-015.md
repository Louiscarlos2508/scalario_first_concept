# STORY-015 : RBAC Guards Dynamiques

**Epic :** EPIC-003 — Backend Foundation
**Priorité :** Must Have
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** STORY-014 (JWT avec claims `roles[]`)

---

## User Story

> **En tant qu'**intégrateur certifié Scalario,
> **je veux** définir les rôles d'un tenant en JSON (config tenant `tenants.config.roles`) et les permissions par route via décorateur `@Roles('OWNER', 'MANAGER')`,
> **so that** ajouter un nouveau rôle (ex: `LIVREUR`, `MAGASINIER`) ne nécessite aucun déploiement backend, et un user avec rôle `COMMERCIAL` reçoit `403 Forbidden` quand il appelle une route réservée à `OWNER`.

---

## Description

### Background

Layer 2 de la chaîne sécurité Scalario (architecture line 629). Après que Layer 1 (STORY-014, JwtAuthGuard) a authentifié l'utilisateur et extrait `req.user.roles`, Layer 2 (`RbacGuard`) vérifie que l'un des rôles du user correspond aux rôles autorisés sur la route.

Principe non-négociable Scalario : **zéro rôle hardcodé dans le code NestJS**. Les rôles sont des données métier qui varient par tenant (Boulangerie Blandine a `OWNER, MANAGER, COMMERCIAL` ; un cabinet médical aurait `OWNER, MEDECIN, INFIRMIER, SECRETAIRE`). Le code RBAC ne connaît aucun rôle — il se contente de comparer des strings.

Le décorateur `@Roles()` reste utilisé sur les routes (parce que le contrôleur EST le contrat backend), mais les valeurs passées sont des strings arbitraires qui doivent exister dans `tenants.config.roles[]`. Cette validation est faite au boot + lors d'un changement de config (cache invalidation).

### Scope

**In scope :**

- Décorateur `@Roles(...roles: string[])` dans `apps/nestjs/src/common/decorators/roles.decorator.ts`.
- Guard `RbacGuard` dans `apps/nestjs/src/security/guards/rbac.guard.ts` : compare `req.user.roles ∩ requiredRoles ≠ ∅`.
- Service `RolesService` qui charge les rôles définis dans `tenants.config.roles[]` au boot et les met en cache (mémoire + Redis si STORY-018 mergée).
- Endpoint `GET /tenants/:slug/roles` (admin only) qui liste les rôles disponibles pour un tenant.
- Endpoint `PATCH /tenants/:slug/roles` qui ajoute/modifie/supprime des rôles dans la config tenant SANS redémarrage backend (cache invalidé).
- Validation au boot : pour chaque controller décoré `@Roles('FOO')`, si `FOO` n'existe dans aucun template du catalogue, log warning (ce sont des rôles "système" — pas un blocker, parce qu'un tenant peut ne PAS utiliser ce rôle).
- Rôles "système" (cross-tenant) : `SUPER_ADMIN` pour les endpoints d'admin Scalario interne (ex: `/tenants/provision`). Ne sont PAS dans `tenants.config.roles` — ce sont des rôles globaux signés dans le JWT par un mécanisme de provisioning interne.
- Rôles par défaut retail dans le template `retail_fresh_produce.json` (déposé dans `catalog/domains/`) : `OWNER`, `MANAGER`, `COMMERCIAL` (sprint plan ligne 367).
- Tests : user COMMERCIAL appelle endpoint `@Roles('OWNER')` → 403.
- Tests : user OWNER appelle endpoint `@Roles('OWNER', 'MANAGER')` → 200.
- Tests : ajout d'un rôle `LIVREUR` via PATCH config → cache invalidé → user avec rôle LIVREUR peut désormais accéder à un endpoint `@Roles('LIVREUR')`.

**Out of scope (autres stories) :**

- ABAC contextuel (department, montant) → STORY-019.
- RLS PostgreSQL → STORY-017.
- Redis cache layer → STORY-018 (cette story utilise un cache mémoire ; STORY-018 ajoutera Redis comme backend).
- Audit log des changements de rôles → STORY-020.
- UI admin pour éditer les rôles → EPIC-008 (admin Flutter Web).
- Rôles avec hiérarchie (ex: OWNER hérite de MANAGER) → Phase 2 (sortie de scope MVP).

### Runtime Flow (RBAC Decision)

1. Client envoie `GET /api/acme/sales` avec `Authorization: Bearer <jwt>`.
2. **Layer 1** `JwtAuthGuard` valide le JWT, peuple `req.user = { user_id, tenant_id, roles: ['COMMERCIAL'], department_id }`.
3. **Layer 2** `RbacGuard` lit le décorateur `@Roles('OWNER', 'MANAGER')` via `Reflector`.
4. `RbacGuard` calcule `intersect = req.user.roles ∩ ['OWNER', 'MANAGER']`.
5. `intersect = []` → throw `ForbiddenException('Insufficient role')`.
6. Réponse `403 Forbidden`.

**Cas dynamique :**
1. Admin tenant ajoute le rôle `LIVREUR` via `PATCH /tenants/acme/roles` body `{ add: ['LIVREUR'] }`.
2. `RolesService` met à jour `tenants.config.roles` JSONB en DB.
3. `RolesService.invalidateCache(tenant_id)` purge la cache mémoire (et Redis quand STORY-018).
4. Prochain appel `GET /tenants/acme/roles` retourne la liste mise à jour.
5. Le décorateur `@Roles('LIVREUR')` placé sur un controller fonctionne immédiatement (zéro redémarrage).

---

## Acceptance Criteria

### Décorateur & Guard

- [ ] AC-01 — Décorateur `@Roles(...roles: string[])` exposé depuis `common/decorators/roles.decorator.ts`. Métadonnée `ROLES_KEY` exposée pour le Reflector.
- [ ] AC-02 — `RbacGuard` implémente `CanActivate` et compose APRÈS `JwtAuthGuard` (Layer 2 après Layer 1).
- [ ] AC-03 — Si la route n'a PAS de `@Roles()` décorateur → `RbacGuard` retourne `true` (pas de restriction de rôle ; la route reste protégée par JwtAuthGuard).
- [ ] AC-04 — Si la route a `@Roles('OWNER')` et `req.user.roles = ['MANAGER']` → 403.
- [ ] AC-05 — Si la route a `@Roles('OWNER', 'MANAGER')` et `req.user.roles = ['MANAGER']` → 200 (intersection non vide).
- [ ] AC-06 — Si la route a `@Roles('OWNER')` et `req.user.roles = ['OWNER', 'COMMERCIAL']` → 200 (user a le rôle requis ET d'autres rôles).
- [ ] AC-07 — Si `req.user.roles = []` → 403 sur toute route avec `@Roles()`.

### Rôles dynamiques par tenant

- [ ] AC-08 — `tenants.config.roles` JSONB stocke un array de strings : `["OWNER", "MANAGER", "COMMERCIAL"]`. Validation Zod schema au commit (pas de doublons, lowercase forbidden, ≤ 32 chars chaque, regex `^[A-Z][A-Z0-9_]+$`).
- [ ] AC-09 — Migration `1700000000002-tenant-roles.ts` ajoute (si absent) la clé `roles` dans `tenants.config` avec default `["OWNER"]` pour les tenants existants.
- [ ] AC-10 — `RolesService.getRolesForTenant(tenant_id)` retourne `string[]` chargé depuis `tenants.config.roles` avec cache mémoire (TTL 5 min) — basculera sur Redis en STORY-018.
- [ ] AC-11 — Validation : un user ne peut pas avoir un rôle absent de `tenants.config.roles`. À chaque login (STORY-014 `auth.service.login`), filtre `user.roles ∩ tenants.config.roles` — si vide, login refusé `403 No valid roles`.

### Endpoints admin rôles

- [ ] AC-12 — `GET /tenants/:slug/roles` retourne `{ roles: ["OWNER", "MANAGER", "COMMERCIAL"] }` — protégé `@Roles('OWNER', 'SUPER_ADMIN')`.
- [ ] AC-13 — `PATCH /tenants/:slug/roles` body `{ add?: string[], remove?: string[] }` met à jour `tenants.config.roles` — protégé `@Roles('OWNER', 'SUPER_ADMIN')` + audit log STORY-020.
- [ ] AC-14 — `PATCH /tenants/:slug/roles` invalide la cache `RolesService` immédiatement (test : ajouter rôle, prochain `GET /tenants/:slug/roles` retourne le rôle SANS attendre TTL).
- [ ] AC-15 — `DELETE` un rôle utilisé par ≥ 1 user actif → `409 Conflict` avec liste des users impactés. L'admin doit d'abord réassigner ces users.

### Rôles système (cross-tenant)

- [ ] AC-16 — Le rôle `SUPER_ADMIN` est défini comme constante côté code (`security/constants.ts`) et ne peut PAS être assigné à un user via `PATCH /tenants/:slug/roles`. Il est posé manuellement par l'ops (script de seed admin) directement dans `users.roles`.
- [ ] AC-17 — `SUPER_ADMIN` bypass `tenants.config.roles` validation au login (un super admin peut authentifier sur n'importe quel tenant).
- [ ] AC-18 — Endpoint `POST /tenants/provision` (créé en STORY-014) protégé `@Roles('SUPER_ADMIN')` — un OWNER ne peut PAS provisionner un nouveau tenant.

### Test scenario template retail_fresh_produce

- [ ] AC-19 — `catalog/domains/retail_fresh_produce.json` contient `"roles": ["OWNER", "MANAGER", "COMMERCIAL"]` au top level.
- [ ] AC-20 — Provisioning d'un tenant via ce template → `tenants.config.roles = ["OWNER", "MANAGER", "COMMERCIAL"]`.

### Tests sécurité (mandatory)

- [ ] AC-21 — Test E2E `rbac.e2e-spec.ts` : create tenant retail → login OWNER → call protected `@Roles('OWNER')` route → 200. Login COMMERCIAL → même route → 403.
- [ ] AC-22 — Test : ajouter rôle `LIVREUR` via PATCH → assigner à un user (via test fixture direct DB update, l'endpoint user-assignment vient plus tard) → login → call route `@Roles('LIVREUR')` → 200.
- [ ] AC-23 — Test : retirer le rôle `LIVREUR` → user déjà loggué garde son JWT mais à la prochaine requête, son `roles` est revalidé contre `tenants.config.roles` → 403 (rôle obsolète invalidé). **Note :** ce check est best-effort Phase 1 (pas à chaque requête — coût). Phase 1 : revalidation au refresh token. Documenter dans threat model.
- [ ] AC-24 — Coverage `security/guards/` ≥ 90%.

---

## Technical Notes

### Composants concernés

- **Module Security :** `apps/nestjs/src/security/` (création).
- **Common :** `apps/nestjs/src/common/decorators/roles.decorator.ts`.
- **Auth :** `apps/nestjs/src/auth/auth.service.ts` (modification : appel `RolesService` au login).
- **Tenants :** `apps/nestjs/src/tenants/` (endpoints rôles).

### Structure de fichiers (cible)

```
apps/nestjs/src/security/
├── security.module.ts
├── guards/
│   ├── rbac.guard.ts                # Layer 2
│   └── __tests__/rbac.guard.spec.ts
├── services/
│   ├── roles.service.ts             # cache mémoire (Redis en STORY-018)
│   └── __tests__/roles.service.spec.ts
├── constants.ts                     # SUPER_ADMIN, SYSTEM_ROLES
└── interfaces/
    └── role-validation.interface.ts

apps/nestjs/src/common/decorators/
└── roles.decorator.ts               # @Roles(...roles: string[])

apps/nestjs/src/tenants/
├── tenants.module.ts
├── tenants.controller.ts            # GET/PATCH /tenants/:slug/roles
├── tenants.service.ts
└── __tests__/

apps/nestjs/migrations/
└── 1700000000002-tenant-roles.ts    # default tenants.config.roles
```

### Pattern : Décorateur `@Roles`

```typescript
// apps/nestjs/src/common/decorators/roles.decorator.ts
import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);
```

### Pattern : RbacGuard (Layer 2)

```typescript
// apps/nestjs/src/security/guards/rbac.guard.ts
import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../../common/decorators/roles.decorator';
import { RolesService } from '../services/roles.service';
import { SUPER_ADMIN } from '../constants';

@Injectable()
export class RbacGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly rolesService: RolesService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (!required || required.length === 0) return true;

    const req = ctx.switchToHttp().getRequest();
    const user = req.user as { roles: string[]; tenant_id: string };
    if (!user || !Array.isArray(user.roles)) {
      throw new ForbiddenException('No roles in token');
    }

    // Super admin bypass
    if (user.roles.includes(SUPER_ADMIN)) return true;

    // Tenant role validity (defense-in-depth: even if JWT has stale role, validate against current config)
    const tenantRoles = await this.rolesService.getRolesForTenant(user.tenant_id);
    const validUserRoles = user.roles.filter((r) => tenantRoles.includes(r));

    const intersection = validUserRoles.filter((r) => required.includes(r));
    if (intersection.length === 0) {
      throw new ForbiddenException(`Required role(s): ${required.join(', ')}`);
    }
    return true;
  }
}
```

### Pattern : RolesService avec cache mémoire

```typescript
// apps/nestjs/src/security/services/roles.service.ts
@Injectable()
export class RolesService {
  private cache = new Map<string, { roles: string[]; expires_at: number }>();
  private readonly TTL_MS = 5 * 60 * 1000;

  constructor(private readonly tenantRepo: Repository<Tenant>) {}

  async getRolesForTenant(tenant_id: string): Promise<string[]> {
    const cached = this.cache.get(tenant_id);
    if (cached && cached.expires_at > Date.now()) return cached.roles;

    const tenant = await this.tenantRepo.findOneOrFail({ where: { id: tenant_id } });
    const roles = (tenant.config?.roles as string[]) ?? [];
    this.cache.set(tenant_id, { roles, expires_at: Date.now() + this.TTL_MS });
    return roles;
  }

  invalidateCache(tenant_id: string): void {
    this.cache.delete(tenant_id);
    // STORY-018 : pub/sub Redis ici pour invalider sur tous les nodes NestJS
  }
}
```

### Pattern : Application globale du RbacGuard

```typescript
// apps/nestjs/src/app.module.ts (extrait)
{
  provide: APP_GUARD,
  useClass: JwtAuthGuard,         // Layer 1
},
{
  provide: APP_GUARD,
  useClass: RbacGuard,            // Layer 2 (après Layer 1 grâce à l'ordre)
},
// Layer 3 (AbacGuard) sera ajouté en STORY-019
```

### Edge cases

- **Rôle utilisé dans `@Roles()` mais absent de tous les tenants config :** Log warning au boot mais ne bloque pas. Permet aux templates futurs d'introduire de nouveaux rôles avant qu'aucun tenant ne les active.
- **JWT contient un rôle obsolète (rôle retiré du tenant entre login et requête) :** `RbacGuard` filtre `user.roles ∩ tenantRoles` avant intersection avec required. Si le rôle `COMMERCIAL` est retiré de la config, un user avec uniquement `COMMERCIAL` reçoit 403 dès la prochaine requête. (Trade-off : appel DB par requête = coût, mitigé par cache 5min.)
- **Multi-rôle user :** Un user peut avoir 2+ rôles (`['OWNER', 'COMMERCIAL']`). Le RbacGuard accepte si AU MOINS UN match.
- **Endpoint sans `@Roles()` :** Reste protégé par JwtAuthGuard (Layer 1) — un anonyme retourne 401, un user authentifié retourne 200.
- **`@Public()` decorator :** Override JwtAuthGuard ET RbacGuard (route 100% publique, ex: `/auth/login`, `/health`).
- **Race condition PATCH config :** Deux admins éditent `tenants.config.roles` simultanément → optimistic locking via colonne `tenants.updated_at` ou `version`. Migration STORY-016 ajoutera `tenants.version`.
- **Suppression d'un rôle utilisé :** AC-15 — vérifier `SELECT count(*) FROM users WHERE tenant_id = ? AND ? = ANY(roles) AND is_active = true`. Si > 0 → 409.

### Sécurité — première classe

| Menace | Layer | Mitigation |
|---|---|---|
| Élévation de privilège (user modifie son JWT pour ajouter `OWNER`) | 2 | JWT signé HS256 — modification = signature invalide (Layer 1 reject avant Layer 2) |
| User loggué avec rôle retiré entre temps | 2 | Cache TTL 5min + revalidation `tenant.config.roles` à chaque requête (intersection) |
| Rôle hardcodé qui crée un fork du code | 2 | Lint check : grep `@Roles\(` dans tout le code → tous les rôles utilisés doivent exister dans `catalog/` ou `SYSTEM_ROLES`. Sinon CI rouge. |
| Provisioning malveillant via SUPER_ADMIN compromis | 2 | SUPER_ADMIN posé manuellement (pas via API) + audit log STORY-020 + alerte ops sur création tenant |
| Cache poisoning (admin malveillant pousse un rôle ghost) | 2 | Validation Zod stricte au PATCH + audit log + cache invalidation event-sourcée (Phase 2) |
| Bypass via `@Roles()` oublié | 2 | Convention : tout controller métier DOIT avoir `@Roles()` — vérifié par CI script `check_roles_decorator.ts` qui scan tous les controllers et fail si manquant |

### Threat model — bypass scenarios

1. **JWT forgé avec rôle SUPER_ADMIN (JWT_SECRET compromis)**
   Layer 2 accepte (rôle système bypass). Mitigation : Layer 4 RLS empêche l'accès aux tables d'autres tenants ; le SUPER_ADMIN compromis a uniquement accès meta (gestion tenants), pas aux données métier — l'attaquant peut créer/supprimer des tenants mais pas lire leurs ventes. Phase 2 : MFA obligatoire sur SUPER_ADMIN.

2. **User OWNER de tenant A appelle endpoint OWNER avec tenant_id de tenant B forgé**
   Layer 1 rejette (signature JWT invalide). Si JWT_SECRET compromis : Layer 4 RLS bloque accès données. Si RLS désactivé par bug : audit log STORY-020 détecte l'anomalie a posteriori.

3. **Race condition refresh : rôle retiré juste avant le refresh, JWT déjà émis**
   Refresh émet une nouvelle paire avec `user.roles ∩ tenants.config.roles` — un rôle retiré entre temps n'est pas reconduit. Auth.service doit appeler `RolesService.getRolesForTenant()` lors de l'émission du nouveau JWT.

### Conflit avec PRD

PRD ligne 349 et sprint plan ligne 367 mentionnent rôles différents (`STAFF` vs `COMMERCIAL`). Cette story tranche : **`COMMERCIAL`** (sprint plan source de vérité, aligné avec écrans Sprint 1). Le template `retail_fresh_produce.json` et l'AC-19 fixent `["OWNER", "MANAGER", "COMMERCIAL"]`. Aucun rôle hardcodé en TS — donc le conflit est purement éditorial (à corriger dans le PRD).

---

## Dependencies

**Prérequis :**
- STORY-013 (NestJS setup)
- STORY-014 (JWT avec `req.user.roles` peuplé)

**Stories bloquées par celle-ci :**
- STORY-019 (ABAC CASL — Layer 3) — direct, RbacGuard est appelé avant AbacGuard
- STORY-021+ (BDUIService, ModuleEngine — toutes les routes métier protégées par `@Roles()`)
- Indirectement, **toutes** les routes backend protégées par rôle.

**Externes :** Aucune (NestJS Reflector + decorator natifs).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-015-rbac-guards`.
- [ ] `pnpm --filter @scalario/nestjs run lint` + `typecheck` + `test` verts.
- [ ] Coverage `security/guards/` + `security/services/` ≥ 90%.
- [ ] Tests E2E : 3 scenarios (OWNER/COMMERCIAL/multi-role) verts.
- [ ] Test dynamique : ajout rôle LIVREUR runtime → user accède immédiatement (sans restart) — vérifié.
- [ ] Test conflict : DELETE rôle utilisé → 409.
- [ ] Lint custom CI : tout `@Roles('FOO')` → `FOO` ∈ catalog roles ∪ SYSTEM_ROLES (sinon CI fail).
- [ ] Template `retail_fresh_produce.json` créé minimal avec roles `["OWNER", "MANAGER", "COMMERCIAL"]`.
- [ ] Audit log appelé sur PATCH /tenants/:slug/roles (stub si STORY-020 pas mergée).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-015 status `completed`, completed_points sprint 2 += 5.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Décorateur `@Roles` + Reflector + tests unitaires | 0.5 | Standard NestJS. |
| `RbacGuard` (Layer 2) avec super admin bypass + intersection tenant config | 1.5 | La logique d'intersection roles ∩ tenantRoles ∩ required est triple — à tester rigoureusement. |
| `RolesService` cache mémoire + invalidation + interface pour Redis (STORY-018) | 1.0 | Cache TTL 5min + interface stable pour Redis swap futur. |
| Endpoints `GET/PATCH /tenants/:slug/roles` + Zod validation + 409 conflict | 1.0 | Validation rôles unique, regex, longueur. Détection users impactés (DELETE). |
| Migration tenant config roles default + template retail_fresh_produce.json minimal | 0.25 | Petit. |
| Constants SYSTEM_ROLES + SUPER_ADMIN + script seed admin | 0.25 | Script séparé `pnpm seed:admin`. |
| Lint CI custom (check_roles_decorator) | 0.25 | TS script qui parse les controllers et valide les `@Roles()`. |
| Tests E2E (3 scenarios) + tests dynamiques (add/remove rôle runtime) | 0.75 | Tests doivent prouver la dimension dynamique (FR-010 critère). |
| Documentation : "ajouter un rôle en 30 secondes" runbook | 0.25 | UX intégrateur — promesse PRD FR-010. |
| **Total** | **5** | Fibonacci 5 — significant. |

**Rationale :** RBAC dynamique + tests dynamiques (add/remove runtime) coûte plus que RBAC statique. La promesse "0 deploy pour ajouter un rôle" doit être vraiment testée — pas juste codée.

---

## Notes additionnelles

- **Pas de hiérarchie de rôles Phase 1 :** Si un endpoint nécessite OWNER OU MANAGER, on liste explicitement `@Roles('OWNER', 'MANAGER')`. Phase 2 pourra introduire `RoleHierarchy` (OWNER inherits MANAGER) si feedback intégrateurs le demande.
- **Pourquoi pas Casbin ?** Casbin = ABAC complet. Phase 1 : RBAC simple (data-driven mais flat) suffit. CASL (STORY-019) prend le relais pour ABAC. Casbin = Phase 3 si Rete Algorithm requis (FR-037).
- **Convention rôles :** `[A-Z][A-Z0-9_]+` (UPPER_SNAKE). Cohérent avec JWT claims standard et lisibilité humaine.
- **Promesse intégrateur :** L'AC-22 (LIVREUR ajouté runtime) est LA preuve marketing de la valeur produit. À faire tester par Carlos en démo.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
