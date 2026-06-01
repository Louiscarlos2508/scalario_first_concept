# `catalog/` — Catalogue Scalario v14

**Mis à jour: 2026-05-31.** Le catalogue est le produit de Scalario — JSON config pour modules, écrans, workflows, UX profiles.

## Structure

```
catalog/
├── README.md
├── CONTRIBUTING.md
├── modules/                           ← Modules métier réutilisables
│   ├── ventes/                        ← Module Ventes (POS, SaleItem)
│   │   ├── module.json                ← Config (entités, écrans, actions)
│   │   └── screens/                   ← Écrans spécifiques au module
│   ├── stock/                         ← Module Stock (Product, StockMovement)
│   ├── pertes/                        ← Module Pertes (Loss)
│   ├── caisse/                        ← Module Caisse (CashSession, workflows)
│   ├── commandes/                     ← Module Commandes (Supplier, PurchaseOrder)
│   ├── equipe/                        ← Module Équipe (Employee)
│   ├── rapports/                      ← Module Rapports
│   └── alertes/                       ← Module Alertes (AlertRule)
├── tenants/                           ← Configs tenant (1 dossier par tenant)
│   └── blandine/                      ← Blandine Boutique (tenant actif unique)
│       ├── module.json                ← Config tenant (modules activés, thème, perms)
│       ├── screens/                   ← Écrans Blandine (rewritten zones format)
│       ├── entities/                  ← Entités Blandine
│       └── theme.json                 ← Thème visuel tenant
├── domains/                           ← (ancien format monolithique, archivé)
│   └── _archived/                     ← retail_fresh_produce.json (v13 legacy)
├── ux_profiles/                       ← UX profiles sectoriels
│   ├── _base/components.json
│   ├── commerce_general/components.json
│   └── ...
├── schemas/                           ← Schémas JSON (contrat BDUI)
│   ├── module-config.schema.json      ← Module contract v1.0.0
│   ├── screen-config.schema.json      ← Screen (layout, zones, components)
│   └── ...
├── capabilities/                      ← Capacités device (stub)
├── queries/                           ← SQL queries named (stub)
└── fusions/                           ← Fusion templates (à venir)
```

## Conventions

- **Fichiers JSON** : snake_case
- **Dossiers modules** : snake_case (`ventes`, `stock`, etc.)
- **Modules** : dossier `modules/<id>/module.json` avec `id`, `entities`, `screens[]`, `actions`, `rbac_roles`
- **Écrans** : format `zones` (kpis, main, aside, actions) — pas de `root.children` legacy
- **Tenants** : dossier `tenants/<slug>/module.json` avec refs vers les screens/entities

## Module Config

```json
{
  "id": "ventes",
  "schema_version": "1.0.0",
  "name": "Ventes",
  "icon": "point_of_sale",
  "entities": [{ "name": "Sale", "fields": [...] }],
  "actions": { "create_sale": { "handler": "crud.create", ... } },
  "screens": ["screens/pos.json", "screens/sale_list.json"],
  "rbac_roles": ["COMMERCIAL", "MANAGER", "OWNER"]
}
```

Les écrans utilisent `zones: { kpis: [...], main: [...], aside: [...], actions: [...] }` avec des `ComponentConfig` ayant `type` + `props`.

## Validation

- **NestJS bootstrap**: `CatalogueValidatorService` rejecte l'app si le catalogue est invalide
- **Zod schemas**: `ModuleConfigZod`, `ScreenConfigZod`, `ComponentConfigZod`
- **ModuleResolverService**: cache 60s + filesystem lookup (v1 domain + v2 module dir)
- **UX Profiles**: `UxProfileValidator.assertVariantAllowed(sector, componentType, variant)`

## Liens

- Schemas: `schemas/module-config.schema.json`, `schemas/screen-config.schema.json`
- Tenant Blandine: `tenants/blandine/module.json`
- UX scenarios: `design-process/C-UX-Scenarios/00-ux-scenarios.md`
