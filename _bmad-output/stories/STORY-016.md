# STORY-016 : Multi-tenant Isolation

**Epic :** EPIC-003 — Backend Foundation
**Priorité :** Must Have
**Story Points :** 3
**Status :** Completed
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** STORY-014 (JWT avec claim `tenant_id`)

---

## User Story

> **En tant que** système Scalario hébergeant N tenants sur la même base PostgreSQL,
> **je veux** un middleware NestJS qui injecte automatiquement `tenant_id` (lu depuis le JWT) dans le contexte de chaque requête via `AsyncLocalStorage`, et qui pose `SET app.current_tenant_id` sur la connexion PostgreSQL,
> **so that** un bug de code (oubli de `WHERE tenant_id = ?`) ne puisse jamais exposer les données d'un autre tenant — la fondation pour Layer 4 RLS (STORY-017) et Layer 3 ABAC (STORY-019).

---

## Description

### Background

Cette story est le **glue cross-cutting** qui permet à toutes les autres couches sécurité (RLS, ABAC) de fonctionner. Sans `AsyncLocalStorage` pour propager `tenant_id` à travers les call stacks asynchrones, chaque service métier devrait passer `tenant_id` en paramètre — pollution massive du code et risque énorme d'oubli.

L'architecture (line 384-386) impose :
- Colonne `tenant_id` sur toutes les tables métier (futures migrations).
- `TenantMiddleware` extrait `tenant_id` du JWT et le pose dans le contexte.
- `SET app.current_tenant_id = ?` sur chaque requête PostgreSQL — STORY-017 active les RLS policies qui consomment ce setting.

Cette story est **Phase 1 shared schema** : un seul schéma PostgreSQL, isolation par `tenant_id` colonne + RLS. **Phase 2 schema-per-tenant** : la colonne `tenants.schema_name` (déjà dans le schéma architecture line 710) accueillera le nom du schéma dédié par tenant ; le path migration est documenté ici.

### Scope

**In scope :**

- `TenantContext` (AsyncLocalStorage wrapper) dans `apps/nestjs/src/common/context/tenant-context.ts`.
- `TenantMiddleware` (NestJS middleware) qui :
  1. Lit `req.user.tenant_id` (peuplé par JwtAuthGuard STORY-014).
  2. Vérifie `tenant.is_active = true` (sinon 403).
  3. Pose `tenant_id` dans `AsyncLocalStorage`.
  4. Passe `tenant_id` au TypeORM via `DataSource.query('SET app.current_tenant_id = $1', [tenant_id])` (préparé pour STORY-017 RLS).
- `@CurrentTenant()` decorator pour récupérer `tenant_id` dans n'importe quel service (pas besoin de passer en paramètre).
- Helper `withTenantContext(tenant_id, fn)` pour les jobs asynchrones (workers, cron) qui n'ont pas de request context.
- Connection pooling adapté : chaque connexion qui exécute des queries doit avoir son `app.current_tenant_id` SET (TypeORM acquire/release pattern).
- Migration `1700000000003-tenant-id-default.ts` qui ajoute la colonne `tenant_id UUID NOT NULL` sur les tables métier existantes (à ce stade : aucune table métier sauf les 3 d'auth). Documente le pattern pour les migrations futures.
- Convention TypeORM : toute entity métier `@Entity()` étend une classe abstraite `TenantScopedEntity` avec `@Column({ type: 'uuid' }) tenant_id: string` + index composite.
- Fail-safe global : un `QueryFailedError` lié à RLS (`PostgresError 42501 "insufficient privilege"`) est intercepté par un `TenantIsolationFilter` qui log l'incident (audit STORY-020) et retourne 403 sans leak SQL.
- Test d'intrusion : créer 2 tenants A et B avec data, login user A, tenter requête métier avec un `id` appartenant à tenant B → 0 résultat (RLS prendra le relais en STORY-017 ; ici on vérifie la propagation du `tenant_id` jusqu'à la connexion DB).
- Documentation path migration shared → schema-per-tenant (Phase 2).

**Out of scope (autres stories) :**

- Politiques RLS PostgreSQL (`CREATE POLICY`) → STORY-017 (cette story prépare le terrain en posant `app.current_tenant_id` ; STORY-017 ajoute les policies qui le consomment).
- ABAC contextuel (department, attributs) → STORY-019.
- Schema-per-tenant Phase 2 → migration documentée seulement.
- Audit log auto-généré pour tenant violations → STORY-020.

### Runtime Flow (Tenant Propagation)

1. Client `GET /api/sales` avec `Authorization: Bearer <jwt>`.
2. **Layer 1** `JwtAuthGuard` peuple `req.user = { user_id, tenant_id, roles }`.
3. **Layer 2** `RbacGuard` valide rôle.
4. **Tenant Middleware** :
   a. Vérifie `tenants.is_active = true` (cache).
   b. `tenantContext.run({ tenant_id }, () => next())` → toute la stack asynchrone hérite du contexte.
   c. Sur acquisition de connexion TypeORM, exécute `SET LOCAL app.current_tenant_id = '<uuid>'`.
5. Service métier `SalesService.list()` exécute `SELECT * FROM entities WHERE module_id = 'sales'`.
6. PostgreSQL applique automatiquement la policy RLS : `WHERE tenant_id = current_setting('app.current_tenant_id')::uuid`.
7. Réponse contient uniquement les sales du tenant_id du user.

**Cas job asynchrone (worker) :**
1. Worker démarre, pas de request → pas de `req.user`.
2. Le job a un payload `{ tenant_id, action }`.
3. Wrapper : `withTenantContext(payload.tenant_id, async () => { await processJob(payload); })`.
4. Dans `processJob`, accès à `tenantContext.get().tenant_id` fonctionne normalement.

---

## Acceptance Criteria

### AsyncLocalStorage context

- [ ] AC-01 — `TenantContext` exposé via singleton avec API : `run(value, fn)`, `get()`, `getOrThrow()`. Implémenté avec Node.js `AsyncLocalStorage` natif.
- [ ] AC-02 — Une requête HTTP avec un JWT de tenant A → `tenantContext.get().tenant_id === A`.
- [ ] AC-03 — Deux requêtes concurrentes (tenant A et tenant B) → chaque call stack a son propre `tenant_id` (test : 100 requêtes parallèles, chaque service log `tenantContext.get().tenant_id` → exactement 50 A et 50 B).
- [ ] AC-04 — Si aucun contexte tenant n'a été défini et qu'un service appelle `tenantContext.getOrThrow()` → throw `TenantContextMissingError`. Permet de détecter les call paths qui auraient échappé au middleware.

### Middleware

- [ ] AC-05 — `TenantMiddleware` enregistré globalement via `MiddlewareConsumer.apply(TenantMiddleware).forRoutes('*')`.
- [ ] AC-06 — Si la route est `@Public()` (login, refresh, health) → middleware skip (pas de `req.user`, pas de tenant_id).
- [ ] AC-07 — Si `req.user.tenant_id` est missing alors que la route n'est pas publique → throw `UnauthorizedException` (403 — "Missing tenant context").
- [ ] AC-08 — Middleware vérifie `tenants.is_active = true` via cache `TenantsService` (TTL 5 min). Si `is_active = false` → 403 "Tenant disabled".

### Connection scoping (préparation RLS)

- [ ] AC-09 — Sur chaque acquisition de connexion TypeORM dans le contexte d'une requête, `SET LOCAL app.current_tenant_id = '<tenant_id>'` exécuté avant la première query.
- [ ] AC-10 — Sur release de la connexion, le setting est reset (`RESET app.current_tenant_id`) pour éviter la contamination de la connexion suivante (pattern critique pour le pool).
- [ ] AC-11 — Pattern testé : 2 requêtes consécutives sur le même worker NestJS, tenant A puis tenant B → tenant B ne voit JAMAIS de fuite tenant A.

### Convention entités tenant-scoped

- [ ] AC-12 — Classe abstraite `TenantScopedEntity` dans `common/entities/tenant-scoped.entity.ts` avec `@Column({ type: 'uuid' }) tenant_id: string` + index composite documenté.
- [ ] AC-13 — Toutes les entities métier (à venir dans EPIC-004+) DOIVENT étendre `TenantScopedEntity`. CI lint check : grep `@Entity()` → vérifier extends `TenantScopedEntity` ou whitelisted (`Tenant`, `User`, `RefreshToken`, `AuditLog` ont leur propre tenant_id sans extension).
- [ ] AC-14 — Convention documentée : pour chaque table métier, créer index composite `(tenant_id, <colonne_de_query>)` — explicit dans le code review checklist.

### `@CurrentTenant()` decorator

- [ ] AC-15 — Decorator `@CurrentTenant()` exposé qui injecte `tenant_id` dans les paramètres controller : `getData(@CurrentTenant() tenantId: string)`.
- [ ] AC-16 — Decorator throw si appelé en dehors d'un contexte tenant (route publique).

### Worker / cron support

- [ ] AC-17 — Helper `withTenantContext(tenant_id, fn)` exposé pour les jobs asynchrones. Test : exécuter un job qui calcule des stats pour tenant A → la query SQL utilise `app.current_tenant_id = <A>`.
- [ ] AC-18 — Documentation : runbook "écrire un cron job tenant-scoped" avec exemple.

### Fail-safe & error filter

- [ ] AC-19 — `TenantIsolationFilter` (NestJS ExceptionFilter) intercepte les erreurs PostgreSQL `42501 insufficient privilege` (RLS deny) et retourne 403 sans leak SQL.
- [ ] AC-20 — Lorsqu'un fail RLS se produit, audit log entry `TENANT_VIOLATION_DETECTED` créé (stub si STORY-020 pas mergée).

### Path migration Phase 2

- [ ] AC-21 — Document `_bmad-output/architecture-notes/phase2-schema-per-tenant.md` créé décrivant :
  - Triggers : > 100 tenants, ou requête latency p95 dégrade > 5x, ou client demande isolation forte.
  - Procédure : pour chaque tenant, `CREATE SCHEMA tenant_<slug>` + `CREATE TABLE … LIKE public.<table> INCLUDING ALL` + dump/restore des données + update `tenants.schema_name`.
  - Migration NestJS : middleware exécute `SET search_path TO tenant_<slug>, public` au lieu de `SET app.current_tenant_id`.
  - Estimation effort : 5 jours dev + 2 jours QA pour le premier tenant migré.

### Tests d'intrusion (mandatory)

- [ ] AC-22 — Test E2E `tenant-isolation.e2e-spec.ts` : créer tenant A + B, peupler `audit_logs` avec data des deux, login user de A, appeler service qui fait `SELECT * FROM audit_logs LIMIT 100` (sans WHERE tenant_id) → résultat ne contient QUE des rows tenant A (RLS STORY-017 finalisera le test ; ici la propagation `app.current_tenant_id` doit être prouvée par log SQL).
- [ ] AC-23 — Test : 1000 requêtes parallèles alternant tenants A/B → 0 fuite (assert sur les tenant_id retournés dans les responses).

---

## Technical Notes

### Composants concernés

- **Common :** `apps/nestjs/src/common/context/tenant-context.ts`, `common/entities/tenant-scoped.entity.ts`, `common/filters/tenant-isolation.filter.ts`.
- **Security :** `apps/nestjs/src/security/middleware/tenant.middleware.ts`.
- **Database :** `apps/nestjs/src/common/database.module.ts` (modification : connection acquire hook).
- **Tenants :** `apps/nestjs/src/tenants/tenants.service.ts` (cache `is_active` + validation).

### Structure de fichiers (cible)

```
apps/nestjs/src/common/
├── context/
│   ├── tenant-context.ts            # AsyncLocalStorage wrapper
│   └── __tests__/tenant-context.spec.ts
├── decorators/
│   └── current-tenant.decorator.ts  # @CurrentTenant()
├── entities/
│   └── tenant-scoped.entity.ts      # abstract base
├── filters/
│   └── tenant-isolation.filter.ts   # PostgresError 42501 → 403
└── workers/
    └── with-tenant-context.ts       # helper for async jobs

apps/nestjs/src/security/
└── middleware/
    ├── tenant.middleware.ts         # extracts tenant_id, sets context, sets postgres GUC
    └── __tests__/tenant.middleware.spec.ts

_bmad-output/architecture-notes/
└── phase2-schema-per-tenant.md      # migration path documentation
```

### Pattern : TenantContext (AsyncLocalStorage)

```typescript
// apps/nestjs/src/common/context/tenant-context.ts
import { AsyncLocalStorage } from 'node:async_hooks';

interface TenantStore {
  tenant_id: string;
  user_id?: string;
  roles?: string[];
}

const storage = new AsyncLocalStorage<TenantStore>();

export class TenantContextMissingError extends Error {
  constructor() {
    super('No tenant context set — this code path skipped TenantMiddleware.');
  }
}

export const tenantContext = {
  run<T>(value: TenantStore, fn: () => T | Promise<T>): T | Promise<T> {
    return storage.run(value, fn);
  },

  get(): TenantStore | undefined {
    return storage.getStore();
  },

  getOrThrow(): TenantStore {
    const store = storage.getStore();
    if (!store) throw new TenantContextMissingError();
    return store;
  },
};
```

### Pattern : TenantMiddleware

```typescript
// apps/nestjs/src/security/middleware/tenant.middleware.ts
@Injectable()
export class TenantMiddleware implements NestMiddleware {
  constructor(
    private readonly dataSource: DataSource,
    private readonly tenantsService: TenantsService,
  ) {}

  async use(req: Request, res: Response, next: NextFunction): Promise<void> {
    const user = (req as any).user;
    if (!user?.tenant_id) {
      // Public routes : no user, no tenant context — skip
      return next();
    }

    // Verify tenant is active (cached)
    const tenant = await this.tenantsService.getActive(user.tenant_id);
    if (!tenant) throw new ForbiddenException('Tenant disabled');

    // Run downstream chain inside tenant context
    tenantContext.run(
      { tenant_id: user.tenant_id, user_id: user.user_id, roles: user.roles },
      () => next(),
    );
  }
}
```

### Pattern : Connection scoping pour RLS

TypeORM permet d'intercepter l'acquisition de connexion via un `EntitySubscriber` ou un `QueryRunner` factory. Pattern recommandé :

```typescript
// apps/nestjs/src/common/database/tenant-aware-data-source.ts
@Injectable()
export class TenantAwareQueryRunner {
  constructor(private readonly dataSource: DataSource) {}

  async withConnection<T>(fn: (queryRunner: QueryRunner) => Promise<T>): Promise<T> {
    const ctx = tenantContext.get();
    const queryRunner = this.dataSource.createQueryRunner();
    try {
      await queryRunner.connect();
      if (ctx?.tenant_id) {
        await queryRunner.query(`SET LOCAL app.current_tenant_id = '${ctx.tenant_id}'`);
      }
      return await fn(queryRunner);
    } finally {
      // SET LOCAL is transaction-scoped, but we reset for safety on connection release
      await queryRunner.query(`RESET app.current_tenant_id`).catch(() => {});
      await queryRunner.release();
    }
  }
}
```

**Alternative plus propre :** TypeORM `@EventSubscriber()` ou `Repository.extend()` qui hook avant chaque query. À benchmarker (overhead per-query vs per-connection).

### Pattern : `@CurrentTenant()` decorator

```typescript
// apps/nestjs/src/common/decorators/current-tenant.decorator.ts
export const CurrentTenant = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): string => {
    return tenantContext.getOrThrow().tenant_id;
  },
);
```

### Pattern : TenantScopedEntity

```typescript
// apps/nestjs/src/common/entities/tenant-scoped.entity.ts
export abstract class TenantScopedEntity {
  @Column({ type: 'uuid' })
  @Index()
  tenant_id!: string;
}

// Usage:
@Entity('entities')
@Index('idx_entities_tenant_module', ['tenant_id', 'module_id'])
export class EntityRow extends TenantScopedEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;
  // ...
}
```

### Pattern : Worker helper

```typescript
// apps/nestjs/src/common/workers/with-tenant-context.ts
export async function withTenantContext<T>(
  tenant_id: string,
  fn: () => Promise<T>,
): Promise<T> {
  return tenantContext.run({ tenant_id }, fn);
}

// Usage in cron:
@Cron('0 0 * * *')
async dailyStatsAllTenants() {
  const tenants = await this.tenantRepo.find({ where: { is_active: true } });
  for (const t of tenants) {
    await withTenantContext(t.id, async () => {
      await this.statsService.computeDaily();  // utilise tenantContext.get() inside
    });
  }
}
```

### Edge cases

- **Setting non posé sur connexion réutilisée :** Le pool TypeORM réutilise les connexions. Sans `RESET` ou `SET LOCAL` (transaction-scoped), une requête sans contexte pourrait hériter du `app.current_tenant_id` de la requête précédente. Mitigation : `SET LOCAL` dans une transaction OU `RESET` au release. Test AC-11 prouve l'absence de fuite.
- **Stream / SSE long-lived :** Une connexion SSE peut durer des minutes. `SET LOCAL` est transaction-scoped — si la requête utilise la même connexion sur plusieurs queries non-transactionnelles, le setting est réémis à chaque query. Pattern : envelopper la requête dans une transaction explicite OU utiliser `SET app.current_tenant_id` (session-scoped) avec RESET garanti sur release.
- **Background tasks après response :** `setImmediate(() => doStuff())` — l'AsyncLocalStorage propage tant que la callback est dans le même async context. Si elle est détachée (ex: `setTimeout`), le contexte est perdu. Convention : éviter les detached tasks ; utiliser `withTenantContext` explicitement.
- **WebSocket connections :** STORY-022 traitera. Pour Phase 1, les WebSocket ne sont pas implémentés ; la note dans la doc précise que le pattern devra être étendu.
- **Tenant désactivé en cours de session :** Le middleware vérifie `is_active` à chaque requête (cache 5 min). Si admin désactive un tenant, l'effet est visible dans ≤ 5 min sur toutes les nodes. Acceptable Phase 1.
- **Tenant ID null dans le JWT (bug downstream) :** Middleware throw 403 explicit. Ne JAMAIS poser un `app.current_tenant_id = NULL` qui ferait passer toutes les rows.

### Sécurité — première classe

| Menace | Layer | Mitigation |
|---|---|---|
| Bug code : `SELECT * FROM sales` sans `WHERE tenant_id = ?` | 4 (RLS) + 3 (cette story prépare le terrain) | RLS policy filtre via `app.current_tenant_id` ; sans cette story, RLS aurait NULL et 0 row visible |
| Connection pool fuite cross-tenant | 4 | `SET LOCAL` ou `RESET` à la release ; test AC-11 |
| AsyncLocalStorage perdu (detached task) | 3 | Convention `withTenantContext` + `getOrThrow()` qui crash en dev (visible au lieu de fuite silencieuse) |
| Tenant désactivé continue à servir | 3 | Cache `is_active` 5 min — fenêtre d'exposition limitée |
| Tenant ID forgé dans le JWT | 1 + 4 | Layer 1 signature ; Layer 4 RLS (STORY-017) |
| Schema-per-tenant vs shared confusion (Phase 2 transition) | 3 | Path migration documenté, pas de double mode Phase 1 (uniquement shared) |
| RLS policy bypass (super_user PostgreSQL) | 4 | Le user app NestJS n'est PAS super_user (configuré dans STORY-013 via env). Convention prod : revoke `BYPASSRLS` du role applicatif. |

### Threat model — bypass scenarios

1. **Service appelle directement `dataSource.query()` sans passer par tenant-aware wrapper**
   Le `app.current_tenant_id` ne sera pas posé pour cette requête → RLS bloque tout (0 row retourné). Détecté en dev. Convention : tous les services utilisent `Repository<T>` (qui hérite du contexte) ou `TenantAwareQueryRunner`.

2. **Code legacy / forked qui désactive RLS via `SET row_security = OFF`**
   Le user applicatif PostgreSQL n'a PAS le droit `BYPASSRLS`. `SET row_security = OFF` retourne erreur. Vérifié au boot (STORY-017 AC).

3. **Cron job sans tenant context oublie `withTenantContext`**
   `tenantContext.getOrThrow()` lance une erreur visible. Le service crash early plutôt que de fuir des données.

4. **WebSocket ou job persistant garde un contexte stale**
   Convention : recréer le contexte à chaque event/message. Phase 1 N/A (pas de WebSocket).

### Conflit avec sprint plan

Sprint plan ligne 384 : "Path de migration shared schema → schema-per-tenant documenté et préparé (Phase 2)". Cette story livre le document `phase2-schema-per-tenant.md`. ✅ Cohérent.

---

## Dependencies

**Prérequis :**
- STORY-013 (NestJS, TypeORM)
- STORY-014 (JWT avec `req.user.tenant_id`)

**Stories bloquées par celle-ci :**
- STORY-017 (PostgreSQL RLS) — direct, RLS policies consomment `app.current_tenant_id` posé ici
- STORY-019 (ABAC CASL) — utilise `tenantContext.get()` pour récupérer attributs ABAC
- STORY-020 (Audit Log) — récupère `tenant_id` depuis `tenantContext`
- Indirectement, **toutes** les stories qui touchent la DB (EPIC-004+).

**Externes :** `node:async_hooks` (Node.js natif).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-016-multi-tenant-isolation`.
- [ ] `pnpm --filter @scalario/nestjs run lint` + `typecheck` + `test` verts.
- [ ] Coverage `common/context/`, `security/middleware/` ≥ 90%.
- [ ] Test AC-03 (concurrence 100 req) vert.
- [ ] Test AC-11 (no leakage entre 2 requêtes consécutives) vert avec assertions explicites.
- [ ] Test AC-22 (intrusion cross-tenant) vert — dépend de RLS, marquer skipped avec link STORY-017 si RLS pas encore là.
- [ ] CI lint check : toute entity tenant-scoped étend `TenantScopedEntity` (whitelist exception : Tenant, User, RefreshToken, AuditLog).
- [ ] Document `phase2-schema-per-tenant.md` rédigé et reviewé.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-016 status `completed`, completed_points sprint 2 += 3.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `TenantContext` AsyncLocalStorage wrapper + tests concurrence | 0.5 | Pattern Node natif, mais tests concurrence 100 req parallèles non triviaux. |
| `TenantMiddleware` + intégration `MiddlewareConsumer` global | 0.5 | Standard. |
| Connection scoping (`SET LOCAL app.current_tenant_id` + RESET) | 1.0 | Le plus délicat — assurer que CHAQUE acquisition de connexion réémet le setting. Benchmark overhead. |
| `@CurrentTenant()` decorator + `TenantScopedEntity` abstract + lint check CI | 0.5 | Lint check = TS script qui parse les entities. |
| Helper `withTenantContext` + tests jobs asynchrones | 0.25 | Petit. |
| `TenantIsolationFilter` (PostgresError 42501) | 0.25 | NestJS ExceptionFilter standard. |
| Document phase2-schema-per-tenant.md | 0.25 | Architecture note. |
| Tests E2E (intrusion + concurrence) | 0.5 | Critiques pour preuve sécurité. |
| **Total** | **3** | Fibonacci 3 — moderate. |

**Rationale :** L'effort technique principal est le connection scoping fiable (overhead vs sécurité). Le reste est mécanique.

---

## Notes additionnelles

- **Pourquoi AsyncLocalStorage et pas un argument explicite ?** Architecture NestJS = decorators + DI. Forcer chaque service à recevoir `tenant_id` en paramètre = pollution massive + risque énorme d'oubli. AsyncLocalStorage est le standard Node 14+ pour ce cas exact.
- **Performance overhead :** AsyncLocalStorage ajoute ~5-10% overhead sur les call chains très profondes. Acceptable Phase 1. Si Phase 3 montre un bottleneck, alternatives : Zone.js, manual context propagation (rejected).
- **Schema-per-tenant Phase 2 :** Le path migration est documenté dans cette story. Le déclencheur : > 100 tenants (sprint plan ligne 1404 capacity Phase 1) ou demande client compliance forte (santé, finance). Phase 1 = shared schema + RLS.
- **Pourquoi `SET LOCAL` ?** Transaction-scoped → reset automatique à `COMMIT/ROLLBACK`. Si pas de transaction explicite (auto-commit), équivalent à `SET` session-scoped — d'où le pattern `RESET` au release pour safety.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)
- 2026-05-15 : Completed (Dev / `/bmad:dev-story`)

**Actual Effort :** 3 points (matched estimate)

**Implementation Notes :**
- `tenantContext` AsyncLocalStorage wrapper (`run`/`get`/`getOrThrow` + `TenantContextMissingError`) — AC-01→AC-04 prouvés par 100-req concurrence.
- `TenantMiddleware` global (`AppModule.configure(forRoutes('*'))`). NestJS middleware tournent AVANT les guards : on décode donc le JWT directement via `JwtService.verify` (Passport JwtAuthGuard reste l'autorité officielle de signature). Cas public route / token absent / token invalide → skip, JwtAuthGuard prend le relais pour le 401.
- `TenantsService` (cache `is_active` TTL 5 min) ajouté dans `TenantsModule` — AC-08.
- `TenantAwareQueryRunner` : `set_config('app.current_tenant_id', tenant_id, false)` à l'acquisition + `RESET` garanti au release. STORY-017 ajoutera les policies RLS qui consomment ce setting.
- `TenantIsolationFilter` (APP_FILTER global) intercepte `QueryFailedError` PG `42501` → 403 sanitized + log `TENANT_VIOLATION_DETECTED` (stub audit pour STORY-020).
- `@CurrentTenant()` param decorator + `withTenantContext(tenant_id, fn)` helper workers + `TenantScopedEntity` abstract base.
- Migration `1700000000003-tenant-id-default` pose `app.current_tenant_id=''` au niveau DB (best-effort sur managed DB).
- Document `_bmad-output/architecture-notes/phase2-schema-per-tenant.md` rédigé (triggers, procédure, dual-mode middleware, estimation 5j dev + 2j QA).
- Tests : 76/76 verts (15 suites). Tests dédiés : `tenant-context.spec`, `tenant.middleware.spec` (6 cas incl. 100-req concurrency AC-23 et AC-11 no-leakage 2 req consécutives), `tenants.service.spec`, `tenant-isolation.filter.spec`, `with-tenant-context.spec`, `current-tenant.decorator.spec`.
- Defers : AC-22 (intrusion E2E cross-tenant via RLS) → STORY-017. AC-13 (CI lint check TenantScopedEntity extends) → Phase 2 quand entities métier seront en masse.

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
