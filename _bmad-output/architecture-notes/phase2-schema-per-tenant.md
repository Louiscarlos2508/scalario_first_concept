# Phase 2 — Schema-per-tenant migration path

**Author :** Architecture — STORY-016
**Status :** Plan (not executed Phase 1)
**Phase 1 :** shared schema + `tenant_id` column + RLS (STORY-017)
**Phase 2 :** dedicated PostgreSQL schema per tenant (`tenant_<slug>`)

---

## Triggers — quand basculer

Phase 1 reste suffisant **tant que** :

- Nombre de tenants < ~100.
- Latency p95 sur queries métier reste < 200 ms (Phase 1 cible).
- Aucun client n'exige une isolation "physique" (compliance santé, finance, secteur public).

Phase 2 devient nécessaire **dès qu'un** des éléments suivants est vrai :

| Trigger | Mesure | Action |
|---|---|---|
| Tenants > 100 | `SELECT count(*) FROM tenants WHERE is_active = true` | Planifier migration progressive |
| Latency p95 dégrade > 5x baseline | Grafana `api_latency_p95{tenant=...}` | Identifier tenants chauds, migrer en priorité |
| Demande compliance forte | Contrat signé avec SLA isolation | Tenant migré dès go-live |
| Table métier > 100 M rows avec `tenant_id` | `pg_relation_size` | Index `(tenant_id, …)` ne tient plus efficacement |

---

## Pré-requis (déjà en place Phase 1)

- Colonne `tenants.schema_name TEXT NULL` à ajouter (TODO — la story qui crée la table tenants la posera ; jusque-là, ALTER TABLE dédié).
- `TenantMiddleware` STORY-016 lit `tenant_id` du JWT et l'expose via `AsyncLocalStorage`.
- `TenantsService.getActive()` charge `is_active`. Étendu Phase 2 pour exposer aussi `schema_name`.

---

## Procédure — migrer un tenant `<slug>` du schéma `public` vers `tenant_<slug>`

```sql
-- 1. Créer le schéma dédié
CREATE SCHEMA tenant_<slug> AUTHORIZATION scalario_app;

-- 2. Pour chaque table métier tenant-scoped :
CREATE TABLE tenant_<slug>.<table> (LIKE public.<table> INCLUDING ALL);

-- 3. Copier les données (lock short-running ; à exécuter en fenêtre maintenance ou
--    via outil online comme pg_repack si > 1 GB).
INSERT INTO tenant_<slug>.<table>
SELECT * FROM public.<table>
WHERE tenant_id = '<tenant_uuid>';

-- 4. Mettre à jour la table tenants
UPDATE tenants SET schema_name = 'tenant_<slug>' WHERE id = '<tenant_uuid>';

-- 5. Vérifier checksums (count, hash MD5 par batch)

-- 6. Supprimer les données du schéma public POUR CE TENANT seulement
DELETE FROM public.<table> WHERE tenant_id = '<tenant_uuid>';

-- 7. Drop la policy RLS pour les rows de ce tenant si nécessaire
--    (la policy reste, c'est juste qu'aucune row pour ce tenant n'y est plus)
```

**Important :** Étape 6 NE PEUT être exécutée qu'après confirmation app-side que le tenant utilise bien `tenant_<slug>` (commit applicatif obligatoire avant cleanup).

---

## Changement applicatif — `TenantMiddleware`

Au lieu de poser uniquement `app.current_tenant_id`, l'app exécute :

```typescript
const tenant = await this.tenantsService.getActive(user.tenant_id);
// tenant = { id, schema_name }

if (tenant.schema_name) {
  // Phase 2 — isolation par schema
  await queryRunner.query(`SET search_path TO ${tenant.schema_name}, public`);
} else {
  // Phase 1 — shared schema + RLS
  await queryRunner.query(`SELECT set_config('app.current_tenant_id', $1, false)`, [tenant.id]);
}
```

Les deux modes **coexistent** pendant la transition : les tenants déjà migrés utilisent `search_path`, les autres `RLS`. C'est le point clé qui permet une migration progressive sans downtime.

---

## Migrations TypeORM par tenant

Phase 1 = un seul jeu de migrations sur `public`.
Phase 2 = chaque tenant migré requiert que les migrations futures **s'appliquent aussi** sur son schéma dédié.

Solution proposée :

1. Garder les migrations sur `public` comme source de vérité (schéma "template").
2. Ajouter une commande `pnpm migration:apply-tenant <slug>` qui exécute le diff sur `tenant_<slug>`.
3. Pipeline CI : la commande s'exécute pour tous les tenants migrés après chaque release.

Alternative (plus simple, moins flexible) : forcer toutes les nouvelles migrations à boucler sur `tenants WHERE schema_name IS NOT NULL`. Surcharge à l'écriture des migrations — acceptable Phase 2.

---

## Estimation effort

| Tâche | Effort |
|---|---|
| Adaptation `TenantMiddleware` dual-mode | 1 jour |
| Script migration `migrate-tenant.sh` (idempotent, dry-run, checksums) | 2 jours |
| Pipeline migration TypeORM multi-schemas | 1 jour |
| Tests E2E + bench (latency, isolation, no leak) | 1 jour |
| **Total Phase 2 setup** | **5 jours dev + 2 jours QA** |
| Migration d'un tenant unique (post-setup) | 1-4 h selon volume |

---

## Risques

1. **Connection pool fragmentation** — un pool fixe (max=10) qui sert N schémas alterne `SET search_path` à chaque requête. Overhead ~0.5 ms par query. Mesurable, acceptable jusqu'à ~50 schemas actifs simultanés.
2. **Migrations divergentes** — si un tenant migré ne reçoit pas une migration, son schéma drift. Mitigation : la commande migration loop est obligatoire en CD, alarme si retour `affected = 0`.
3. **Cross-tenant analytics** — Phase 1 permet `SELECT … FROM public.<table>` global pour analytics. Phase 2 impose `UNION ALL` sur N schémas. Solution : table d'agrégation dédiée + ETL nocturne.

---

## Décision finale

> Phase 1 (shared schema + RLS) ships avec STORY-016 + STORY-017. Phase 2 est **planifiée mais pas implémentée** ; ce document est référencé dans le runbook ops. Réévaluation trimestrielle ou dès qu'un trigger ci-dessus s'allume.
