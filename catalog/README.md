# `catalog/` — Catalogue Scalario v14

**Mis a jour: 2026-05-26.** Le catalogue est le produit de Scalario — JSON config pour modules, ecrans, workflows, UX profiles.

## Structure

```
catalog/
├── README.md
├── CONTRIBUTING.md
├── domains/
│   └── retail_fresh_produce.json    ← Domain config (tenant defaults, roles)
├── modules/
│   ├── gestion/
│   │   └── retail_fresh_produce.json ← Module Blandine (5 screens, 4 entities)
│   └── operations/
│       └── cloture_caisse.json       ← Workflow cloture caisse
├── ux_profiles/
│   ├── _base/components.json         ← Variants allowed globally
│   ├── commerce_general/components.json
│   ├── pharmacie/components.json     ← with-chart disabled on KPICard
│   └── btp/components.json
├── capabilities/
├── queries/
├── fusions/
└── schemas/
    ├── module-config.schema.json      ← Module contract (entities, screens, actions, rbac)
    ├── screen-config.schema.json      ← Screen (layout, zones, components)
    ├── component-config.schema.json   ← ComponentConfig v1.1.0 (variant, actions, children)
    ├── workflow.schema.json
    ├── ux-profile.schema.json
    ├── capability.schema.json
    └── examples/                      ← Example JSONs for all schemas
```

## Conventions

- **Fichiers JSON** : snake_case
- **Dossiers** : snake_case
- **Prefixed underscore** `_X` = system folder (not a sector): `_base/`

## Module Config (retail_fresh_produce.json)

```json
{
  "id": "retail_fresh_produce",
  "schema_version": "1.0.0",
  "name": "...",
  "entities": [...],
  "rbac_roles": ["OWNER", "MANAGER", "COMMERCIAL"],
  "screens": [
    { "screen": "dashboard_owner", "root": { "type": "Scaffold", ... } },
    { "screen": "stock_list", ... },
    { "screen": "loss_form", ... },
    { "screen": "delivery_validation", ... },
    { "screen": "daily_report", ... }
  ]
}
```

Screens use `root: { type: "Scaffold", ... }` with nested ComponentConfig children. Layout via Grid (span, gap, responsive), Slots (banner/main/aside), Row, Column, Stack.

## Validation

- **NestJS**: `CatalogueValidatorService` → `ModuleConfigZod`, `ScreenConfigZod`, `ComponentConfigZod`
- **Flutter**: `ComponentConfig.fromJson()` + `ScalarioCanvasRegistry.build()`
- **UX Profiles**: `UxProfileValidator.assertVariantAllowed(sector, componentType, variant)`

## Liens

- Architecture: `DESIGN.md`
- Sprint plan: `_bmad-output/architecture-v14/sprint-plan/sprint-plan-v14.md`
- Module Blandine: `modules/gestion/retail_fresh_produce.json`
