# Story 4.1: Transaction Entity & Payments Service

Status: done

## Story

As a system architect,
I want the Order entity decomposed into a shared Transaction with lifecycle types and a dedicated PaymentsService with FCFA rounding,
so that transaction processing is shared infrastructure usable by any vertical.

## Acceptance Criteria

1. **AC1 — shared.transactions table:** Given the shared schema exists from Epics 2–3, when the transactions migration runs, then `shared.transactions` is created with: `id` (UUID PK), `total_amount` (DECIMAL 10,2), `items_json` (JSON), `payment_method` (TEXT nullable), `payment_splits` (JSON nullable), `lifecycle_type` (TEXT NOT NULL default 'instant'), `transaction_type` (TEXT NOT NULL default 'sale'), `customer_id` (UUID nullable), `session_id` (UUID nullable), `tenant_id` (UUID NOT NULL), `created_at` (TIMESTAMPTZ default now()), with indexes on `(tenant_id, created_at)` and `(customer_id)`.

2. **AC2 — Data migration from public.orders:** Given existing Order records in `public.orders`, when the migration runs, then all rows are copied to `shared.transactions` with: same UUID, `lifecycle_type = 'instant'`, `transaction_type = 'sale'`, all other fields preserved. Zero data loss verified by row count. `public.orders` is NOT dropped (Story 4.2 handles the switch).

3. **AC3 — FCFA 5-franc rounding:** Given the PaymentsService receives a total amount and currency `XOF`, when `roundTotal(amount)` is called, then the result is rounded to the nearest 5 FCFA (e.g., 1247 → 1245, 1248 → 1250). Algorithm: `Math.round(amount / 5) * 5`.

4. **AC4 — Change due calculation:** Given a cash payment greater than the transaction total, when `calculateChange(total, paid)` is called, then the function returns `paid - total` (change due). Negative change = underpayment (error condition).

5. **AC5 — Split payment structure:** Given a transaction with `payment_splits` JSON, when the payment is processed, then `payment_splits` records each split as `{ method: string, amount: number }[]` and the sum of split amounts equals the total.

6. **AC6 — Prisma Transaction model in shared schema:** Given the migration runs, when `npx prisma generate` runs, then the `Transaction` model is available with `@@schema("shared")` and `prisma.transaction` accessor is available. The `transaction_type` field includes `'transfer_inter_tenant'` as a valid value (Phase 3 Connect, FR55 from Story 1.6 AC4).

7. **AC7 — updated_at trigger:** Given the `shared.transactions` table, when a row is updated, then `updated_at` is automatically refreshed by a DB-level trigger (consistent with Story 2.1 and 3.1 trigger patterns).

8. **AC8 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 4.1 changes are applied, all existing tests continue to pass with zero regressions.

## Tasks / Subtasks

### Phase 1 — Prisma schema update (AC6)

- [x] **1.1** Add `Transaction` model to `apps/backend/prisma/schema.prisma` in the SHARED SCHEMA section (after `Contact`):
  ```prisma
  model Transaction {
    id              String   @id @default(uuid()) @db.Uuid
    totalAmount     Decimal  @map("total_amount") @db.Decimal(10, 2)
    itemsJson       Json     @map("items_json")
    paymentMethod   String?  @map("payment_method")
    paymentSplits   Json?    @map("payment_splits")
    lifecycleType   String   @default("instant") @map("lifecycle_type")
    // Valid values: 'instant' | 'accumulating' | 'scheduled'
    transactionType String   @default("sale") @map("transaction_type")
    // Valid values: 'sale' | 'transfer_inter_tenant' (Phase 3 — Scalario Connect, FR55)
    customerId      String?  @map("customer_id") @db.Uuid
    sessionId       String?  @map("session_id") @db.Uuid
    tenantId        String   @map("tenant_id") @db.Uuid
    createdAt       DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
    updatedAt       DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)

    @@index([tenantId, createdAt])
    @@index([customerId])
    @@map("transactions")
    @@schema("shared")
  }
  ```
  **No `@relation` to Tenant, Contact, or PosSession** — use raw UUID fields (consistent with Contact/CatalogItem pattern). Cross-schema `@relation` deferred to Epic 6+ when needed.

- [x] **1.2** Run `npx prisma generate` from `apps/backend/` — verify schema is valid and `prisma.transaction` accessor appears in generated types.

### Phase 2 — Migration file (AC1–AC2, AC7)

- [x] **2.1** Create directory: `apps/backend/prisma/migrations/20260315080000_shared_transactions/`

- [x] **2.2** Create `migration.sql` (see Dev Notes for complete SQL). The migration must:
  - CREATE `shared.transactions` table with all fields from AC1
  - CREATE 2 indexes from AC1
  - INSERT data from `public.orders` → `shared.transactions` (same UUIDs, lifecycle_type='instant', transaction_type='sale')
  - CREATE `updated_at` auto-update trigger (same pattern as Story 2.1 and 3.1)
  - NOT drop `public.orders` (Story 4.2 handles the switch)

- [x] **2.3** Verify migration SQL: grep for `DROP TABLE` — must not appear in executable statements. `public.orders` must remain intact.

### Phase 3 — PaymentsService (AC3–AC5)

- [x] **3.1** Create `apps/backend/src/shared/payments/payments.service.ts`:
  - `roundTotal(amount: number): number` — FCFA 5-franc rounding: `Math.round(amount / 5) * 5`
  - `calculateChange(total: number, paid: number): number` — returns `paid - total`
  - `buildSplits(splits: Record<string, number>): { method: string; amount: number }[]` — converts payment_splits map to array form

- [x] **3.2** Create `apps/backend/src/shared/payments/payments.module.ts` as DynamicModule:
  ```typescript
  @Module({})
  export class PaymentsModule {
    static register(): DynamicModule {
      return {
        module: PaymentsModule,
        providers: [PaymentsService],
        exports: [PaymentsService],
      };
    }
  }
  ```

### Phase 4 — Tests (AC3–AC5, AC8)

- [x] **4.1** Create `apps/backend/src/shared/payments/payments.service.spec.ts`:
  - Test `roundTotal(1247)` → 1245
  - Test `roundTotal(1248)` → 1250
  - Test `roundTotal(1250)` → 1250 (already rounded)
  - Test `roundTotal(1)` → 0 (rounds down at boundary)
  - Test `roundTotal(3)` → 5 (rounds up at midpoint)
  - Test `calculateChange(600, 1000)` → 400
  - Test `calculateChange(600, 600)` → 0
  - Test `buildSplits({ CASH: 500, MOBILE_MONEY: 100 })` → `[{ method: 'CASH', amount: 500 }, { method: 'MOBILE_MONEY', amount: 100 }]`

- [x] **4.2** Run `npx jest --no-coverage` from `apps/backend/` — all existing tests pass.

## Dev Notes

### Scope Boundary — What Story 4.1 Does NOT Do

| Out of Scope | When | Story |
|---|---|---|
| TransactionsController + REST API | Story 4.2 | When transactions endpoints built |
| `POST /transactions` endpoint | Story 4.2 | Part of transactions API |
| Drop `public.orders` | Story 4.2 | After API switch |
| PosService.syncOrder() proxy to TransactionsService | Story 4.2 | After API built |
| TransactionsModule DynamicModule registration in AppModule | Story 4.2 | When module built |
| ContactsService.updateBalance() integration | Story 4.2 | Credit payment handling |
| StockAdjusted event | Epic 5 | Inventory module |

### Critical: FR55 — transaction_type MUST Include 'transfer_inter_tenant'

Story 1.6 AC4 explicitly deferred this to Story 4.1:
> `shared.transactions.transaction_type += 'transfer_inter_tenant'` — add when `Transaction` model is created in **Epic 4, Story 4-1**

From Story 1.6 Completion Notes:
> `transactions.transfer_inter_tenant` ... deferred to Epics 2–4 (models don't exist yet).

The `transactionType` field is a String discriminator (same pattern as `itemType` on CatalogItem and `contactType` on Contact). The MVP value is `'sale'`. The Phase 3 Connect value `'transfer_inter_tenant'` must be documented in the Prisma model comment at creation time to avoid a breaking migration at Phase 3 launch.

### Transaction Model: Field Decisions

| Field | Type | Notes |
|---|---|---|
| `id` | UUID PK | Client-generated for offline-first idempotency (Story 4.2) |
| `totalAmount` | Decimal(10,2) | XOF amounts — FCFA 5-franc rounded by PaymentsService |
| `itemsJson` | Json | Denormalized items snapshot — same as Order.itemsJson |
| `paymentMethod` | String? | 'CASH' \| 'MOBILE_MONEY' \| 'CREDIT' \| 'SPLIT' |
| `paymentSplits` | Json? | `{ method, amount }[]` — populated when paymentMethod='SPLIT' |
| `lifecycleType` | String | 'instant' (MVP) \| 'accumulating' \| 'scheduled' (future) |
| `transactionType` | String | 'sale' (MVP) \| 'transfer_inter_tenant' (Phase 3 FR55) |
| `customerId` | String? UUID | FK → shared.contacts.id (raw, no @relation) |
| `sessionId` | String? UUID | FK → public.pos_sessions.id (raw, no @relation — cross-schema) |
| `tenantId` | String UUID | FK → kernel.tenants.id (raw, no @relation — cross-schema) |
| `createdAt` | DateTime | Immutable — set on creation |
| `updatedAt` | DateTime @updatedAt | Auto-updated by Prisma + DB trigger |

### FCFA Rounding Algorithm

```typescript
roundTotal(amount: number): number {
  return Math.round(amount / 5) * 5;
}
```

Boundary cases:
- `Math.round(1247 / 5)` = `Math.round(249.4)` = 249 → 249 × 5 = **1245** ✅
- `Math.round(1248 / 5)` = `Math.round(249.6)` = 250 → 250 × 5 = **1250** ✅
- `Math.round(1250 / 5)` = `Math.round(250)` = 250 → 250 × 5 = **1250** ✅
- `Math.round(2 / 5)` = `Math.round(0.4)` = 0 → 0 × 5 = **0** (rounds down)
- `Math.round(3 / 5)` = `Math.round(0.6)` = 1 → 1 × 5 = **5** (rounds up)

**Note:** XOF (West African CFA Franc) has no decimal subunits. All amounts stored as integers effectively. `Decimal(10,2)` for Prisma type consistency with existing Order.totalAmount.

### Migration SQL — Complete Reference

```sql
-- Story 4.1: Create shared.transactions table
-- Migrates existing public.orders → shared.transactions (same UUIDs)
-- public.orders remains intact for backward compat until Story 4.2
-- shared schema already exists from Stories 2.1, 3.1

-- Step 1: Create shared.transactions table
CREATE TABLE "shared"."transactions" (
    "id"               UUID            NOT NULL DEFAULT gen_random_uuid(),
    "total_amount"     DECIMAL(10,2)   NOT NULL,
    "items_json"       JSONB           NOT NULL,
    "payment_method"   TEXT,
    "payment_splits"   JSONB,
    "lifecycle_type"   TEXT            NOT NULL DEFAULT 'instant',
    "transaction_type" TEXT            NOT NULL DEFAULT 'sale',
    "customer_id"      UUID,
    "session_id"       UUID,
    "tenant_id"        UUID            NOT NULL,
    "created_at"       TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"       TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- Step 2: Indexes (tenant isolation + customer lookup)
CREATE INDEX "transactions_tenant_id_created_at_idx"
    ON "shared"."transactions"("tenant_id", "created_at");

CREATE INDEX "transactions_customer_id_idx"
    ON "shared"."transactions"("customer_id");

-- Step 3: Data migration — copy public.orders → shared.transactions
-- Preserves UUIDs so existing client references remain valid
INSERT INTO "shared"."transactions" (
    "id",
    "total_amount",
    "items_json",
    "payment_method",
    "payment_splits",
    "lifecycle_type",
    "transaction_type",
    "customer_id",
    "session_id",
    "tenant_id",
    "created_at",
    "updated_at"
)
SELECT
    "id",
    "total_amount",
    "items_json",
    "payment_method",
    "payment_splits",
    'instant'   AS "lifecycle_type",
    'sale'      AS "transaction_type",
    "customer_id",
    "session_id",
    "tenant_id",
    "created_at",
    COALESCE("created_at", CURRENT_TIMESTAMP) AS "updated_at"
FROM "public"."orders";

-- Step 4: updated_at auto-update trigger (consistent with Story 2.1 and 3.1 patterns)
CREATE OR REPLACE FUNCTION shared_transactions_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER "transactions_updated_at_trigger"
    BEFORE UPDATE ON "shared"."transactions"
    FOR EACH ROW EXECUTE FUNCTION shared_transactions_update_updated_at();

-- NOTE: public.orders is NOT dropped (backward compat — Story 4.2 handles the switch)
-- NOTE: transaction_type 'transfer_inter_tenant' is a valid value reserved for Phase 3 Connect (FR55)
```

### PaymentsService — No DB Dependency

PaymentsService is a pure computation service with no Prisma dependency. It will be injected by TransactionsService (Story 4.2) to:
1. Round totals before persisting
2. Calculate change due for cash payments
3. Build payment_splits JSON structure

No database calls → no need for PrismaService injection in PaymentsService.

### PaymentsModule: No Controller

PaymentsModule is a service-only module. It has no HTTP controller. It exports PaymentsService for use by TransactionsModule in Story 4.2.

### Placement in schema.prisma

Insert `Transaction` model in SHARED SCHEMA section, after `Contact`:
```
// SHARED SCHEMA (shared.*)
model CatalogItem { ... @@schema("shared") }
model Category   { ... @@schema("shared") }
model Contact    { ... @@schema("shared") }
model Transaction { ... @@schema("shared") }   ← NEW HERE
```

### prisma migrate dev Is Blocked

Same constraint as all prior stories — `prisma migrate dev` is blocked in non-interactive environments. Create migration files manually:
1. Create directory: `apps/backend/prisma/migrations/20260315080000_shared_transactions/`
2. Write `migration.sql` manually (see complete SQL above)
3. Run `npx prisma generate` to validate schema

### Existing public.orders Fields Mapping

| public.orders | shared.transactions | Notes |
|---|---|---|
| `id` | `id` | Same UUID — preserves client offline sync state |
| `total_amount` | `total_amount` | Identical |
| `items_json` | `items_json` | Identical |
| `payment_method` | `payment_method` | Identical |
| `payment_splits` | `payment_splits` | Identical |
| `customer_id` | `customer_id` | Now FK → shared.contacts (Story 3.2) |
| `session_id` | `session_id` | Still FK → public.pos_sessions |
| `tenant_id` | `tenant_id` | Identical |
| `created_at` | `created_at` | Identical |
| _(new)_ | `lifecycle_type` | Set to 'instant' for all existing rows |
| _(new)_ | `transaction_type` | Set to 'sale' for all existing rows |
| _(new)_ | `updated_at` | Derived from created_at via COALESCE |

### Project Structure Notes

Files to create (no src/ changes):
```
apps/backend/prisma/
├── schema.prisma                                      [MODIFY — add Transaction model in SHARED SCHEMA]
└── migrations/
    └── 20260315080000_shared_transactions/
        └── migration.sql                              [NEW]

apps/backend/src/
└── shared/
    └── payments/
        ├── payments.service.ts                        [NEW — pure computation]
        ├── payments.service.spec.ts                   [NEW — unit tests]
        └── payments.module.ts                         [NEW — DynamicModule, no controller]
```

No changes to `src/pos/`, `src/app.module.ts`, or any existing module in this story.

### Established Patterns (apply from prior stories)

- `jest.clearAllMocks()` in `beforeEach` (not `resetAllMocks`)
- PrismaModule is `@Global()` — no explicit import needed in providers
- AuditLogService is `@Global()` via KernelModule — injectable everywhere
- EventBusService uses `publish()` not `emit()` (confirmed in Story 3.2)
- No global prefix in `main.ts` — routes at root (e.g., `/transactions/...` not `/api/v1/...`)
- DynamicModule pattern: `@Module({})` class + `static register(): DynamicModule`

### References

- [Epic 4 Story 4.1 ACs](_bmad-output/planning-artifacts/epics.md)
- [Story 1.6 AC4 — FR55 transfer_inter_tenant deferred to Story 4.1](_bmad-output/implementation-artifacts/1-6-phase3-db-anticipation-fields.md)
- [Story 2.1 — migration pattern (trigger, INSERT SELECT)](_bmad-output/implementation-artifacts/2-1-shared-schema-catalogitem-entity.md)
- [Story 3.1 — Contact model pattern (no @relation, raw tenantId)](_bmad-output/implementation-artifacts/3-1-contact-entity-migration.md)
- [Story 3.2 — DynamicModule pattern (CatalogModule, ContactsModule)](_bmad-output/implementation-artifacts/3-2-contacts-api-credit-management.md)
- [Current schema.prisma — SHARED SCHEMA section](apps/backend/prisma/schema.prisma)
- [Order model (public schema — migration source)](apps/backend/prisma/schema.prisma)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `Transaction` model added to `shared` schema after `Contact` — no `@relation` to Tenant/Contact/PosSession (raw UUID fields, consistent with CatalogItem/Contact patterns)
- `transactionType` field includes `'transfer_inter_tenant'` as documented valid value — FR55 from Story 1.6 AC4 obligation fulfilled
- `prisma generate` succeeded — `prisma.transaction` accessor available in generated client
- Migration SQL: CREATE TABLE, 2 indexes, INSERT SELECT from public.orders (lifecycle_type='instant', transaction_type='sale'), updated_at trigger
- `shared_transactions_update_updated_at()` function name distinct from other trigger functions
- No `DROP TABLE` in migration — `public.orders` preserved for backward compat (Story 4.2 handles the switch)
- `PaymentsService` is a pure computation service — no Prisma dependency, no DB calls
- `PaymentsModule` is a DynamicModule with no controller (service-only)
- FCFA rounding confirmed: `Math.round(amount / 5) * 5` — boundary cases verified in tests
- 160/160 tests pass — 13 new payments tests, zero regressions

### File List

- `apps/backend/prisma/schema.prisma` — added Transaction model in SHARED SCHEMA section
- `apps/backend/prisma/migrations/20260315080000_shared_transactions/migration.sql` — new migration
- `apps/backend/src/shared/payments/payments.service.ts` — new (pure computation)
- `apps/backend/src/shared/payments/payments.service.spec.ts` — new (13 tests)
- `apps/backend/src/shared/payments/payments.module.ts` — new (DynamicModule, no controller)
