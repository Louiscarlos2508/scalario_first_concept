# Story 5.4: Loss Declaration & Partial Inventory

Status: review

## Story

As a commercial or manager,
I want to declare stock losses with a mandatory reason and perform partial inventory counts,
so that all stock discrepancies are documented and shrinkage is traceable.

## Acceptance Criteria

1. **AC1 — LOSS movement (reason mandatory):** Given an authenticated Commercial or Manager user, when they call `POST /inventory/movements` with `type=LOSS`, `catalogItemId`, `quantity`, and `reason`, then a LOSS `InventoryMovement` is created, reducing stock. The `reason` field is mandatory and non-empty for LOSS type (validation enforced in service). An AuditLog entry is recorded.

2. **AC2 — POST /inventory/adjust (partial inventory count):** Given an authenticated Manager user, when they call `POST /inventory/adjust` with `catalogItemId` and `countedQuantity`, then the service calculates `variance = countedQuantity - currentStock`. If variance != 0, an ADJUSTMENT movement is created for the variance (positive or negative). If variance != 0 and no `reason` is provided, a 400 error is returned. If variance == 0, no movement is created and a `{ adjusted: false }` response is returned.

3. **AC3 — GET /inventory/stock?catalogItemId=<id>:** Given the inventory module processes movements, when `GET /inventory/stock?catalogItemId=<id>&tenantId=<uuid>` is called, then the current stock level is calculated by summing all movements: `DELIVERY + TRANSFER_IN + ADJUSTMENT(positive)` - `SALE + TRANSFER_OUT + LOSS + ADJUSTMENT(negative)`. Returns `{ catalogItemId, tenantId, currentStock, computedAt }`.

4. **AC4 — GET /inventory/movements?since=<ISO8601> (delta sync):** Given inventory movements exist, when `GET /inventory/movements?since=<ISO8601>&tenantId=<uuid>` is called, then only movements with `created_at > since` are returned. Response includes `meta.serverTime`, `meta.total`, `meta.hasMore`. This completes the delta-sync pattern from Story 5.2 with explicit validation.

5. **AC5 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 5.4 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — InventoryService: LOSS validation + adjust + stock level (AC1, AC2, AC3)

- [x] **1.1** Update `inventory.service.ts`:
  - Update `createMovement()`: if `type === 'LOSS'` and `!reason || reason.trim() === ''`, throw `BadRequestException('reason is required for LOSS movements')`
  - Add `adjustInventory(data: { catalogItemId, countedQuantity, reason?, tenantId, userId? })`:
    - Calls `getCurrentStock(catalogItemId, tenantId)` to get current stock
    - Calculates `variance = countedQuantity - currentStock`
    - If variance == 0: returns `{ adjusted: false, catalogItemId, tenantId }`
    - If variance != 0 and no reason: throws `BadRequestException('reason is required for non-zero adjustments')`
    - If variance != 0: calls `createMovement({ type: 'ADJUSTMENT', quantity: Math.abs(variance), reason, catalogItemId, tenantId, userId })` — store positive quantity; the sign is inferred from variance context (or store actual signed quantity in ADJUSTMENT — document the chosen convention)
  - Add `getCurrentStock(catalogItemId: string, tenantId: string)`:
    - Queries `prisma.inventoryMovement.findMany({ where: { catalogItemId, tenantId } })`
    - Sums: `DELIVERY + TRANSFER_IN` as +qty; `SALE + TRANSFER_OUT + LOSS` as -qty; `ADJUSTMENT` as signed (see note below)
    - Returns computed stock as number

- [x] **1.2** ADJUSTMENT sign convention decision:
  - **Option A:** Store absolute quantity, add separate `direction` field (not in current schema, requires migration)
  - **Option B:** Store signed quantity (negative for downward adjustment, positive for upward)
  - **Recommended:** Option B — store signed quantity in `quantity` field for ADJUSTMENT type only. Document this in Completion Notes.

### Phase 2 — InventoryController: /adjust + /stock endpoints (AC2, AC3, AC4)

- [x] **2.1** Update `inventory.controller.ts`:
  - `POST /inventory/adjust` — `@Roles('owner', 'manager')`
  - `GET /inventory/stock` — no role restriction (all authenticated); query params: `catalogItemId`, `tenantId`
  - Verify `GET /inventory/movements?since=` returns correct meta (serverTime, hasMore) — already in Story 5.2 `getMovements()`; add integration test here

### Phase 3 — Tests (AC1, AC2, AC3, AC4, AC5)

- [x] **3.1** Update `inventory.service.spec.ts`:
  - Test LOSS without reason: throws BadRequestException
  - Test LOSS with reason: movement created with reason
  - Test `adjustInventory` zero variance: returns `{ adjusted: false }`, no movement created
  - Test `adjustInventory` positive variance: ADJUSTMENT movement created
  - Test `adjustInventory` negative variance: ADJUSTMENT movement created
  - Test `adjustInventory` non-zero variance without reason: throws BadRequestException
  - Test `getCurrentStock`: sums correctly across all movement types
  - Test `getCurrentStock` with no movements: returns 0

- [x] **3.2** Update `inventory.controller.spec.ts`:
  - Test POST /inventory/adjust: passes countedQuantity + reason to service
  - Test GET /inventory/stock: passes catalogItemId + tenantId to service

- [x] **3.3** Run `npx jest --no-coverage` — all tests pass.

## Dev Notes

### Stock Level Calculation Logic

```typescript
async getCurrentStock(catalogItemId: string, tenantId: string): Promise<number> {
  const movements = await this.prisma.inventoryMovement.findMany({
    where: { catalogItemId, tenantId },
    select: { type: true, quantity: true },
  });

  let stock = 0;
  for (const m of movements) {
    const qty = Number(m.quantity);
    switch (m.type) {
      case 'DELIVERY':
      case 'TRANSFER_IN':
        stock += qty;
        break;
      case 'SALE':
      case 'TRANSFER_OUT':
      case 'LOSS':
        stock -= qty;
        break;
      case 'ADJUSTMENT':
        stock += qty; // signed — positive=increase, negative=decrease
        break;
    }
  }
  return stock;
}
```

For ADJUSTMENT: use **signed quantity** (Option B) so negative quantity means downward correction. No schema change needed since `DECIMAL(10,2)` accepts negative values.

### ADJUSTMENT signed quantity storage

When `adjustInventory` is called and variance != 0:
```typescript
await this.createMovement({
  type: 'ADJUSTMENT',
  quantity: variance, // positive = counted more; negative = counted less
  reason,
  catalogItemId,
  tenantId,
  userId,
}, userId);
```

Skip the `Math.abs()` for ADJUSTMENT — the sign carries the direction. All other types (SALE, LOSS, etc.) always store positive quantities.

### GET /inventory/stock response shape

```json
{
  "catalogItemId": "...",
  "tenantId": "...",
  "currentStock": 42.5,
  "computedAt": "2026-03-15T10:00:00.000Z"
}
```

### Import BadRequestException

```typescript
import { BadRequestException, Injectable } from '@nestjs/common';
```

### References

- [Story 5.1 — InventoryMovement schema](_bmad-output/implementation-artifacts/5-1-inventory-schema-stock-movement-types.md)
- [Story 5.2 — InventoryController + getMovements() with delta sync](_bmad-output/implementation-artifacts/5-2-supplier-delivery-reception.md)
- [Story 5.3 — Transfer chain pattern](_bmad-output/implementation-artifacts/5-3-stock-transfers-chain-of-custody.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- **ADJUSTMENT sign convention (Option B chosen):** ADJUSTMENT movements store signed quantity directly in `quantity` field (`DECIMAL(10,2)` accepts negative). Positive = inventory increase (counted more than expected), negative = inventory decrease. `getCurrentStock()` sums ADJUSTMENT as `stock += qty` (signed). No schema migration needed.
- `createMovement()` updated: throws `BadRequestException('reason is required for LOSS movements')` when `type === 'LOSS'` and reason is missing/blank (AC1).
- `getCurrentStock(catalogItemId, tenantId)` added: queries `shared.stock_movements`, sums DELIVERY + TRANSFER_IN as +qty; SALE + TRANSFER_OUT + LOSS as -qty; ADJUSTMENT as signed qty. Returns number (AC3).
- `adjustInventory(data)` added: calls `getCurrentStock`, computes `variance = countedQuantity - currentStock`. Zero variance → `{ adjusted: false }`. Non-zero + no reason → `BadRequestException`. Creates ADJUSTMENT movement with signed variance quantity (AC2).
- `InventoryController` updated: `POST /inventory/adjust` (`@Roles('owner', 'manager')`), `GET /inventory/stock` (all authenticated) returning `{ catalogItemId, tenantId, currentStock, computedAt }` (AC2, AC3). `GET /inventory/movements?since=` meta (serverTime, hasMore) verified via new spec test (AC4).
- 13 new tests added. 213/213 tests pass, 0 regressions (AC5).

### File List

- apps/backend/src/shared/inventory/inventory.service.ts [MODIFIED — LOSS validation, getCurrentStock, adjustInventory]
- apps/backend/src/shared/inventory/inventory.controller.ts [MODIFIED — POST /adjust + GET /stock endpoints]
- apps/backend/src/shared/inventory/inventory.service.spec.ts [MODIFIED — LOSS, getCurrentStock, adjustInventory tests]
- apps/backend/src/shared/inventory/inventory.controller.spec.ts [MODIFIED — adjust + stock endpoint tests]

## Change Log

- 2026-03-15: Story 5.4 implemented — LOSS reason validation, getCurrentStock (movement summation), adjustInventory (variance-based ADJUSTMENT), POST /inventory/adjust, GET /inventory/stock. Option B signed ADJUSTMENT convention. 213/213 tests pass.
