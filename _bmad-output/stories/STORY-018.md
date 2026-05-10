# STORY-018 : Redis Sessions + Cache Layouts BDUI

**Epic :** EPIC-003 — Backend Foundation
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** STORY-013 (Redis service Docker), STORY-014 (refresh tokens existent en DB)

---

## User Story

> **En tant que** système Scalario,
> **je veux** un service Redis configuré avec 3 namespaces : (1) blacklist refresh tokens révoqués, (2) cache layouts BDUI par clé `{tenant_id}:{screen_id}:{role}` TTL 5min, (3) placeholder rate limiting LLM Phase 2,
> **so that** la révocation de tokens est instantanée (pas d'attente TTL JWT 15 min), les layouts BDUI sont servis en < 20ms (cache hit) sans hit DB, et l'invalidation de cache via pub/sub est event-driven (pas de stale data quand un admin modifie la config tenant).

---

## Description

### Background

Architecture line 224-228 définit Redis avec 3 rôles distincts. Cette story matérialise ces 3 rôles dans des modules NestJS :
- **Sessions blacklist** : étend la révocation DB de STORY-014. Quand un user logout ou un refresh est marqué `revoked_at`, le hash du token est aussi pushed dans Redis avec TTL = `expires_at - now()`. Le `JwtAuthGuard` vérifie Redis à chaque requête pour révocation instantanée (au lieu d'attendre l'expiration de 15 min de l'access token).

  **Note importante :** la révocation Redis cible les *refresh tokens* (architecture line 1336). Pour révoquer aussi les access tokens en cours, on doit blacklister leur `jti` (JWT ID claim) — cette story ajoute le claim `jti` et la blacklist côté access token aussi, parce que sinon un access token compromis reste valide jusqu'à 15 min.

- **Cache layouts BDUI** : prépare l'infrastructure pour STORY-021 (BDUIService). Layouts servis depuis le cache quand possible. Invalidation pub/sub event-driven (un PATCH config tenant émet un event, tous les nodes invalident leur cache local + Redis).

- **Rate limiting LLM** : placeholder Phase 2 (FR-024+). Cette story expose l'interface `RateLimiterService` mais l'implémentation par tenant viendra avec FastAPI.

### Scope

**In scope :**

- Module `apps/nestjs/src/cache/` complet : `cache.module.ts`, `redis.service.ts`, `token-blacklist.service.ts`, `bdui-cache.service.ts`, interfaces, `__tests__/`.
- Client Redis : `ioredis` package (mature, supporte cluster, retry, circuit breaker built-in).
- `RedisService` factory : 1 instance par usage logique (sessions, cache, futur rate-limit) — keys préfixées pour éviter collisions (`session:`, `bdui:`, `ratelimit:`).
- `TokenBlacklistService` : `add(token_hash, ttl_seconds)`, `isRevoked(token_hash): boolean`. JWT access tokens reçoivent un claim `jti`. La blacklist contient des `jti` pour access tokens et `token_hash` pour refresh tokens.
- Modification `JwtAuthGuard` (STORY-014) pour vérifier blacklist Redis sur chaque requête (cache check ~1ms). Si blacklisté → 401.
- Modification `AuthService.logout` (STORY-014) pour push dans Redis blacklist avec TTL = `exp - now()`.
- `BdUiCacheService` : `get(tenant_id, screen_id, role)`, `set(...)`, `invalidate(tenant_id, screen_id?)`, `invalidateAll(tenant_id)`. Sérialisation JSON. Compression gzip si payload > 10KB.
- Pub/sub channel `bdui:invalidate` : when admin updates tenant config → publish `{ tenant_id, screens?: [...] }` → tous les nodes NestJS écoutent et invalident leur cache local L1 + Redis L2.
- `RateLimiterService` interface stub (méthodes `check`, `increment`) — implémentation Phase 2.
- Health check `/health` (STORY-013) inclut Redis ping.
- Tests : blacklist (add → check → expire), cache hit/miss/invalidate, pub/sub propagation cross-process.
- Configuration : `REDIS_URL`, `REDIS_PASSWORD`, `REDIS_DB_SESSIONS=0`, `REDIS_DB_CACHE=1` (séparation logique via Redis databases).

**Out of scope (autres stories) :**

- BDUIService NestJS (utilise le cache) → STORY-021 EPIC-004.
- Rate limiting LLM par tenant → Phase 2 (FR-024+).
- Audit log Redis ops → STORY-020 (cette story émet des events que STORY-020 capture si déjà mergée).
- Redis Cluster / Sentinel → Phase 2 (sprint plan ligne 1410).
- Redis persistence tuning (AOF / RDB) → Phase 2 ops.

### Runtime Flow

**Logout (révocation instantanée) :**
1. Client `POST /auth/logout` avec `{ refresh_token }`.
2. STORY-014 `AuthService.logout` :
   a. `UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = ?` (DB).
   b. `tokenBlacklist.add(refresh_token_hash, ttl_seconds = expires_at - now())`.
   c. **Nouveau** : `tokenBlacklist.add(jti_of_current_access_token, 900)` (max 15 min).
3. Client réutilise l'access token → `JwtAuthGuard` lit `jti` → vérifie blacklist → 401.

**Cache hit BDUI (futur usage STORY-021) :**
1. Client `GET /api/acme/layout/dashboard` (Authorization Bearer).
2. STORY-021 `BdUiController.getLayout` appelle `bdUiCache.get('acme', 'dashboard', 'COMMERCIAL')`.
3. Redis hit → retourne JSON décompressé en ~5ms.
4. Client reçoit le layout.

**Cache invalidation (admin update config) :**
1. Admin `PATCH /tenants/acme/config` (modifie `screen_configs.config`).
2. Service publish `bdui:invalidate` event : `{ tenant_id: 'acme', screens: ['dashboard'] }`.
3. Tous les nodes NestJS reçoivent le message → invalident leur cache local L1 (`Map`) + Redis L2 (`DEL`).
4. Prochain `GET /layout/dashboard` → miss → recharge depuis DB.

---

## Acceptance Criteria

### RedisService bootstrap

- [ ] AC-01 — `ioredis` ajouté à `apps/nestjs/package.json`. Configuration depuis `REDIS_URL` (ex: `redis://:password@redis:6379`).
- [ ] AC-02 — `RedisService` exposé en singleton. Connection retry exponential backoff (3 retries → fail). Health check intégré.
- [ ] AC-03 — Au boot NestJS, ping Redis `PONG` doit répondre en < 50ms. Si fail → boot continue (NestJS ne crash pas) mais log error et `/health` retourne 503 jusqu'à reconnexion.
- [ ] AC-04 — `/health` endpoint (STORY-013) retourne `redis: 'up'` ou `redis: 'down'` selon état du ping.

### Token blacklist (Layer 1.5)

- [ ] AC-05 — `TokenBlacklistService.add(key, ttl)` insère dans Redis : `SET blacklist:<key> 1 EX <ttl>`. Préfixe `blacklist:` pour scope.
- [ ] AC-06 — `TokenBlacklistService.isRevoked(key)` retourne `boolean` via `EXISTS blacklist:<key>` en < 5ms.
- [ ] AC-07 — JWT payload (modification STORY-014) inclut désormais le claim `jti` (UUID v4 généré à l'émission).
- [ ] AC-08 — `JwtAuthGuard` vérifie `isRevoked(payload.jti)` AVANT toute autre logique. Si true → 401 `Token revoked`.
- [ ] AC-09 — `AuthService.logout` (modif STORY-014) appelle :
  - `tokenBlacklist.add(refresh_token_hash, ttl = (expires_at - now()) seconds)`.
  - `tokenBlacklist.add(access_token_jti, 900)` — TTL = max possible (15 min).
- [ ] AC-10 — Test : login → logout → tenter `GET /auth/me` avec l'access token → 401 immédiat (sans attendre 15 min d'expiration JWT).
- [ ] AC-11 — Test : add à blacklist avec TTL 1s → wait 2s → `isRevoked` retourne false (TTL expiré).

### BDUI Cache layer

- [ ] AC-12 — `BdUiCacheService.get(tenant_id, screen_id, role)` retourne `JSON | null`. Clé Redis : `bdui:{tenant_id}:{screen_id}:{role}`.
- [ ] AC-13 — `BdUiCacheService.set(tenant_id, screen_id, role, layout)` stocke avec TTL 5 min (300s). Si payload > 10KB → gzip avant store, marqué par préfixe binaire `\x1f\x8b`.
- [ ] AC-14 — `BdUiCacheService.invalidate(tenant_id, screen_id?)` :
  - Si `screen_id` fourni : `DEL bdui:{tenant_id}:{screen_id}:*` (scan + del par batch).
  - Si non : `DEL bdui:{tenant_id}:*`.
- [ ] AC-15 — Cache hit < 20ms p95 sur payload moyen (5KB JSON). Mesure benchmark dédié `scripts/benchmark-bdui-cache.sh`.
- [ ] AC-16 — Cache local L1 (in-process `Map` avec LRU max 100 entries, TTL 60s) en plus de Redis L2 — réduit p99 latency sur hit chaud.

### Pub/sub invalidation

- [ ] AC-17 — Channel Redis `bdui:invalidate` configuré. Publisher utilise `redis.publish('bdui:invalidate', JSON.stringify({tenant_id, screens?}))`.
- [ ] AC-18 — Subscriber `BdUiCacheService.subscribeInvalidation()` initialisé au boot. Sur message reçu → `invalidate(tenant_id, screen_id)` local L1 + L2.
- [ ] AC-19 — Test cross-process : 2 instances NestJS (simulées via 2 connections), set cache instance 1, publish invalidate depuis instance 2 → instance 1 voit le cache invalidé en < 100ms.

### Module integration

- [ ] AC-20 — `RolesService` (STORY-015) cache TTL 5 min : migrer du cache mémoire vers Redis (clé `roles:{tenant_id}`). Maintenir cache L1 in-process pour < 1ms hit.
- [ ] AC-21 — `RolesService.invalidateCache(tenant_id)` publie sur channel `roles:invalidate` ; tous les nodes nettoyent leur cache local. Permet à STORY-015 AC-14 (PATCH config → invalidation immédiate) de fonctionner cross-process.

### Rate limiter stub

- [ ] AC-22 — `RateLimiterService` interface défini avec méthodes `check(key, limit, window)`, `increment(key)`. Implémentation `RedisRateLimiter` créée mais non câblée Phase 1. Test unitaire couvre l'algo (token bucket Redis-based) mais aucune route ne l'utilise yet.

### Sécurité

- [ ] AC-23 — `REDIS_PASSWORD` requis (boot fail si absent). Aucune connexion Redis sans password.
- [ ] AC-24 — Redis `requirepass` actif dans `docker-compose.yml` (modif STORY-013 si nécessaire).
- [ ] AC-25 — Aucun PII clair dans Redis. Token hashes uniquement (jamais le token brut). Si layout JSON contient des noms users → cache key inclut `role` mais payload est filtré côté BDUIService (STORY-021) avant store.

### Tests

- [ ] AC-26 — Coverage `cache/` ≥ 85%.
- [ ] AC-27 — Test E2E : login → logout → access token réutilisé → 401 (sans attendre TTL JWT).
- [ ] AC-28 — Test : Redis down → graceful degradation (cache miss = recharge DB ; blacklist check fail = log error mais ne bloque pas la requête — décision Phase 1 : fail-open sur blacklist Redis pour éviter total outage si Redis crash). Documenter explicitement ce trade-off dans threat model.

---

## Technical Notes

### Composants concernés

- **Module Cache :** `apps/nestjs/src/cache/` (création).
- **Auth modif :** `apps/nestjs/src/auth/auth.service.ts`, `auth/strategies/jwt.strategy.ts`, `auth/guards/jwt-auth.guard.ts` (claim `jti` + blacklist check).
- **Security modif :** `apps/nestjs/src/security/services/roles.service.ts` (Redis swap).

### Structure de fichiers (cible)

```
apps/nestjs/src/cache/
├── cache.module.ts
├── services/
│   ├── redis.service.ts             # ioredis singleton wrapper
│   ├── token-blacklist.service.ts   # blacklist:<jti|hash>
│   ├── bdui-cache.service.ts        # bdui:{tenant}:{screen}:{role}
│   └── rate-limiter.service.ts      # stub Phase 2
├── interfaces/
│   ├── token-blacklist.interface.ts
│   ├── bdui-cache.interface.ts
│   └── rate-limiter.interface.ts
├── __tests__/
│   ├── token-blacklist.service.spec.ts
│   ├── bdui-cache.service.spec.ts
│   └── pubsub-invalidation.e2e-spec.ts
└── constants.ts                     # KEY_PREFIXES, TTLs
```

### Pattern : RedisService

```typescript
// apps/nestjs/src/cache/services/redis.service.ts
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client!: Redis;
  private subscriber!: Redis;  // dedicated for pub/sub (best practice ioredis)

  async onModuleInit() {
    this.client = new Redis(process.env.REDIS_URL!, {
      maxRetriesPerRequest: 3,
      retryStrategy: (times) => Math.min(times * 200, 2000),
      lazyConnect: false,
    });
    this.subscriber = this.client.duplicate();

    await this.client.ping(); // boot health check
  }

  getClient(): Redis { return this.client; }
  getSubscriber(): Redis { return this.subscriber; }

  async onModuleDestroy() {
    await this.client.quit();
    await this.subscriber.quit();
  }
}
```

### Pattern : TokenBlacklistService

```typescript
// apps/nestjs/src/cache/services/token-blacklist.service.ts
@Injectable()
export class TokenBlacklistService {
  private readonly PREFIX = 'blacklist:';

  constructor(private readonly redis: RedisService) {}

  async add(key: string, ttlSeconds: number): Promise<void> {
    if (ttlSeconds <= 0) return;  // already expired
    await this.redis.getClient().set(`${this.PREFIX}${key}`, '1', 'EX', ttlSeconds);
  }

  async isRevoked(key: string): Promise<boolean> {
    try {
      const result = await this.redis.getClient().exists(`${this.PREFIX}${key}`);
      return result === 1;
    } catch (err) {
      // Redis down — fail-open (log + allow request) Phase 1
      // TODO Phase 2: fail-closed with circuit breaker
      this.logger.error('Redis blacklist check failed', err);
      return false;
    }
  }
}
```

### Pattern : Modification JwtAuthGuard

```typescript
// apps/nestjs/src/auth/guards/jwt-auth.guard.ts (modif)
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(
    private readonly reflector: Reflector,
    private readonly blacklist: TokenBlacklistService,
  ) {
    super();
  }

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    if (this.reflector.get(IS_PUBLIC_KEY, ctx.getHandler())) return true;

    const ok = (await super.canActivate(ctx)) as boolean;
    if (!ok) return false;

    const req = ctx.switchToHttp().getRequest();
    const jti = req.user?.jti;
    if (jti && (await this.blacklist.isRevoked(jti))) {
      throw new UnauthorizedException('Token revoked');
    }
    return true;
  }
}
```

### Pattern : BdUiCacheService

```typescript
// apps/nestjs/src/cache/services/bdui-cache.service.ts
import { gzipSync, gunzipSync } from 'node:zlib';

@Injectable()
export class BdUiCacheService implements OnModuleInit {
  private readonly PREFIX = 'bdui:';
  private readonly TTL = 300; // 5 min
  private readonly COMPRESS_THRESHOLD = 10 * 1024;
  private readonly local = new LRUCache<string, any>({ max: 100, ttl: 60_000 });

  constructor(private readonly redis: RedisService) {}

  async onModuleInit() {
    await this.redis.getSubscriber().subscribe('bdui:invalidate');
    this.redis.getSubscriber().on('message', (channel, message) => {
      if (channel === 'bdui:invalidate') {
        const { tenant_id, screens } = JSON.parse(message);
        this.invalidateLocal(tenant_id, screens);
      }
    });
  }

  async get<T>(tenant_id: string, screen_id: string, role: string): Promise<T | null> {
    const key = `${this.PREFIX}${tenant_id}:${screen_id}:${role}`;
    const local = this.local.get(key);
    if (local) return local as T;

    const raw = await this.redis.getClient().getBuffer(key);
    if (!raw) return null;
    const json = raw[0] === 0x1f && raw[1] === 0x8b
      ? gunzipSync(raw).toString('utf8')
      : raw.toString('utf8');
    const parsed = JSON.parse(json);
    this.local.set(key, parsed);
    return parsed;
  }

  async set<T>(tenant_id: string, screen_id: string, role: string, value: T): Promise<void> {
    const key = `${this.PREFIX}${tenant_id}:${screen_id}:${role}`;
    const json = JSON.stringify(value);
    const buf = Buffer.byteLength(json) > this.COMPRESS_THRESHOLD
      ? gzipSync(json)
      : Buffer.from(json);
    await this.redis.getClient().set(key, buf, 'EX', this.TTL);
    this.local.set(key, value);
  }

  async invalidate(tenant_id: string, screen_id?: string): Promise<void> {
    const pattern = screen_id
      ? `${this.PREFIX}${tenant_id}:${screen_id}:*`
      : `${this.PREFIX}${tenant_id}:*`;
    // SCAN + DEL by batch (avoid KEYS in production)
    const stream = this.redis.getClient().scanStream({ match: pattern, count: 100 });
    for await (const keys of stream) {
      if ((keys as string[]).length) await this.redis.getClient().del(...(keys as string[]));
    }
    await this.redis.getClient().publish('bdui:invalidate', JSON.stringify({ tenant_id, screens: screen_id ? [screen_id] : undefined }));
  }

  private invalidateLocal(tenant_id: string, screens?: string[]) {
    for (const key of this.local.keys()) {
      if (!key.startsWith(`${this.PREFIX}${tenant_id}:`)) continue;
      if (screens && !screens.some((s) => key.includes(`:${s}:`))) continue;
      this.local.delete(key);
    }
  }
}
```

### Edge cases

- **Redis down au boot :** NestJS log error mais ne crash pas. `/health` retourne 503 sur le check redis. Une fois Redis up, NestJS reconnecte automatiquement (ioredis retry). Trade-off : meilleur fail-open pour blacklist (sinon outage Redis = outage Scalario).
- **Pub/sub message manqué :** Si une instance NestJS perd la connexion au moment de la publication, elle manque le message. Redis pub/sub n'a pas de durabilité. Mitigation : TTL 5min sur le cache → max 5 min de stale data. Phase 2 : Redis Streams ou backplane Kafka pour durabilité.
- **Race condition cache vs DB :** Set cache après commit DB (pas avant). Si commit fail, cache n'est jamais peuplé avec stale data.
- **Race condition invalidation vs set :** PATCH config → invalidate publié → autre node fait set juste avant le message → cache stale. Mitigation : invalidate fait `DEL` (idempotent), set se contente d'overwrite. La fenêtre de stale data = TTL local L1 max (60s). Acceptable.
- **Memory bloat L1 :** `LRUCache` borné à 100 entries × ~50KB = 5MB max par instance. Acceptable.
- **Compression payload < 10KB :** Pas compressé. Évite overhead gzip pour petits payloads.
- **JTI collision :** `crypto.randomUUID()` = ~5×10^36 possibilities — collision impossible en pratique. Pas de check unicité nécessaire.

### Sécurité — première classe

| Menace | Layer | Mitigation |
|---|---|---|
| Token volé utilisé après logout | 1 (renforcé) | Blacklist Redis instantanée — fenêtre d'exploitation = 0 (vs 15 min sans blacklist) |
| Redis exposé publiquement | infra | `requirepass` + pas de port exposé en prod (réseau Docker interne) |
| Memory exhaustion attack (push 1M tokens dans blacklist) | 1.5 | TTL borné par `expires_at` du token (max 7 jours pour refresh, 15 min access) — taille blacklist auto-bornée |
| Cache poisoning (admin malveillant push layout XSS) | 2 | Layout JSON validé par Zod (STORY-014b/021) avant store. Le cache contient des données déjà validées. |
| Pub/sub message forgé (Redis client externe) | infra | Redis password protégé + réseau interne. Pub/sub channels non exposés. |
| Cache hit révèle existence d'un screen_id | bas | Acceptable — screen_ids ne sont pas des secrets |
| Audit log des révocations manqué | 5 | Chaque `add()` blacklist log dans audit (STORY-020) |
| Fail-open blacklist (Redis down) | trade-off documenté | Fenêtre exposition = durée outage Redis. Phase 2 : circuit breaker fail-closed après N failures |

### Threat model — bypass scenarios

1. **Attaquant a un access token volé, user logout, attaquant continue à requêter**
   Sans blacklist : valide jusqu'à exp (15 min). Avec blacklist : invalidé instantanément. ✅

2. **Attaquant a un refresh token volé, présente avant que le user fasse refresh légitime**
   STORY-014 reuse detection révoque la famille → tous les tokens (access + refresh) blacklistés. L'attaquant et le user sont déconnectés simultanément. ✅

3. **Redis down — attaquant rejoue un token logged out**
   Fail-open Phase 1 : la requête passe (blacklist check renvoie false sur erreur). C'est un trade-off documenté — outage Redis = outage Scalario sinon. Phase 2 : circuit breaker + alerting.

4. **Attaquant accède à Redis directement (réseau interne compromis)**
   Tokens hashes uniquement (jamais le token brut). Layouts BDUI sont publics par tenant (déjà filtrés par rôle au store). PII : aucun en clair.

### Conflit avec l'architecture

Architecture line 1336 mentionne "Insert refresh_token_hash dans Redis blacklist (TTL = durée restante)". Cette story ajoute la blacklist `jti` pour les access tokens aussi, parce que sinon un access compromis reste valide jusqu'à 15 min après logout. Discussion design : acceptable ou over-engineering ?

**Décision :** ajouter (cohérent avec la promesse "révocation instantanée"). Coût : +1 entry Redis par logout. Acceptable.

---

## Dependencies

**Prérequis :**
- STORY-013 (service Redis Docker)
- STORY-014 (refresh tokens, AuthService.logout)

**Stories bloquées par celle-ci :**
- STORY-021 (BDUIService) — utilise `BdUiCacheService` directement
- STORY-015 (RBAC) — option : migrer le cache mémoire vers Redis (peut être fait en parallèle ou en retro)

**Externes :** `ioredis`, `lru-cache` (npm packages).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-018-redis-cache`.
- [ ] `pnpm --filter @scalario/nestjs run lint` + `typecheck` + `test` verts.
- [ ] Coverage `cache/` ≥ 85%.
- [ ] AC-10 (logout → 401 immédiat) prouvé par test E2E.
- [ ] AC-19 (cross-process invalidation < 100ms) prouvé par test multi-instance.
- [ ] AC-15 (cache hit < 20ms p95) mesuré et documenté.
- [ ] Modification `JwtAuthGuard` (claim `jti` + blacklist) reviewée — pas de régression sur les tests STORY-014.
- [ ] `RolesService` migré vers Redis avec invalidation pub/sub (STORY-015 AC-14 cross-process désormais effectif).
- [ ] Documentation : README cache module + trade-off fail-open documenté.
- [ ] Code review passé.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-018 status `completed`, completed_points sprint 2 += 3.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `RedisService` ioredis singleton + health check + retry strategy | 0.5 | Standard. |
| `TokenBlacklistService` + JWT `jti` claim + JwtAuthGuard hook | 0.75 | Modif STORY-014 + tests E2E révocation instantanée. |
| `BdUiCacheService` (get/set/invalidate + gzip + L1 LRU) | 1.0 | Sérialisation, compression, scanStream pour invalidation pattern. |
| Pub/sub channels (`bdui:invalidate`, `roles:invalidate`) + subscriber init | 0.5 | Tests cross-process non triviaux. |
| Migration `RolesService` mémoire → Redis (STORY-015) | 0.25 | Petit refactor. |
| `RateLimiterService` stub Phase 2 + interface tests | 0.25 | Boilerplate. |
| Tests + benchmarks + documentation fail-open | 0.75 | Critique : test E2E révocation, benchmark p95. |
| **Total** | **3** | Fibonacci 3 — moderate. |

**Rationale :** Pas de logique métier complexe, mais beaucoup de modules NestJS et de tests d'intégration (cross-process, pub/sub). La compression + L1 LRU + pub/sub est un design solide qui évite la dette technique Phase 2.

---

## Notes additionnelles

- **Pourquoi `ioredis` et pas `redis` (node-redis) ?** ioredis a le pub/sub natif plus mature, support cluster Phase 2, et un retry built-in. node-redis v4+ rattrappe mais ioredis reste le standard NestJS communautaire.
- **Pourquoi `getBuffer` et pas `get` ?** Le payload peut être gzippé (binaire). `get` retourne string et corromprait les bytes binaires.
- **Trade-off fail-open documenté :** Phase 1 priorise la disponibilité (Scalario continue à servir si Redis crash 30s). Phase 2 circuit breaker permettra fail-closed après seuil de failures (sinon attaquant peut DDoS Redis pour bypass blacklist).
- **Cache local L1 LRU :** 100 entries × ~50KB = 5MB par instance NestJS. Acceptable. Si > 100 tenants × > 5 screens × 3 rôles, on dépasse 100 entries — LRU évince les moins utilisés. C'est OK : redirige sur L2 Redis.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
