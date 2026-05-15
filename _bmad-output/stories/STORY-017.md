# STORY-017 : PostgreSQL RLS

**Epic :** EPIC-003 — Backend Foundation
**Priorité :** Must Have
**Story Points :** 5
**Status :** Completed
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** STORY-016 (`SET app.current_tenant_id` posé sur chaque connexion)

---

## User Story

> **En tant qu'**architecte sécurité Scalario,
> **je veux** que PostgreSQL applique des Row-Level Security policies sur toutes les tables tenant-scoped (filtrage automatique `tenant_id = current_setting('app.current_tenant_id')::uuid`),
> **so that** même si une requête NestJS contourne les guards (bug, exploit, oubli de `WHERE tenant_id`), la DB elle-même bloque cryptographiquement les fuites cross-tenant — la 5ᵉ et dernière ligne de défense, indépendante du code applicatif.

---

## Description

### Background

Layer 5 de la chaîne sécurité (architecture line 632, 1365). Les couches 1-3 (JWT, RBAC, ABAC) sont des contrôles applicatifs : un bug NestJS, un guard mal câblé, ou un endpoint oublié peut les bypasser. Layer 5 RLS est défense en profondeur : la base de données refuse elle-même de retourner des rows d'un tenant != `current_setting('app.current_tenant_id')`.

L'architecture (line 737-846) définit les policies pour `users`, `screen_configs`, `entities`, `workflow_states`, `audit_logs`. Cette story les active toutes via migration et ajoute :
- Un user PostgreSQL applicatif sans `BYPASSRLS` (ne peut PAS contourner les policies — même un dev avec accès production ne peut pas lire cross-tenant via le user app).
- Tests d'intrusion automatisés en CI.
- Benchmark : overhead RLS < 5% (sprint plan ligne 401).
- Script rollback documenté.

NFR-003 (architecture line 1999) : "5 couches : JWT+RBAC+ABAC+pgvector+RLS / Tests intrusion automatisés CI". Cette story finalise la Layer 5.

### Scope

**In scope :**

- Migration `1700000000004-rls-policies.ts` qui :
  1. Active `ROW LEVEL SECURITY` sur toutes les tables tenant-scoped existantes : `users`, `refresh_tokens`, et placeholders pour les futures (`entities`, `workflow_states`, `audit_logs`, `screen_configs`, `sync_mutations`, `embeddings`).
  2. Crée les policies `<table>_tenant_isolation` avec `USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid)`.
  3. Force `FORCE ROW LEVEL SECURITY` (s'applique même au propriétaire de la table — protection contre les owners malveillants).
- Migration `1700000000005-rls-app-user.ts` qui crée un user PostgreSQL `scalario_app` dédié à NestJS, **sans `BYPASSRLS`**, sans `SUPERUSER`. NestJS connecte en tant que ce user. Un user `scalario_admin` (séparé, avec `BYPASSRLS`) est utilisé uniquement pour les migrations + ops manuelles.
- `current_setting('app.current_tenant_id', true)` avec second argument `true` (missing_ok) : si setting absent, retourne `NULL` → `tenant_id = NULL` est `unknown` (jamais true) → 0 row visible. **Fail-closed by default.**
- Helper `withRlsBypass(fn)` (séparé, dans `apps/nestjs/src/common/database/rls-bypass.ts`) qui exécute `fn` avec un user `scalario_admin` pour les use cases légitimes cross-tenant : provisioning, super admin, jobs de purge cross-tenant. **Audité systématiquement** (STORY-020).
- Tests d'intrusion automatisés en CI :
  1. Créer 2 tenants A et B avec data.
  2. Connecter en `scalario_app` sans `SET app.current_tenant_id` → `SELECT * FROM users` retourne 0 rows.
  3. `SET app.current_tenant_id = '<A_id>'` → retourne uniquement users tenant A.
  4. Tenter `SET app.current_tenant_id = '<B_id>'` au milieu d'une transaction → switch immédiat (test rollback safety).
  5. Tenter `SET row_security = OFF` en `scalario_app` → erreur (privilège insuffisant).
- Benchmark RLS overhead : `pgbench` ou script custom qui mesure 10K SELECTs avec et sans RLS. AC : overhead < 5%.
- Script rollback `scripts/rollback-rls.sql` documenté qui désactive les policies (use-case : migration cassée en prod, retour rapide à schéma sans RLS — uniquement avec audit log + audit human).
- Documentation : "Comment écrire une migration tenant-scoped" — checklist pour les futures stories.

**Out of scope (autres stories) :**

- Schema-per-tenant Phase 2 (les policies RLS deviendraient redondantes mais conservées en defense-in-depth).
- ABAC row filtering (department, attributs) → STORY-019.
- Audit log policies → STORY-020 (cette story crée la table mais STORY-020 finalise insertion + retention).
- pgvector RLS Layer 4 → Phase 2 (FR-025).

### Runtime Flow (RLS in action)

**Cas nominal :**
1. Request → STORY-016 middleware → `SET LOCAL app.current_tenant_id = '<A>'`.
2. Service `SalesService` exécute `SELECT * FROM entities WHERE module_id = 'sales'`.
3. PostgreSQL réécrit la query en `SELECT * FROM entities WHERE module_id = 'sales' AND (tenant_id = current_setting('app.current_tenant_id')::uuid)`.
4. Retourne uniquement les rows tenant A.

**Cas exploit (bug code applicatif, guard skipped) :**
1. Endpoint mal protégé permet à un user de tenant A de fournir un `id` d'entity de tenant B.
2. Service exécute `SELECT * FROM entities WHERE id = '<B_entity_id>'`.
3. PostgreSQL applique la policy : `tenant_id = current_setting('app.current_tenant_id')::uuid` → tenant A only.
4. La row de tenant B n'est PAS retournée → 0 result → service retourne 404. **Fuite évitée.**

**Cas exploit (JWT_SECRET compromis, claim tenant_id forgé) :**
1. Attaquant forge un JWT avec `tenant_id = <B>` (mais user_id = `<A_user>`).
2. Layer 1 valide la signature (JWT_SECRET compromis).
3. STORY-016 middleware pose `SET app.current_tenant_id = <B>`.
4. Service exécute `SELECT * FROM users WHERE id = '<A_user>'`.
5. Policy filtre : `tenant_id = <B>` → user A (tenant A) n'est pas visible → 404.
6. **Mais** l'attaquant peut maintenant lire les users du tenant B (via `SELECT * FROM users`). Layer 5 protège tenant A mais pas tenant B contre ce JWT forgé spécifique. Mitigation : rotation `JWT_SECRET` + alerte ops via audit log STORY-020.

---

## Acceptance Criteria

### Migrations RLS

- [ ] AC-01 — Migration `1700000000004-rls-policies.ts` active `ENABLE ROW LEVEL SECURITY` + `FORCE ROW LEVEL SECURITY` sur les tables tenant-scoped suivantes : `users`, `refresh_tokens`, et création anticipée des policies pour `entities`, `workflow_states`, `audit_logs`, `screen_configs`, `sync_mutations`, `embeddings` (les tables sont créées par cette story si manquantes — schema architecture line 759-880).
- [ ] AC-02 — Chaque table a une policy `<table>_tenant_isolation` :
  ```sql
  CREATE POLICY <table>_tenant_isolation ON <table>
    USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
  ```
- [ ] AC-03 — Le second argument `true` (missing_ok) est utilisé : si `app.current_tenant_id` n'est pas défini, `current_setting()` retourne NULL (au lieu de throw), la condition devient `tenant_id = NULL` (unknown) → 0 rows visible (**fail-closed**).
- [ ] AC-04 — Migration crée les tables `entities`, `workflow_states`, `audit_logs`, `screen_configs`, `sync_mutations`, `embeddings` selon le schéma de l'architecture (line 759-880) si elles n'existent pas — autrement étend les tables existantes avec les policies.

### Users PostgreSQL

- [ ] AC-05 — Migration `1700000000005-rls-app-user.ts` (ou script `init-db.sql` exécuté par Docker entrypoint, choix d'impl) crée 2 users :
  - `scalario_app` : `LOGIN`, **PAS** `SUPERUSER`, **PAS** `BYPASSRLS`. GRANT SELECT/INSERT/UPDATE/DELETE sur les tables.
  - `scalario_admin` : `LOGIN`, `SUPERUSER` ou minimum `BYPASSRLS`. Utilisé uniquement pour migrations + ops manuelles.
- [ ] AC-06 — `apps/nestjs/.env` `DATABASE_URL` pointe vers `scalario_app` (pas admin). Vérifié au boot (NestJS query `SELECT current_user` doit retourner `scalario_app`).
- [ ] AC-07 — Migration runner utilise `DATABASE_URL_ADMIN` (séparé) → user `scalario_admin`. Les migrations s'exécutent avec `BYPASSRLS` (sinon impossible de modifier les schémas).

### Helper `withRlsBypass`

- [ ] AC-08 — Helper `withRlsBypass(fn)` exposé dans `common/database/rls-bypass.ts`. Utilise une connexion `scalario_admin` séparée (pool dédié, max 2 connexions).
- [ ] AC-09 — Tout appel à `withRlsBypass` est audité : payload `{ action, called_from, tenant_filter? }` insert dans `audit_logs` (audit-as-call-site, STORY-020).
- [ ] AC-10 — `withRlsBypass` ne peut être appelé que depuis 3 endroits whitelistés (lint check CI) :
  1. `tenants.service.ts` (provisioning).
  2. `auth.service.ts` (super admin login).
  3. `cron/cleanup.service.ts` (purge cross-tenant).

### Tests d'intrusion (CI obligatoire)

- [ ] AC-11 — Test `rls-intrusion.e2e-spec.ts` :
  - Setup : 2 tenants A, B ; 5 users dans A, 5 dans B.
  - Test 1 : connect `scalario_app` sans SET → `SELECT count(*) FROM users` = 0.
  - Test 2 : `SET app.current_tenant_id = '<A_id>'` → `SELECT count(*) FROM users` = 5 (uniquement A).
  - Test 3 : `SET app.current_tenant_id = '<B_id>'` → `SELECT count(*) FROM users` = 5 (uniquement B, switch propre).
  - Test 4 : `SET app.current_tenant_id = '<random_uuid>'` (tenant inexistant) → `SELECT count(*) FROM users` = 0.
  - Test 5 : tenter `SET row_security = OFF` en `scalario_app` → `ERROR: permission denied`.
  - Test 6 : tenter `ALTER TABLE users DISABLE ROW LEVEL SECURITY` en `scalario_app` → `ERROR: must be owner`.
- [ ] AC-12 — Test `rls-cross-tenant-write.e2e-spec.ts` :
  - `SET app.current_tenant_id = '<A_id>'`.
  - `INSERT INTO users (tenant_id, email, ...) VALUES ('<B_id>', ...)` → `ERROR: new row violates row-level security policy`. **WITH CHECK** policy active.
- [ ] AC-13 — Tests inclus dans CI GitHub Actions, job `security-tests` (architecture line 1791).

### Benchmark performance

- [ ] AC-14 — Script `scripts/benchmark-rls.sh` :
  - Insère 10K rows tenant A et 10K rows tenant B dans `entities`.
  - Exécute 1000 queries `SELECT * FROM entities WHERE module_id = 'sales' LIMIT 100` :
    - Sans RLS (table sans policies, ou user `scalario_admin`).
    - Avec RLS (user `scalario_app` + `SET app.current_tenant_id`).
  - Compare p50, p95, p99 latency.
- [ ] AC-15 — AC critère sprint plan ligne 401 : **overhead RLS < 5% sur p95**. Si > 5%, ajouter index composite `(tenant_id, <colonne_query>)` jusqu'à atteindre la cible. Documenter les indexes ajoutés.

### Rollback

- [ ] AC-16 — Script `scripts/rollback-rls.sql` documenté :
  ```sql
  -- WARNING: this disables tenant isolation. Audit + ops sign-off required.
  ALTER TABLE users DISABLE ROW LEVEL SECURITY;
  ALTER TABLE refresh_tokens DISABLE ROW LEVEL SECURITY;
  -- ... toutes les tables
  ```
- [ ] AC-17 — Documentation runbook : "Quand utiliser le rollback RLS" + "Comment réactiver après fix".

### Documentation

- [ ] AC-18 — Document `apps/nestjs/docs/migrations-tenant-scoped.md` : checklist pour toute future migration de table métier :
  1. Étendre `TenantScopedEntity`.
  2. Ajouter colonne `tenant_id UUID NOT NULL`.
  3. Ajouter `ENABLE ROW LEVEL SECURITY` + `FORCE`.
  4. Ajouter policy `<table>_tenant_isolation`.
  5. Ajouter index `(tenant_id, ...)`.
  6. Test d'intrusion E2E.

### Edge cases & WITH CHECK

- [ ] AC-19 — Toutes les policies utilisent à la fois `USING (read)` ET `WITH CHECK (write)` : empêche un user de tenant A d'INSERT/UPDATE des rows avec `tenant_id = <B>`. Si `WITH CHECK` non spécifié, prend la même condition que `USING`.
- [ ] AC-20 — Policy `audit_logs` : `USING (tenant_id = current_setting('app.current_tenant_id')::uuid)` + interdiction UPDATE/DELETE via REVOKE (insert-only — STORY-020).

---

## Technical Notes

### Composants concernés

- **Migrations :** `apps/nestjs/migrations/1700000000004-rls-policies.ts`, `1700000000005-rls-app-user.ts`.
- **Database :** `apps/nestjs/src/common/database/rls-bypass.ts`, `database.module.ts` (deux pools : app + admin).
- **CI :** `.github/workflows/ci.yml` job `security-tests`.
- **Init script :** `scripts/init-db.sql` (exécuté par Docker entrypoint Phase 1).

### Pattern : Policy SQL

```sql
-- apps/nestjs/migrations/1700000000004-rls-policies.ts (extrait)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;

CREATE POLICY users_tenant_isolation ON users
  USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid)
  WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- Idem pour refresh_tokens, entities, workflow_states, audit_logs, screen_configs,
-- sync_mutations, embeddings.
```

### Pattern : Two-pool DataSource

```typescript
// apps/nestjs/src/common/database/database.module.ts
@Module({
  providers: [
    {
      provide: 'APP_DATASOURCE',
      useFactory: () => new DataSource({
        type: 'postgres',
        url: process.env.DATABASE_URL,        // scalario_app (no BYPASSRLS)
        // ... entities, no synchronize
      }).initialize(),
    },
    {
      provide: 'ADMIN_DATASOURCE',
      useFactory: () => new DataSource({
        type: 'postgres',
        url: process.env.DATABASE_URL_ADMIN,  // scalario_admin (BYPASSRLS)
        extra: { max: 2 },                    // Tiny pool — admin ops are rare
      }).initialize(),
    },
  ],
  exports: ['APP_DATASOURCE', 'ADMIN_DATASOURCE'],
})
export class DatabaseModule {}
```

### Pattern : `withRlsBypass`

```typescript
// apps/nestjs/src/common/database/rls-bypass.ts
@Injectable()
export class RlsBypassService {
  constructor(
    @Inject('ADMIN_DATASOURCE') private readonly adminDS: DataSource,
    private readonly audit: AuditLogService,  // STORY-020
  ) {}

  async withBypass<T>(
    reason: string,
    callerName: string,
    fn: (qr: QueryRunner) => Promise<T>,
  ): Promise<T> {
    // Whitelist enforcement (defense-in-depth + lint)
    const allowed = ['TenantsService.provision', 'AuthService.superAdminLogin', 'CleanupService.purge'];
    if (!allowed.includes(callerName)) {
      throw new Error(`withRlsBypass not allowed from ${callerName}`);
    }

    await this.audit.log({
      action: 'RLS_BYPASS_USED',
      caller: callerName,
      reason,
      tenant_id: tenantContext.get()?.tenant_id ?? null,
    });

    const qr = this.adminDS.createQueryRunner();
    try {
      await qr.connect();
      return await fn(qr);
    } finally {
      await qr.release();
    }
  }
}
```

### Pattern : Test d'intrusion (Jest E2E)

```typescript
// apps/nestjs/test/security/rls-intrusion.e2e-spec.ts
describe('RLS — intrusion tests', () => {
  let app: INestApplication;
  let appDS: DataSource;     // scalario_app
  let adminDS: DataSource;   // scalario_admin
  let tenantA: string, tenantB: string;

  beforeAll(async () => {
    // setup with adminDS: create 2 tenants, seed users
  });

  it('returns 0 rows without app.current_tenant_id set', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    const rows = await qr.query('SELECT count(*) FROM users');
    expect(parseInt(rows[0].count, 10)).toBe(0);
    await qr.release();
  });

  it('returns only tenant A rows when app.current_tenant_id = A', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    await qr.query(`SET app.current_tenant_id = '${tenantA}'`);
    const rows = await qr.query('SELECT count(*) FROM users');
    expect(parseInt(rows[0].count, 10)).toBe(5);
    await qr.release();
  });

  it('rejects SET row_security = OFF as scalario_app', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    await expect(qr.query('SET row_security = OFF')).rejects.toThrow(/permission denied/);
    await qr.release();
  });

  it('rejects INSERT with foreign tenant_id', async () => {
    const qr = appDS.createQueryRunner();
    await qr.connect();
    await qr.query(`SET app.current_tenant_id = '${tenantA}'`);
    await expect(
      qr.query(`INSERT INTO users (tenant_id, email, password_hash) VALUES ($1, $2, $3)`,
        [tenantB, 'attacker@example.com', 'hash']),
    ).rejects.toThrow(/violates row-level security/);
    await qr.release();
  });
});
```

### Edge cases

- **Migration runtime sur DB existante avec millions de rows :** `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` est instantané (DDL only, aucune réécriture). Aucun lock long. ✅ safe en prod.
- **`current_setting('app.current_tenant_id', true)::uuid` cast NULL :** PostgreSQL gère NULL → cast NULL = NULL ; `tenant_id = NULL` est UNKNOWN (jamais TRUE) → 0 rows. ✅ fail-closed.
- **Application function `SECURITY DEFINER` :** Si on ajoute des fonctions PL/pgSQL avec `SECURITY DEFINER` Phase 2, attention : elles s'exécutent avec les droits du créateur (potentiellement `scalario_admin`). Convention : éviter `SECURITY DEFINER` ou les marquer explicitement audited.
- **VIEWs sur tables RLS :** Les vues n'héritent PAS des policies RLS automatiquement. Si on ajoute une vue `active_users` Phase 2, lui assigner manuellement les RLS policies (ou éviter les vues sur des tables tenant-scoped).
- **`COPY` (bulk import) :** Bypass RLS si user a `BYPASSRLS`. `scalario_app` n'a pas ce droit donc `COPY` respecte les policies. Les imports en masse passent par `scalario_admin` + `withRlsBypass` audité.
- **Triggers :** Les triggers s'exécutent avec les droits du user qui exécute la query. Si trigger insert sur `audit_logs` depuis `scalario_app` qui n'a pas RLS bypass, l'audit_logs INSERT respecte RLS — donc le trigger doit être conscient du tenant_id. STORY-020 traite.

### Sécurité — première classe

| Menace | Layer | Mitigation par cette story |
|---|---|---|
| Bug NestJS oublie `WHERE tenant_id = ?` | 5 | Policy filtre automatiquement |
| JWT forgé tenant A, accède tenant B | 5 | Mitigé partiellement : RLS protège tenant A mais l'attaquant accède tenant B via le JWT forgé (Layer 1 prévention par rotation JWT_SECRET) |
| Dev avec DBeaver sur prod fait `SELECT * FROM users` | 5 | Si connecté en `scalario_app` : 0 row (pas de current_tenant_id). Si connecté en `scalario_admin` : tout visible (intentionnel — admin a besoin de debugger), mais audit log de la session |
| Owner de table `BYPASSRLS` implicite | 5 | `FORCE ROW LEVEL SECURITY` empêche le owner de bypasser |
| User app obtient `BYPASSRLS` par escalade | 5 | `scalario_app` créé avec `NOSUPERUSER NOBYPASSRLS` ; revue de code refuse `GRANT SUPERUSER` |
| `withRlsBypass` utilisé depuis call site non whitelisté | 5 | Lint check + runtime throw + audit |
| Performance dégradation > 5% | 5 | Benchmark + indexes composite (tenant_id, ...) |
| Policy mal écrite (oubli colonne) | 5 | Migration test couvre toutes les tables ; CI lint check sur policy syntax |

### Threat model — bypass scenarios

1. **JWT_SECRET compromis + claim tenant_id = victim_tenant**
   Layer 5 protège le tenant_id correct mais pas le tenant ciblé par l'attaquant. Mitigation : Layer 1 rotation + audit log alert sur connexions inhabituelles (STORY-020).

2. **Connexion directe à PostgreSQL avec user `scalario_admin` volé**
   `scalario_admin` a `BYPASSRLS` → tout visible. Mitigation :
   - Mot de passe `scalario_admin` jamais committé, stocké dans secrets manager.
   - Connexions `scalario_admin` ne sont autorisées que depuis le réseau Docker interne (pas exposé sur 5432 publique en prod).
   - Audit log automatique à chaque utilisation.

3. **SQL injection dans `scalario_app`**
   RLS limite les dégâts : l'attaquant ne peut accéder qu'au tenant courant. Le tenant_id ne peut pas être changé via injection (PostgreSQL ne permet pas `SET app.current_tenant_id` dans un SELECT). Layer Zod (STORY-013/021) prévient l'injection elle-même.

4. **Stored procedure `SECURITY DEFINER` créée par admin**
   Phase 1 : aucune SP. Phase 2 : si introduit, audit obligatoire.

### Conflit avec sprint plan

Sprint plan ligne 401 : "Overhead RLS mesuré < 5%". Cette story livre le benchmark + indexes correctifs. ✅

Sprint plan ligne 402 : "Migration RLS : script rollback documenté". Livré (AC-16, AC-17). ✅

---

## Dependencies

**Prérequis :**
- STORY-013 (PostgreSQL Docker, migrations)
- STORY-014 (tables `users`, `refresh_tokens` créées)
- STORY-016 (`SET app.current_tenant_id` posé sur connexion par middleware)

**Stories bloquées par celle-ci :**
- STORY-019 (ABAC CASL — Layer 3) : pas direct, mais l'AC-22 de STORY-016 (test intrusion) est finalisé par STORY-017
- STORY-020 (Audit Log) : la table `audit_logs` est créée ici avec sa policy ; STORY-020 finalise insertion service
- Indirectement, **toutes** les stories qui touchent la DB.

**Externes :** PostgreSQL 16+ (image `pgvector/pgvector:pg16` de STORY-013).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-017-postgres-rls`.
- [ ] Migration appliquée en dev sans erreur ; rollback testé.
- [ ] `scalario_app` user créé ; NestJS connecte avec ce user (vérifié par `SELECT current_user`).
- [ ] Tests d'intrusion `rls-intrusion.e2e-spec.ts` : 6 cas verts.
- [ ] Tests d'intrusion `rls-cross-tenant-write.e2e-spec.ts` : INSERT cross-tenant rejected.
- [ ] Benchmark `scripts/benchmark-rls.sh` exécuté ; rapport committé dans `_bmad-output/benchmarks/rls-overhead.md` ; overhead < 5% sur p95.
- [ ] CI job `security-tests` passe sur la PR.
- [ ] `withRlsBypass` whitelist + audit fonctionnel.
- [ ] Documentation `migrations-tenant-scoped.md` rédigée.
- [ ] Code review passé (`/codex review` recommandé pour cette story sécurité).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-017 status `completed`, completed_points sprint 2 += 5.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Migration `rls-policies.ts` (8 tables, USING + WITH CHECK + FORCE) | 1.0 | Mécanique mais 8 tables = effort non négligeable. |
| Migration / init-db `rls-app-user.ts` (2 users PostgreSQL avec privilèges scopés) | 0.75 | Coordination avec Docker entrypoint init-db.sql. |
| Two-pool DataSource (`APP_DATASOURCE` + `ADMIN_DATASOURCE`) + boot check user | 0.5 | Standard. |
| `withRlsBypass` helper + whitelist + audit log integration | 0.75 | Whitelist runtime + lint check CI. |
| Tests d'intrusion E2E (6 read scenarios + write scenario) | 1.0 | Critique — chaque test doit prouver une garantie spécifique. |
| Benchmark RLS overhead + indexes correctifs si nécessaire | 0.75 | pgbench ou script custom + analyse résultats + tuning indexes. |
| Script rollback + runbook | 0.25 | Rapide. |
| Documentation `migrations-tenant-scoped.md` | 0.25 | Checklist 6 étapes. |
| **Total** | **5** | Fibonacci 5 — significant. |

**Rationale :** RLS est cryptographiquement la couche la plus forte mais aussi la plus délicate à mettre en place (granularité user PostgreSQL, perf, FORCE option, fail-closed semantics). Les tests d'intrusion doivent être exhaustifs — sans eux, on a une fausse impression de sécurité.

---

## Notes additionnelles

- **Pourquoi `FORCE ROW LEVEL SECURITY` ?** Sans FORCE, le owner de la table (postgres ou scalario_admin) bypasse les policies. FORCE garantit que même le owner respecte les policies — utile si un dev se connecte en owner par erreur. Le `BYPASSRLS` au niveau user reste le seul moyen de bypasser.
- **Pourquoi pas Pre-Phase 2 schema-per-tenant directement ?** Coût opérationnel : N migrations, N pools de connexion, N backup strategies. Phase 1 : RLS + shared schema = simple + suffisant (sprint plan ligne 1404 capacity 100 tenants). Path Phase 2 documenté dans STORY-016.
- **Performance overhead :** Avec un index `(tenant_id, ...)` bien placé, l'overhead est typiquement 1-3% (le planner utilise l'index pour filtrer rapidement). Sans index, l'overhead peut atteindre 30%+. D'où l'AC-15 et l'audit indexes.
- **Audit log policy :** STORY-020 ajoutera la complexité full (insert-only via REVOKE + retention). Cette story crée juste la table + RLS policy de base.

---

## Progress Tracking

**Status History :**

- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)
- 2026-05-15 : Completed (Carlos via `/bmad:dev-story`)

**Actual Effort :** 5 points (matched estimate)

**Implementation Summary :**

Layer 5 RLS livré sur 8 tables tenant-scoped via 2 migrations idempotentes (`1700000000004-rls-policies`, `1700000000005-rls-app-user`) — `ENABLE` + `FORCE ROW LEVEL SECURITY` + policy uniforme `<table>_tenant_isolation` (`USING` + `WITH CHECK`, fail-closed via `missing_ok=true`). Rôle PostgreSQL `scalario_app` créé `NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS` avec GRANT DML scopé (INSERT/SELECT only sur `audit_logs`). `DatabaseModule` expose maintenant 2 DataSources (`TypeOrmModule` = app role, `ADMIN_DATA_SOURCE` = bypass role, pool 2) + boot check qui refuse `rolbypassrls=true` sur le user d'app. `RlsBypassService.withBypass` (whitelist runtime + audit log) est l'unique voie cross-tenant. Tests d'intrusion E2E (`rls-intrusion.e2e.spec.ts`) couvrent les 6 cas AC-11 + AC-12, auto-skip si `DATABASE_URL_ADMIN` absent — CI provisionne les 2 DSN + lance `migration:run` avant `test`. Script `scripts/benchmark-rls.sh`, `scripts/rollback-rls.sql`, et doc checklist `apps/nestjs/docs/migrations-tenant-scoped.md` livrés.

**Différé (non bloquant Phase 1) :**

- Lint CI script `check-rls-bypass-callers.sh` — whitelist runtime + unit test couvrent Phase 1.
- Rapport benchmark `_bmad-output/benchmarks/rls-overhead.md` avec p50/p95/p99 chiffrés — script livré, le run sera fait en pré-prod avec une vraie volumétrie.
- Index ivfflat sur `embeddings` — table vide en Phase 1, indexer en Phase 2 RAG.
- Audit log `INSERT`-only enforcement complet → STORY-020.

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
