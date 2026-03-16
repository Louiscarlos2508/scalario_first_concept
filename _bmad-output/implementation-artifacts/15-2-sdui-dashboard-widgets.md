# Story 15.2 — SDUI Dashboard Widgets

## Metadata
- **Epic:** Epic 15 — SDUI Dashboard & UI Polish
- **Story ID:** 15-2-sdui-dashboard-widgets
- **Status:** review
- **Priority:** High
- **Depends on:** 15-1-sdui-dashboard-wiring (stubs registered, SDUI wiring in place)

---

## Story

**As a** developer,
**I want** the three dashboard panel types (`kpi_card_grid`, `line_chart`, `terminal_status_list`) to be real widgets consuming existing Riverpod providers and styled with AppTheme tokens,
**So that** the dashboard SDUI layout renders actual business data — no more stub `Text` placeholders.

---

## Acceptance Criteria

1. **`KpiCardGrid` widget** — Registered as `kpi_card_grid`. Reads `salesStatsProvider` via `ref.watch`. Renders a responsive `Wrap` or `GridView` of KPI cards (Ventes du jour, Transactions, Clients actifs, Stock faible). Each card uses `AppColors` and `AppTextStyles` — zero `Colors.green/blue/purple` hardcoded. Currency values display in FCFA (e.g., `1 500 FCFA`), not `$`.

2. **`LineChartWidget` widget** — Registered as `line_chart`. Reads `salesStatsProvider` via `ref.watch`. Uses `fl_chart` `LineChart` with `AppColors.primary` (`#1565C0`) for the line color — replaces `Colors.teal`. Title from the layout JSON `title` property (e.g., "Ventes des 7 derniers jours"). X-axis labels formatted as `dd/MM` in French locale.

3. **`TerminalStatusList` widget** — Registered as `terminal_status_list`. Reads `terminalStatusProvider` via `ref.watch`. Title "État des caisses" (from layout JSON or hardcoded French). Online chip: `AppColors.success` (`#2E7D32`). Offline chip: `AppColors.textSecondary`. Replaces `Colors.green` and `Colors.grey` hardcoded values.

4. **AppTheme token compliance** — All 3 widgets use only tokens from `AppColors` and `AppTextStyles`. No `Colors.*` literals, no `TextStyle(fontSize: x)` literals outside AppTextStyles. PR fails if `Colors.green`, `Colors.blue`, `Colors.teal`, `Colors.grey`, `Colors.purple` appear in new widget files.

5. **`setupSduiRegistry()` updated** — Replaces the 3 stub `Text(...)` registrations from Story 15-1 with the real widget constructors. Existing `product_grid` and `cart_panel` registrations unchanged.

6. **No regression** — All existing tests pass. The integration test from Story 15-1 (`dashboard_sdui_integration_test.dart`) is updated to register real widgets (like `pos_screen_test.dart` does for POS) and validate data rendering (at least one KPI card text visible).

---

## Tasks/Subtasks

- [x] **Task 1: Create `lib/features/dashboard/presentation/widgets/kpi_card_grid.dart`**
  - [x] `ConsumerWidget` watching `salesStatsProvider`
  - [x] 4 KPI cards: Ventes du jour, Transactions, Clients actifs, Stock faible
  - [x] Uses `AppColors`, `AppTextStyles` exclusively
  - [x] Currency: FCFA format (e.g., `NumberFormat('#,##0', 'fr_FR').format(v) + ' FCFA'`)

- [x] **Task 2: Create `lib/features/dashboard/presentation/widgets/line_chart_widget.dart`**
  - [x] `ConsumerWidget` watching `salesStatsProvider`
  - [x] `fl_chart` LineChart with `AppColors.primary` line color
  - [x] Accepts `title` string from SDUI props map (falls back to 'Ventes')
  - [x] X-axis dates in `dd/MM` format

- [x] **Task 3: Create `lib/features/dashboard/presentation/widgets/terminal_status_list.dart`**
  - [x] `ConsumerWidget` watching `terminalStatusProvider`
  - [x] Title "État des caisses"
  - [x] Online: `AppColors.success`, Offline: `AppColors.textSecondary`
  - [x] Replaces existing `TerminalsStatusWidget` in `dashboard_screen.dart`

- [x] **Task 4: Update `sdui_registry_setup.dart`** — swap stubs for real widgets

- [x] **Task 5: Update `dashboard_sdui_integration_test.dart`** — register real widgets, validate data render

- [x] **Task 6: Run `flutter test` — zero errors/regressions**

---

## Dev Notes

### Technical Context

- `salesStatsProvider` is `AsyncNotifierProvider<SalesStatsNotifier, List<SalesStat>>` in `dashboard_providers.dart`. `SalesStat` has `day: DateTime`, `revenue: double`, `orderCount: int`.
- `terminalStatusProvider` is `FutureProvider<List<Map<String, dynamic>>>` returning list with keys `deviceId`, `lastSeen` (ISO string), `status` (`'ONLINE'`/`'OFFLINE'`).
- AppTheme tokens location: `lib/core/theme/app_theme.dart` — check `AppColors` and `AppTextStyles` class names before using.
- SDUI props: `SduiSection` has a `props: Map<String, dynamic>` field. `line_chart` receives `title` and `data_provider` keys from the JSON. Widget factory receives `Map<String, dynamic> props` — use `props['title'] as String? ?? 'Ventes'`.
- `TerminalsStatusWidget` in `dashboard_screen.dart` (lines 317–387) can be replaced by `TerminalStatusList` — the existing class can be deleted once the SDUI widget is registered.
- FCFA formatting: use `intl` package already in `pubspec.yaml`. Pattern: `NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)`.

### File Paths

```
apps/frontend/lib/features/dashboard/presentation/widgets/kpi_card_grid.dart       ← CREATED
apps/frontend/lib/features/dashboard/presentation/widgets/line_chart_widget.dart    ← CREATED
apps/frontend/lib/features/dashboard/presentation/widgets/terminal_status_list.dart ← CREATED
apps/frontend/lib/core/sdui/sdui_registry_setup.dart                                ← MODIFIED
apps/frontend/test/dashboard_sdui_integration_test.dart                             ← MODIFIED
apps/frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart     ← MODIFIED (removed TerminalsStatusWidget)
```

---

## Dev Agent Record

### Implementation Plan

1. Created `KpiCardGrid` — `ConsumerWidget` watching `salesStatsProvider`. Computes total revenue (FCFA via `NumberFormat.currency`) and total order count from the stats list. `Clients actifs` and `Stock faible` show `--` (no provider yet). 4-card `Wrap` layout using `AppColors`/`AppTextStyles` tokens exclusively.
2. Created `LineChartWidget` — `ConsumerWidget` watching `salesStatsProvider`. Uses `fl_chart` `LineChart` with `AppColors.primary` line and `AppColors.primary.withValues(alpha: 0.1)` fill area. Title injected from SDUI props map. Empty-state guard shows French placeholder text.
3. Created `TerminalStatusList` — `ConsumerWidget` watching `terminalStatusProvider`. Online detection: `status == 'ONLINE'` AND seen within 5 minutes. Uses `AppColors.success`/`AppColors.textSecondary` for chip colors. French labels throughout.
4. Updated `sdui_registry_setup.dart` — removed stub `Text(...)` registrations; replaced with real widget factories. `line_chart` factory passes `props['title']` to `LineChartWidget`.
5. Removed `TerminalsStatusWidget` from `dashboard_screen.dart` — superseded by `TerminalStatusList` via SDUI registry.
6. Updated `dashboard_sdui_integration_test.dart` — registers real widgets in `setUp`, overrides `salesStatsProvider` and `terminalStatusProvider` with mock data, validates FCFA rendering and French labels.

### Completion Notes

- All 6 tasks complete. 63/63 tests pass. Zero regressions.
- `Clients actifs` and `Stock faible` show `--` — no dedicated providers yet; wired when those endpoints exist.
- `withOpacity` replaced by `withValues(alpha:)` in `TerminalStatusList` to avoid deprecation warning.

---

## File List

| Action | Path |
|--------|------|
| Created | `apps/frontend/lib/features/dashboard/presentation/widgets/kpi_card_grid.dart` |
| Created | `apps/frontend/lib/features/dashboard/presentation/widgets/line_chart_widget.dart` |
| Created | `apps/frontend/lib/features/dashboard/presentation/widgets/terminal_status_list.dart` |
| Modified | `apps/frontend/lib/core/sdui/sdui_registry_setup.dart` |
| Modified | `apps/frontend/test/dashboard_sdui_integration_test.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story created — Real dashboard widgets with AppTheme tokens |
| 2026-03-15 | Implementation complete — KpiCardGrid, LineChartWidget, TerminalStatusList, registry updated, TerminalsStatusWidget removed, 63/63 tests green |
