# Story 5.2: Supplier Delivery Reception

Status: review

## Story

As a store manager,
I want to receive supplier deliveries and record received quantities against expected quantities,
so that delivery variances are tracked and attributed automatically.

## Acceptance Criteria

1. **AC1 — POST /inventory/movements (DELIVERY):** Given an authenticated Manager or Owner user, when they call `POST /inventory/movements` with `type=DELIVERY`, `catalogItemId`, and received `quantity`, then a DELIVERY `InventoryMovement` is created, and an AuditLog entry is recorded (`action='CREATE'`, `entity='InventoryMovement'`).

2. **AC2 — Variance note in reason field:** Given a delivery with an expected quantity discrepancy (e.g., expected 20, received 18), when the manager records reception with an optional `reason` (e.g., "2 cartons not delivered"), then the movement records the actual received quantity with `reason` set to the note.

3. **AC3 — StockAdjusted event:** Given a DELIVERY movement is created, when `InventoryService.createMovement()` runs, then a `stock.adjusted` event is emitted via `EventBusService.publish('stock.adjusted', { movementId, catalogItemId, type, tenantId })`.

4. **AC4 — Drop public.stock_movements (migration):** Given all movement data was migrated to `shared.stock_movements` in Story 5.1, when the Story 5.2 migration runs, then `public.stock_movements` is dropped. The `StockMovement` model is removed from `schema.prisma`. The `products StockMovement[]` and `Tenant.stockMovements StockMovement[]` relations are cleaned up.

5. **AC5 — Proxy /pos/stock-movements to InventoryService:** Given old `/pos/stock-movements` endpoints exist in PosService, when Story 5.2 is applied, then `PosService.getStockMovements()` delegates to `InventoryService.getMovements()`. `PosService.adjustStock()` delegates to `InventoryService.createMovement()`. Response shapes are preserved.

6. **AC6 — InventoryController: POST + GET /inventory/movements:** Given the InventoryController is implemented, when `GET /inventory/movements` is called, then movements are returned with optional `tenantId` and `since` filters (delta sync).

7. **AC7 — @RequiresModule('inventory') gate:** Given the InventoryController has `@RequiresModule('inventory')`, when a tenant without the inventory module calls any inventory endpoint, then ModuleGuard returns 403.

8. **AC8 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 5.2 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — Migration: drop public.stock_movements (AC4)

- [x] **1.1** Create `apps/backend/prisma/migrations/20260315110000_drop_public_stock_movements/migration.sql`:
  ```sql
  -- Drop public.stock_movements after migration to shared.stock_movements (Story 5.1)
  ALTER TABLE "public"."stock_movements" DROP CONSTRAINT IF EXISTS "stock_movements_product_id_fkey";
  ALTER TABLE "public"."stock_movements" DROP CONSTRAINT IF EXISTS "stock_movements_tenant_id_fkey";
  DROP TABLE "public"."stock_movements" CASCADE;
  ```

- [x] **1.2** Update `schema.prisma`:
  - Remove `StockMovement` model from public schema
  - Remove `stockMovements StockMovement[]` from `Product` model
  - Remove `stockMovements StockMovement[]` from `Tenant` model
  - Run `npx prisma generate`

### Phase 2 — InventoryService enhancements (AC1, AC2, AC3)

- [x] **2.1** Update `inventory.service.ts`:
  - Inject `AuditLogService` and `EventBusService`
  - Update `createMovement()`: after persist, emit `stock.adjusted` event and log AuditLog entry
  - Add `getMovements(params: { tenantId?, since?, page?, limit? })`: delta-sync query with `since → createdAt: { gt }`, returns `{ items, meta }`

### Phase 3 — InventoryController (AC6, AC7)

- [x] **3.1** Create `apps/backend/src/shared/inventory/inventory.controller.ts`:
  - `@Controller('inventory')` + `@RequiresModule('inventory')`
  - `POST /inventory/movements` — `@Roles('owner', 'manager')`; extracts userId from `req.user?.sub`
  - `GET /inventory/movements` — no role restriction (all authenticated)

- [x] **3.2** Add `controllers: [InventoryController]` to `InventoryModule.register()` in `inventory.module.ts`.

### Phase 4 — PosService proxy (AC5)

- [x] **4.1** Inject `InventoryService` into `PosService` (PosModule imports InventoryModule).

- [x] **4.2** Update `pos.service.ts`:
  - `adjustStock()` → delegates to `inventoryService.createMovement()` (map productId to catalogItemId, quantity/type/reason fields)
  - `getStockMovements()` → delegates to `inventoryService.getMovements()`

- [x] **4.3** Add `InventoryModule.register()` to `PosModule` imports.

### Phase 5 — Tests (AC1, AC3, AC6, AC8)

- [x] **5.1** Update `inventory.service.spec.ts`:
  - Add mocks for AuditLogService and EventBusService
  - Test `createMovement`: emits `stock.adjusted` event + logs AuditLog
  - Test `getMovements`: without since returns all; with since filters by createdAt

- [x] **5.2** Create `inventory.controller.spec.ts`:
  - Mock InventoryService
  - Test POST: extracts userId from req.user.sub
  - Test GET: passes parsed params

- [x] **5.3** Run `npx jest --no-coverage` — all tests pass.

## Dev Notes

### StockMovement Model Removal Cascade

`StockMovement` in `schema.prisma` (public schema) has relations to:
- `Product` model: `stockMovements StockMovement[]`
- `Tenant` model: `stockMovements StockMovement[]`

Remove both after dropping public.stock_movements. Confirm with `npx prisma generate`.

### PosService.adjustStock() → InventoryService mapping

```typescript
async adjustStock(productId: string, quantity: number, type: string, reason: string) {
  return this.inventoryService.createMovement({
    catalogItemId: productId, // best-effort: productId used as catalogItemId
    quantity: Math.abs(quantity),
    type: type as any,
    reason,
    tenantId: /* resolve from product or use first tenant */,
  }, null);
}
```

Note: The old `adjustStock()` used `prisma.$transaction` to update `product.stockQuantity`. This is now removed — stock level is derived from summing movements (Story 5.4 GET /inventory/stock). Update any callers that expected a Product back.

### Established Patterns

- `@RequiresModule` + `@Roles` from kernel decorators
- DynamicModule with controllers added in this story
- `EventBusService.publish()` (not `.emit()`)
- `jest.clearAllMocks()` in `afterEach`

### References

- [Story 5.1 — InventoryMovement model + InventoryModule](_bmad-output/implementation-artifacts/5-1-inventory-schema-stock-movement-types.md)
- [Story 4.2 — TransactionsController pattern](_bmad-output/implementation-artifacts/4-2-transaction-api-local-first-recording.md)
- [PosService — adjustStock() + getStockMovements() to proxy](apps/backend/src/pos/pos.service.ts)
- [schema.prisma — StockMovement model to remove](apps/backend/prisma/schema.prisma)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- Migration `20260315110000_drop_public_stock_movements/migration.sql`: drops public.stock_movements CASCADE (AC4). `StockMovement` model removed from schema.prisma along with `Tenant.stockMovements` and `Product.stockMovements` relations. `npx prisma generate` confirmed valid.
- `InventoryService` updated: injects `AuditLogService` and `EventBusService`. `createMovement()` now emits `stock.adjusted` event via `EventBusService.publish()` and logs AuditLog entry after persist (AC1, AC3). `getMovements()` added with delta-sync support (`since → createdAt: { gt }`), returns `{ items, meta }` (AC6).
- `InventoryController` created: `@Controller('inventory')`, `@RequiresModule('inventory')`. POST `/inventory/movements` with `@Roles('owner', 'manager')` — extracts userId from `req.user?.sub`. GET `/inventory/movements` — all authenticated (AC6, AC7).
- `InventoryModule.register()` updated: adds `controllers: [InventoryController]`.
- `PosService.adjustStock()` delegates to `inventoryService.createMovement()` — looks up product for tenantId, maps productId→catalogItemId, uses `Math.abs(quantity)` (AC5). `PosService.getStockMovements()` delegates to `inventoryService.getMovements()` (AC5).
- `PosModule` updated: imports `InventoryModule.register()` (AC5).
- 9 new tests (4 additional createMovement + 2 getMovements + controller spec). 187/187 tests pass, 0 regressions (AC8).

### File List

- apps/backend/prisma/migrations/20260315110000_drop_public_stock_movements/migration.sql [NEW]
- apps/backend/prisma/schema.prisma [MODIFIED — StockMovement model removed, relations cleaned up]
- apps/backend/src/shared/inventory/inventory.service.ts [MODIFIED — AuditLog + EventBus injected, createMovement updated, getMovements added]
- apps/backend/src/shared/inventory/inventory.controller.ts [NEW]
- apps/backend/src/shared/inventory/inventory.module.ts [MODIFIED — InventoryController added]
- apps/backend/src/shared/inventory/inventory.service.spec.ts [MODIFIED — AuditLog/EventBus mocks, new tests]
- apps/backend/src/shared/inventory/inventory.controller.spec.ts [NEW]
- apps/backend/src/pos/pos.service.ts [MODIFIED — adjustStock + getStockMovements delegate to InventoryService]
- apps/backend/src/pos/pos.module.ts [MODIFIED — InventoryModule.register() added]

## Change Log

- 2026-03-15: Story 5.2 implemented — drop public.stock_movements migration, InventoryService enhanced (AuditLog + EventBus + getMovements), InventoryController created, PosService proxied to InventoryService. 187/187 tests pass.
