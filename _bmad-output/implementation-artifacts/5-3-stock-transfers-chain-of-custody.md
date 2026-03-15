# Story 5.3: Stock Transfers & Chain-of-Custody

Status: review

## Story

As a store manager and commercial,
I want to create stock transfers with double-validation (sender declares, receiver confirms),
so that transfer variances are automatically tracked and attributed to the correct link in the chain.

## Acceptance Criteria

1. **AC1 — TRANSFER_OUT creates movement with reference_id:** Given an authenticated Manager user, when they call `POST /inventory/movements` with `type=TRANSFER_OUT`, `catalogItemId`, `quantity`, and optional `destinationInfo`, then a TRANSFER_OUT `InventoryMovement` is created with a self-generated `referenceId` (UUID). A `transfer.created` event is emitted with `{ referenceId, tenantId, status: 'pending' }`.

2. **AC2 — TRANSFER_IN confirmation links to TRANSFER_OUT via reference_id:** Given a pending TRANSFER_OUT exists with a known `referenceId`, when an authenticated Commercial calls `POST /inventory/movements` with `type=TRANSFER_IN`, the same `referenceId`, and their received `quantity`, then a TRANSFER_IN movement is created linked via `referenceId`. The TRANSFER_IN movement stores the received quantity (may differ from sent quantity).

3. **AC3 — Variance calculation:** Given a TRANSFER_OUT of quantity 8 and a TRANSFER_IN of quantity 7 (same referenceId), when the TRANSFER_IN is confirmed, then the service calculates variance = sent - received = 1. The variance is stored in the TRANSFER_IN movement's `reason` field (e.g., "Variance: 1 kg") and a `transfer.confirmed` event is emitted with `{ referenceId, sent, received, variance, tenantId }`.

4. **AC4 — GET /inventory/movements returns transfer history:** Given transfer movements exist, when `GET /inventory/movements?referenceId=<uuid>` is called, then the TRANSFER_OUT and TRANSFER_IN pair is returned, showing: type, quantity, referenceId, createdAt, and reason (variance).

5. **AC5 — @Roles restriction:** Given the InventoryController, when `POST /inventory/movements` with `type=TRANSFER_OUT` is called by a Commercial (not Manager), then access is denied by the `@Roles` guard. TRANSFER_IN confirmation is available to both Commercial and Manager.

6. **AC6 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 5.3 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — InventoryService transfer logic (AC1, AC2, AC3)

- [x] **1.1** Update `inventory.service.ts`:
  - `createTransferOut(data: { catalogItemId, quantity, reason?, tenantId, userId? })`:
    - Generates a new UUID as `referenceId`
    - Creates TRANSFER_OUT movement with that referenceId
    - Emits `transfer.created` event: `{ referenceId, tenantId, status: 'pending' }`
    - Returns movement
  - `confirmTransferIn(data: { referenceId, catalogItemId, quantity, tenantId, userId? })`:
    - Finds the matching TRANSFER_OUT movement (by referenceId)
    - Calculates variance = TRANSFER_OUT.quantity - receivedQuantity
    - Creates TRANSFER_IN movement with same referenceId, receivedQuantity, reason="Variance: X" if variance != 0
    - Emits `transfer.confirmed` event: `{ referenceId, sent: outQty, received: inQty, variance, tenantId }`
    - Returns TRANSFER_IN movement
  - Update `createMovement()` to handle `referenceId` in data

- [x] **1.2** Update `getMovements()` to support `referenceId` filter: `where.referenceId = referenceId` when provided.

### Phase 2 — InventoryController transfer endpoints (AC2, AC5)

- [x] **2.1** Update `inventory.controller.ts`:
  - `POST /inventory/movements` with `type=TRANSFER_OUT`: guarded by `@Roles('owner', 'manager')`
  - `POST /inventory/movements/confirm` (or `POST /inventory/movements` with `type=TRANSFER_IN`): available to `@Roles('owner', 'manager', 'commercial')` — use single endpoint with conditional role check, OR separate `POST /inventory/movements/confirm` endpoint

  **Recommended approach — single endpoint with type-based role logic:**
  In the controller, detect `body.type` and apply correct role. Use `@Roles('owner', 'manager', 'commercial')` on POST, and let the service validate business rules (TRANSFER_OUT requires Manager+).

  **Or separate endpoints approach:**
  - `POST /inventory/movements` — `@Roles('owner', 'manager')` for DELIVERY, TRANSFER_OUT, LOSS, ADJUSTMENT
  - `POST /inventory/movements/confirm` — `@Roles('owner', 'manager', 'commercial')` for TRANSFER_IN only

  Choose the cleaner approach and document the decision.

### Phase 3 — Tests (AC1, AC2, AC3, AC6)

- [x] **3.1** Update `inventory.service.spec.ts`:
  - Test `createTransferOut`: creates TRANSFER_OUT with referenceId, emits `transfer.created`
  - Test `confirmTransferIn`: finds TRANSFER_OUT, creates TRANSFER_IN, calculates variance, emits `transfer.confirmed`
  - Test zero variance: reason not set when sent == received
  - Test missing TRANSFER_OUT: throws error or returns gracefully

- [x] **3.2** Update `inventory.controller.spec.ts` with transfer endpoint tests.

- [x] **3.3** Run `npx jest --no-coverage` — all tests pass.

## Dev Notes

### referenceId Pattern

`referenceId` is already in the `InventoryMovement` schema (created in Story 5.1). No migration needed for Story 5.3.

```typescript
async createTransferOut(data: any, userId: string | null) {
  const referenceId = require('crypto').randomUUID();
  const movement = await this.prisma.inventoryMovement.create({
    data: {
      catalogItemId: data.catalogItemId,
      quantity: data.quantity,
      type: 'TRANSFER_OUT',
      reason: data.reason ?? null,
      tenantId: data.tenantId,
      userId,
      referenceId,
    },
  });
  this.eventBus.publish('transfer.created', { referenceId, tenantId: data.tenantId, status: 'pending' });
  return movement;
}

async confirmTransferIn(data: any, userId: string | null) {
  const outMovement = await this.prisma.inventoryMovement.findFirst({
    where: { referenceId: data.referenceId, type: 'TRANSFER_OUT' },
  });
  if (!outMovement) throw new Error(`No TRANSFER_OUT found for referenceId: ${data.referenceId}`);

  const variance = Number(outMovement.quantity) - Number(data.quantity);
  const reason = variance !== 0 ? `Variance: ${variance}` : null;

  const inMovement = await this.prisma.inventoryMovement.create({
    data: {
      catalogItemId: data.catalogItemId ?? outMovement.catalogItemId,
      quantity: data.quantity,
      type: 'TRANSFER_IN',
      reason,
      tenantId: data.tenantId,
      userId,
      referenceId: data.referenceId,
    },
  });

  this.eventBus.publish('transfer.confirmed', {
    referenceId: data.referenceId,
    sent: Number(outMovement.quantity),
    received: Number(data.quantity),
    variance,
    tenantId: data.tenantId,
  });

  return inMovement;
}
```

### Role Design Decision

Since all movement types share `POST /inventory/movements`, and TRANSFER_OUT requires Manager+ while TRANSFER_IN (confirm) also allows Commercial, consider using a dedicated `POST /inventory/movements/confirm` endpoint for TRANSFER_IN confirmations to keep role guards clean. Document the chosen approach in the story Completion Notes.

### References

- [Story 5.1 — InventoryMovement schema with referenceId](_bmad-output/implementation-artifacts/5-1-inventory-schema-stock-movement-types.md)
- [Story 5.2 — InventoryService.createMovement() + InventoryController pattern](_bmad-output/implementation-artifacts/5-2-supplier-delivery-reception.md)
- [EventBusService.publish() — confirmed pattern](apps/backend/src/kernel/events/event-bus.service.ts)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- **Endpoint design decision:** Separate endpoints approach chosen — `POST /inventory/movements` (`@Roles('owner', 'manager')`) for DELIVERY/TRANSFER_OUT/LOSS/ADJUSTMENT; `POST /inventory/movements/confirm` (`@Roles('owner', 'manager', 'commercial')`) for TRANSFER_IN. Keeps `@Roles` guards declarative without runtime type-checking in the controller.
- `createTransferOut()`: generates UUID via `crypto.randomUUID()` as `referenceId`, creates TRANSFER_OUT movement, logs AuditLog, emits `transfer.created` event with `{ referenceId, tenantId, status: 'pending' }` (AC1).
- `confirmTransferIn()`: finds TRANSFER_OUT by `referenceId` (throws if not found), calculates `variance = sent - received`, stores `reason="Variance: X"` if non-zero (null if zero), creates TRANSFER_IN movement, logs AuditLog, emits `transfer.confirmed` event with `{ referenceId, sent, received, variance, tenantId }` (AC2, AC3).
- `getMovements()` updated: supports `referenceId` filter (`where.referenceId = referenceId`) enabling transfer history lookup (AC4).
- `InventoryController` updated: `POST /inventory/movements` routes `TRANSFER_OUT` to `createTransferOut()`, all other types to `createMovement()`; `GET /inventory/movements` exposes `referenceId` query param (AC4, AC5).
- No migration needed — `referenceId` column already exists in `shared.stock_movements` from Story 5.1.
- 13 new tests added. 200/200 tests pass, 0 regressions (AC6).

### File List

- apps/backend/src/shared/inventory/inventory.service.ts [MODIFIED — createTransferOut + confirmTransferIn + getMovements referenceId filter]
- apps/backend/src/shared/inventory/inventory.controller.ts [MODIFIED — TRANSFER_OUT routing + /movements/confirm endpoint + referenceId query param]
- apps/backend/src/shared/inventory/inventory.service.spec.ts [MODIFIED — createTransferOut + confirmTransferIn tests]
- apps/backend/src/shared/inventory/inventory.controller.spec.ts [MODIFIED — transfer endpoint tests]

## Change Log

- 2026-03-15: Story 5.3 implemented — createTransferOut (referenceId, transfer.created event), confirmTransferIn (variance calc, transfer.confirmed event), getMovements referenceId filter, /movements/confirm endpoint. 200/200 tests pass.
