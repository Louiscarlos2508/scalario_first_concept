# STORY-020 : Audit Log

**Epic :** EPIC-003 — Backend Foundation
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** STORY-014 (auth events), STORY-016 (`tenantContext` pour récupérer tenant_id)

---

## User Story

> **En tant qu'**auditeur, OWNER d'un tenant Scalario, ou ops Scalario,
> **je veux** un log immuable et insert-only de toutes les actions sensibles (auth events, mutations métier, ABAC denies, RLS bypass, appels LLM) avec `who/what/when/tenant/result`,
> **so that** je puisse retracer toute action a posteriori, détecter les anomalies de sécurité, et satisfaire les exigences d'audit comptable OHADA Phase 2 — sans que personne (même un OWNER) ne puisse altérer le log historique.

---

## Description

### Background

Layer 5 logique (architecture line 633 mentionne "Audit log → insert-only" comme partie de la chaîne sécurité). Cette story finalise la table `audit_logs` (créée avec sa policy RLS dans STORY-017) et ajoute :
- Service `AuditLogService` avec API simple `log(entry)`.
- Interceptor NestJS `AuditInterceptor` qui audit automatiquement les actions sensibles (selon décorateur `@Audited()`).
- REVOKE UPDATE/DELETE sur `audit_logs` pour `scalario_app` → insert-only enforced par PostgreSQL.
- Cron job de purge basé sur `tenant.config.audit_retention_days` (default 90j).
- Endpoint `GET /tenants/:slug/audit-logs` (OWNER only) avec pagination et filtres.
- Index optimisés pour les queries time-range par tenant.

L'audit log est un **outil d'investigation**, pas un outil de prévention. Il complète les Layers 1-5 en fournissant la traçabilité forensique.

### Scope

**In scope :**

- Module `apps/nestjs/src/audit/` complet : `audit.module.ts`, `audit-log.service.ts`, `audit.interceptor.ts`, `entities/audit-log.entity.ts`, `dto/`, `__tests__/`.
- Migration `1700000000006-audit-log-policies.ts` :
  - Vérifie que la table `audit_logs` existe (créée par STORY-017).
  - REVOKE UPDATE, DELETE on `audit_logs` from `scalario_app` (l'app peut INSERT et SELECT seulement).
  - Le user `scalario_admin` garde DELETE pour la purge cron (audit-as-admin).
- `AuditLogService.log(entry)` :
  - Insert non-bloquant : retourne immédiatement, l'INSERT se fait async (fire-and-forget avec retry).
  - Pour les events critiques (`AUTH_FAIL`, `RLS_BYPASS_USED`, `ABAC_DENY`), insert synchrone (plus garantie).
  - Hash SHA-256 du payload (jamais les données complètes pour respecter la confidentialité — architecture line 836).
  - Auto-fill `tenant_id` depuis `tenantContext.get()` si non fourni.
  - Auto-fill `user_id` depuis JWT context si non fourni.
- `@Audited(action: string)` decorator pour controllers : audit automatique de chaque appel à la route.
- `AuditInterceptor` global : audit toutes les routes décorées `@Audited()` :
  - Capture `action`, `module_id`, `entity_id` (depuis path params), `payload_hash`.
  - Sur success : log avec `metadata.result = 'success'`.
  - Sur error : log avec `metadata.result = 'error', error_code`.
- Events automatiquement audités (sans decorator, hooks dans les services) :
  - Auth : `AUTH_LOGIN_SUCCESS`, `AUTH_LOGIN_FAIL`, `AUTH_REFRESH`, `AUTH_REFRESH_REUSE_DETECTED`, `AUTH_LOGOUT`, `TENANT_PROVISIONED`.
  - Security : `RBAC_DENY`, `ABAC_DENY`, `RLS_BYPASS_USED`, `TENANT_VIOLATION_DETECTED`.
  - Config : `TENANT_CONFIG_PATCHED`, `TENANT_ROLES_PATCHED`, `TENANT_ABAC_RULES_PATCHED`.
  - LLM (Phase 2 stub) : `LLM_CALL` avec `model, tokens_used, query_hash`.
- Endpoint `GET /tenants/:slug/audit-logs` :
  - Protégé `@Roles('OWNER', 'SUPER_ADMIN')` + `@AbacAction('read', 'AuditLog')`.
  - Pagination cursor-based (audit_log peut atteindre millions de rows).
  - Filtres : `from`, `to`, `user_id`, `action`, `module_id`.
  - Réponse paginée triée `created_at DESC`.
- Cron job `AuditPurgeService` (`@Cron('0 3 * * *')` quotidien à 3h) :
  - Pour chaque tenant : `DELETE FROM audit_logs WHERE tenant_id = ? AND created_at < now() - interval '<retention_days> days'`.
  - Default 90 jours (sprint plan ligne 452). Configurable via `tenant.config.audit_retention_days`.
  - Log la purge elle-même (`AUDIT_PURGE` event) pour méta-audit.
  - Utilise `withRlsBypass` (audité, STORY-017).
- Index `(tenant_id, created_at DESC)` + `(tenant_id, user_id, created_at DESC)` pour queries rapides (sprint plan ligne 453).

**Out of scope (autres stories) :**

- Export audit logs vers SIEM / Splunk → Phase 3.
- Signature cryptographique des logs (blockchain-style) → Phase 3 si compliance demande.
- UI admin pour visualiser audit logs → EPIC-008 admin Flutter Web.
- Streaming audit logs en temps réel → Phase 2.

### Runtime Flow (Audit)

**Cas auth login :**
1. User `POST /auth/login` (STORY-014).
2. `AuthService.login` succès → `auditLog.log({ action: 'AUTH_LOGIN_SUCCESS', user_id, tenant_id, metadata: { ip, user_agent } })`.
3. INSERT async dans `audit_logs`.

**Cas action métier auditée :**
1. Controller `@Audited('CREATE_INVOICE') @Post('invoices')`.
2. Service traite la requête.
3. `AuditInterceptor` (around) :
   - Hash payload SHA-256.
   - Sur completion success : INSERT `{ action: 'CREATE_INVOICE', user_id, tenant_id, module_id: 'invoices', entity_id: response.id, payload_hash, metadata: { result: 'success', latency_ms } }`.
   - Sur error : INSERT `{ ..., metadata: { result: 'error', error_code: 'VALIDATION_FAILED' } }`.

**Cas RLS bypass (STORY-017) :**
1. `withRlsBypass('purgeOldData', 'CleanupService.purge', fn)`.
2. Service `RlsBypassService` :
   - INSERT sync `{ action: 'RLS_BYPASS_USED', caller: 'CleanupService.purge', reason: 'purgeOldData', user_id: null, tenant_id: null }`.
   - Exécute `fn` avec admin connection.

**Cas query OWNER :**
1. OWNER `GET /tenants/acme/audit-logs?from=2026-05-01&action=AUTH_LOGIN_FAIL`.
2. RBAC + ABAC OK.
3. Service paginé retourne 100 dernières entries matchantes triées DESC.

**Cas purge cron :**
1. À 3h chaque nuit, `AuditPurgeService.purgeAll()`.
2. Pour chaque tenant : `DELETE FROM audit_logs WHERE tenant_id = ? AND created_at < now() - 90d`.
3. Log `AUDIT_PURGE` méta-event avec `rows_deleted`.

---

## Acceptance Criteria

### Schema & migration

- [ ] AC-01 — Migration `1700000000006-audit-log-policies.ts` :
  - Vérifie existence table `audit_logs` (créée STORY-017).
  - REVOKE UPDATE, DELETE on `audit_logs` from `scalario_app`.
  - GRANT INSERT, SELECT on `audit_logs` to `scalario_app`.
  - GRANT DELETE on `audit_logs` to `scalario_admin` (pour cron purge).
- [ ] AC-02 — Test : `scalario_app` tente `UPDATE audit_logs SET action = 'X' WHERE id = ?` → `ERROR: permission denied`.
- [ ] AC-03 — Test : `scalario_app` tente `DELETE FROM audit_logs WHERE id = ?` → `ERROR: permission denied`.
- [ ] AC-04 — Index `idx_audit_logs_tenant_time (tenant_id, created_at DESC)` et `idx_audit_logs_user (tenant_id, user_id, created_at DESC)` créés.

### `AuditLogService`

- [ ] AC-05 — `AuditLogService.log(entry)` API : `{ action: string, user_id?, tenant_id?, module_id?, entity_id?, payload?, metadata? }`. Auto-fill `user_id` + `tenant_id` depuis `tenantContext.get()` si non fournis.
- [ ] AC-06 — `payload` est SHA-256 hashé avant insert : `payload_hash = sha256(JSON.stringify(payload))`. Le payload original n'est JAMAIS persisté (architecture line 836 — confidentialité).
- [ ] AC-07 — Insert async par défaut (retourne immédiatement). Buffer interne par batch de 100 (flush toutes les 1s ou quand buffer plein).
- [ ] AC-08 — Insert sync forcé pour les events critiques : `AUTH_FAIL`, `AUTH_REFRESH_REUSE_DETECTED`, `RLS_BYPASS_USED`, `ABAC_DENY`, `TENANT_VIOLATION_DETECTED`. Liste des sync events configurable via constante `SYNC_AUDIT_ACTIONS`.
- [ ] AC-09 — Sur erreur d'insert (DB down) : log Sentry/console error mais **ne crash jamais l'app** (audit ne doit pas bloquer business).

### `AuditInterceptor`

- [ ] AC-10 — Decorator `@Audited(action: string)` exposé.
- [ ] AC-11 — `AuditInterceptor` global enregistré dans `app.module.ts`. Active uniquement sur les routes décorées `@Audited()`.
- [ ] AC-12 — Capture latency_ms (entre handle and complete observable).
- [ ] AC-13 — Capture `metadata.result = 'success' | 'error'`. Sur erreur, capture `error_code` et `error_message` (sans stack trace).
- [ ] AC-14 — Capture `module_id` et `entity_id` depuis path params ou response (configurable via decorator option).

### Auto-audit events

- [ ] AC-15 — Auth events (STORY-014 modif) :
  - `AuthService.login` success → `AUTH_LOGIN_SUCCESS`.
  - `AuthService.login` fail (4xx) → `AUTH_LOGIN_FAIL` (avec `metadata: { reason: 'invalid_credentials' | 'tenant_not_found' | 'user_disabled' }`).
  - `AuthService.refresh` success → `AUTH_REFRESH`.
  - `AuthService.refresh` reuse → `AUTH_REFRESH_REUSE_DETECTED` (sync, critical).
  - `AuthService.logout` → `AUTH_LOGOUT`.
  - `TenantsService.provision` → `TENANT_PROVISIONED`.
- [ ] AC-16 — Security events :
  - `RbacGuard` deny → `RBAC_DENY` (avec `metadata: { required_roles, user_roles }`).
  - `AbacGuard` deny → `ABAC_DENY` (avec `metadata: { action, subject }`).
  - `RlsBypassService.withBypass` → `RLS_BYPASS_USED` (sync).
  - `TenantIsolationFilter` (PostgresError 42501) → `TENANT_VIOLATION_DETECTED` (sync).
- [ ] AC-17 — Config events :
  - `PATCH /tenants/:slug/roles` → `TENANT_ROLES_PATCHED` (avec `metadata: { added, removed }`).
  - `PATCH /tenants/:slug/config` → `TENANT_CONFIG_PATCHED`.
  - `PATCH /tenants/:slug/abac-rules` → `TENANT_ABAC_RULES_PATCHED`.

### Query endpoint

- [ ] AC-18 — `GET /tenants/:slug/audit-logs` retourne paginé :
  - Query params : `from`, `to` (ISO), `user_id`, `action`, `module_id`, `cursor` (base64-encoded `(created_at, id)`), `limit` (default 100, max 500).
  - Response : `{ entries: AuditLogEntry[], next_cursor?: string }`.
- [ ] AC-19 — Endpoint protégé `@Roles('OWNER', 'SUPER_ADMIN')` + `@AbacAction('read', 'AuditLog')`.
- [ ] AC-20 — Performance : query 1M rows tenant filter + 30 day range + cursor pagination → < 200ms p95 grâce à l'index `(tenant_id, created_at DESC)`.

### Purge cron

- [ ] AC-21 — `AuditPurgeService` `@Cron('0 3 * * *')` quotidien.
- [ ] AC-22 — Pour chaque tenant : `DELETE FROM audit_logs WHERE tenant_id = ? AND created_at < now() - (audit_retention_days || 90) * interval '1 day'`.
- [ ] AC-23 — Utilise `withRlsBypass` (audité). La purge elle-même log un `AUDIT_PURGE` event avec `rows_deleted`.
- [ ] AC-24 — Configurable via `tenant.config.audit_retention_days`. Min 30j (legal/compliance), max 3650j (10 ans).

### Tests

- [ ] AC-25 — Tests unitaires `audit-log.service.spec.ts` : auto-fill, hash payload, async vs sync, batching.
- [ ] AC-26 — Tests d'intégration : INSERT depuis `scalario_app` OK ; UPDATE/DELETE depuis `scalario_app` rejected.
- [ ] AC-27 — Test E2E : login fail × 5 → 5 entries `AUTH_LOGIN_FAIL` dans audit_logs.
- [ ] AC-28 — Test E2E : RLS bypass usage → entry `RLS_BYPASS_USED` audité avant exécution.
- [ ] AC-29 — Test cron purge : seed 1000 rows > 90j + 100 rows < 90j → exécuter purge → 100 rows restantes + 1 `AUDIT_PURGE` event.
- [ ] AC-30 — Coverage `audit/` ≥ 90%.

---

## Technical Notes

### Composants concernés

- **Module Audit :** `apps/nestjs/src/audit/` (création complète).
- **Auth modif :** `apps/nestjs/src/auth/auth.service.ts` (hooks audit events).
- **Security modif :** `RbacGuard`, `AbacGuard`, `RlsBypassService`, `TenantIsolationFilter` (hooks audit events).
- **Tenants modif :** `apps/nestjs/src/tenants/tenants.service.ts` (audit PATCH config/roles/abac).

### Structure de fichiers (cible)

```
apps/nestjs/src/audit/
├── audit.module.ts
├── services/
│   ├── audit-log.service.ts          # log(entry), batch, sync/async
│   ├── audit-purge.service.ts        # cron @Cron('0 3 * * *')
│   └── __tests__/
├── interceptors/
│   └── audit.interceptor.ts          # @Audited routes
├── decorators/
│   └── audited.decorator.ts          # @Audited(action)
├── entities/
│   └── audit-log.entity.ts           # TypeORM entity (read-only)
├── dto/
│   ├── audit-log.dto.ts              # log entry input
│   └── audit-query.dto.ts            # GET endpoint query params
├── controllers/
│   └── audit.controller.ts           # GET /tenants/:slug/audit-logs
├── constants.ts                      # SYNC_AUDIT_ACTIONS, RETENTION_DEFAULTS
└── interfaces/
    └── audit-entry.interface.ts

apps/nestjs/migrations/
└── 1700000000006-audit-log-policies.ts
```

### Pattern : AuditLogService

```typescript
// apps/nestjs/src/audit/services/audit-log.service.ts
import { createHash } from 'node:crypto';

const SYNC_ACTIONS = new Set([
  'AUTH_LOGIN_FAIL',
  'AUTH_REFRESH_REUSE_DETECTED',
  'RLS_BYPASS_USED',
  'ABAC_DENY',
  'TENANT_VIOLATION_DETECTED',
]);

@Injectable()
export class AuditLogService implements OnModuleDestroy {
  private buffer: AuditEntry[] = [];
  private flushInterval = setInterval(() => this.flush(), 1000);

  constructor(
    @Inject('APP_DATASOURCE') private readonly ds: DataSource,
    private readonly logger: Logger,
  ) {}

  async log(entry: AuditEntryInput): Promise<void> {
    const ctx = tenantContext.get();
    const enriched: AuditEntry = {
      action: entry.action,
      tenant_id: entry.tenant_id ?? ctx?.tenant_id ?? null,
      user_id: entry.user_id ?? ctx?.user_id ?? null,
      module_id: entry.module_id ?? null,
      entity_id: entry.entity_id ?? null,
      payload_hash: entry.payload
        ? createHash('sha256').update(JSON.stringify(entry.payload)).digest('hex')
        : null,
      metadata: entry.metadata ?? {},
      created_at: new Date(),
    };

    if (SYNC_ACTIONS.has(entry.action)) {
      await this.insertOne(enriched);
    } else {
      this.buffer.push(enriched);
      if (this.buffer.length >= 100) await this.flush();
    }
  }

  private async flush(): Promise<void> {
    if (this.buffer.length === 0) return;
    const toInsert = this.buffer.splice(0);
    try {
      await this.ds.createQueryBuilder()
        .insert().into('audit_logs').values(toInsert).execute();
    } catch (err) {
      this.logger.error('Audit log flush failed', err);
      // Don't crash app — best-effort. Phase 2: Sentry alert + retry queue.
    }
  }

  private async insertOne(entry: AuditEntry): Promise<void> {
    try {
      await this.ds.createQueryBuilder()
        .insert().into('audit_logs').values(entry).execute();
    } catch (err) {
      this.logger.error('Audit log sync insert failed', err);
    }
  }

  async onModuleDestroy() {
    clearInterval(this.flushInterval);
    await this.flush();
  }
}
```

### Pattern : AuditInterceptor

```typescript
// apps/nestjs/src/audit/interceptors/audit.interceptor.ts
@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(
    private readonly reflector: Reflector,
    private readonly audit: AuditLogService,
  ) {}

  intercept(ctx: ExecutionContext, next: CallHandler): Observable<any> {
    const action = this.reflector.get<string>(AUDITED_KEY, ctx.getHandler());
    if (!action) return next.handle();

    const req = ctx.switchToHttp().getRequest();
    const start = Date.now();

    return next.handle().pipe(
      tap((response) => {
        this.audit.log({
          action,
          module_id: req.params?.moduleId,
          entity_id: response?.id ?? req.params?.id,
          payload: req.body,
          metadata: { result: 'success', latency_ms: Date.now() - start },
        });
      }),
      catchError((err) => {
        this.audit.log({
          action,
          module_id: req.params?.moduleId,
          payload: req.body,
          metadata: {
            result: 'error',
            error_code: err.status ?? 500,
            error_message: err.message?.slice(0, 200),
            latency_ms: Date.now() - start,
          },
        });
        return throwError(() => err);
      }),
    );
  }
}
```

### Pattern : AuditPurgeService

```typescript
@Injectable()
export class AuditPurgeService {
  constructor(
    private readonly tenantRepo: Repository<Tenant>,
    private readonly rlsBypass: RlsBypassService,
    private readonly audit: AuditLogService,
  ) {}

  @Cron('0 3 * * *')
  async purgeAll(): Promise<void> {
    const tenants = await this.tenantRepo.find({ where: { is_active: true } });
    for (const tenant of tenants) {
      const retention = tenant.config?.audit_retention_days ?? 90;
      const cutoff = new Date(Date.now() - retention * 24 * 3600 * 1000);
      try {
        const result = await this.rlsBypass.withBypass(
          'audit-purge',
          'CleanupService.purge',
          (qr) =>
            qr.query(
              `DELETE FROM audit_logs WHERE tenant_id = $1 AND created_at < $2`,
              [tenant.id, cutoff],
            ),
        );
        await this.audit.log({
          action: 'AUDIT_PURGE',
          tenant_id: tenant.id,
          metadata: { rows_deleted: result.rowCount, retention_days: retention },
        });
      } catch (err) {
        this.logger.error(`Purge failed for tenant ${tenant.id}`, err);
      }
    }
  }
}
```

### Edge cases

- **Audit DB down :** Service log error mais ne crash pas. Buffer en mémoire jusqu'à reconnexion. Si buffer > 10K entries → drop oldest + log warning. Phase 2 : queue persistante (Redis Streams) pour ne perdre aucune entry.
- **Payload contient PII :** Le `payload_hash` SHA-256 est unidirectionnel — impossible de reconstruire le payload. Garantit la confidentialité tout en permettant la détection de duplicates.
- **Audit purge supprime un event en cours d'investigation :** Mitigation : `tenant.config.audit_retention_days` configurable up à 3650j. Pour investigations en cours, ops peut désactiver la purge (`audit_retention_days = 0` → no purge).
- **Audit log lui-même purgé :** L'event `AUDIT_PURGE` est aussi soumis à la rétention → un AUDIT_PURGE > 90j sera lui-même purgé. Acceptable Phase 1 ; Phase 2 retenir indéfiniment les méta-events (`AUDIT_PURGE`, `RLS_BYPASS_USED`, `TENANT_VIOLATION_DETECTED`).
- **Cron job overlap (purge tenant N alors que purge tenant N-1 toujours en cours) :** Lock distributed Redis (clé `lock:audit-purge`, TTL 1h) — empêche overlap.
- **Tenant supprimé :** RLS empêche d'auditer un tenant inexistant. Mitigation : la suppression d'un tenant est elle-même un event `TENANT_DELETED` (sync, audit log avant suppression effective).

### Sécurité — première classe

| Menace | Layer | Mitigation |
|---|---|---|
| OWNER altère un audit log pour cacher une action | 5 (DB) | REVOKE UPDATE/DELETE → impossible même pour OWNER |
| App compromise tente d'insert audit forgé | 5 | RLS isole le tenant (insertion cross-tenant rejected par WITH CHECK STORY-017) |
| Performance dégrade avec millions d'audit rows | infra | Cron purge + index time-range + partition par mois (Phase 2) |
| Audit logs leak PII | 5 | Hash SHA-256 du payload, jamais le payload brut |
| OWNER lit audit logs d'autres tenants | 5 | RLS Layer 5 + RBAC + ABAC `read AuditLog` filtre par tenant_id |
| Attaquant désactive l'audit pour cacher ses actes | code | Audit hooks dans les guards / services critiques sont obligatoires (CI lint check) |
| Audit purge supprime evidence | 5 | Méta-audit `AUDIT_PURGE` + retention min 30j |
| RLS_BYPASS_USED ignoré | 5 | Sync insert + audit reviewé hebdo par ops (runbook) |

### Threat model — bypass scenarios

1. **Service oublie de logger une action sensible**
   Mitigation : convention `@Audited()` decorator obligatoire sur tous les `@Post`, `@Patch`, `@Delete` métier. CI lint check qui scan les controllers et fail si manquant. Audit hooks dans les guards (RBAC/ABAC deny) sont garantis par le code core (pas opt-in).

2. **Buffer in-memory perdu sur crash NestJS**
   Phase 1 : best-effort, perte acceptable. Phase 2 : Redis Streams comme write-ahead log.

3. **OWNER demande la suppression de logs (legal request)**
   Procédure ops : connecter en `scalario_admin` + `withRlsBypass` + DELETE explicite. **Cette action est elle-même auditée** (méta-audit `AUDIT_LEGAL_DELETE`).

4. **Attaquant compromet `scalario_admin` pour DELETE audit**
   Risque résiduel Phase 1. Mitigation : credentials `scalario_admin` rotation mensuelle + multi-factor pour les ops humaines + Phase 3 signature cryptographique blockchain-style.

### Conflit avec PRD/sprint plan

PRD ligne 452 : "Logs immuables (insert-only, pas d'update/delete)". Sprint plan ligne 451 : "Table `audit_log` : insert-only (0 UPDATE/DELETE autorisé — enforced par RLS)". 

**Précision :** RLS ne peut PAS empêcher UPDATE/DELETE par lui-même (RLS filtre les rows visibles, pas les actions). L'enforcement insert-only se fait via `REVOKE UPDATE, DELETE` au niveau des privilèges PostgreSQL — c'est le pattern correct. Cette story le précise et corrige l'imprécision sémantique du sprint plan.

PRD ligne 449 vs sprint plan ligne 449 : "Chaque `POST /:moduleId/action` logué". Cette story implémente via le decorator `@Audited` qui sera apposé en STORY-022 (ModuleEngine). Cette story fournit l'infrastructure ; STORY-022 décore les routes.

---

## Dependencies

**Prérequis :**
- STORY-013 (NestJS bootstrap)
- STORY-014 (auth events à hooker)
- STORY-016 (`tenantContext` pour auto-fill)
- STORY-017 (table `audit_logs` créée + RLS policy + user `scalario_admin`)

**Stories qui consomment ce service (peuvent être implémentées en parallèle) :**
- STORY-014 (hooks AUTH_*)
- STORY-015 (hooks RBAC_DENY, TENANT_ROLES_PATCHED)
- STORY-017 (hooks RLS_BYPASS_USED, TENANT_VIOLATION_DETECTED)
- STORY-019 (hooks ABAC_DENY, TENANT_ABAC_RULES_PATCHED)
- STORY-022+ (`@Audited()` sur routes métier, Phase 2 LLM_CALL)

**Externes :** `@nestjs/schedule` (pour cron).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-020-audit-log`.
- [ ] `pnpm --filter @scalario/nestjs run lint` + `typecheck` + `test` verts.
- [ ] Coverage `audit/` ≥ 90%.
- [ ] AC-02, AC-03 (REVOKE UPDATE/DELETE) testés.
- [ ] AC-08 (sync events critiques) testé : RLS_BYPASS_USED appearing in DB before fn returns.
- [ ] AC-20 (query 1M rows < 200ms) bench documenté.
- [ ] AC-29 (purge cron) testé.
- [ ] Hooks audit dans STORY-014 (auth), STORY-015 (RBAC), STORY-017 (RLS), STORY-019 (ABAC) câblés (PR séparée si stories pas encore mergées, sinon dans cette PR).
- [ ] Documentation `apps/nestjs/docs/audit-events-catalog.md` listant tous les events auditables et leur structure metadata.
- [ ] Code review passé (`/codex review` recommandé).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-020 status `completed`, completed_points sprint 2 += 3.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Migration `audit-log-policies.ts` (REVOKE/GRANT, indexes) | 0.25 | Petit. |
| `AuditLogService` (log API + buffering async + sync critical events + auto-fill context) | 1.0 | Logique non triviale : batching + sync/async différenciés + crash-safety. |
| `@Audited()` decorator + `AuditInterceptor` (success + error path + latency) | 0.5 | NestJS interceptor pattern + edge cases error capture. |
| Hooks dans STORY-014 (auth), STORY-015 (RBAC), STORY-017 (RLS), STORY-019 (ABAC) | 0.5 | Disséminé dans plusieurs services — doit être systématique. |
| Endpoint `GET /tenants/:slug/audit-logs` paginé + filtres + cursor | 0.5 | Pagination cursor-based pour scale (1M+ rows). |
| `AuditPurgeService` cron + lock distributed Redis + méta-audit | 0.5 | Cron + lock + per-tenant retention config. |
| Tests + bench + documentation events catalog | 0.75 | 30 ACs implique beaucoup de tests. |
| **Total** | **3** | Fibonacci 3 — moderate. Les hooks dispersés et les sync vs async events sont la difficulté principale. |

**Rationale :** Audit log apparait simple (INSERT-only) mais le diable est dans les détails : buffering async crash-safe, sync events critiques, auto-fill context, hooks systématiques, query performante sur table qui grossit vite. Sans ces nuances, l'audit log serait soit lent soit incomplet.

---

## Notes additionnelles

- **Pourquoi pas un service externe (Datadog, Splunk) Phase 1 ?** Coût + complexité + dépendance externe. Phase 1 : DB locale = simple + auto-isolation tenant via RLS. Phase 3 : export vers SIEM si compliance demande.
- **Pourquoi pas signature cryptographique blockchain-style ?** Phase 1 : insert-only via privilèges PostgreSQL = suffisant contre OWNER/user altération. Phase 3 : signature si audit financier OHADA exige preuves cryptographiques.
- **Catalog d'events :** Document `audit-events-catalog.md` listera tous les events possibles avec leur structure `metadata` — référence pour les futures stories qui ajoutent des events.
- **Méta-événements éternels (Phase 2) :** Considérer une table séparée `audit_meta_events` pour `RLS_BYPASS_USED`, `TENANT_VIOLATION_DETECTED`, `AUDIT_PURGE`, `AUDIT_LEGAL_DELETE` qui ne sont JAMAIS purgés. Ces events sont rares (< 100/an) et critiques.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
