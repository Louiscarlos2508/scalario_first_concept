# `catalog/modules/` — Modules ERP génériques (Scalario Kit)

**Refondu par STORY-V14-006.** Contient les modules ERP **génériques** consommés par les 6 moteurs Scalario (ModuleList, ModuleForm, ModuleDetail, ModuleReport, ModuleKanban, ModuleDashboard — V14-007).

## Sous-dossiers (par domaine fonctionnel)

| Dossier | Modules |
|---|---|
| `gestion/` | commandes, stock, clients, fournisseurs |
| `finance/` | factures, paiements, rapports_fin |
| `rh/` | employes, conges, paie |
| `operations/` | livraisons, planning, chantiers, **cloture_caisse** (migré depuis `catalog/workflows/wf_cloture_caisse.json` v13) |
| `_overrides_per_tenant/` | Phase 2 : Scalario Forge dépose ici les overrides spécifiques tenant |

## Format

Chaque module est un fichier JSON validé par `catalog/schemas/module-config.schema.json` + `apps/nestjs/src/catalog-loader/validators/module-config.zod.ts`.

Exemple :
```json
{
  "id": "commandes",
  "schema_version": "1.0.0",
  "name": "Commandes",
  "i18n_key": "module.commandes.name",
  "entities": [ ... ],
  "screens": [ ... ],
  "actions": { ... },
  "permissions": [ ... ]
}
```

## Héritage

Un module peut hériter d'un autre via le champ `inherits` (résolu au boot par le loader) :
```json
{
  "id": "commandes_pharmacie",
  "inherits": ["commandes"],
  "screens": [ ... ]  // surcharge uniquement
}
```

## Phase 1 (actuelle) vs Phase 2

- **Phase 1** : les 6 modules v13 sont archivés dans `_archive_v13/modules/`. Le module `operations/cloture_caisse.json` (workflow FSM) est le seul vivant en v14 jusqu'à V14-007.
- **Phase 2** (V14-007) : implémentation des 6 modules génériques (`gestion/commandes.json`, etc.) qui remplacent les v13.

## Liens

- Story Phase 2 : `_bmad-output/stories/STORY-V14-007.md`
- Schema : `catalog/schemas/module-config.schema.json`
