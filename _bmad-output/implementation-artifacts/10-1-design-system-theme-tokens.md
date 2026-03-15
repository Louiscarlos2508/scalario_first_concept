# Story 10.1 — Design System Theme Tokens

## Metadata
- **Epic:** Epic 10 — SDUI Foundation & Engine
- **Story ID:** 10-1-design-system-theme-tokens
- **Status:** in-progress
- **Priority:** High
- **Depends on:** 10-0-fix-compile-errors (done)

---

## Story

**As a** developer,
**I want** a centralized `AppTheme` file encoding every design system token from `docs/design-system.md`,
**So that** all screens adopt correct colors, typography, and component defaults automatically.

---

## Acceptance Criteria

1. **AppColors** — `lib/core/theme/app_theme.dart` exports `AppColors` class with static `const Color` values:
   - `primary = Color(0xFF1565C0)` — Bleu confiance (10% accent)
   - `success = Color(0xFF2E7D32)` — Vert
   - `error = Color(0xFFC62828)` — Rouge
   - `warning = Color(0xFFF9A825)` — Jaune
   - `surface = Color(0xFFFFFFFF)` — Surfaces
   - `background = Color(0xFFF5F5F5)` — Fond app (60%)
   - `textPrimary = Color(0xFF212121)` — Texte principal
   - `textSecondary = Color(0xFF757575)` — Texte léger
   - `border = Color(0xFFE0E0E0)` — Bordures

2. **AppTheme.textTheme** — defines 8 text styles mapped to Flutter `TextTheme` slots:
   - `displayMedium` → 22sp Bold `#212121` (titre principal)
   - `titleLarge` → 18sp SemiBold `#212121` (titre section)
   - `titleMedium` → 16sp SemiBold `#212121` (titre carte)
   - `bodyMedium` → 14sp Regular `#212121` (corps)
   - `bodySmall` → 12sp Regular `#757575` (corps petit)
   - `labelSmall` → 11sp Medium `#757575` (étiquette)
   - `headlineLarge` → 20sp Bold monospace `#212121` (prix)
   - `headlineMedium` → 18sp Bold monospace `#212121` (quantité)

3. **Component defaults (Fitts ≥ 48dp)** — `AppTheme.light()` sets:
   - `ElevatedButtonThemeData` with `minimumSize: Size(64, 48)`
   - `FilledButtonThemeData` with `minimumSize: Size(88, 56)` (primary CTA)
   - `InputDecorationTheme` with `OutlineInputBorder` using `AppColors.border`
   - `CardTheme` with `elevation: 0`, `borderRadius: 12`, side `AppColors.border`

4. **main.dart wired** — `MaterialApp(theme: AppTheme.light())` is set (single line change).

5. **Breakpoints** — `lib/core/theme/app_breakpoints.dart` exports:
   - `const double kCompact = 600.0`
   - `const double kMedium = 1024.0`

6. **Scope** — Zero screen/widget files modified. Theme tokens and `main.dart` only.

---

## Tasks/Subtasks

- [ ] **Task 1: Create `lib/core/theme/app_theme.dart`**
  - [ ] Define `AppColors` with all 9 static const Color values
  - [ ] Define `AppTextStyles` with 8 TextStyle constants
  - [ ] Implement `AppTheme.light()` with colorScheme, textTheme, component themes

- [ ] **Task 2: Create `lib/core/theme/app_breakpoints.dart`**
  - [ ] Export `kCompact = 600.0` and `kMedium = 1024.0`

- [ ] **Task 3: Wire theme in `lib/main.dart`**
  - [ ] Add import for `app_theme.dart`
  - [ ] Set `theme: AppTheme.light()` in `MaterialApp`

- [ ] **Task 4: Write unit tests for theme tokens**
  - [ ] Verify all 9 AppColors values
  - [ ] Verify all 8 TextTheme slots
  - [ ] Verify component minimum sizes (Fitts law)
  - [ ] Verify breakpoint values

- [ ] **Task 5: Run flutter analyze and flutter test**
  - [ ] Zero new errors
  - [ ] All tests pass (no regressions)

---

## Dev Notes

### Technical Context

- **Flutter version:** 3.x with Material 3 (`useMaterial3: true` already in main.dart)
- **ColorScheme:** Use `ColorScheme.fromSeed(seedColor: AppColors.primary)` as base, then override with exact AppColors values to guarantee exact hex fidelity
- **TextTheme:** Flutter Material 3 TextTheme slot naming — use `TextTheme()` constructor with named params
- **Monospace font:** Use `fontFamily: 'monospace'` (maps to system monospace — Roboto Mono on Android). No external font packages.
- **FontWeight.w600** = SemiBold in Flutter
- **FilledButtonTheme:** Available via `filledButtonTheme` property in `ThemeData` (Material 3)
- **CardTheme border:** Use `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border))`
- **InputDecorationTheme border:** Use `border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border))`

### Scope Constraint

Fix ONLY theme files and main.dart. Do NOT modify any screen/widget files. The theme propagates automatically through the widget tree.

### File Paths

```
apps/frontend/lib/core/theme/app_theme.dart        ← CREATE
apps/frontend/lib/core/theme/app_breakpoints.dart  ← CREATE
apps/frontend/lib/main.dart                        ← MODIFY (theme: line only)
apps/frontend/test/theme_test.dart                 ← CREATE (unit tests)
```

---

## Dev Agent Record

### Debug Log

### Completion Notes

---

## File List

| Action | Path |
|--------|------|

---

## Change Log

| Date | Change |
|------|--------|
