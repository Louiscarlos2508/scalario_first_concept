# STORY V14-007 — 6 moteurs ERP génériques (ModuleList, ModuleForm, ModuleDetail, ModuleReport, ModuleKanban, ModuleDashboard)

**Phase :** 1 — Fondations
**Bloc :** Scalario Kit
**Story Points :** 8
**Status :** defined
**Created :** 2026-05-25
**Dépendances :** V14-002 (variant), V14-003 (Canvas Registry), V14-006 (catalogue), STORY-022 (ActionDispatcher refactoré en Scalario Flow)

---

## User Story

> **En tant que** Scalario Labs (Phase 1) et Config Agent IA (Phase 2+),
> **je veux** 6 moteurs ERP codés une seule fois qui rendent **n'importe quelle** entité depuis du JSON (liste, formulaire, détail, rapport, kanban, dashboard),
> **so that** ajouter un nouveau métier ne demande qu'un nouveau fichier JSON dans `catalog/modules/` — **zéro ligne de code Flutter ou NestJS**.

---

## Contexte v14

Le PRD v14 §16 dit explicitement :

> ERP classique : 50 modules codés en dur → 50 écrans Flutter codés.
> Ton ERP BDUI : 6 moteurs génériques + configs JSON → 1 moteur Flutter qui rend tout.

Cette story est le **cœur du modèle v14**. Elle remplace l'approche v13 STORY-040 (6 modules métier hardcodés `module_dashboard_owner`, `module_ventes`…) qui a été marquée **DEPRECATE** dans l'audit.

---

## Les 6 moteurs

### 1. ModuleList — n'importe quelle liste d'entités
- **Entrée JSON** : `entity_source`, `columns[]`, `filters[]`, `sort_by`, `pagination`, `row_action[]`
- **Composant DS** : `DataTable` (variantes : `default` / `compact` / `card-list` / `timeline`)
- **Usage** : Commandes, Stock, Clients, Factures, Employés, Fournisseurs

### 2. ModuleForm — n'importe quel formulaire
- **Entrée JSON** : `entity`, `fields[]` (FormField + variants), `sections[]`, `submit_pipeline`
- **Composant DS** : `FormSection` + `FormField.text/number/date/select/search/scan`
- **Usage** : Nouvelle commande, Fiche employé, Déclaration perte

### 3. ModuleDetail — n'importe quelle fiche détail
- **Entrée JSON** : `entity`, `header_template`, `tabs[]` (chacun contenant des `children: ComponentConfig[]`)
- **Composant DS** : `DetailView` (variantes : `inline` / `tabs` / `accordion`)
- **Usage** : Détail commande, Profil client, Fiche produit

### 4. ModuleReport — n'importe quel rapport/export
- **Entrée JSON** : `query_id` (catalog/queries SQL), `chart_type`, `export_formats[]`, `filters[]`
- **Composant DS** : `ChartBar` + `ChartPie` + `DataTable` + `Button` (export PDF/CSV/XLSX)
- **Usage** : CA mensuel, Rapport paie, Balance comptable

### 5. ModuleKanban — n'importe quel workflow en colonnes
- **Entrée JSON** : `entity`, `column_field` (ex: `status`), `columns_order[]`, `card_template`, `transitions[]` (FSM)
- **Composant DS** : `Kanban` (variantes : `default` / `compact`) + `Card` draggable
- **Usage** : Congés, Chantiers, Support tickets, Pipeline commercial

### 6. ModuleDashboard — KPIs de n'importe quelle source
- **Entrée JSON** : `kpis[]` (KPICard + source), `widgets[]` (charts, datatables, alerts)
- **Composant DS** : `KPICard` + `LineChart` + `DataTable` + `AlertBanner` (toutes variantes)
- **Usage** : Dashboard DG, Stats vendeur, Vue Comptable

---

## Acceptance Criteria

### Côté Flutter — 6 widgets génériques

- [ ] AC-01 — `lib/features/modules/module_list/module_list_screen.dart` — accepte un `ModuleListConfig` JSON, rend la DataTable avec filtres, actions row, pagination.
- [ ] AC-02 — `lib/features/modules/module_form/module_form_screen.dart` — accepte un `ModuleFormConfig` JSON, rend les FormFields, validation live (via Scalario Form), submit pipeline (via Scalario Flow).
- [ ] AC-03 — `lib/features/modules/module_detail/module_detail_screen.dart` — accepte un `ModuleDetailConfig`, gère les tabs, embeds des `children` ComponentConfig.
- [ ] AC-04 — `lib/features/modules/module_report/module_report_screen.dart` — accepte un `ModuleReportConfig`, exécute la `query_id` côté serveur, rend graphique + table + boutons export.
- [ ] AC-05 — `lib/features/modules/module_kanban/module_kanban_screen.dart` — accepte un `ModuleKanbanConfig`, rend colonnes draggables, drop → FSM transition (via Scalario Flow).
- [ ] AC-06 — `lib/features/modules/module_dashboard/module_dashboard_screen.dart` — accepte un `ModuleDashboardConfig`, rend KPIs + widgets en grille adaptative.

### Routing data-driven

- [ ] AC-07 — `lib/core/canvas/module_router.dart` — résout `module_id` → moteur générique via `engine: 'ModuleList' | 'ModuleForm' | ...` dans le catalogue.
- [ ] AC-08 — `go_router` config : route `/modules/:moduleId` → résolution dynamique vers le moteur déclaré.

### Côté NestJS — endpoints génériques

- [ ] AC-09 — `engines/action/action.controller.ts` route `POST /api/v1/:tenant/:moduleId/action` accepte n'importe quelle action du module (déjà refactoré dans Scalario Flow).
- [ ] AC-10 — `engines/datasource/datasource.controller.ts` route `GET /api/v1/:tenant/:moduleId/data` accepte les filtres déclarés dans le module config.
- [ ] AC-11 — Le routing utilise le catalogue (V14-006) pour résoudre quel ModuleEngine appliquer.

### Catalogue de démarrage Phase 1

- [ ] AC-12 — `catalog/modules/gestion/commandes.json` (ModuleList + workflow approval)
- [ ] AC-13 — `catalog/modules/gestion/stock.json` (ModuleList + alertes seuils)
- [ ] AC-14 — `catalog/modules/finance/factures.json` (ModuleList + génération PDF)
- [ ] AC-15 — `catalog/modules/rh/employes.json` (ModuleList + ModuleForm)
- [ ] AC-16 — Tous validés par CatalogueValidator (Zod).

### Héritage + overrides

- [ ] AC-17 — Mécanisme `inherits: "catalog/modules/gestion/commandes"` + `overrides: { ... }` fonctionne côté NestJS BduiResolver (deep merge).
- [ ] AC-18 — Test E2E : un tenant pharmacie override `commandes` avec champ `ordonnance: { type: "file", required: true }` → ce champ apparaît UNIQUEMENT pour ce tenant, sans modifier le module standard.

### Tests

- [ ] AC-19 — 6 widget snapshot tests (1 par moteur), Light + Dark.
- [ ] AC-20 — 4 tests E2E NestJS : list + form + detail + dashboard avec catalogue Phase 1.
- [ ] AC-21 — Coverage ≥ 80% sur `lib/features/modules/` et `engines/action/` + `engines/datasource/`.

---

## Notes techniques

- **Pas de logique métier dans ces 6 widgets** — uniquement de la rendition data-driven.
- **Le catalogue est tout** — ajouter un module = ajouter un fichier JSON.
- **Compatible héritage** : `inherits` + `overrides` deep merge (JSON Patch RFC 7396 — merge patch).
- **Pas de FSM ici** — les workflows (commande draft→soumise→validée) sont déclarés dans le module et exécutés par Scalario Flow (FSM XState).

---

## Definition of Done

- [ ] 6 moteurs Flutter livrés + testés
- [ ] Endpoints NestJS génériques opérationnels
- [ ] Catalogue standards Phase 1 (≥ 8 modules) committé dans `catalog/modules/`
- [ ] Héritage + overrides testé E2E
- [ ] Coverage ≥ 80%
- [ ] flutter analyze + pnpm typecheck + pnpm lint = 0 erreur
- [ ] Memory : `feedback_scalario_6_moteurs.md` (modèle générique, pas de modules métier hardcodés)
- [ ] PR mergée sur main
