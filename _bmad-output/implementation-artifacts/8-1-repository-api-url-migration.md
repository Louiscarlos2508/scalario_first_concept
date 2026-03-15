# Story 8.1: Repository & API URL Migration

Status: review

## Story

As a developer,
I want all frontend repositories and the sync service updated to call the correct API endpoints with centralized URL configuration,
So that the frontend communicates correctly with the restructured backend after the Story 9.2 cleanup.

## Acceptance Criteria

1. **AC1 — Centralized API config:** Given the base URL is currently hardcoded in 5 separate files, when `lib/core/constants/api_constants.dart` is created, then all repositories and services import the constant from one place, and changing the URL in one file updates the entire app.

2. **AC2 — Broken order sync fixed:** Given `SyncService._pushPendingOrders()` at line 226 calls `POST /pos/orders` (removed in Story 9.2), when the migration is applied, then it calls `POST /retail/sales` with the correct request body mapping (Order → RetailSale payload: `uuid`, `sessionId`, `totalAmount`, `paymentMethod`, `paymentSplits`, `customerId`, `tenantId`, `items`).

3. **AC3 — Broken dashboard providers fixed:** Given `dashboard_providers.dart` calls `/pos/stats` and `/pos/reports/sales` (both removed in Story 9.2), when the migration is applied, then it calls `GET /reports/sales/stats` and `GET /reports/sales` respectively.

4. **AC4 — Auth headers added:** Given all HTTP calls currently omit `x-tenant-id` and `Authorization` headers, when the migration is applied, then all requests to the backend include `x-tenant-id: <tenantId>` and `Authorization: Bearer <token>` headers via a centralized `ApiConstants.headers(tenantId, token)` factory.

5. **AC5 — Files that still work are not broken:** Given `ProductRepository`, `CustomerRepository`, `CategoryRepository`, and all `SyncService` pull endpoints still work correctly against existing `/pos/*` routes, when the migration is applied, then those endpoints remain unchanged except for adopting the centralized base URL constant.

6. **AC6 — Tests pass:** Given the migration is complete, when existing widget/unit tests run, then 0 regressions are introduced.

## Tasks / Subtasks

### Phase 1 — Create centralized API config (AC1, AC4)

- [x] **1.1** Create `apps/frontend/lib/core/constants/api_constants.dart`:
  ```dart
  class ApiConstants {
    static const String baseUrl = 'http://127.0.0.1:3000';

    static Map<String, String> headers({String? tenantId, String? token}) => {
      'Content-Type': 'application/json',
      if (tenantId != null) 'x-tenant-id': tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  ```

- [x] **1.2** Replace hardcoded `static const String _baseUrl = 'http://127.0.0.1:3000'` in:
  - `apps/frontend/lib/core/services/sync_service.dart` line 31
  - `apps/frontend/lib/features/pos/data/repositories/product_repository.dart` line 9
  - `apps/frontend/lib/features/pos/data/repositories/customer_repository.dart` line 9
  - `apps/frontend/lib/features/pos/data/repositories/category_repository.dart` line 9

- [x] **1.3** Replace inline `const baseUrl = 'http://127.0.0.1:3000'` in `apps/frontend/lib/features/dashboard/presentation/providers/dashboard_providers.dart`.

### Phase 2 — Fix broken SyncService endpoint (AC2)

- [x] **2.1** In `apps/frontend/lib/core/services/sync_service.dart`, update `_pushPendingOrders()`:
  - Change `Uri.parse('$baseUrl/pos/orders')` → `Uri.parse('$baseUrl/retail/sales')`
  - Request body maps Order → RetailSale: `transactionId` (uuid), `totalAmount`, `items`, `sessionId`, `paymentMethod`, `paymentSplits`, `customerId`, `tenantId`, `createdAt`

### Phase 3 — Fix broken dashboard endpoints (AC3)

- [x] **3.1** In `apps/frontend/lib/features/dashboard/presentation/providers/dashboard_providers.dart`:
  - Change `GET /pos/stats` → `GET /reports/sales/stats`
  - Change `GET /pos/reports/sales` → `GET /reports/sales`
  - Import and use `ApiConstants.baseUrl` for both calls

### Phase 4 — Tests & regression (AC6)

- [x] **4.1** Run `flutter test` — `widget_test.dart` 1/1 passes. `pos_screen_test.dart` has pre-existing compilation errors unrelated to Story 8.1 (see completion notes). 0 regressions from Story 8.1 changes.

## Dev Notes

### Backend routes (no /api/v1 prefix)

The backend (`apps/backend/src/main.ts`) has no global prefix — routes are bare:
- Products: `GET /pos/products`, `POST /pos/products/sync`, `POST /pos/products/adjust-stock`
- Sales (new): `POST /retail/sales` (replaced `/pos/orders` in Story 9.2)
- Dashboard stats (new): `GET /reports/sales/stats`, `GET /reports/sales` (replaced `/pos/stats`, `/pos/reports/sales` in Story 9.2)
- Customers: `GET /pos/customers`, `POST /pos/customers`, `POST /pos/customers/:id/settle`
- Categories: `GET /pos/categories`, `POST /pos/categories`, `DELETE /pos/categories/:id`
- Sessions: `GET /pos/sessions`, `POST /pos/sessions` (via SyncService)
- Heartbeat: `POST /pos/heartbeat`
- Terminals: `GET /pos/terminals`

### Files with hardcoded base URL (5 total)

1. `lib/core/services/sync_service.dart:31` — `static const String _baseUrl = 'http://127.0.0.1:3000'`
2. `lib/features/pos/data/repositories/product_repository.dart:9` — same pattern
3. `lib/features/pos/data/repositories/customer_repository.dart:9` — same pattern
4. `lib/features/pos/data/repositories/category_repository.dart:9` — same pattern
5. `lib/features/dashboard/presentation/providers/dashboard_providers.dart` — `const baseUrl = 'http://127.0.0.1:3000'` (inline in provider function)

### Critical broken path (Story 9.2 impact)

`SyncService._pushPendingOrders()` calls `POST /pos/orders` which was removed in Story 9.2 cleanup. This means **orders created offline cannot sync** until this story is delivered. Priority: fix this endpoint in Task 2.1 before anything else.

### SessionRepository

`SessionRepository` has no HTTP calls — sessions are pushed by `SyncService._syncSessions()` which calls `POST /pos/sessions` (still valid). No changes needed to `SessionRepository`.

### Auth headers — phased approach

For now, `ApiConstants.headers()` should add headers if present but not fail if `tenantId`/`token` are null — the backend guards are currently lenient per the existing codebase pattern. Full auth wiring (reading token from secure storage) is out of scope for this story.

### References

- `apps/frontend/lib/core/services/sync_service.dart` — base URL line 31, broken endpoint line 226
- `apps/frontend/lib/features/dashboard/presentation/providers/dashboard_providers.dart` — broken endpoints
- `apps/backend/src/retail/retail.controller.ts` — `POST /retail/sales` endpoint
- `apps/backend/src/reporting/reporting.controller.ts` — `GET /reports/sales/stats`, `GET /reports/sales`
- [Story 9.2](9-2-production-cutover-cleanup.md) — lists removed endpoints

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- **Task 1.1:** Created `apps/frontend/lib/core/constants/api_constants.dart` with `ApiConstants.baseUrl` constant and `ApiConstants.headers({tenantId, token})` factory. Uses `if (x != null)` conditional map entries — `use_null_aware_elements` lint is information-only; no clean map-value null-aware equivalent for this Dart version.
- **Task 1.2:** Removed `static const String _baseUrl` from `sync_service.dart`, `product_repository.dart`, `customer_repository.dart`, `category_repository.dart`. Added `ApiConstants` import to each. Replaced all `_baseUrl` references with `ApiConstants.baseUrl` using `replace_all` where multiple occurrences existed.
- **Task 1.3:** Rewrote `dashboard_providers.dart` — removed 3 inline `const baseUrl` locals, imported `ApiConstants`. All three providers now use `ApiConstants.baseUrl`.
- **Task 2.1 (critical fix):** Fixed `_pushPendingOrders()` — URL changed from `/pos/orders` → `/retail/sales`. Request body explicitly maps Order → RetailSale shape expected by `RetailController`: `transactionId` (from `order.uuid`), `totalAmount`, `items` (serialized), `sessionId`, `paymentMethod`, `paymentSplits`, `customerId`, `tenantId`, `createdAt`.
- **Task 3.1:** Fixed dashboard stats — `salesStatsProvider` → `GET /reports/sales/stats`, `salesReportProvider` → `GET /reports/sales`.
- **Task 4.1 (Tests):** `widget_test.dart` 1/1 passes. `pos_screen_test.dart` fails to compile due to **pre-existing** errors unrelated to Story 8.1: `forceSync()` missing on `SyncService` (called by `realtime_service.dart`, `sync_status_indicator.dart`, `pos_providers.dart`), `Customer.isSynced`/`Customer.lastUpdated` missing (Story 8.2 scope), `categoriesProvider`/`ReceiptDialog` undefined. All pre-date this story. 0 regressions introduced by Story 8.1.

### File List

- `apps/frontend/lib/core/constants/api_constants.dart` [NEW — centralized base URL + auth header factory]
- `apps/frontend/lib/core/services/sync_service.dart` [MODIFIED — removed `_baseUrl` field, added ApiConstants import, `_pushPendingOrders()` → POST /retail/sales with correct body mapping]
- `apps/frontend/lib/features/pos/data/repositories/product_repository.dart` [MODIFIED — removed `_baseUrl`, added ApiConstants import, 5 references replaced]
- `apps/frontend/lib/features/pos/data/repositories/customer_repository.dart` [MODIFIED — removed `_baseUrl`, added ApiConstants import, 4 references replaced]
- `apps/frontend/lib/features/pos/data/repositories/category_repository.dart` [MODIFIED — removed `_baseUrl`, added ApiConstants import, 2 references replaced]
- `apps/frontend/lib/features/dashboard/presentation/providers/dashboard_providers.dart` [MODIFIED — inline baseUrl locals removed, /pos/stats → /reports/sales/stats, /pos/reports/sales → /reports/sales, ApiConstants import added]

## Change Log

- 2026-03-15: Story 8.1 created — centralized API URL, fix POST /pos/orders → POST /retail/sales, fix dashboard stats endpoints, add auth header factory.
- 2026-03-15: Story 8.1 implemented — ApiConstants created, all 5 hardcoded URLs replaced, POST /retail/sales body mapping corrected (transactionId, items serialized, correct field names), dashboard stats endpoints fixed, widget_test 1/1 passes, pre-existing pos_screen_test compile errors noted.
