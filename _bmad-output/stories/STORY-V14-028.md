# STORY-V14-028 : Scalario Vault niveau 3 — catalogue SQL nommé par métier + vues matérialisées

**Epic :** EPIC-V14-019 — Scalario Vault
**Priorité :** Should Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-9 (Phase 2)
**Dépendances :** V14-006 (catalog/queries/), STORY-017 v13 (RLS)

---

## User Story

> **En tant que** ModuleReport (rapport CA mensuel, balance comptable, rapport paie),
> **je veux** référencer une query SQL nommée du catalogue (`query_id: 'pharma.rapport_ventes_medicaments'`) plutôt que de générer du SQL ad-hoc avec le LLM,
> **so that** les queries complexes sont **validées par un humain** (Carlos) au catalogue, jamais générées par l'IA au runtime, et les rapports critiques utilisent des vues matérialisées pour performance.

---

## Description

### Background

PRD v14 §10.2 + §22.5 — DataSourceRegistry niveau 3 = SQL nommé. Règle critique :

> Règle : l'IA référence une query par son ID — elle ne génère **JAMAIS** de SQL brut. Le SQL reste dans le catalogue — validé par toi, jamais exposé à l'IA.

### Scope

**In scope :**
- Loader `src/catalog-loader/loaders/query-loader.ts` charge `catalog/queries/<sector>/<name>.sql` au boot
- Service `QueryRegistryService.exec(query_id, params, tenantId)` :
  - Récupère SQL depuis catalogue
  - Substitue params **typés** (Zod schema par query) — anti-SQL-injection
  - Applique tenant filter automatique (`WHERE tenant_id = $1`)
  - Exécute via TypeORM raw query
- 5 queries démarrage : `commun/dashboard_kpis.sql`, `commun/audit_trail.sql`, `pharmacie/rapport_ventes_medicaments.sql`, `pharmacie/alerte_peremption.sql`, `finance/balance_comptable.sql`
- Vues matérialisées : `dashboard_kpis_mv` (refresh 1h via pg_cron)
- Tests : invocation des 5 queries + sécurité (params typés rejette injection)

**Out of scope :**
- Editeur SQL UI (Phase 3)
- Performance auto-tuning (V14-033)

---

## Acceptance Criteria

- [ ] **AC-01** — `query-loader.ts` charge `*.sql` au boot avec metadata `params_schema` (Zod).
- [ ] **AC-02** — `QueryRegistryService.exec('pharma.rapport_ventes_medicaments', { from: '2026-01-01', to: '2026-03-31' }, tenantId)` retourne résultats.
- [ ] **AC-03** — Substitution params **typés** : `params_schema.parse(params)` avant exec — rejet SQL injection (`from: "'; DROP TABLE--"`).
- [ ] **AC-04** — Tenant filter auto : SQL ne contient pas `WHERE tenant_id`, ajouté automatiquement par le service.
- [ ] **AC-05** — Erreur 404 si `query_id` inexistant.
- [ ] **AC-06** — 5 queries démarrage livrées :
  - `commun/dashboard_kpis.sql` (CA, nb ventes, alertes par jour/semaine/mois)
  - `commun/audit_trail.sql` (top events sensibles)
  - `pharmacie/rapport_ventes_medicaments.sql` (ventes médicaments period)
  - `pharmacie/alerte_peremption.sql` (médicaments expirent < 30j)
  - `finance/balance_comptable.sql` (balance par compte)
- [ ] **AC-07** — Vue matérialisée `dashboard_kpis_mv` créée + cron refresh 1h (pg_cron).
- [ ] **AC-08** — Endpoint `POST /api/v1/:tenant/queries/:query_id/exec { params }` avec RBAC OWNER+MANAGER+DG.
- [ ] **AC-09** — Test sécurité : tentative injection SQL via param → rejetée par Zod parse + audit log.

---

## Technical Notes

### Structure SQL fichier

```sql
-- catalog/queries/pharmacie/rapport_ventes_medicaments.sql
-- @params { from: 'date', to: 'date', category_id?: 'uuid' }
-- @access ['OWNER', 'MANAGER', 'DG', 'PHARMACIEN']
SELECT
  m.nom as medicament,
  COUNT(*) as nb_ventes,
  SUM(v.total_amount) as ca_total
FROM tenant_<id>.ventes v
JOIN tenant_<id>.medicaments m ON v.medicament_id = m.id
WHERE v.created_at BETWEEN :from AND :to
  AND v.tenant_id = :tenant_id  -- injected by service
  -- AND m.category_id = :category_id  -- optional
GROUP BY m.nom
ORDER BY ca_total DESC
LIMIT 50;
```

### Edge cases

- Query sur table inexistante (tenant pas migré) → erreur claire
- Param Date timezone → toujours UTC, conversion locale côté Flutter
- Vue matérialisée stale (refresh failed) → log + fallback live query

---

## Dependencies

- **Prérequis :** V14-006 (catalog/queries/), STORY-017 v13 (RLS pour tenant filter)
- **Stories bloquées :** V14-007 (ModuleReport utilise QueryRegistry), V14-016 (RAG sur query results)

---

## Definition of Done

- [ ] Query loader + service
- [ ] 5 queries livrées + tests
- [ ] Vue matérialisée dashboard_kpis_mv + pg_cron
- [ ] Endpoint exec + RBAC + injection test
- [ ] Docs `docs/scalario-vault-niveau-3.md`
- [ ] sprint-status.yaml V14-028 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Query loader + Zod params schema | 1.5 |
| 5 queries SQL + metadata | 1.0 |
| Vue matérialisée + pg_cron | 0.5 |
| Endpoint exec + tests sécurité | 1.0 |
| Docs | 1.0 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
