# Story 10.4 — SDUI Flutter Renderer Engine

## Metadata
- **Epic:** Epic 10 — SDUI Foundation & Engine
- **Story ID:** 10-4-sdui-flutter-renderer
- **Status:** done
- **Priority:** High
- **Depends on:** 10-3-sdui-backend-layout-service (done)

---

## Story

**As a** Flutter developer,
**I want** a generic widget renderer that converts a parsed `SduiLayout` into a Flutter widget tree,
**So that** any screen can be driven by server-provided JSON without hardcoded widget hierarchies.

---

## Acceptance Criteria

1. **SduiLayout model** — `SduiLayout.fromJson` parses the top-level JSON envelope. `SduiLayout.retailPosDefault()` returns the hardcoded fallback layout for offline use (Story 10-5).

2. **Widget registry + renderer** — `SduiWidgetRegistry` maps type strings to factory functions. `SduiRenderer(layout: layout)` builds the widget tree: `product_grid` → `ProductGrid`, `cart_panel` → `CartPanel`, `split_view` → `LayoutBuilder` with `kCompact`/`kMedium`, `stacked_with_fab_cart` → full-width product grid + floating cart badge.

3. **Cache + stale-while-revalidate** — `sduiLayoutProvider(screen)` returns cached layout from SharedPreferences (key: `sdui_layout_{screen}`, TTL: 1 hour). Refetches in background after TTL.

4. **Offline resilience** — If fetch fails (offline), stale cache is used without throwing. If no cache at all, exception propagates.

5. **Unknown type fallback** — Unknown panel/layout type renders `SizedBox.shrink()` — fails silently, logs in debug mode only.

---

## Tasks/Subtasks

- [x] **Task 1: Add `shared_preferences` to pubspec.yaml**

- [x] **Task 2: Create `lib/core/sdui/sdui_layout.dart`**
  - [x] `SduiLayout` model with `fromJson`, `toJson`
  - [x] `SduiLayout.retailPosDefault()` factory

- [x] **Task 3: Create `lib/core/sdui/sdui_widget_registry.dart`**
  - [x] `SduiWidgetRegistry` singleton with `register`, `build`, `reset` (for tests)
  - [x] Unknown type → `SizedBox.shrink()` + `kDebugMode` debugPrint (silent in prod)

- [x] **Task 4: Create `lib/core/sdui/sdui_renderer.dart`**
  - [x] `SduiRenderer` ConsumerWidget
  - [x] Handle `split_view` with LayoutBuilder + kCompact/kMedium breakpoints
  - [x] Handle `horizontal_split` (Row with flex)
  - [x] Handle `stacked_with_fab_cart` (full-screen product grid + FAB badge)
  - [x] Handle `dashboard_scroll` (scrollable Column of sections)
  - [x] Delegate panel types to `SduiWidgetRegistry`

- [x] **Task 5: Create `lib/core/services/sdui_service.dart`**
  - [x] `SduiService` with injectable `http.Client` for testability
  - [x] `fetchLayout(screen, {tenantId, token})`: check cache → fetch → cache result
  - [x] Offline fallback: stale cache used without throwing

- [x] **Task 6: Create `lib/core/sdui/sdui_providers.dart`**
  - [x] `sduiServiceProvider` (Provider<SduiService>)
  - [x] `sduiLayoutProvider` (FutureProvider.family<SduiLayout, String>)

- [x] **Task 7: Write tests**
  - [x] `test/sdui_layout_test.dart` — fromJson, retailPosDefault, toJson round-trip (8 tests)
  - [x] `test/sdui_renderer_test.dart` — unknown type → SizedBox.shrink, registry, horizontal_split, dashboard_scroll (7 tests)

- [x] **Task 8: Run flutter analyze + flutter test — zero errors/regressions**

---

## Dev Notes

### Technical Context

- `shared_preferences` v2.5.4 already in pubspec.lock (transitive) — added as direct dep `^2.3.0`
- `SduiRenderer` extends `ConsumerWidget` to read `cartProvider` for FAB badge item count in `stacked_with_fab_cart`
- `SduiWidgetRegistry` uses `kDebugMode + debugPrint` (not `assert`) for unknown types — truly silent in prod, visible in debug
- `SduiWidgetRegistry.reset()` provided for test isolation
- `SduiService` accepts `http.Client` in constructor for test injection
- `flutter analyze` on new files: **0 issues**

### File Paths

```
apps/frontend/pubspec.yaml                         ← MODIFIED
apps/frontend/lib/core/sdui/sdui_layout.dart       ← CREATED
apps/frontend/lib/core/sdui/sdui_widget_registry.dart ← CREATED
apps/frontend/lib/core/sdui/sdui_renderer.dart     ← CREATED
apps/frontend/lib/core/services/sdui_service.dart  ← CREATED
apps/frontend/lib/core/sdui/sdui_providers.dart    ← CREATED
apps/frontend/test/sdui_layout_test.dart           ← CREATED
apps/frontend/test/sdui_renderer_test.dart         ← CREATED
```

---

## Dev Agent Record

### Debug Log

- `assert(false, ...)` in registry threw `AssertionError` in test mode — replaced with `if (kDebugMode) debugPrint(...)` for true silent degradation
- `CartNotifier extends StateNotifier<CartState>` (not new `Notifier` API) — test override uses `cartProvider.overrideWith((ref) => CartNotifier())`

### Completion Notes

- `SduiLayout` — model + `fromJson` + `toJson` + `toJsonString` + `retailPosDefault()` static factory
- `SduiWidgetRegistry` — static `register/build/hasType/reset`; unknown → `SizedBox.shrink()` + debugPrint
- `SduiRenderer` — ConsumerWidget handling `split_view` (LayoutBuilder), `horizontal_split` (Row+flex), `stacked_with_fab_cart` (Stack+FAB), `dashboard_scroll` (SingleChildScrollView)
- `SduiService` — SharedPreferences TTL cache (1h); stale-while-revalidate; offline fallback
- `sduiLayoutProvider` — FutureProvider.family with tenantId injection
- 15 new tests (8 layout + 7 renderer); all pass
- 55/55 total tests pass — zero regressions
- 0 analyze issues in new code

---

## File List

| Action | Path |
|--------|------|
| Modified | `apps/frontend/pubspec.yaml` |
| Created | `apps/frontend/lib/core/sdui/sdui_layout.dart` |
| Created | `apps/frontend/lib/core/sdui/sdui_widget_registry.dart` |
| Created | `apps/frontend/lib/core/sdui/sdui_renderer.dart` |
| Created | `apps/frontend/lib/core/services/sdui_service.dart` |
| Created | `apps/frontend/lib/core/sdui/sdui_providers.dart` |
| Created | `apps/frontend/test/sdui_layout_test.dart` |
| Created | `apps/frontend/test/sdui_renderer_test.dart` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story implemented — SDUI engine (model, registry, renderer, service, providers); 15 tests; 55/55 pass |
