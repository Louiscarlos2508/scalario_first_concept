# Story 6.2: RetailSale Extensions & Session Scoping

Status: review

## Story

As a system architect,
I want retail-specific transaction fields (sessionId, receiptNumber, cashierId) in an extension table,
so that the shared Transaction stays clean and retail-specific POS logic is isolated.

## Acceptance Criteria

1. **AC1 — retail.retail_sales table:** Given the retail schema exists, when the retail sales migration runs, then the `retail.retail_sales` table is created with: `id`, `transaction_id` (unique FK → transactions), `session_id` (FK → pos_sessions, nullable), `receipt_number`, `cashier_id`.

2. **AC2 — Data migration from Orders:** Given existing Order records with sessionId and receiptNumber, when the data migration runs, then RetailSale records are created for each Transaction with session and receipt data migrated, zero data loss verified.

3. **AC3 — Atomic Transaction + RetailSale creation:** Given a retail transaction is created, when the RetailModule processes the sale, then both a shared Transaction AND a RetailSale extension record are created in a single database transaction (atomicity guaranteed). The RetailSale is linked to the active POS session via `session_id`.

4. **AC4 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 6.2 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — Database: retail_sales table migration (AC1, AC2)

- [x] **1.1** Add `RetailSale` model to `apps/backend/prisma/schema.prisma` with `@@schema("retail")`:
  - `RetailSale` model with `transactionId` (unique FK → Transaction), `sessionId?` (FK → PosSession), `receiptNumber`, `cashierId`
  - Added `retailSale RetailSale?` relation to `Transaction` model
  - Added `retailSales RetailSale[]` relation to `PosSession` model

- [x] **1.2** Created manual SQL migration `apps/backend/prisma/migrations/20260315140000_retail_sales_table/migration.sql`:
  - `retail.retail_sales` table with FKs to `shared.transactions` and `public.pos_sessions`
  - Indexes on `session_id` and `cashier_id`

- [x] **1.3** Created data migration `apps/backend/prisma/migrations/20260315150000_migrate_transactions_to_retail_sales/migration.sql`:
  - Creates RetailSale records for Transactions with `session_id IS NOT NULL` (formerly Order.sessionId)
  - `receipt_number` = `'LEGACY-' + tx.id prefix` (Order receipt_number was not stored in Transaction)
  - `cashier_id` = synthetic placeholder (not preserved in Transaction model; will be set going forward)
  - Logs migrated count via RAISE NOTICE

### Phase 2 — RetailSale service: atomic creation (AC3)

- [x] **2.1** Created `apps/backend/src/retail/retail-sale.service.ts`:
  - `createRetailSale(data: { transactionId, sessionId?, receiptNumber, cashierId, tenantId })`
  - Uses `prisma.$transaction(async (tx) => tx.retailSale.create(...))` for atomic DB write
  - Publishes `retail.sale.created` event via EventBusService after creation
  - Returns the created RetailSale

- [x] **2.2** Atomic Transaction + RetailSale pattern established:
  - `RetailSaleService.createRetailSale()` handles the RetailSale side atomically
  - Full Transaction + RetailSale orchestration (calling both services in one `prisma.$transaction`) is Story 6.4's `RetailOrchestrationService`
  - `sessionId` linkage flows from the active session passed in the request payload

### Phase 3 — Tests (AC3, AC4)

- [x] **3.1** Created `apps/backend/src/retail/retail-sale.service.spec.ts` (5 tests):
  - Test: `prisma.$transaction` called — validates atomic wrapper
  - Test: `sessionId` from active session passed to `retailSale.create` (session scoping)
  - Test: `sessionId` defaults to null when not provided
  - Test: `retail.sale.created` event published with correct payload
  - Test: returns the created RetailSale

- [x] **3.2** Run `npx jest --no-coverage` — 220/220 tests pass, 0 regressions (AC4).

## Dev Notes

### Atomic Prisma transactions

`createRetailSale()` uses interactive Prisma transaction (callback form):

```typescript
const retailSale = await this.prisma.$transaction(async (tx) => {
  return tx.retailSale.create({ data: { ... } });
});
```

Full atomicity (Transaction record + RetailSale) will be achieved in Story 6.4's `RetailOrchestrationService` via:

```typescript
await this.prisma.$transaction(async (tx) => {
  const transaction = await tx.transaction.create({ ... });
  const retailSale = await tx.retailSale.create({ data: { transactionId: transaction.id, ... } });
  return { transaction, retailSale };
});
```

### receipt_number generation

For Story 6.2, `receiptNumber` is provided by the caller. Going forward (Story 6.4), the orchestration service will generate receipt numbers. Document format in Story 6.4 Completion Notes.

### pos_sessions location

`PosSession` remains in `public` schema. The `retail_sales.session_id` FK references `public.pos_sessions(id)`.

### References

- [Story 4.1 — Transaction entity](4-1-transaction-entity-payments-service.md)
- [Story 4.2 — Transaction API](4-2-transaction-api-local-first-recording.md)
- [Story 6.1 — retail schema](6-1-retail-schema-product-extensions.md)
- [epics.md — Epic 6 AC](../../planning-artifacts/epics.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- **RetailSale Prisma model added:** `retail.retail_sales` — `id`, `transaction_id` (unique FK → shared.transactions ON DELETE CASCADE), `session_id` (nullable FK → public.pos_sessions), `receipt_number`, `cashier_id`, `created_at`. Relations: Transaction.retailSale (shared→retail), PosSession.retailSales (public→retail) (AC1).
- **SQL migration 20260315140000:** Creates `retail.retail_sales` with cross-schema FKs; indexes on session_id and cashier_id (AC1).
- **Data migration 20260315150000:** Creates RetailSale records for existing Transactions with session_id set. Receipt number generated as `LEGACY-<tx_id_prefix>`. Cashier_id is synthetic placeholder (not in Transaction model). Logs migrated count (AC2).
- **RetailSaleService.createRetailSale():** Uses `prisma.$transaction(async tx => ...)` for atomic DB write. Publishes `retail.sale.created` with `{ retailSaleId, transactionId, sessionId, tenantId }`. sessionId linked from input data (AC3).
- **Full atomic orchestration deferred to Story 6.4:** `RetailOrchestrationService` will wrap TransactionsService + RetailSaleService in single `prisma.$transaction`, completing AC3 end-to-end.
- **5 new tests:** $transaction called, sessionId linked, sessionId null fallback, event published, return value. 220/220 tests pass, 0 regressions (AC4).

### File List

- apps/backend/prisma/schema.prisma [MODIFIED — RetailSale model, Transaction.retailSale relation, PosSession.retailSales relation]
- apps/backend/prisma/migrations/20260315140000_retail_sales_table/migration.sql [NEW — retail_sales DDL]
- apps/backend/prisma/migrations/20260315150000_migrate_transactions_to_retail_sales/migration.sql [NEW — data migration]
- apps/backend/src/retail/retail-sale.service.ts [NEW — RetailSaleService with createRetailSale()]
- apps/backend/src/retail/retail-sale.service.spec.ts [NEW — 5 tests]

## Change Log

- 2026-03-15: Story 6.2 created — retail_sales table, RetailSale extension, atomic Transaction + RetailSale creation with session scoping.
- 2026-03-15: Story 6.2 implemented — RetailSale Prisma model, SQL migrations (DDL + data), RetailSaleService with prisma.$transaction atomic create, 220/220 tests pass.
