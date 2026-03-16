# Story 17.3 — Frontend : Navigation Dépenses + KPIs Bénéfice dans le dashboard

## Metadata
- **Epic:** Epic 17 — Dépenses & Bénéfice
- **Story ID:** 17-3-expenses-navigation
- **Status:** review
- **Priority:** High
- **Depends on:** 17-2

---

## Story

**As a** store owner viewing the backoffice dashboard,
**I want** to see "Dépenses" and "Bénéfice net" KPI cards alongside sales,
**So that** I have a real-time view of my shop's financial health.

---

## Acceptance Criteria

1. **Entrée de navigation "Dépenses"** :
   - Ajout d'une entrée "Dépenses" dans le menu/shell backoffice (`DashboardShell` ou équivalent)
   - Tap → navigue vers `ExpensesScreen`
   - Icône : `Icons.receipt_long` ou similaire

2. **KPI "Dépenses (période)"** dans `KpiCardGrid` :
   - Valeur = `SUM(expense.amount)` sur la période active
   - Format FCFA
   - Source : `expensesProvider` (réutilisé depuis 17-2)

3. **KPI "Bénéfice net"** dans `KpiCardGrid` :
   - Valeur = `totalVentes − totalDépenses` sur la période active
   - Format FCFA
   - Couleur verte si ≥ 0, rouge + icône `⚠` si < 0

4. **Cohérence de période** :
   - Quand le filtre de période change, `expensesProvider` se recharge avec la même plage
   - Les KPIs "Dépenses" et "Bénéfice net" se mettent à jour en même temps que "Ventes (période)"

---

## Tasks/Subtasks

- [x] **Task 1 : Entrée navigation**
  - [x] Ajouter "Dépenses" dans le shell/menu de navigation backoffice
  - [x] Route vers `ExpensesScreen`

- [x] **Task 2 : KPI "Dépenses (période)" dans `KpiCardGrid`**
  - [x] Watcher `expensesProvider` dans `KpiCardGrid`
  - [x] Affichage montant total en FCFA

- [x] **Task 3 : KPI "Bénéfice net" dans `KpiCardGrid`**
  - [x] Calcul `netProfit = totalSales - totalExpenses`
  - [x] Couleur conditionnelle (vert / rouge)
  - [x] Icône `⚠` si négatif

- [x] **Task 4 : Synchronisation du filtre de période**
  - [x] `expensesProvider` paramétré par le même `DateTimeRange` que `salesStatsProvider`
  - [x] `ref.invalidate` des deux providers lors du changement de période

- [x] **Task 5 : Tests**
  - [x] Mock `expensesProvider` → vérifie que "Dépenses (période)" s'affiche dans `KpiCardGrid`
  - [x] Bénéfice net négatif → icône warning vérifiée
  - [x] Navigation tap "Dépenses" → label "Dépenses" présent dans NavigationRail

---

## Dev Notes

- `expensesProvider` already watches `salesStatsDateRangeProvider` (from Story 17-2), so period sync is automatic — no extra wiring needed beyond `ref.invalidate(expensesProvider)` on manual refresh.
- `KpiCardGrid` uses `expensesAsync.valueOrNull ?? []` so expenses load independently from sales stats — the grid shows immediately with `totalExpenses=0` while expenses are still fetching.
- Added `_KpiCard.showWarning` bool + `valueColor` to support the red/warning state for negative net profit.
- Navigation rail overflow: test surface (800×600 default) becomes too small for 8 nav items. Fixed with `tester.binding.setSurfaceSize(const Size(800, 960))` in 800dp tests.

---

## Dev Agent Record

### Implementation Plan
- Task 1: Add `_NavItem` for "Dépenses" (index 6) in `dashboard_shell.dart`; add `ExpensesScreen()` to `_screens` in `dashboard_screen.dart`.
- Task 2+3: Update `kpi_card_grid.dart` — watch `expensesProvider`, compute `totalExpenses` + `netProfit`, render two new `_KpiCard`s with conditional color/warning icon.
- Task 4: Add `ref.invalidate(expensesProvider)` to the 30s timer and manual refresh button in `OverviewScreen`.
- Task 5: New group `'KPI Dépenses & Bénéfice net (Story 17-3)'` in `dashboard_sdui_integration_test.dart` (3 tests); new test in `dashboard_navigation_test.dart` for "Dépenses" nav label.

### Completion Notes
- All 5 tasks complete and validated.
- 135/135 flutter tests pass (4 new tests added, zero regressions).
- `setSurfaceSize(800, 960)` applied to both 800dp navigation tests to accommodate 8 nav items.

---

## File List

- `apps/frontend/lib/features/retail/backoffice/presentation/widgets/dashboard_shell.dart` — added "Dépenses" `_NavItem` at index 6
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — added `ExpensesScreen` import + entry in `_screens`; added `expensesProvider` invalidation on timer and refresh button
- `apps/frontend/lib/features/retail/reports/presentation/widgets/kpi_card_grid.dart` — watches `expensesProvider`; two new KPI cards (Dépenses, Bénéfice net); `_KpiCard` extended with `valueColor` and `showWarning`
- `apps/frontend/test/dashboard_sdui_integration_test.dart` — added group `'KPI Dépenses & Bénéfice net (Story 17-3)'` with 3 tests
- `apps/frontend/test/dashboard_navigation_test.dart` — added "Dépenses" nav label test; added `setSurfaceSize(800, 960)` to both 800dp tests

---

## Change Log

- 2026-03-16 — Story 17-3 implemented. Navigation entry, KPI cards (Dépenses + Bénéfice net), period sync, 4 new tests. 135/135 tests pass.
