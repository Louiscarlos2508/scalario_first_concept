# `catalog/queries/` — SQL nommé (Scalario Vault niveau 3)

**Créé par STORY-V14-006.** Catalogue de **queries SQL nommées** pour les rapports complexes — niveau 3 de Scalario Vault.

## RÈGLE CRITIQUE (PRD v14 §22.5)

> Le SQL brut est **JAMAIS** exposé à l'IA. L'IA référence une query par son ID (`query_id: 'pharmacie.rapport_ventes_medicaments'`) — elle ne génère **JAMAIS** de SQL au runtime.
>
> Le SQL reste **validé par un humain** (Carlos) au catalogue. C'est la barrière anti-hallucination et anti-injection.

## Sous-dossiers (par secteur)

| Dossier | Queries démarrage (V14-028) |
|---|---|
| `commun/` | dashboard_kpis, audit_trail |
| `pharmacie/` | rapport_ventes_medicaments, alerte_peremption, ca_par_famille |
| `btp/` | avancement_chantier, cout_materiaux |
| `finance/` | balance_comptable, rapprochement_bancaire |

## Format

Chaque query est un fichier `.sql` avec header de **metadata** parsé par `apps/nestjs/src/catalog-loader/loaders/query-loader.ts` :

```sql
-- catalog/queries/pharmacie/rapport_ventes_medicaments.sql
-- @params { "from": "date", "to": "date", "category_id": "uuid?" }
-- @access ["OWNER", "MANAGER", "DG", "PHARMACIEN"]
SELECT
  m.nom as medicament,
  COUNT(*) as nb_ventes,
  SUM(v.total_amount) as ca_total
FROM tenant_<id>.ventes v
JOIN tenant_<id>.medicaments m ON v.medicament_id = m.id
WHERE v.created_at BETWEEN :from AND :to
  AND v.tenant_id = :tenant_id  -- injecté par le service
GROUP BY m.nom
ORDER BY ca_total DESC
LIMIT 50;
```

### Header metadata

- `-- @params { "<name>": "<type>" }` — schema des paramètres typés (Zod côté service)
- `-- @access [ "ROLE1", "ROLE2" ]` — rôles autorisés
- `:from`, `:to`, `:tenant_id` — substitution typée par le service (anti-SQL-injection)

### Tenant filter automatique

Le service `QueryRegistryService` (V14-028) injecte automatiquement `WHERE tenant_id = :tenant_id` — le SQL n'a pas besoin de le déclarer.

## Vues matérialisées

Certaines queries doivent être backées par une vue matérialisée (perf). Convention : suffixe `_mv` dans le SQL + refresh via `pg_cron`. Documenté par la story qui crée la vue (V14-028 pour `dashboard_kpis_mv`).

## Phase 1 vs Phase 2

- **Phase 1** : structure créée, dossiers vides. Loader stub fonctionnel.
- **Phase 2** (V14-028) : implémentation des 5 queries démarrage + vue matérialisée `dashboard_kpis_mv` + endpoint `POST /api/v1/:tenant/queries/:query_id/exec`.

## Liens

- Story Phase 2 : `_bmad-output/stories/STORY-V14-028.md`
- PRD v14 §22.5 — anti-hallucination via SQL nommé
- Loader : `apps/nestjs/src/catalog-loader/loaders/query-loader.ts`
