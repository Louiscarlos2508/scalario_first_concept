# Story 7.1: Daily Consolidation Reports

Status: review

## Story

As a store manager,
I want to generate a daily consolidation report covering sales, losses, variances, and transfers,
So that I can review the day's operations and send a summary to the owner.

## Acceptance Criteria

1. **AC1 — GET /api/v1/reports/sales:** Given an authenticated Manager user, when they call `GET /api/v1/reports/sales?from=<date>&to=<date>&groupBy=day`, then the report returns: total revenue, sale count, breakdown by payment method, total losses declared, total transfer variances, for the requested date range.

2. **AC2 — GET /api/v1/reports/sessions:** Given an authenticated Manager user, when they call `GET /api/v1/reports/sessions?from=<date>&to=<date>`, then the report returns: all sessions with their closure summaries, cash variances per commercial, and variance explanations.

3. **AC3 — GET /api/v1/reports/inventory:** Given an authenticated Manager user, when they call `GET /api/v1/reports/inventory?from=<date>&to=<date>`, then the report returns: deliveries received, transfers completed with variances, losses declared with motifs, adjustments from partial counts.

4. **AC4 — ReportingModule scaffold:** Given the ReportingModule is implemented, when it is registered in AppModule, then it is a read-only module that queries across shared and retail schemas, imports KernelModule (global), CatalogModule, TransactionsModule, and InventoryModule — and is decorated with `@RequiresModule` if the tenant has reporting enabled (or defaults open to Manager/Owner).

5. **AC5 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 7.1 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — ReportingModule scaffold (AC4)

- [x] **1.1** Create `apps/backend/src/reporting/reporting.module.ts` with DynamicModule pattern.

- [x] **1.2** Register `ReportingModule.register()` in `apps/backend/src/app.module.ts` imports array.

### Phase 2 — ReportingService: sales + sessions + inventory aggregation (AC1, AC2, AC3)

- [x] **2.1** Create `apps/backend/src/reporting/reporting.service.ts` with `getSalesReport()`, `getSessionReport()`, `getInventoryReport()`.

- [x] **2.2** Create `apps/backend/src/reporting/reporting.controller.ts`:
  - `@Controller('reports')` + `@Roles('owner', 'manager')`
  - `GET /reports/sales` → `getSalesReport()`
  - `GET /reports/sessions` → `getSessionReport()`
  - `GET /reports/inventory` → `getInventoryReport()`

### Phase 3 — Tests (AC1, AC2, AC3, AC4, AC5)

- [x] **3.1** Create `apps/backend/src/reporting/reporting.service.spec.ts` — 4 service tests.

- [x] **3.2** Create `apps/backend/src/reporting/reporting.controller.spec.ts` — 3 controller tests.

- [x] **3.3** Run `npx jest --no-coverage` — 256/256 tests pass, 0 regressions (AC5).

## Dev Notes

### Architecture: read-only queries across schemas

`ReportingService` does NOT mutate data. It only reads from `shared.transactions`, `public.pos_sessions`, `shared.stock_movements`. No events emitted, no audit logs.

### Transfer variance calculation

Combined query: `inventoryMovement.findMany({ where: { type: { in: ['LOSS', 'TRANSFER_IN', 'TRANSFER_OUT'] } } })`. Group in memory. `totalTransferVariances` = count of TRANSFER movements (MVP: frontend computes actual variance from the returned data).

### PosSession query for sessions report

`prisma.posSession` is in `public` schema (not retail). Date filter is on `closedAt`, not `createdAt`. Use `buildDateRange()` helper and assign to `where.closedAt`.

### Date range handling

`buildDateRange(from?, to?)` returns `undefined` when both absent (Prisma ignores undefined query params), or `{ gte, lte }` object when provided.

### References

- [Story 4.2 — Transaction model](4-2-transaction-api-local-first-recording.md)
- [Story 5.2 — Inventory movements (DELIVERY, TRANSFER)](5-2-supplier-delivery-reception.md)
- [Story 6.3 — PosSession (variance fields)](6-3-cash-session-management.md)
- [Story 6.4 — RetailModule pattern (DynamicModule)](6-4-retail-module-registration-pos-orchestration.md)
- [epics.md — Epic 7 AC](../../planning-artifacts/epics.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- **ReportingModule.register():** DynamicModule importing TransactionsModule, InventoryModule, CatalogModule. Declares ReportingController (controller), ReportingService (provider + export). Registered in AppModule (AC4).
- **ReportingService.getSalesReport():** Single combined `inventoryMovement.findMany` (type IN LOSS/TRANSFER_IN/TRANSFER_OUT) + `transaction.findMany`. Returns totalRevenue, saleCount, breakdownByPaymentMethod, totalLosses, totalTransferVariances (AC1).
- **ReportingService.getSessionReport():** Queries CLOSED pos_sessions with optional closedAt date filter. Returns sessions + totalVariance (AC2).
- **ReportingService.getInventoryReport():** Single query, groups by type into deliveries/transfersIn/transfersOut/losses/adjustments (AC3).
- **ReportingController:** `@Controller('reports')` + `@Roles('owner', 'manager')`. 3 GET endpoints (AC1, AC2, AC3).
- **buildDateRange helper:** Returns undefined (no filter) or `{ gte, lte }` object. `getSessionReport` uses it on `closedAt` field.
- **7 new tests:** 4 service + 3 controller. 256/256 pass, 0 regressions (AC5).

### File List

- apps/backend/src/reporting/reporting.module.ts [NEW]
- apps/backend/src/reporting/reporting.service.ts [NEW]
- apps/backend/src/reporting/reporting.controller.ts [NEW]
- apps/backend/src/reporting/reporting.service.spec.ts [NEW]
- apps/backend/src/reporting/reporting.controller.spec.ts [NEW]
- apps/backend/src/app.module.ts [MODIFIED — ReportingModule.register() added]

## Change Log

- 2026-03-15: Story 7.1 created — ReportingModule scaffold, ReportingService (sales/sessions/inventory reports), ReportingController.
- 2026-03-15: Story 7.1 implemented — ReportingModule, ReportingService (3 report methods + buildDateRange), ReportingController (3 endpoints, Manager/Owner only), 256/256 tests pass.
