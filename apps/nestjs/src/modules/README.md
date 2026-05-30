# `modules/` — Modules ERP génériques (Phase 2 — V14-007)

**Status :** Placeholder. À implémenter en V14-007 (6 moteurs ERP génériques).

## Rôle (cf PRD v14 §10)

Les 6 modules génériques de Scalario : `ModuleList`, `ModuleForm`, `ModuleDetail`, `ModuleReport`, `ModuleKanban`, `ModuleDashboard`. Chacun est un **engine paramétrable** (pas du code hardcodé) qui consomme le catalogue pour produire un module ERP fonctionnel.

## Contenu attendu (Phase 2)

```
modules/
├── module-list/
│   ├── module-list.service.ts
│   ├── module-list.controller.ts
│   └── __tests__/
├── module-form/
├── module-detail/
├── module-report/         # consomme catalog/queries/*.sql via QueryRegistry
├── module-kanban/
└── module-dashboard/      # vues matérialisées + KPIs
```

## Principe

- **Pas de logique métier hardcodée** : chaque module est dirigé par le catalogue
- **6 engines** = 6 patterns d'interaction (liste/form/detail/report/kanban/dashboard)
- **Composables** : un tenant peut activer 1, 3, 6 modules selon son besoin

## Dépendances

- `bdui/` (pour générer le JSON UI rendu par Scalario Canvas)
- `engines/action/` (pour les ActionEngine pipelines)
- `catalog-loader/` (pour lire les configs)
- `engines/workflow/` (pour les workflows FSM par module)

## Liens

- Story Phase 2 : `_bmad-output/stories/STORY-V14-007.md`
- PRD v14 §10 — 6 moteurs ERP
