# Story 6.4: Retail Module Registration & POS Orchestration

Status: review

## Story

As a developer,
I want the RetailModule to wrap shared modules into a cohesive POS vertical,
so that activating the retail vertical for a tenant gives them the complete POS experience.

## Acceptance Criteria

1. **AC1 — RetailModule.register() in AppModule:** Given the RetailModule is implemented, when it is registered in AppModule via `RetailModule.register()`, then it imports CatalogModule, TransactionsModule, InventoryModule, PaymentsModule, ContactsModule, and declares dependency on all of them in the Module registry.

2. **AC2 — POS orchestration service (atomic sale):** Given a retail tenant's Commercial creates a sale, when the POS orchestration service processes it, then it coordinates: Transaction creation (shared) → RetailSale extension (retail) → Stock decrement (shared, via event) → Customer balance update if credit (shared) — all in a single atomic operation.

3. **AC3 — @RequiresModule('retail') on retail endpoints:** Given the retail vertical endpoints (`/api/v1/retail/*`), when decorated with `@RequiresModule('retail')`, then only tenants with the retail module activated can access them.

4. **AC4 — Backward compatibility: old POS endpoints proxy to retail services:** Given all old POS endpoints, when the retail module is deployed, then old endpoints proxy to the new retail services with identical behavior for backward compatibility.

5. **AC5 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 6.4 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — RetailModule scaffold (AC1, AC3)

- [x] **1.1** Create `apps/backend/src/retail/retail.module.ts` with DynamicModule pattern:
  ```typescript
  import { DynamicModule, Module } from '@nestjs/common';
  import { CatalogModule } from '../shared/catalog/catalog.module';
  import { TransactionsModule } from '../shared/transactions/transactions.module';
  import { InventoryModule } from '../shared/inventory/inventory.module';
  import { PaymentsModule } from '../shared/payments/payments.module';
  import { ContactsModule } from '../shared/contacts/contacts.module';

  @Module({})
  export class RetailModule {
    static register(): DynamicModule {
      return {
        module: RetailModule,
        imports: [
          CatalogModule.register(),
          TransactionsModule.register(),
          InventoryModule.register(),
          PaymentsModule.register(),
          ContactsModule.register(),
        ],
        controllers: [RetailController, RetailSessionController],
        providers: [RetailOrchestrationService, RetailSaleService, PosSessionService],
        exports: [RetailOrchestrationService],
      };
    }
  }
  ```

- [x] **1.2** Register `RetailModule.register()` in `apps/backend/src/app.module.ts` imports array.

- [x] **1.3** Ensure all `@Controller` and `@Get`/`@Post` decorators under `/api/v1/retail/*` use `@RequiresModule('retail')`.

### Phase 2 — RetailOrchestrationService: atomic sale (AC2)

- [x] **2.1** Create `apps/backend/src/retail/retail-orchestration.service.ts`:
  - `createSale(data: { items, paymentMethod, customerId?, sessionId?, tenantId, userId })`:
    - Uses `prisma.$transaction()` for atomic:
      1. Create shared `Transaction` (TransactionsService)
      2. Create `RetailSale` extension (RetailSaleService)
    - After commit, publish `transaction.created` event → InventoryService handles stock decrement via `@OnEvent('transaction.created')`
    - If `customerId` and credit payment: emit `credit.applied` event → ContactsService handles balance update

- [x] **2.2** Create `apps/backend/src/retail/retail.controller.ts`:
  - `POST /api/v1/retail/sales` — `@RequiresModule('retail')` + `@Roles('owner', 'manager', 'commercial')`
  - Delegates to `RetailOrchestrationService.createSale()`

### Phase 3 — Backward compat proxying (AC4)

- [x] **3.1** In `apps/backend/src/pos/pos.controller.ts`, update existing endpoints to proxy to retail services:
  - `POST /pos/orders` → proxy to `RetailOrchestrationService.createSale()`
  - `GET /pos/sessions` → proxy to `PosSessionService.getActiveSession()`
  - `POST /pos/sessions/open` → proxy to `PosSessionService.openSession()`
  - `POST /pos/sessions/close/:id` → proxy to `PosSessionService.closeSession()`
  - Preserve identical request/response shapes

### Phase 4 — Tests (AC1, AC2, AC3, AC4, AC5)

- [x] **4.1** Create `apps/backend/src/retail/retail-orchestration.service.spec.ts`:
  - Mock PrismaService (`$transaction`), EventBusService
  - Test atomic sale: Transaction + RetailSale both created in same $transaction
  - Test event emission: `transaction.created` published after commit
  - Test credit flow: `credit.applied` emitted when payment is credit

- [x] **4.2** Update/create `apps/backend/src/retail/retail.module.spec.ts`:
  - Test that RetailModule.register() returns DynamicModule with correct imports

- [x] **4.3** Run `npx jest --no-coverage` — 245/245 tests pass, 0 regressions (AC5).

## Dev Notes

### DynamicModule pattern (consistent with other modules)

All shared modules in this project follow the same pattern:

```typescript
static register(): DynamicModule {
  return {
    module: XModule,
    imports: [...],
    controllers: [...],
    providers: [...],
    exports: [...],
  };
}
```

### Event-driven stock decrement

Do NOT call InventoryService directly from the orchestration service for stock updates. Instead, publish `transaction.created` event. `InventoryService.handleTransactionCreated(@OnEvent)` already handles stock decrements from `itemsJson`. This avoids circular dependencies.

### @RequiresModule('retail') guard

The `@RequiresModule('retail')` decorator + `ModuleGuard` checks that the tenant's activated modules include `'retail'`. This is implemented in the kernel (Story 1.3).

### Atomic operation scope

```typescript
// Atomic: Transaction + RetailSale in one DB transaction
const result = await this.prisma.$transaction(async (tx) => {
  const transaction = await tx.transaction.create({ ... });
  const retailSale = await tx.retailSale.create({ data: { transactionId: transaction.id, ... } });
  return { transaction, retailSale };
});

// Post-commit: stock update via event (async, non-atomic)
this.eventBus.publish('transaction.created', { transactionId: transaction.id, tenantId });
```

### crypto.randomUUID() fix

Node.js < 19 doesn't expose `crypto` as a global. Use `import { randomUUID } from 'crypto'` instead of `crypto.randomUUID()`.

### References

- [Story 1.3 — Module registry + @RequiresModule guard](1-3-module-registry-activation.md)
- [Story 6.1 — retail schema](6-1-retail-schema-product-extensions.md)
- [Story 6.2 — RetailSale service](6-2-retailsale-extensions-session-scoping.md)
- [Story 6.3 — PosSessionService](6-3-cash-session-management.md)
- [epics.md — Epic 6 AC](../../planning-artifacts/epics.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `crypto.randomUUID()` not available as global in Node.js/Jest. Fixed by importing `{ randomUUID } from 'crypto'`.

### Completion Notes List

- **RetailModule.register():** DynamicModule importing CatalogModule, TransactionsModule, InventoryModule, PaymentsModule, ContactsModule. Declares RetailController + RetailSessionController (controllers), RetailOrchestrationService + RetailSaleService + PosSessionService (providers), exports RetailOrchestrationService (AC1).
- **AppModule:** Added `RetailModule.register()` to imports array (AC1).
- **RetailOrchestrationService:** `createSale()` uses `prisma.$transaction(async tx => {...})` (interactive) to atomically create Transaction + RetailSale. Post-commit emits `transaction.created` (stock decrement via InventoryService @OnEvent) and `credit.applied` when CREDIT/SPLIT payment (AC2).
- **RetailController:** `@Controller('retail/sales')` + `@RequiresModule('retail')` + `@Roles(...)`. Single `POST /` endpoint delegates to orchestration service (AC2, AC3).
- **RetailSessionController:** Already had `@RequiresModule('retail')` from Story 6.3 (AC3).
- **PosModule + PosController:** Added `RetailOrchestrationService` as provider. `POST /pos/orders` now proxies to `RetailOrchestrationService.createSale()` with field mapping. Session endpoints already proxied via PosSessionController (AC4).
- **7 new tests:** 5 orchestration service + 2 module shape. 245/245 pass, 0 regressions (AC5).

### File List

- apps/backend/src/retail/retail.module.ts [NEW]
- apps/backend/src/retail/retail.controller.ts [NEW]
- apps/backend/src/retail/retail-orchestration.service.ts [NEW]
- apps/backend/src/retail/retail-orchestration.service.spec.ts [NEW]
- apps/backend/src/retail/retail.module.spec.ts [NEW]
- apps/backend/src/app.module.ts [MODIFIED — RetailModule.register() added]
- apps/backend/src/pos/pos.module.ts [MODIFIED — RetailOrchestrationService provider added]
- apps/backend/src/pos/pos.controller.ts [MODIFIED — POST /pos/orders proxied to RetailOrchestrationService]

## Change Log

- 2026-03-15: Story 6.4 created — RetailModule.register(), RetailOrchestrationService (atomic sale via prisma.$transaction), @RequiresModule('retail'), backward compat proxying from old POS endpoints.
- 2026-03-15: Story 6.4 implemented — RetailModule, RetailOrchestrationService (atomic prisma.$transaction + events), RetailController, PosModule/PosController updated for backward compat, 245/245 tests pass.
