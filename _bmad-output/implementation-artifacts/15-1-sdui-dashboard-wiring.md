# Story 15.1 — SDUI Dashboard Wiring

## Metadata
- **Epic:** Epic 15 — SDUI Dashboard & UI Polish
- **Story ID:** 15-1-sdui-dashboard-wiring
- **Status:** done
- **Priority:** High
- **Depends on:** Epic 10 done (SduiRenderer, SduiWidgetRegistry, sduiLayoutProvider all operational)

---

## Story

**As a** developer,
**I want** `OverviewScreen` to be driven by `sduiLayoutProvider('dashboard')` using `retail.dashboard.json`,
**So that** the dashboard body is controlled by the SDUI engine — the same way PosScreen was wired in Story 10-5.

---

## Acceptance Criteria

1. **Registry wiring** — `kpi_card_grid`, `line_chart`, and `terminal_status_list` are registered in `setupSduiRegistry()` with stub `Text` placeholders (real widgets come in Story 15-2). Registration is additive — `product_grid` and `cart_panel` remain registered.

2. **OverviewScreen SDUI-driven** — `OverviewScreen` watches `sduiLayoutProvider('dashboard')`. The hardcoded `_buildDashboard()` / `_buildSalesChart()` / `_buildStatCard()` body is replaced by `SduiRenderer(layout: layout)`. The `AppBar` (title, date range picker, refresh button) remains unchanged.

3. **Offline fallback** — When `sduiLayoutProvider('dashboard')` throws or is loading, `OverviewScreen` silently falls back to `SduiLayout.dashboardDefault()`. No blank screen.

4. **`SduiLayout.dashboardDefault()`** — Static factory on `SduiLayout` that returns the layout equivalent to `retail.dashboard.json` hardcoded in Dart — matching the 3 sections: `kpi_card_grid`, `line_chart`, `terminal_status_list`.

5. **Backend endpoint** — `GET /sdui/layout?screen=dashboard` returns the parsed `retail.dashboard.json`. The existing `SduiService.getLayout()` already resolves files by screen name — no new logic needed, only the JSON file must exist (it does).

6. **Integration tests** — `test/dashboard_sdui_integration_test.dart` covers:
   - Tablet (800dp): stubs for all 3 panel types rendered in a `Column`
   - Phone (400dp): same stubs rendered (dashboard uses `dashboard_scroll`, no layout split)
   - Offline fallback: never-completing `Completer` → stubs still render via `SduiLayout.dashboardDefault()`

7. **No regression** — All 59 existing tests continue to pass.

---

## Tasks/Subtasks

- [x] **Task 1: Add `SduiLayout.dashboardDefault()` to `sdui_layout.dart`**
  - [x] Static factory returning `dashboard_scroll` layout with 3 sections matching `retail.dashboard.json`

- [x] **Task 2: Register dashboard stub widgets in `sdui_registry_setup.dart`**
  - [x] `kpi_card_grid` → `Text('KpiCardGrid')`
  - [x] `line_chart` → `Text('LineChart')`
  - [x] `terminal_status_list` → `Text('TerminalStatusList')`

- [x] **Task 3: Update `OverviewScreen` to use SDUI**
  - [x] Watch `sduiLayoutProvider('dashboard')` ; loading + error → `SduiLayout.dashboardDefault()`
  - [x] Replace body with `SduiRenderer(layout: layout)`
  - [x] Keep `AppBar` (title, date range picker, refresh) unchanged

- [x] **Task 4: Create `test/dashboard_sdui_integration_test.dart`**
  - [x] `setUp`/`tearDown` registering stub widgets
  - [x] Tablet test (800dp `SizedBox`)
  - [x] Phone test (400dp `SizedBox`)
  - [x] Offline fallback test (never-completing `Completer`)

- [x] **Task 5: Run `flutter test` — zero errors/regressions**

---

## Dev Notes

### Technical Context

- `sduiLayoutProvider` is `FutureProvider.family<SduiLayout, String>`. The `'dashboard'` key maps to `GET /sdui/layout?screen=dashboard` on the NestJS backend.
- `SduiService.getLayout(businessType, screen)` resolves to `retail.dashboard.json` using the path pattern `src/sdui/layouts/{businessType}.{screen}.json`. The file exists at `apps/backend/src/sdui/layouts/retail.dashboard.json`.
- `dashboard_scroll` layout type is already handled by `SduiRenderer._buildSubLayout()` — it renders a `SingleChildScrollView(Column(children: sections))`.
- Stub widgets must be registered BEFORE `sduiLayoutProvider` resolves. `setupSduiRegistry()` in `main()` covers the runtime case. Tests must call `setUp`/`tearDown` with `SduiWidgetRegistry`.
- The `OverviewScreen` currently uses `salesStatsProvider` and `terminalStatusProvider` to build its body — these providers are handed off to the real widgets in Story 15-2. In 15-1, stub `Text` widgets are sufficient.
- `_refreshTimer` in `_OverviewScreenState` refreshes `salesStatsProvider` and `terminalStatusProvider` — keep it; it will be used by real widgets in 15-2.

### File Paths

```
apps/frontend/lib/core/sdui/sdui_layout.dart              ← MODIFIED (add dashboardDefault)
apps/frontend/lib/core/sdui/sdui_registry_setup.dart      ← MODIFIED (add 3 stub registrations)
apps/frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart ← MODIFIED
apps/frontend/test/dashboard_sdui_integration_test.dart   ← CREATED
```

---

## File List

| Action | Path |
|--------|------|
| Modified | `apps/frontend/lib/core/sdui/sdui_layout.dart` |
| Modified | `apps/frontend/lib/core/sdui/sdui_registry_setup.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart` |
| Created | `apps/frontend/test/dashboard_sdui_integration_test.dart` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story created — Dashboard SDUI wiring |
| 2026-03-15 | Story implemented and completed |

---

## Senior Developer Review

**Status:** APPROVED

**Summary:**
- `SduiLayout.dashboardDefault()` factory added mirroring `retail.dashboard.json` (3 sections: `kpi_card_grid`, `line_chart`, `terminal_status_list`)
- 3 stub widget registrations added to `setupSduiRegistry()` (additive — POS registrations unchanged)
- `OverviewScreen` body replaced with `SduiRenderer` driven by `sduiLayoutProvider('dashboard')`; loading/error both fall back to `dashboardDefault()` — no blank screens
- Old `_buildDashboard` / `_buildSalesChart` / `_buildStatCard` methods removed; `fl_chart` and `sales_stat` imports removed (they were only used by those methods)
- `AppBar` (title, date range picker, refresh button) unchanged
- `_refreshTimer` kept (used by real widgets in Story 15-2)
- `test/dashboard_sdui_integration_test.dart` created: tablet (800dp), phone (400dp), offline fallback tests
- **62/62 tests pass** (59 original + 3 new)
