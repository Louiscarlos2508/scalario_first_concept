# STORY-V14-029 : Schema-per-tenant migration PostgreSQL (`public.*` + `{tenant_id}.*`)

**Epic :** EPIC-V14-019 — Scalario Vault
**Priorité :** Must Have (Phase 3 critique)
**Story Points :** 13
**Status :** defined
**Sprint :** v14-13 (Phase 3 — Mois 7-12)
**Dépendances :** STORY-016 v13 (Multi-tenant ALS+GUC), STORY-017 v13 (RLS), `_bmad-output/architecture-notes/phase2-schema-per-tenant.md`

---

## User Story

> **En tant que** Scalario à plusieurs dizaines de tenants Phase 3,
> **je veux** que chaque tenant ait son propre schéma PostgreSQL (`tenant_blandine.commandes`, `tenant_pharma.commandes`, etc.) plutôt qu'un schéma partagé + RLS,
> **so that** l'isolation est **absolue** (impossible de leak cross-tenant même via bug NestJS), les migrations métier peuvent diverger par tenant, et la performance s'améliore (indexes par schéma plus petits).

---

## Description

### Background

PRD v14 §22.1 + note technique existante `_bmad-output/architecture-notes/phase2-schema-per-tenant.md` (de STORY-016 v13) : structure cible

```sql
public.tenants            -- partagé : id, name, handle, network_*, config_id
public.tenant_configs     -- partagé : tenant_id, version, config JSONB
public.users              -- partagé : id, tenant_id, email, roles[]
public.audit_logs         -- partagé : tenant_id, action, payload, created_at

tenant_<id>.commandes     -- ISOLÉ par schéma
tenant_<id>.stock
tenant_<id>.factures
tenant_<id>.embeddings    -- pgvector
```

C'est un refactor MAJEUR — toutes les requêtes métier doivent passer par `search_path` dynamique.

### Scope

**In scope :**
- Migration TypeORM : drop tables tenant-scoped de `public.*`, recréer dans `tenant_<id>.*` par tenant
- `TenantSchemaResolver` : middleware NestJS qui set `SET LOCAL search_path = 'tenant_<id>'` à chaque requête après resolve tenant
- Migration data : script qui copie `public.commandes WHERE tenant_id = X` → `tenant_X.commandes` pour chaque tenant existant
- Cron de création schéma automatique au provisioning d'un nouveau tenant
- Tests E2E : cross-tenant isolation absolue (un user de tenant_A ne peut JAMAIS voir tenant_B même via SQL injection)

**Out of scope :**
- Multi-région réplication — V14-035
- pgvector dans schémas tenants (V14-016 mentionne déjà `tenant_<id>.embeddings`)

---

## Acceptance Criteria

- [ ] **AC-01** — Migration TypeORM crée la structure `public.*` (tenants, tenant_configs, users, audit_logs) + functions de création schéma `create_tenant_schema(tenant_id UUID)`.
- [ ] **AC-02** — Helper `create_tenant_schema()` crée `tenant_<id>.commandes`, `.stock`, `.factures`, `.entities`, `.embeddings` avec indexes.
- [ ] **AC-03** — `TenantSchemaResolver` NestJS middleware : après auth + tenant resolve, set `SET LOCAL search_path = 'tenant_<id>', public` sur la connexion.
- [ ] **AC-04** — Tous les services métier (engines/action, engines/datasource, modules/*) utilisent `search_path` dynamique — pas de `WHERE tenant_id = X` explicite.
- [ ] **AC-05** — Migration data : script `pnpm migrate:to-schema-per-tenant` qui (a) crée schémas existants, (b) copie données, (c) vérifie checksums, (d) drop colonnes `tenant_id` des tables métier maintenant dans `tenant_*`.
- [ ] **AC-06** — Provisioning nouveau tenant déclenche `create_tenant_schema(new_id)` automatiquement.
- [ ] **AC-07** — Test E2E intrusion : user de tenant_A tente requête SQL crafted `SELECT * FROM tenant_B.commandes` → ROLE Postgres n'a pas USAGE sur schéma tenant_B → 0 rows.
- [ ] **AC-08** — Tests perfs : 100k rows par tenant — query indexée < 50ms (vs ~150ms avec RLS).
- [ ] **AC-09** — Rollback plan : script `migrate:revert-schema-per-tenant` qui restaure `public.*` + recopie data.
- [ ] **AC-10** — Documentation runbook ops (création tenant, suppression tenant, backup par tenant).

---

## Technical Notes

- Phase 3 critique = on a 20-30 clients déjà actifs, migration doit être ZÉRO downtime — utiliser strategy blue/green ou rolling schema migration.
- pgvector index `tenant_<id>.embeddings.embedding USING ivfflat` créé à la création schéma (table vide initialement = OK).
- Edge case : connection pool TypeORM (poolSize=10) → chaque connection set son `search_path` au début de chaque transaction (via middleware QueryRunner).

---

## Dependencies

- **Prérequis :** STORY-016, STORY-017 v13
- **Stories bloquées :** Phase 2 business (semi self-service) nécessite isolation absolue avant scaling

---

## Definition of Done

- [ ] Migration + helper function créés
- [ ] TenantSchemaResolver opérationnel
- [ ] Migration data des tenants existants OK
- [ ] Tests intrusion + perf
- [ ] Runbook ops
- [ ] sprint-status.yaml V14-029 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Migration TypeORM + create_tenant_schema | 3.0 |
| TenantSchemaResolver middleware + tests | 3.0 |
| Script migration data + checksums | 3.0 |
| Tests intrusion + perfs | 2.0 |
| Runbook + rollback | 2.0 |
| **Total** | **13** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
