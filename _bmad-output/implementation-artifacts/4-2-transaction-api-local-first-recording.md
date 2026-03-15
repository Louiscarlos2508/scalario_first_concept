# Story 4.2: Transaction API & Local-First Recording

Status: review

## Story

As a commercial,
I want to create sales transactions that are written locally first and synced when connectivity returns,
so that I can process sales without interruption regardless of network status.

## Acceptance Criteria

1. **AC1 — POST /transactions (idempotent create + AuditLog):** Given an authenticated user, when they call `POST /transactions` with a client-generated UUID and transaction data, then:
   - The transaction is created in `shared.transactions` with the provided UUID
   - If the UUID already exists, the existing record is returned without error (idempotent)
   - An AuditLog entry is recorded: `action='CREATE'`, `entity='Transaction'`, `entityId=<uuid>`

2. **AC2 — Credit payment: ContactsService.updateBalance():** Given a transaction with `paymentMethod = 'CREDIT'` and a `customerId`, when the transaction is recorded, then `ContactsService.updateBalance(customerId, totalAmount)` is called to increment the customer's outstanding balance.

3. **AC3 — Split payment with credit component:** Given a transaction with `paymentMethod = 'SPLIT'` and `paymentSplits` containing a CREDIT entry, when the transaction is recorded, then `ContactsService.updateBalance(customerId, creditAmount)` is called for only the credit portion.

4. **AC4 — GET /transactions (delta sync):** Given an authenticated user, when they call `GET /transactions?since=<ISO8601>&tenantId=<uuid>`, then only transactions with `created_at > since` are returned (OR all if no since). Response includes `meta.serverTime`, `meta.total`, `meta.hasMore`.

5. **AC5 — TransactionCreated event:** Given a new transaction is created (not a duplicate), when `TransactionsService.createTransaction()` runs, then a `transaction.created` event is emitted via `EventBusService.publish()`.

6. **AC6 — TransactionsModule as DynamicModule:** Given the TransactionsModule is implemented, when it is registered in AppModule, then it is registered as `TransactionsModule.register()` (DynamicModule pattern), and exports `TransactionsService`.

7. **AC7 — @RequiresModule('transactions') gate:** Given the TransactionsController has `@RequiresModule('transactions')`, when a tenant without the `transactions` module activated calls any transactions endpoint, then ModuleGuard returns 403.

8. **AC8 — Old /pos/orders proxy:** Given the old `syncOrder()` method exists in PosService, when Story 4.2 is applied, then `PosService.syncOrder()` delegates to `TransactionsService.createTransaction()`. The response shape is preserved for backward compat.

9. **AC9 — Drop public.orders (migration):** Given all order data exists in `shared.transactions` from Story 4.1, when the Story 4.2 migration runs, then `public.orders` is dropped. The `Order` model is removed from `schema.prisma`. Relations on `Tenant` and `PosSession` that reference `Order` are cleaned up.

10. **AC10 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 4.2 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — Migration: drop public.orders (AC9)

- [x] **1.1** Create directory: `apps/backend/prisma/migrations/20260315090000_drop_public_orders/`

- [x] **1.2** Create `migration.sql`:
  ```sql
  -- Story 4.2: Drop public.orders after migration to shared.transactions (Story 4.1)
  -- Optional row-count verification (uncomment for live DB):
  -- DO $$ ... END $$;

  -- Drop PosSession.orders FK before dropping orders table
  ALTER TABLE "public"."orders" DROP CONSTRAINT IF EXISTS "orders_session_id_fkey";
  ALTER TABLE "public"."orders" DROP CONSTRAINT IF EXISTS "orders_tenant_id_fkey";

  -- Drop public.orders (CASCADE removes any remaining dependent objects)
  DROP TABLE "public"."orders" CASCADE;
  ```

- [x] **1.3** Update Prisma schema:
  - Remove `Order` model entirely from `schema.prisma`
  - Remove `orders Order[]` from `Tenant` model
  - Remove `orders Order[]` from `PosSession` model
  - Keep `PosSession.id` references intact (sessionId is raw String on Transaction)
  - Run `npx prisma generate` to confirm schema is valid

### Phase 2 — TransactionsService implementation (AC1–AC5, AC8)

- [x] **2.1** Create `apps/backend/src/shared/transactions/transactions.service.ts`:
  - Inject `PrismaService`, `AuditLogService`, `EventBusService`, `ContactsService`, `PaymentsService`
  - `createTransaction(data, userId)`:
    - Upsert by id (idempotent — if exists, return existing)
    - If new: apply FCFA rounding via `paymentsService.roundTotal()`
    - If new + CREDIT: call `contactsService.updateBalance(customerId, totalAmount)`
    - If new + SPLIT with CREDIT: call `contactsService.updateBalance(customerId, splits.CREDIT)`
    - If new: emit `transaction.created` via `eventBus.publish()`
    - If new: log AuditLog action='CREATE'
  - `getTransactions(params: { tenantId?, since?, page?, limit? })`:
    - When `since`: `where.createdAt = { gt: new Date(since) }`; include all
    - When no `since`: return all non-deleted (no isDeleted on Transaction)
    - Returns `{ items, meta: { total, page, limit, hasMore, serverTime } }`

- [x] **2.2** Create `apps/backend/src/shared/transactions/transactions.controller.ts`:
  - `@Controller('transactions')` + `@RequiresModule('transactions')`
  - `POST /transactions` — `@Roles('owner', 'commercial')`; extracts userId from `req.user?.sub`
  - `GET /transactions` — no `@Roles` (all authenticated)

- [x] **2.3** Create `apps/backend/src/shared/transactions/transactions.module.ts` as DynamicModule:
  ```typescript
  @Module({})
  export class TransactionsModule {
    static register(): DynamicModule {
      return {
        module: TransactionsModule,
        imports: [ContactsModule.register(), PaymentsModule.register()],
        providers: [TransactionsService],
        controllers: [TransactionsController],
        exports: [TransactionsService],
      };
    }
  }
  ```

- [x] **2.4** Register `TransactionsModule.register()` in `apps/backend/src/app.module.ts`.

### Phase 3 — PosService proxy (AC8)

- [x] **3.1** Inject `TransactionsService` into `PosService` (PosModule imports TransactionsModule).

- [x] **3.2** Update `apps/backend/src/pos/pos.service.ts` — refactor `syncOrder()` to delegate to `TransactionsService.createTransaction()`:
  - Map `orderData` fields to Transaction shape
  - Return order-compatible shape for backward compat
  - Keep existing tenant/session resolution logic before delegating

- [x] **3.3** Add `TransactionsModule` to `PosModule` imports.

### Phase 4 — Tests (AC1–AC5, AC10)

- [x] **4.1** Create `apps/backend/src/shared/transactions/transactions.service.spec.ts`:
  - Mock PrismaService (transaction.upsert, transaction.findMany, transaction.count, transaction.findUnique)
  - Mock AuditLogService (log)
  - Mock EventBusService (publish)
  - Mock ContactsService (updateBalance)
  - Mock PaymentsService (roundTotal)
  - Test createTransaction: creates transaction + AuditLog + TransactionCreated event
  - Test createTransaction: idempotent — existing UUID returns existing record without AuditLog
  - Test createTransaction + CREDIT: calls contactsService.updateBalance with full amount
  - Test createTransaction + SPLIT with CREDIT: calls contactsService.updateBalance with credit portion only
  - Test getTransactions: without `since` returns all; with `since` filters by createdAt

- [x] **4.2** Create `apps/backend/src/shared/transactions/transactions.controller.spec.ts`:
  - Mock TransactionsService
  - Test POST /transactions: extracts userId from req.user.sub
  - Test GET /transactions: passes parsed params

- [x] **4.3** Run `npx jest --no-coverage` from `apps/backend/` — all tests pass.

## Dev Notes

### Scope Boundary — What Story 4.2 Does NOT Do

| Out of Scope | When | Story |
|---|---|---|
| StockAdjusted event on transaction | Epic 5 | Inventory module |
| `GET /transactions/:id` | Later | If needed |
| RLS policy on shared.transactions | Later | After full Supabase RLS setup |
| `transfer_inter_tenant` transaction type usage | Phase 3 | Scalario Connect |
| Scheduled/accumulating lifecycle types | Future | Retail extensions |

### Idempotency: Upsert by UUID

```typescript
async createTransaction(data: any, userId: string | null) {
  // Check existence first to know if new
  const existing = await this.prisma.transaction.findUnique({ where: { id: data.id } });
  if (existing) return existing; // idempotent — no side effects

  // New transaction: round total, persist, fire events
  const roundedTotal = this.paymentsService.roundTotal(Number(data.totalAmount));
  const newTx = await this.prisma.transaction.create({
    data: {
      id: data.id,
      totalAmount: roundedTotal,
      itemsJson: data.itemsJson || [],
      paymentMethod: data.paymentMethod,
      paymentSplits: data.paymentSplits,
      lifecycleType: data.lifecycleType ?? 'instant',
      transactionType: data.transactionType ?? 'sale',
      customerId: data.customerId ?? null,
      sessionId: data.sessionId ?? null,
      tenantId: data.tenantId,
    },
  });

  // Credit balance update
  if (data.paymentMethod === 'CREDIT' && data.customerId) {
    await this.contactsService.updateBalance(data.customerId, roundedTotal);
  } else if (data.paymentMethod === 'SPLIT' && data.paymentSplits && data.customerId) {
    const splits = typeof data.paymentSplits === 'string'
      ? JSON.parse(data.paymentSplits) : data.paymentSplits;
    if (splits['CREDIT']) {
      await this.contactsService.updateBalance(data.customerId, splits['CREDIT']);
    }
  }

  // Audit + event
  await this.auditLog.log({
    tenantId: data.tenantId,
    userId,
    action: 'CREATE',
    entity: 'Transaction',
    entityId: newTx.id,
    before: null,
    after: { totalAmount: String(newTx.totalAmount), paymentMethod: newTx.paymentMethod },
  });
  this.eventBus.publish('transaction.created', { transactionId: newTx.id, tenantId: newTx.tenantId });

  return newTx;
}
```

### Order Model Removal: Cascade Impact

After `public.orders` is dropped, the `Order` model must be removed from schema.prisma. Cascade:

**Models to update:**
- Remove `Order` model entirely
- `Tenant` model: remove `orders Order[]` from relations list
- `PosSession` model: remove `orders Order[]` from relations list (PosSession has `orders Order[]`)

After removal, `prisma.order` is no longer accessible. `PosService.syncOrder()` must delegate to `TransactionsService.createTransaction()`.

**PosSession.orders clean-up check:** Read `schema.prisma` PosSession model before editing — confirm it has `orders Order[]` relation that needs removal.

### DynamicModule with Sub-Imports

TransactionsModule imports ContactsModule and PaymentsModule to inject their services:
```typescript
static register(): DynamicModule {
  return {
    module: TransactionsModule,
    imports: [ContactsModule.register(), PaymentsModule.register()],
    providers: [TransactionsService],
    controllers: [TransactionsController],
    exports: [TransactionsService],
  };
}
```

NestJS deduplicates module instances — calling `.register()` multiple times across AppModule, PosModule, TransactionsModule is safe.

### PosService.syncOrder() Refactoring

After this story, `syncOrder()` becomes a thin proxy:
```typescript
async syncOrder(orderData: any) {
  try {
    // Resolve tenantId (keep existing logic)
    let tenantId = orderData.tenantId;
    // ... tenant fallback logic ...

    return this.transactionsService.createTransaction({
      id: orderData.uuid,
      totalAmount: orderData.totalAmount,
      itemsJson: orderData.items || [],
      paymentMethod: orderData.paymentMethod,
      paymentSplits: orderData.payment_splits,
      customerId: orderData.customer_id,
      sessionId: orderData.sessionId,
      tenantId,
    }, null);
  } catch (error: any) {
    console.error('POS Sync Error Internal:', error);
    throw error;
  }
}
```

The existing tenant resolution, contact validation, and session validation logic can be simplified since TransactionsService handles the idempotency.

### EventBusService.publish() — Confirmed Pattern

From Story 3.2 implementation: `EventBusService` has `publish(eventName, payload)` not `emit()`. Use:
```typescript
this.eventBus.publish('transaction.created', { transactionId: newTx.id, tenantId: newTx.tenantId });
```

### Established Patterns

- `jest.clearAllMocks()` in `beforeEach` (not `resetAllMocks`)
- PrismaModule is `@Global()` — no explicit import needed
- AuditLogService injectable globally (KernelModule is `@Global()`)
- EventBusService injectable globally (KernelModule is `@Global()`)
- ContactsService injectable via `ContactsModule.register()` import
- No global prefix in `main.ts` — routes at `/transactions/...`
- DynamicModule pattern consistent with CatalogModule and ContactsModule

### Project Structure Notes

Files to create/modify:
```
apps/backend/prisma/
├── schema.prisma                                      [MODIFY — remove Order model; update Tenant, PosSession]
└── migrations/
    └── 20260315090000_drop_public_orders/
        └── migration.sql                              [NEW — DROP public.orders]

apps/backend/src/
├── shared/
│   └── transactions/
│       ├── transactions.service.ts                    [NEW]
│       ├── transactions.service.spec.ts               [NEW]
│       ├── transactions.controller.ts                 [NEW]
│       ├── transactions.controller.spec.ts            [NEW]
│       └── transactions.module.ts                     [NEW]
├── pos/
│   ├── pos.module.ts                                  [MODIFY — add TransactionsModule.register()]
│   └── pos.service.ts                                 [MODIFY — syncOrder() delegates to TransactionsService]
└── app.module.ts                                      [MODIFY — add TransactionsModule.register()]
```

### References

- [Epic 4 Story 4.2 ACs](_bmad-output/planning-artifacts/epics.md)
- [Story 4.1 — Transaction model + PaymentsService](_bmad-output/implementation-artifacts/4-1-transaction-entity-payments-service.md)
- [Story 3.2 — ContactsService.updateBalance() + DynamicModule pattern](_bmad-output/implementation-artifacts/3-2-contacts-api-credit-management.md)
- [Story 2.3 — CatalogModule DynamicModule pattern](_bmad-output/implementation-artifacts/2-3-catalog-sync-adapter-delta-pull.md)
- [EventBusService (publish() confirmed)](apps/backend/src/kernel/events/event-bus.service.ts)
- [PosService.syncOrder() — to be proxied](apps/backend/src/pos/pos.service.ts)
- [PosService current state after Story 3.2](apps/backend/src/pos/pos.service.ts)
- [schema.prisma — Order model to remove + PosSession orders relation](apps/backend/prisma/schema.prisma)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- Migration `20260315090000_drop_public_orders/migration.sql` drops `public.orders` with CASCADE; FKs dropped before table.
- `Order` model removed from schema.prisma; `Tenant.orders` and `PosSession.orders` relations cleaned up. `npx prisma generate` confirmed valid.
- `TransactionsService.createTransaction()`: idempotent findUnique-first pattern; FCFA rounding via PaymentsService; CREDIT/SPLIT balance update via ContactsService; AuditLog + `transaction.created` event on new transactions only.
- `TransactionsService.getTransactions()`: `since` param maps to `createdAt: { gt }` filter; meta includes serverTime, hasMore.
- `TransactionsController`: `@RequiresModule('transactions')`, POST guarded by `@Roles('owner', 'commercial')`, userId from `req.user?.sub`.
- `TransactionsModule.register()`: DynamicModule importing ContactsModule and PaymentsModule; registered in AppModule and PosModule.
- `PosService.syncOrder()` refactored to thin proxy; `getSalesStats()` and `getSalesReport()` updated to use `shared.transactions` (compile-time requirement after Order model removal).
- 172/172 tests pass (24 suites); 12 new tests added (service: 8, controller: 4).

### File List

- apps/backend/prisma/migrations/20260315090000_drop_public_orders/migration.sql [NEW]
- apps/backend/prisma/schema.prisma [MODIFIED — Order model removed, Tenant.orders + PosSession.orders relations removed]
- apps/backend/src/shared/transactions/transactions.service.ts [NEW]
- apps/backend/src/shared/transactions/transactions.controller.ts [NEW]
- apps/backend/src/shared/transactions/transactions.module.ts [NEW]
- apps/backend/src/shared/transactions/transactions.service.spec.ts [NEW]
- apps/backend/src/shared/transactions/transactions.controller.spec.ts [NEW]
- apps/backend/src/app.module.ts [MODIFIED — TransactionsModule.register() added]
- apps/backend/src/pos/pos.module.ts [MODIFIED — TransactionsModule.register() added]
- apps/backend/src/pos/pos.service.ts [MODIFIED — syncOrder() proxied, getSalesStats/getSalesReport updated to shared.transactions]

## Change Log

- 2026-03-15: Story 4.2 implemented — TransactionsService (idempotent create, FCFA rounding, credit balance, events, audit), TransactionsController (POST/GET), TransactionsModule (DynamicModule), AppModule + PosModule registration, PosService.syncOrder() proxy, migration drop public.orders, Order model removal. 172/172 tests pass.
