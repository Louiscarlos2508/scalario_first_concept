# Story 5.1: Inventory Schema & Stock Movement Types

Status: done

## Story

As a system architect,
I want stock movements extracted to a shared module with typed movement categories,
so that inventory tracking is shared infrastructure with clear movement semantics.

## Acceptance Criteria

1. **AC1 — shared.stock_movements table:** Given the shared schema exists, when the inventory migration runs, then the `shared.stock_movements` table is created with: `id` (UUID PK), `catalog_item_id` (UUID, nullable for legacy records), `quantity` (DECIMAL 10,2), `type` (TEXT: SALE|DELIVERY|TRANSFER_OUT|TRANSFER_IN|LOSS|ADJUSTMENT), `reason` (TEXT nullable), `tenant_id` (UUID NOT NULL), `user_id` (UUID nullable), `reference_id` (UUID nullable — for Story 5.3 transfer linking), `created_at` (TIMESTAMPTZ), with indexes on `(tenant_id, created_at)` and `(catalog_item_id)` and `(reference_id)`.

2. **AC2 — Data migration from public.stock_movements:** Given existing StockMovement records in the public schema, when the migration runs, then all movements are copied to `shared.stock_movements` with `product_id` mapped to `catalog_item_id` as-is (same UUID column), `user_id` defaulting to NULL, `reference_id` to NULL, and type mapped verbatim. The migration is non-destructive — `public.stock_movements` is kept for backward compat (dropped in Story 5.2).

3. **AC3 — TransactionCreated event handler:** Given a `transaction.created` event is published, when the InventoryService `@OnEvent('transaction.created')` handler receives it, then a SALE-type `InventoryMovement` is created for each item in `itemsJson`, decrementing stock (quantity stored as negative or as positive depending on sign convention — use positive quantity, type=SALE implies decrement semantically).

4. **AC4 — InventoryModule as DynamicModule:** Given the InventoryModule is implemented, when it is registered in AppModule, then it is registered as `InventoryModule.register()` (DynamicModule), exports `InventoryService`, and `InventoryService` is wired with `@OnEvent` listener.

5. **AC5 — InventoryService.createMovement():** Given the InventoryService is invoked, when `createMovement(data, userId)` is called, then a movement is persisted to `shared.stock_movements`. No AuditLog or event yet (those come in Story 5.2+ per movement type).

6. **AC6 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 5.1 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — Migration & Schema (AC1, AC2)

- [x] **1.1** Create `apps/backend/prisma/migrations/20260315100000_shared_inventory_movements/migration.sql`:
  ```sql
  -- Story 5.1: Create shared.stock_movements table
  -- public.stock_movements kept intact for backward compat (dropped in Story 5.2)

  CREATE TABLE "shared"."stock_movements" (
      "id"              UUID            NOT NULL DEFAULT gen_random_uuid(),
      "catalog_item_id" UUID,
      "quantity"        DECIMAL(10,2)   NOT NULL,
      "type"            TEXT            NOT NULL,
      "reason"          TEXT,
      "tenant_id"       UUID            NOT NULL,
      "user_id"         UUID,
      "reference_id"    UUID,
      "created_at"      TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT "inventory_movements_pkey" PRIMARY KEY ("id")
  );

  CREATE INDEX "inventory_movements_tenant_id_created_at_idx"
      ON "shared"."stock_movements"("tenant_id", "created_at");
  CREATE INDEX "inventory_movements_catalog_item_id_idx"
      ON "shared"."stock_movements"("catalog_item_id");
  CREATE INDEX "inventory_movements_reference_id_idx"
      ON "shared"."stock_movements"("reference_id");

  -- Data migration: copy public.stock_movements → shared.stock_movements
  -- product_id is used as catalog_item_id (best-effort; NULLs allowed for legacy records)
  INSERT INTO "shared"."stock_movements" (
      "id", "catalog_item_id", "quantity", "type", "reason",
      "tenant_id", "user_id", "reference_id", "created_at"
  )
  SELECT
      "id",
      "product_id"            AS "catalog_item_id",
      "quantity",
      COALESCE("type", 'ADJUSTMENT') AS "type",
      "reason",
      "tenant_id",
      NULL                    AS "user_id",
      NULL                    AS "reference_id",
      "created_at"
  FROM "public"."stock_movements";
  ```

- [x] **1.2** Add `InventoryMovement` model to `apps/backend/prisma/schema.prisma` in SHARED SCHEMA (after Transaction model):
  ```prisma
  model InventoryMovement {
    id            String   @id @default(uuid()) @db.Uuid
    catalogItemId String?  @map("catalog_item_id") @db.Uuid
    // Valid values: 'SALE' | 'DELIVERY' | 'TRANSFER_OUT' | 'TRANSFER_IN' | 'LOSS' | 'ADJUSTMENT'
    type          String
    quantity      Decimal  @db.Decimal(10, 2)
    reason        String?
    tenantId      String   @map("tenant_id") @db.Uuid
    userId        String?  @map("user_id") @db.Uuid
    referenceId   String?  @map("reference_id") @db.Uuid
    createdAt     DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

    @@index([tenantId, createdAt])
    @@index([catalogItemId])
    @@index([referenceId])
    @@map("stock_movements")
    @@schema("shared")
  }
  ```

- [x] **1.3** Run `npx prisma generate` to confirm schema is valid.

### Phase 2 — InventoryService & InventoryModule (AC3, AC4, AC5)

- [x] **2.1** Create `apps/backend/src/shared/inventory/inventory.service.ts`:
  - Inject `PrismaService`
  - `createMovement(data: { catalogItemId?, quantity, type, reason?, tenantId, userId?, referenceId? })`: persists to `prisma.inventoryMovement.create()`
  - `@OnEvent('transaction.created')` handler: reads event payload `{ transactionId, tenantId }`, fetches transaction from DB, iterates `itemsJson`, creates SALE movement per item
  - **Movement sign convention:** quantity stored as absolute positive value; type (SALE/DELIVERY/etc.) determines direction semantically

- [x] **2.2** Create `apps/backend/src/shared/inventory/inventory.module.ts` as DynamicModule:
  ```typescript
  @Module({})
  export class InventoryModule {
    static register(): DynamicModule {
      return {
        module: InventoryModule,
        providers: [InventoryService],
        exports: [InventoryService],
      };
    }
  }
  ```

- [x] **2.3** Register `InventoryModule.register()` in `apps/backend/src/app.module.ts`.

### Phase 3 — Tests (AC3, AC5, AC6)

- [x] **3.1** Create `apps/backend/src/shared/inventory/inventory.service.spec.ts`:
  - Mock PrismaService (`inventoryMovement.create`, `transaction.findUnique`)
  - Test `createMovement`: persists movement with correct fields
  - Test `@OnEvent('transaction.created')` handler: creates SALE movements for each item in itemsJson
  - Test handler with empty itemsJson: no movements created
  - Test handler when transaction not found: no movements created (graceful)

- [x] **3.2** Run `npx jest --no-coverage` — all tests pass.

## Dev Notes

### InventoryMovement vs StockMovement Naming

The existing `StockMovement` model in `schema.prisma` maps to `public.stock_movements` (`@@schema("public")`). The new model maps to `shared.stock_movements` (`@@schema("shared")`). Prisma requires distinct model names — use **`InventoryMovement`** for the new shared model. This avoids a name conflict while keeping public.stock_movements intact for backward compat (Story 5.2 drops it).

### product_id → catalog_item_id Migration

Products (`public.products`) and CatalogItems (`shared.catalog_items`) are **separate entities** with independent IDs. The migration uses product_id as catalog_item_id with `nullable` fallback — this is best-effort. Legacy movements may reference product UUIDs that don't exist in catalog_items. This is acceptable since:
- New movements created via InventoryService will always have valid catalog_item_id
- Legacy movements are read-only historical data
- Story 5.4's stock level calculation can filter NULL catalog_item_id records

### TransactionCreated Event Handler

```typescript
@OnEvent('transaction.created')
async handleTransactionCreated(payload: { transactionId: string; tenantId: string }) {
  const tx = await this.prisma.transaction.findUnique({ where: { id: payload.transactionId } });
  if (!tx) return;

  const items = Array.isArray(tx.itemsJson) ? tx.itemsJson as any[] : [];
  for (const item of items) {
    const qty = Number(item.quantity ?? item.qty ?? 1);
    if (qty <= 0) continue;
    await this.createMovement({
      catalogItemId: item.catalogItemId ?? item.productId ?? null,
      quantity: qty,
      type: 'SALE',
      tenantId: payload.tenantId,
    });
  }
}
```

Import `@OnEvent` from `@nestjs/event-emitter`. The decorator registers this method as a listener on the global EventEmitter2 instance (set up in `AppModule` via `EventEmitterModule.forRoot()`). InventoryService must be in a module registered in AppModule for the listener to activate.

### DynamicModule Pattern

Consistent with CatalogModule, ContactsModule, PaymentsModule, TransactionsModule. No controller in 5.1 (API endpoints come in 5.2+). No sub-module imports needed — PrismaService is global.

### Established Patterns

- `jest.clearAllMocks()` in `afterEach` (not `resetAllMocks`)
- PrismaModule is `@Global()` — no explicit import
- AuditLogService and EventBusService are globally injectable (not needed in 5.1)
- `npx prisma generate` after schema changes

### Project Structure

```
apps/backend/prisma/
├── schema.prisma                                      [MODIFY — add InventoryMovement model]
└── migrations/
    └── 20260315100000_shared_inventory_movements/
        └── migration.sql                              [NEW]

apps/backend/src/
├── shared/
│   └── inventory/
│       ├── inventory.service.ts                       [NEW]
│       ├── inventory.service.spec.ts                  [NEW]
│       └── inventory.module.ts                        [NEW]
└── app.module.ts                                      [MODIFY — add InventoryModule.register()]
```

### References

- [Story 4.1 — Transaction model pattern](_bmad-output/implementation-artifacts/4-1-transaction-entity-payments-service.md)
- [Story 4.2 — TransactionCreated event emitter](_bmad-output/implementation-artifacts/4-2-transaction-api-local-first-recording.md)
- [schema.prisma — existing StockMovement model to keep intact](apps/backend/prisma/schema.prisma)
- [EventBusService.publish() — uses EventEmitter2](apps/backend/src/kernel/events/event-bus.service.ts)
- [CatalogModule — DynamicModule pattern reference](apps/backend/src/shared/catalog/catalog.module.ts)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- Migration `20260315100000_shared_inventory_movements/migration.sql`: creates `shared.stock_movements` with all AC1 fields (including `reference_id` for Story 5.3). Data migrated from `public.stock_movements` with `product_id → catalog_item_id` (nullable for legacy compat). `public.stock_movements` kept intact.
- `InventoryMovement` model added to schema.prisma (SHARED SCHEMA, after Transaction). Distinct model name avoids conflict with existing `StockMovement` (public). `npx prisma generate` confirmed valid.
- `InventoryService.createMovement()`: persists to `prisma.inventoryMovement.create()`. Positive quantity convention — type determines direction semantically.
- `@OnEvent('transaction.created')` handler: fetches transaction, iterates itemsJson, creates SALE movement per item. Falls back to `productId` if `catalogItemId` absent. Skips qty <= 0. Returns gracefully if transaction not found.
- `InventoryModule.register()`: DynamicModule, no sub-imports (PrismaService global), no controller (API in Story 5.2+). Registered in AppModule.
- 7 new tests in `inventory.service.spec.ts`. 179/179 tests pass, 0 regressions.

### File List

- apps/backend/prisma/migrations/20260315100000_shared_inventory_movements/migration.sql [NEW]
- apps/backend/prisma/schema.prisma [MODIFIED — InventoryMovement model added in shared schema]
- apps/backend/src/shared/inventory/inventory.service.ts [NEW]
- apps/backend/src/shared/inventory/inventory.module.ts [NEW]
- apps/backend/src/shared/inventory/inventory.service.spec.ts [NEW]
- apps/backend/src/app.module.ts [MODIFIED — InventoryModule.register() added]

## Change Log

- 2026-03-15: Story 5.1 implemented — shared.stock_movements migration, InventoryMovement Prisma model, InventoryService (createMovement + transaction.created event handler), InventoryModule (DynamicModule). 179/179 tests pass.
