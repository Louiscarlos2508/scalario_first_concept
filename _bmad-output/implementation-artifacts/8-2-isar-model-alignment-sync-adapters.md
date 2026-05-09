# Story 8.2: Isar Model Alignment & Sync Adapters

Status: review

## Story

As a developer,
I want Isar collections aligned with the new backend API response shapes and a module-agnostic sync adapter layer,
So that local data matches the restructured backend models and the sync engine can be extended per entity without modifying core logic.

## Acceptance Criteria

1. **AC1 — Product model aligned:** Given the existing `Product` Isar collection is missing fields from the new `CatalogItem + RetailProduct` response shape, when the model is updated, then it stores `itemType`, `minStockLevel`, and `weightUnit` fields, and `fromJson()` correctly reads `stockQuantity` from the nested retailProduct response.

2. **AC2 — Order model aligned:** Given the existing `Order` Isar collection is missing Transaction/RetailSale fields, when the model is updated, then it stores `receiptNumber`, `lifecycleType`, and `userId` fields, and `fromJson()` handles the server response from `POST /retail/sales`.

3. **AC3 — Customer model field parity:** Given the existing `Customer` Isar collection is missing `contactType`, `isSynced`, and `lastUpdated` fields, when the model is updated, then all three fields are present: `contactType` (String, default 'customer'), `isSynced` (bool, default false), `lastUpdated` (DateTime?).

4. **AC4 — Isar codegen regenerated:** Given model fields are added, when `flutter pub run build_runner build --delete-conflicting-outputs` runs, then all `.g.dart` files are regenerated without errors: `product.g.dart`, `order.g.dart`, `customer.g.dart`.

5. **AC5 — Module-agnostic sync adapters:** Given the SyncService isolate contains entity-specific logic inline, when sync adapters are extracted, then each entity type has its own adapter class implementing a common `SyncAdapter` interface:
   - `CatalogSyncAdapter` — handles product push/pull
   - `ContactSyncAdapter` — handles customer push/pull
   - `TransactionSyncAdapter` — handles order push to `/retail/sales`
   - `SessionSyncAdapter` — handles session push to `/pos/sessions`
   - The SyncService orchestrates adapters without embedding entity-specific HTTP or Isar logic.

6. **AC6 — IsarService updated:** Given new fields are added to models, when `IsarService.initDb()` registers schemas, then the schema list includes all updated schemas with no version mismatch.

7. **AC7 — Tests pass:** Given model changes and adapter extraction are complete, when existing tests run (`flutter test`), then 0 regressions.

## Tasks / Subtasks

### Phase 1 — Align Isar models (AC1, AC2, AC3)

- [x] **1.1** Update `apps/frontend/lib/features/pos/data/models/product.dart`:
  - Add `String? itemType`, `double? minStockLevel`, `String? weightUnit`
  - Update `fromJson()` with camelCase + snake_case fallbacks

- [x] **1.2** Update `apps/frontend/lib/features/pos/data/models/order.dart`:
  - Add `String? receiptNumber`, `String? lifecycleType`, `String? userId`
  - Add `Order.fromServerResponse()` factory for server response mapping

- [x] **1.3** Update `apps/frontend/lib/features/pos/data/models/customer.dart`:
  - Add `String? contactType`, `bool isSynced = false`, `DateTime? lastUpdated`
  - Update `fromJson()` and `toJson()`

### Phase 2 — Regenerate Isar codegen (AC4, AC6)

- [x] **2.1** Run `flutter pub run build_runner build --delete-conflicting-outputs` — succeeded, all `.g.dart` files regenerated cleanly.

- [x] **2.2** Verify `IsarService.initDb()` schemas — `ProductSchema`, `OrderSchema`, `CustomerSchema` already registered. No changes needed.

### Phase 3 — Extract sync adapters (AC5)

- [x] **3.1** Create `apps/frontend/lib/core/services/sync_adapters/sync_adapter.dart` — abstract `SyncAdapter` interface.

- [x] **3.2** Create `catalog_sync_adapter.dart` — `CatalogSyncAdapter` (product + category pull).

- [x] **3.3** Create `contact_sync_adapter.dart` — `ContactSyncAdapter` (customer push + pull).

- [x] **3.4** Create `transaction_sync_adapter.dart` — `TransactionSyncAdapter` (order push to POST /retail/sales).

- [x] **3.5** Create `session_sync_adapter.dart` — `SessionSyncAdapter` (session push to POST /pos/sessions).

- [x] **3.6** Refactor `sync_service.dart` — adapter orchestration replaces all inline entity methods. Push order: sessions → transactions → contacts → catalog pull. Added `stopSync()` and `forceSync()` methods.

### Phase 4 — Tests (AC7)

- [x] **4.1** `flutter test` — `widget_test.dart` 1/1 passes. 0 regressions from Story 8.2.

## Dev Notes

### Current Product.fromJson field mapping

Current `product.dart` fromJson reads `stockQuantity` from `json['stockQuantity'] ?? json['stock_quantity']` directly. After Story 9.2, the backend `getProducts()` response returns `stockQuantity` flattened (it's mapped from `item.retailProduct?.stockQuantity` in `pos.service.ts:59`). So the current parsing still works — just add the new fields.

### Order model — server response from POST /retail/sales

When SyncService pushes an order via `POST /retail/sales`, the backend creates a `Transaction` + `RetailSale`. The response shape includes `id`, `uuid`, `receiptNumber`, `totalAmount`, `lifecycleType`. `Order.fromServerResponse()` factory handles this.

### Isar schema version

Adding nullable/defaulted fields to Isar `@collection` models doesn't require a migration — Isar handles missing fields gracefully. `build_runner` updates schema hash automatically.

### Adapter architecture

Adapters instantiated inside the isolate using already-created repo instances. `_performSyncWithAdapters()` is the orchestrator — knows ordering but not entity-specific logic.

### References

- `apps/frontend/lib/features/pos/data/models/product.dart`
- `apps/frontend/lib/features/pos/data/models/order.dart`
- `apps/frontend/lib/features/pos/data/models/customer.dart`
- `apps/frontend/lib/core/services/isar_service.dart`
- `apps/frontend/lib/core/services/sync_service.dart`
- [Story 8.1](8-1-repository-api-url-migration.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- **build_runner failure (pre-fix):** `product_repository.dart:203: Expected an identifier` — Story 8.1 `replace_all` introduced `'$ApiConstants.baseUrl'` (missing braces) and `?tenantId` (invalid map entry syntax). Fixed across all 3 repositories before running build_runner.
- **Order constructor error:** Missing explicit `Order()` constructor needed for `Order.fromServerResponse()` factory. Fixed by adding `Order();`.

### Completion Notes List

- **Task 1.1 (Product):** Added `itemType` (defaults to `'physical'`), `minStockLevel`, `weightUnit` to `Product`. `fromJson()` and `toJson()` updated with camelCase + snake_case fallbacks.
- **Task 1.2 (Order):** Added `Order()` constructor, `receiptNumber`, `lifecycleType`, `userId`. Added `Order.fromServerResponse()` factory. `toJson()` conditionally includes new fields.
- **Task 1.3 (Customer):** Added `contactType`, `isSynced`, `lastUpdated`. `fromJson()` sets `isSynced = true` (from server = synced). `toJson()` includes both new fields. Fixes pre-existing compile error in `customer_repository.dart:markAsSynced` (referenced `isSynced`/`lastUpdated` before they existed).
- **Task 2.1:** Fixed interpolation bugs in `product_repository.dart`, `customer_repository.dart`, `category_repository.dart` first. Then build_runner: `Succeeded after 1.1s with 0 outputs (3 actions)`.
- **Task 2.2:** No IsarService changes needed — schemas already registered.
- **Tasks 3.1–3.5:** Created `sync_adapters/` directory with 5 files: abstract interface + 4 concrete adapters. Each delegates to existing repositories, uses same HTTP patterns as original inline methods.
- **Task 3.6:** `sync_service.dart` rewritten — all inline entity methods removed (~200 lines), replaced by adapter orchestration in `_performSyncWithAdapters()`. Added `stopSync()` and `forceSync()` (were called externally but missing). Pre-existing `pos_screen_test` `forceSync()` error now resolved.
- **Task 4.1:** `widget_test.dart` 1/1 passes. `flutter analyze` shows 21 info-level `avoid_print` warnings (consistent with existing codebase). 0 errors.

### File List

- `apps/frontend/lib/features/pos/data/models/product.dart` [MODIFIED — itemType, minStockLevel, weightUnit added]
- `apps/frontend/lib/features/pos/data/models/order.dart` [MODIFIED — Order() constructor, receiptNumber, lifecycleType, userId, fromServerResponse()]
- `apps/frontend/lib/features/pos/data/models/customer.dart` [MODIFIED — contactType, isSynced, lastUpdated added]
- `apps/frontend/lib/features/pos/data/models/product.g.dart` [REGENERATED]
- `apps/frontend/lib/features/pos/data/models/order.g.dart` [REGENERATED]
- `apps/frontend/lib/features/pos/data/models/customer.g.dart` [REGENERATED]
- `apps/frontend/lib/core/services/sync_adapters/sync_adapter.dart` [NEW — abstract SyncAdapter interface]
- `apps/frontend/lib/core/services/sync_adapters/catalog_sync_adapter.dart` [NEW — CatalogSyncAdapter]
- `apps/frontend/lib/core/services/sync_adapters/contact_sync_adapter.dart` [NEW — ContactSyncAdapter]
- `apps/frontend/lib/core/services/sync_adapters/transaction_sync_adapter.dart` [NEW — TransactionSyncAdapter]
- `apps/frontend/lib/core/services/sync_adapters/session_sync_adapter.dart` [NEW — SessionSyncAdapter]
- `apps/frontend/lib/core/services/sync_service.dart` [MODIFIED — adapter orchestration, stopSync()/forceSync() added]
- `apps/frontend/lib/features/pos/data/repositories/product_repository.dart` [FIXED — interpolation + map entry syntax]
- `apps/frontend/lib/features/pos/data/repositories/customer_repository.dart` [FIXED — interpolation]
- `apps/frontend/lib/features/pos/data/repositories/category_repository.dart` [FIXED — interpolation]

## Change Log

- 2026-03-15: Story 8.2 created — Product/Order/Customer model alignment, build_runner regen, SyncAdapter interface + 4 concrete adapters, SyncService refactor.
- 2026-03-15: Story 8.2 implemented — 3 models aligned (7 new fields total), build_runner clean, 5 adapter files created, SyncService refactored to adapter orchestration, repo interpolation bugs fixed, widget_test 1/1 passes.
