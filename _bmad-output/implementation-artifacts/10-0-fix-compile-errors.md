# Story 10.0 — Fix Compile Errors

## Metadata
- **Epic:** Epic 10 — SDUI Foundation & Engine
- **Story ID:** 10-0-fix-compile-errors
- **Status:** review
- **Priority:** High (blocking all Epic 10 work)
- **Depends on:** None

---

## Story

**As a** developer,
**I want** the existing compile errors in `pos_providers.dart`, `product_grid.dart`, and `cart_panel.dart` fixed,
**So that** the app builds cleanly and all subsequent SDUI work can proceed on a stable base.

---

## Acceptance Criteria

1. **SyncService constructor** — `syncServiceProvider` in `pos_providers.dart` calls `SyncService()` with zero positional arguments, matching the actual no-arg constructor in `sync_service.dart`.

2. **categoriesProvider defined** — A `categoriesProvider` (FutureProvider<List<Category>>) is declared in `pos_providers.dart` and importable by `product_grid.dart` and any other consumer, returning categories for the active tenant from `CategoryRepository`.

3. **ReceiptDialog imported** — `cart_panel.dart` imports `receipt_dialog.dart`; the reference to `ReceiptDialog(order: order)` compiles without error.

4. **Zero compile errors** — `flutter analyze` reports zero errors (warnings acceptable, infos acceptable).

5. **All tests pass** — `flutter test` completes with all tests green (12/12 existing tests pass, no regressions).

---

## Tasks/Subtasks

- [x] **Task 1: Run flutter analyze and capture full error list**
  - [x] Run `flutter analyze` from `apps/frontend/`
  - [x] Document all errors (not just the 3 known ones) — found 9 compile errors total

- [x] **Task 2: Fix Error 1 — SyncService constructor**
  - [x] In `pos_providers.dart` `syncServiceProvider`, replaced 5-arg call with `SyncService()`
  - [x] Removed unused repo variables
  - [x] Fixed `main.dart` `startSync()` missing tenantId arg

- [x] **Task 3: Fix Error 2 — categoriesProvider missing**
  - [x] Added `categoriesProvider` FutureProvider<List<Category>> to `pos_providers.dart`
  - [x] Provider uses `categoryRepositoryProvider` + `activeTenantProvider`
  - [x] Returns empty list when tenantId is null

- [x] **Task 4: Fix Error 3 — ReceiptDialog import missing in cart_panel.dart**
  - [x] Added import for `receipt_dialog.dart` to `cart_panel.dart`

- [x] **Task 5: Fix additional errors surfaced by flutter analyze**
  - [x] `categories_screen.dart` — replaced wrong import, fixed `category.id` → `category.remoteId`
  - [x] `customers_screen.dart` — added missing `auth_state.dart` import
  - [x] `product_form_dialog.dart` — replaced wrong import, fixed `c.id` → `c.remoteId` in dropdown
  - [x] `settle_debt_dialog.dart` — fixed `customer.id` → `customer.remoteId!`
  - [x] `product_grid.dart` — fixed `c.id` → `c.remoteId`, removed stale import

- [x] **Task 6: Verify — flutter analyze reports zero errors**
  - 108 items remaining are all `info`/`warning` (pre-existing, out of scope)

- [x] **Task 7: Verify — flutter test passes 13/13**
  - `pos_screen_test` required provider mocks for `SessionGuard`, `SyncService`, and `IsarService`; added stubs

---

## Dev Notes

### Known errors (pre-confirmed)

1. **`pos_providers.dart` ~line 77** — `SyncService` has a no-arg constructor; the provider passes 5 repos that are no longer needed. Root cause: `SyncService` was refactored to use an isolate with internal repo construction (see `_syncIsolateEntryPoint`). The provider wiring was not updated.

2. **`product_grid.dart` line 13** — `categoriesProvider` is referenced but never defined. It must be a `FutureProvider<List<Category>>` in `pos_providers.dart`. The `CategoryRepository.getCategories(tenantId)` requires a `tenantId` param.

3. **`cart_panel.dart` ~line 155** — `ReceiptDialog` is used in the checkout `onPressed` handler but `receipt_dialog.dart` is not imported. The existing import is `receipt_service.dart` (different file).

### Scope constraint
Fix ONLY compile errors. No style changes, no translations, no refactors, no logic changes beyond what is required to resolve the error.

---

## Dev Agent Record

### Debug Log

9 compile errors found (3 known + 6 additional). Root cause pattern: Epic 8 refactored `SyncService` to isolate-based (no constructor args) and introduced `categoriesProvider`/`remoteId` conventions, but several dashboard files were not updated to match. All errors fixed in scope.

### Completion Notes

- `flutter analyze` — 0 errors, 108 info/warnings (pre-existing, out of scope)
- `flutter test` — 13/13 pass (12 baseline + `pos_screen_test` now passing)
- `pos_screen_test` required provider stubs: `isarServiceProvider` (stub with never-completing `initDb`), `syncServiceProvider` (empty stream), `sessionProvider` (pre-seeded `_FakeSessionNotifier`), `categoriesProvider`, `userProfileProvider`, `activeTenantProvider`
- `pumpAndSettle()` replaced with `pump(Duration(milliseconds: 300))` in pos_screen_test — live streams/animations from un-mocked widgets prevent settle

---

## File List

| Action | Path |
|--------|------|
| Modified | `apps/frontend/lib/features/pos/presentation/providers/pos_providers.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/cart_panel.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/product_grid.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/categories_screen.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/customers_screen.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/widgets/product_form_dialog.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/widgets/settle_debt_dialog.dart` |
| Modified | `apps/frontend/lib/main.dart` |
| Modified | `apps/frontend/test/pos_screen_test.dart` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story implemented — 9 compile errors fixed, 13/13 tests pass |
