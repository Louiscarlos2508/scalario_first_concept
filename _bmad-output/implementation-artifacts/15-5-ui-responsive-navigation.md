# Story 15.5 — UI Responsive Navigation

## Metadata
- **Epic:** Epic 15 — SDUI Dashboard & UI Polish
- **Story ID:** 15-5-ui-responsive-navigation
- **Status:** review
- **Priority:** Medium
- **Depends on:** 15-1-sdui-dashboard-wiring (DashboardScreen shell must be stable before nav refactor)

---

## Story

**As a** merchant using Scalario on a phone or tablet,
**I want** the navigation to adapt to my screen size — bottom bar on phone, side rail on tablet —
**So that** the interface respects Material 3 adaptive navigation patterns and Loi de Fitts (thumb zones).

---

## Acceptance Criteria

1. **Breakpoint** — Width < `kCompact` (600px): `BottomNavigationBar`. Width ≥ `kCompact` (600px): `NavigationRail` (left side). Uses `LayoutBuilder` on `DashboardShell` (or equivalent shell widget). `kCompact = 600` from `lib/core/constants/app_breakpoints.dart`.

2. **`DashboardShell` updated** — `DashboardShell` widget in `dashboard_shell.dart` replaces its current navigation implementation with the adaptive pattern. Current navigation items (Tableau de bord, Inventaire, Catégories, Clients, Historique, Rapports, Paramètres) carry over — 7 items max (Loi de Hick).

3. **`BottomNavigationBar` (phone)** — Shows max 5 items; overflow items accessible via "Plus" or hidden. Bottom bar placed inside `SafeArea`. Touch targets ≥ 48dp (Material default, verify no padding overrides). Active item uses `AppColors.primary`.

4. **`NavigationRail` (tablet)** — Full 7-item list (scroll if needed). Left side. No `BottomNavigationBar` rendered. Active item uses `AppColors.primary`. Labels visible (not icon-only).

5. **`SafeArea`** — Every screen has `SafeArea` wrapping its `Scaffold` body (or the `DashboardShell` wraps the content area in `SafeArea`). Prevents content hiding behind notches, status bars, home indicators.

6. **Touch targets** — All navigation items, FABs, and action buttons verified ≥ 48×48dp. Use `SizedBox(height: 48, width: 48)` minimum for custom tap areas. No `IconButton` padding override below Material default.

7. **`PosScreen`** — The POS screen is full-screen and does not use `DashboardShell` navigation. Verify it is excluded from the shell navigation (it navigates separately via session guard). No regression on POS layout.

8. **Regression** — All 59+ existing tests pass. A new test `test/dashboard_navigation_test.dart` validates:
   - At 400dp width: `BottomNavigationBar` present, `NavigationRail` absent
   - At 800dp width: `NavigationRail` present, `BottomNavigationBar` absent

---

## Tasks/Subtasks

- [x] **Task 1: Read `dashboard_shell.dart` current implementation** before touching anything

- [x] **Task 2: Update `DashboardShell` with adaptive navigation**
  - [x] `LayoutBuilder` → width < 600 → `BottomNavigationBar`
  - [x] width ≥ 600 → `NavigationRail` + `Expanded` content area in `Row`
  - [x] `SafeArea` wrapping on the content area

- [x] **Task 3: Apply French labels to navigation items** (coordinate with 15-4)
  - [x] "Overview" → **"Accueil"**
  - [x] "Inventory" → **"Inventaire"**
  - [x] "Categories" → **"Catégories"**
  - [x] "Customers" → **"Clients"**
  - [x] "History" → **"Historique"**
  - [x] "Reports" → **"Rapports"**
  - [x] "Settings" → **"Paramètres"**

- [x] **Task 4: Verify touch targets** — audit nav items and FABs for ≥ 48dp

- [x] **Task 5: Create `test/dashboard_navigation_test.dart`**
  - [x] 400dp test → BottomNavigationBar
  - [x] 800dp test → NavigationRail

- [x] **Task 6: Run `flutter test` — zero errors/regressions**

---

## Dev Notes

### Technical Context

- `DashboardShell` is at `apps/frontend/lib/features/dashboard/presentation/widgets/dashboard_shell.dart`. Read it before implementing — it may already use `NavigationRail` or `BottomNavigationBar`.
- `kCompact = 600` is in `apps/frontend/lib/core/constants/app_breakpoints.dart`. Import from there — do not hardcode `600`.
- Material 3 adaptive navigation pattern: `Row(children: [NavigationRail(...), VerticalDivider(), Expanded(child: content)])` for wide layout.
- `SafeArea` should wrap the content body in `DashboardShell`, not each individual screen, to avoid double-SafeArea.
- For `BottomNavigationBar` with 7 items: either show only 5 and hide the rest (acceptable for MVP) or use `NavigationBar` (Material 3) which handles overflow better. Prefer `NavigationBar` if the codebase already uses Material 3 theming.
- `PosScreen` is reached via `Navigator.push` from outside `DashboardShell`, so it is naturally excluded from the navigation shell.

### Breakpoint Reference

```dart
// lib/core/constants/app_breakpoints.dart
const double kCompact = 600;   // phone → tablet boundary
const double kMedium = 1024;   // tablet → desktop boundary
```

### Test Pattern (from pos_sdui_integration_test.dart)

```dart
// Constrain with SizedBox to control LayoutBuilder
Widget _buildAt(double width) => ProviderScope(
  child: MaterialApp(home: Scaffold(
    body: SizedBox(width: width, child: DashboardShell(...)),
  )),
);
```

### File Paths

```
apps/frontend/lib/features/dashboard/presentation/widgets/dashboard_shell.dart ← MODIFIED
apps/frontend/test/dashboard_navigation_test.dart                               ← CREATED
```

---

## Dev Agent Record

### Implementation Plan

`DashboardShell` was already using `NavigationRail` exclusively (no responsive handling). Replaced `build()` with a `LayoutBuilder` that dispatches to `_buildPhoneLayout` (< `kCompact`) or `_buildTabletLayout` (≥ `kCompact`) based on `constraints.maxWidth`.

1. **`_buildTabletLayout`** — full `NavigationRail` (7 items, extended ≥ 1200px) with `leading` tenant-switcher, `trailing` POS/logout/sync actions, and `SafeArea` wrapping the `Expanded` content area.
2. **`_buildPhoneLayout`** — `BottomNavigationBar` (first 5 items, `BottomNavigationBarType.fixed`, `selectedItemColor: AppColors.primary`); `selectedIndex` clamped to 0–4 for MVP overflow; body wrapped in `SafeArea(bottom: false)`.
3. **French labels** — all 7 `_NavItem` labels set to French: Accueil, Inventaire, Catégories, Clients, Historique, Rapports, Paramètres.
4. **Touch targets** — `NavigationRail` and `BottomNavigationBar` use Material 3 defaults (≥ 48dp); `IconButton` trailing uses Material default 48×48dp tap area.
5. **Test** — `pumpAndSettle` replaced with `pump()` + `pump(50ms)` for 800dp test to avoid timeout from `SyncStatusIndicator`'s continuous animation.

### Completion Notes

All 6 tasks complete. 65/65 tests pass (63 pre-existing + 2 new navigation tests). Zero regressions.

---

## File List

| Action | Path |
|--------|------|
| Modified | `apps/frontend/lib/features/dashboard/presentation/widgets/dashboard_shell.dart` |
| Created | `apps/frontend/test/dashboard_navigation_test.dart` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story created — Adaptive BottomNav/NavigationRail with SafeArea and Fitts compliance |
| 2026-03-15 | Implementation complete — `DashboardShell` adaptive nav (LayoutBuilder), French labels, SafeArea, 2 new tests, 65/65 green |
