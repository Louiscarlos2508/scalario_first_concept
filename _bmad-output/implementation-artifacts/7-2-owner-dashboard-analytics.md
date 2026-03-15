# Story 7.2: Owner Dashboard & Analytics

Status: review

## Story

As a shop owner,
I want to view a dashboard with revenue, sale count, losses, cash variances, and critical stock levels,
So that I can monitor my business remotely without being physically present.

## Acceptance Criteria

1. **AC1 — GET /api/v1/reports/sales/stats:** Given an authenticated Owner user, when they call `GET /api/v1/reports/sales/stats?from=<date>&to=<date>`, then the response includes: total revenue, total sale count, average transaction value, top 3 products by sales volume, total losses, and total cash variances.

2. **AC2 — GET /api/v1/reports/inventory (critical stock):** Given an authenticated Owner user, when they call `GET /api/v1/reports/inventory` with no date filter, then the response includes current stock levels for all products with items below `min_stock_level` flagged as critical.

3. **AC3 — Role enforcement:** Given a Commercial user attempts to access any reporting endpoint, when the RolesGuard evaluates the request, then access is denied — reporting is limited to Manager and Owner roles.

4. **AC4 — Backward compat: old POS stats/reports proxy to ReportingService:** Given the old stats/reports methods in PosService (`GET /pos/stats`, `GET /pos/reports/sales`, `GET /pos/stock-movements`), when the reporting module is deployed, then old report endpoints proxy to the new ReportingService with identical response shapes.

5. **AC5 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 7.2 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — Extend ReportingService with dashboard methods (AC1, AC2)

- [x] **1.1** Add `getSalesStats(params: { tenantId: string; from?: string; to?: string })` to `ReportingService`:
  - Total revenue (sum totalAmount from transactions)
  - Total sale count
  - Average transaction value
  - Top 3 products by sales volume (parse `itemsJson` array from transactions, aggregate by productId/name)
  - Total losses (sum from LOSS inventory movements)
  - Total cash variances (sum of `variance` from CLOSED pos_sessions in date range)
  - Return: `{ totalRevenue, saleCount, avgTransactionValue, top3Products, totalLosses, totalCashVariance, from, to }`

- [x] **1.2** Add `getCriticalStock(tenantId: string)` to `ReportingService`:
  - Query `prisma.retailProduct.findMany({ where: { ... }, include: { catalogItem: true } })`
  - Filter: items where `stockQuantity <= minStockLevel` (critical) vs items with stock > minStockLevel
  - Return: `{ criticalItems: [...], allItems: [...] }` where each item includes name, barcode, stockQuantity, minStockLevel

### Phase 2 — Extend ReportingController (AC1, AC2, AC3)

- [x] **2.1** Add to `ReportingController`:
  - `GET /reports/sales/stats` — `@Roles('owner', 'manager')` → `getSalesStats()`
  - Extend existing `GET /reports/inventory` to handle no-date case → `getCriticalStock()`

  Note: `@Roles('owner', 'manager')` is already on the controller class from Story 7.1, so Commercial users are automatically denied (AC3).

### Phase 3 — Backward compat proxying from PosController (AC4)

- [x] **3.1** Update `apps/backend/src/pos/pos.controller.ts`:
  - `GET /pos/stats` → proxy to `ReportingService.getSalesStats()`
  - `GET /pos/reports/sales` → proxy to `ReportingService.getSalesReport()`
  - `GET /pos/stock-movements` → proxy to `ReportingService.getInventoryReport()`
  - Add `ReportingService` to `PosModule` providers and inject in `PosController`

### Phase 4 — Tests (AC1, AC2, AC3, AC4, AC5)

- [x] **4.1** Extend `apps/backend/src/reporting/reporting.service.spec.ts`:
  - Test `getSalesStats`: correct revenue/count/avg; top 3 products parsed from itemsJson; losses + variance sums
  - Test `getCriticalStock`: items below min_stock_level flagged as critical; items above not flagged

- [x] **4.2** Extend `apps/backend/src/reporting/reporting.controller.spec.ts`:
  - `GET /reports/sales/stats` delegates to getSalesStats
  - `GET /reports/inventory` (no date) delegates to getCriticalStock

- [x] **4.3** Run `npx jest --no-coverage` — all tests pass.

## Dev Notes

### Top 3 products from itemsJson

`Transaction.itemsJson` is a JSON array of `{ productId?, name, quantity, price }`. To aggregate:
```typescript
const productVolume: Record<string, { name: string; quantity: number }> = {};
for (const tx of transactions) {
  const items = tx.itemsJson as any[];
  if (Array.isArray(items)) {
    for (const item of items) {
      const key = item.productId || item.name || 'UNKNOWN';
      if (!productVolume[key]) productVolume[key] = { name: item.name, quantity: 0 };
      productVolume[key].quantity += Number(item.quantity);
    }
  }
}
const top3 = Object.entries(productVolume)
  .sort((a, b) => b[1].quantity - a[1].quantity)
  .slice(0, 3)
  .map(([id, v]) => ({ id, name: v.name, quantity: v.quantity }));
```

### Critical stock query

`RetailProduct` is in `retail` schema. `CatalogItem` is in `shared` schema. Cross-schema relation works via Prisma include:
```typescript
const products = await this.prisma.retailProduct.findMany({
  where: { catalogItem: { tenantId } },
  include: { catalogItem: true },
});
const criticalItems = products.filter(
  p => p.minStockLevel !== null && p.stockQuantity.lte(p.minStockLevel)
);
```
Note: `stockQuantity` and `minStockLevel` are `Decimal` — use `.lte()` for comparison.

### Role enforcement is inherited from Story 7.1

`ReportingController` is decorated with `@Roles('owner', 'manager')` at the class level. No Commercial user can reach any `/reports/*` endpoint. This satisfies AC3 without additional changes.

### POS backward compat proxy

`PosService.getSalesStats()` uses raw SQL (`prisma.$queryRaw`). For backward compat, the simplest approach is to keep `PosService.getSalesStats()` as-is and proxy from `PosController.getStats()` to `ReportingService.getSalesStats()`. Since the response shape may differ slightly, map the response in the controller if needed.

### References

- [Story 7.1 — ReportingModule + ReportingService base](7-1-daily-consolidation-reports.md)
- [Story 6.1 — RetailProduct model (stockQuantity, minStockLevel)](6-1-retail-schema-product-extensions.md)
- [Story 4.2 — Transaction itemsJson](4-2-transaction-api-local-first-recording.md)
- [epics.md — Epic 7 AC](../../planning-artifacts/epics.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- `getSalesStats` runs 3 parallel queries (transactions, LOSS movements, CLOSED sessions) and aggregates KPIs including top 3 products parsed from `itemsJson`.
- `getCriticalStock` uses cross-schema Prisma relation (`retailProduct` → `catalogItem`) and Decimal `.lte()` for comparison.
- `GET /reports/inventory` dual behavior: no date params → `getCriticalStock()`; with date params → `getInventoryReport()`.
- `ReportingService` added to `PosModule` providers (it depends only on the globally scoped `PrismaService`).
- `PosController` proxies `GET /pos/stats`, `GET /pos/stock-movements`, `GET /pos/reports/sales` to `ReportingService` for backward compat.
- All 263 tests pass, 0 regressions.

### File List

- `apps/backend/src/reporting/reporting.service.ts` — extended with `getSalesStats()` and `getCriticalStock()`
- `apps/backend/src/reporting/reporting.controller.ts` — extended with `GET /reports/sales/stats` and dual-behavior `GET /reports/inventory`
- `apps/backend/src/pos/pos.module.ts` — added `ReportingService` to providers
- `apps/backend/src/pos/pos.controller.ts` — injected `ReportingService`, proxied `/pos/stats`, `/pos/stock-movements`, `/pos/reports/sales`
- `apps/backend/src/reporting/reporting.service.spec.ts` — added `retailProduct.findMany` mock + 5 new tests (getSalesStats ×3, getCriticalStock ×2)
- `apps/backend/src/reporting/reporting.controller.spec.ts` — added `getSalesStats`/`getCriticalStock` to mock + 3 new test cases

## Change Log

- 2026-03-15: Story 7.2 created — getSalesStats (dashboard KPIs), getCriticalStock, role enforcement (Manager/Owner only), POS backward compat proxying.
