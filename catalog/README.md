# `catalog/` — Catalogue Scalario v14

**Refondu par STORY-V14-006 (2026-05-25).** Documente la structure v14 du catalogue qui alimente Scalario Kit / Profile / Pipe.

## Principe

Le catalogue est le **produit** de Scalario. C'est un dossier de fichiers JSON qui décrivent des secteurs d'activité (commerce, pharmacie, BTP, cabinet médical…). Le backend et l'app mobile ne contiennent **aucun code métier** — ils lisent ce dossier et rendent l'expérience correspondante.

> Métaphore : Scalario est un orchestre. Le catalogue est la partition.

Pour ajouter un nouveau secteur (ou un module), vous **n'écrivez aucune ligne de TypeScript ni de Dart**. Vous écrivez du JSON.

## Structure v14

```
catalog/
├── README.md                  ← ce fichier
├── schemas/                   ← JSON Schemas (contrats validés en TS via Zod)
│   ├── module-config.schema.json
│   ├── screen-config.schema.json
│   ├── component-config.schema.json
│   ├── workflow.schema.json
│   ├── ux-profile.schema.json     ← NOUVEAU v14
│   ├── capability.schema.json     ← NOUVEAU v14
│   └── examples/
│
├── modules/                   ← Modules ERP génériques (Scalario Kit)
│   ├── README.md
│   ├── gestion/              commandes, stock, clients, fournisseurs
│   ├── finance/              factures, paiements, rapports_fin
│   ├── rh/                   employes, conges, paie
│   ├── operations/           livraisons, planning, chantiers, cloture_caisse
│   └── _overrides_per_tenant/   Phase 2 : Scalario Forge dépose ici
│
├── ux_profiles/              ← UX par métier (Scalario Profile)
│   ├── README.md
│   ├── _base/                composants/layout/UX patterns communs
│   ├── commerce_general/
│   ├── pharmacie/
│   ├── btp/
│   └── cabinet_medical/
│
├── capabilities/             ← Hardware/système (Scalario Sense)
│   ├── README.md
│   ├── input/                barcode_scan, photo_capture, signature, NFC, voice
│   ├── output/               printer_bluetooth, sms_send, share_file
│   ├── location/             gps_position, gps_track
│   ├── auth/                 biometrie
│   ├── integration/          webhook_send, http_call
│   └── payment/              wave_pay, orange_money, mtn_momo (Phase 2)
│
├── queries/                  ← SQL nommé (Scalario Vault niveau 3)
│   ├── README.md             RÈGLE : jamais exposé à l'IA, référencé par query_id
│   ├── commun/               dashboard_kpis, audit_trail
│   ├── pharmacie/            rapport_ventes_medicaments, alerte_peremption
│   ├── btp/                  avancement_chantier, cout_materiaux
│   └── finance/              balance_comptable, rapprochement_bancaire
│
└── _archive_v13/             ← Sauvegarde fichiers v13 (référence audit)
    ├── README.md
    ├── domains/              retail_fresh_produce.json
    └── modules/              module_dashboard_owner, module_stock, etc.
```

## Conventions

- **Fichiers JSON** : snake_case (`gestion/commandes.json`, `pharmacie/components.json`)
- **Dossiers** : snake_case (`ux_profiles/`, `cabinet_medical/`)
- **Préfixe underscore** `_X` = dossier "système" (pas un secteur) :
  - `_base/` = règles communes héritées
  - `_overrides_per_tenant/` = overrides Forge
  - `_archive_v13/` = archive de la v13

## Schémas validés

Chaque fichier JSON est validé par **deux couches** :
1. **JSON Schema** dans `schemas/` (contrat externe)
2. **Zod schema** dans `apps/nestjs/src/catalog-loader/validators/` (runtime TS)

Schemas v14 ajoutés :
- `ux-profile.schema.json` — pour `ux_profiles/<sector>/*.json`
- `capability.schema.json` — pour `capabilities/<category>/*.json`

## Loaders NestJS

`apps/nestjs/src/catalog-loader/loaders/` :
- `ux-profile-loader.ts` — charge `catalog/ux_profiles/`
- `capability-loader.ts` — charge `catalog/capabilities/`
- `query-loader.ts` — charge `catalog/queries/` (RÈGLE : SQL jamais exposé à l'IA)
- (modules loader existant dans `services/catalogue-loader.service.ts`)

## Mapping v13 → v14

| v13 | v14 |
|---|---|
| `catalog/domains/retail_fresh_produce.json` | `catalog/_archive_v13/domains/` |
| `catalog/modules/module_*.json` (×6) | `catalog/_archive_v13/modules/` |
| `catalog/workflows/wf_cloture_caisse.json` | `catalog/modules/operations/cloture_caisse.json` |
| `catalog/schemas/` | inchangé (+ 2 nouveaux schemas v14) |

## Variantes (v1.1.0)

Chaque `ComponentConfig` expose un champ `variant: string` (default `'default'`).

| Variante | Resolution |
|---|---|
| `'default'` | Rendu standard du composant |
| `'auto'` | Resolution automatique par `ScalarioCanvasResolver` selon taille ecran, role, nb enfants |
| `'compact'` | Variante reduite (petits ecrans, tableaux denses) |
| `'hero'` | Variante large (grands ecrans, dashboard OWNER) |

La variante `'auto'` est resolue cote Flutter par `ScalarioCanvasResolver.resolveVariant(variant, ctx)` :
- `width < 360` ou `(role == 'COMMERCIAL' && childCount > 3)` → `'compact'`
- `width >= 900 && role in {'OWNER', 'SUPER_ADMIN'}` → `'hero'`
- Sinon → `'default'`

Le catalogue des variantes autorisees par composant est defini dans `_bmad-output/stories/STORY-V14-004.md`.

## Actions (v1.1.0)

Chaque `ComponentConfig` peut declarer `actions: ActionStep[]` — un pipeline d'actions declenchees
sur evenement du composant (onTap, onSubmit, onChange…).

```json
{
  "actions": [
    {
      "registry": "vault",
      "fn": "save_entity",
      "inputs": { "entity": "Vente", "data": { "$ref": "$form.values" } },
      "output": "saved_vente",
      "on_error": { "network": "notify", "validation": "fail" }
    }
  ]
}
```

| Champ | Description |
|---|---|
| `registry` | Engine cible : `canvas`, `form`, `calc`, `sense`, `vault`, `live` |
| `fn` | Nom de la fonction dans le registre de l'engine |
| `inputs` | Parametres libres, variables resolues au runtime (`$user.id`, `$form.values.price`) |
| `output` | Nom de la variable de sortie dans le contexte du pipeline |
| `on_error` | Comportement par type d'erreur : `skip`, `retry`, `notify`, `fail` |

L'execution runtime des `actions` est faite par **V14-007** (Scalario Flow refactored).

## Composition recursive (v1.1.0)

`children: ComponentConfig[]` permet la composition recursive (Section > Row > [KPICard, DataTable]).
Limite de profondeur : **5 niveaux** (anti-abuse).

```json
{
  "type": "Section",
  "children": [
    { "type": "Row", "children": [
      { "type": "KPICard", "variant": "compact" }
    ]}
  ]
}
```

## Comment ajouter

- **Un module générique** (Phase 2 — V14-007) → `modules/<gestion|finance|rh|operations>/<name>.json`
- **Un profile UX sectoriel** → `ux_profiles/<sector>/components.json` + `layouts.json`
- **Une capability hardware** → `capabilities/<category>/<name>.json`
- **Une query SQL nommée** (Vault niveau 3) → `queries/<sector>/<name>.sql` avec header `-- @params { … }` + `-- @access [ … ]`

## Liens

- Story : `_bmad-output/stories/STORY-V14-006.md`
- PRD v14 §16 + §11 + §9 + §12 — catalogues v14
- Migration log : `_bmad-output/architecture-v14/migration-log.md`
