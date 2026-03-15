# Story 2.1: Shared Schema & CatalogItem Entity

Status: review

## Story

As a system architect,
I want the Product entity decomposed into a shared CatalogItem with a polymorphic type discriminator,
so that any vertical can extend the base catalog without touching shared code.

## Acceptance Criteria

1. **AC1 — shared schema + catalog_items table:** Given the kernel schema exists from Epic 1, when the shared catalog migration runs, then the `shared` schema is created and the `catalog_items` table contains: `id` (UUID PK), `name` (TEXT), `price` (Decimal 10,2), `barcode` (TEXT nullable), `item_type` (TEXT default 'physical'), `category_id` (UUID nullable — raw FK, no constraint yet), `tenant_id` (UUID NOT NULL), `is_deleted` (BOOLEAN default false), `created_at` (TIMESTAMPTZ), `updated_at` (TIMESTAMPTZ), `supplier_reference` (UUID nullable — Phase 3 Connect anticipation field from Story 1.6).

2. **AC2 — Data migration from public.products:** Given existing `public.products` records, when the migration runs, then all rows are copied to `shared.catalog_items` with: same UUID (preserving all existing client references), `item_type = 'physical'` (all existing products are physical), `supplier_reference = NULL`. Zero data loss verified by row count assertion in migration.

3. **AC3 — Indexes created:** Given the `catalog_items` table exists, when indexes are created, then:
   - `(tenant_id, updated_at)` index exists for delta sync queries
   - `(tenant_id, category_id)` index exists for product grid filtering
   - `(barcode)` index exists for barcode scan lookup

4. **AC4 — Prisma datasource updated:** Given the multi-schema Prisma setup, when `prisma generate` runs, then the datasource `schemas` array includes `"shared"` and the generated Prisma client exposes `prisma.catalogItem` as an accessor.

5. **AC5 — Backward compat: public.products unchanged:** Given existing POS endpoints read from `public.products`, when this migration runs, then the `public.products` table remains intact with all existing data. No controller, service, or guard is modified. The old Product model stays in schema.prisma — Story 2.2 handles the API switch.

6. **AC6 — Regression: 0 test failures:** Given the existing test suite (110 tests), when Story 2.1 changes are applied, then all 110 tests continue to pass with zero regressions.

## Tasks / Subtasks

### Phase 1 — Prisma schema update

- [x] **1.1** Update `apps/backend/prisma/schema.prisma` datasource block — add `"shared"` to the `schemas` array:
  - Change: `schemas = ["kernel", "public"]`
  - To: `schemas = ["kernel", "shared", "public"]`

- [x] **1.2** Add `CatalogItem` model to `apps/backend/prisma/schema.prisma` with `@@schema("shared")` — insert between the kernel section and the public models:

  ```prisma
  // ═══════════════════════════════════════════
  // SHARED SCHEMA
  // ═══════════════════════════════════════════

  model CatalogItem {
    id                String   @id @default(uuid()) @db.Uuid
    name              String
    price             Decimal  @db.Decimal(10, 2)
    barcode           String?
    itemType          String   @default("physical") @map("item_type")
    // Valid values: 'physical' | 'bookable' | 'service'
    categoryId        String?  @map("category_id") @db.Uuid
    // Raw FK — no @relation yet; Category moves to shared in Story 2.2
    tenantId          String   @map("tenant_id") @db.Uuid
    isDeleted         Boolean  @default(false) @map("is_deleted")
    createdAt         DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
    updatedAt         DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)

    /// Phase 3 — Scalario Connect. Supplier's reference ID for this item on the B2B network.
    supplierReference String?  @map("supplier_reference") @db.Uuid

    @@index([tenantId, updatedAt])
    @@index([tenantId, categoryId])
    @@index([barcode])
    @@map("catalog_items")
    @@schema("shared")
  }
  ```

  **Do NOT add `@relation` to Category or StockMovement** — those cross-schema relations come in Stories 2.2 and 5.x respectively.

- [x] **1.3** Run `npx prisma generate` to verify the schema is valid and regenerate the Prisma client. Confirm `prisma.catalogItem` accessor is available in the generated types.

### Phase 2 — Migration file

- [x] **2.1** Create migration directory: `apps/backend/prisma/migrations/20260315040000_shared_schema_catalogitem/`

- [x] **2.2** Create `migration.sql` in that directory with the following content (see Dev Notes for exact SQL). The migration must:
  - Create `shared` schema
  - Create `shared.catalog_items` table with all fields from AC1
  - Copy data from `public.products` → `shared.catalog_items` (same UUIDs, item_type='physical')
  - Create the 3 indexes from AC3
  - Include a row count assertion comment (verification step)

- [x] **2.3** Verify the migration SQL is correct: no DROP TABLE on `public.products`, no schema removal, only ADD operations. `public.products` remains intact.

### Phase 3 — Regression tests

- [x] **3.1** Run `npx jest --no-coverage` from `apps/backend/` — verify 110/110 tests pass. The schema changes are additive; existing mocks and services are untouched.

## Dev Notes

### Scope Boundary — What Story 2.1 Does NOT Do

| Out of Scope | When | Story |
|---|---|---|
| `shared.categories` table | Story 2.2 | When Category API is built |
| `CatalogService` + REST API | Story 2.2 | When endpoints are implemented |
| Delta sync endpoint | Story 2.3 | When sync adapter is built |
| `RetailProduct` model | Epic 6 | Vertical extension |
| Remove `public.products` | Story 2.2 | After API switch |
| Remove `public.categories` | Story 2.2 | After API switch |
| `@relation` on `categoryId` | Story 2.2 | After `shared.categories` exists |
| `StockMovement` → `CatalogItem` relation | Epic 5 | Inventory module |
| RLS policy on `catalog_items` | Story 2.2 | With full catalog API |

### Critical: supplier_reference MUST Be Included Here

Story 1.6 explicitly deferred `catalog_items.supplier_reference` to Story 2.1 (because `CatalogItem` didn't exist yet). This field **must be included** in this migration to honor the Phase 3 zero-breaking-migration guarantee.

From Story 1.6 Completion Notes:
> `contacts.linked_tenant_id`, `catalog_items.supplier_reference`, `transactions.transfer_inter_tenant` deferred to Epics 2–4 (models don't exist yet).

### Prisma datasource — Adding "shared" Schema

Current datasource (from Story 1.6):
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  schemas  = ["kernel", "public"]
}
```

Target (Story 2.1):
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  schemas  = ["kernel", "shared", "public"]
}
```

**Order matters for Prisma migration processing.** `shared` between `kernel` and `public` matches the architecture dependency order.

### CatalogItem Model Placement in schema.prisma

Insert the new SHARED SCHEMA section between the kernel section and the public models. The file structure should be:

```
// KERNEL SCHEMA (lines 12–134, unchanged)
model Tenant { ... }
model OrganizationMember { ... }
...
model AuditLog { ... }

// SHARED SCHEMA (NEW — Story 2.1)
model CatalogItem { ... @@schema("shared") }

// PUBLIC SCHEMA (unchanged)
model Category { ... @@schema("public") }   // stays public until Story 2.2
model Product { ... @@schema("public") }    // stays public until Story 2.2
...
```

### Category FK — No @relation in Story 2.1

`CatalogItem.categoryId` is a raw `String?` without a Prisma `@relation`. This is intentional:
- `Category` is still in `public` schema (not `shared`) during Story 2.1
- Cross-schema FK from `shared.catalog_items` → `public.categories` would work at DB level but is architecturally wrong
- Story 2.2 moves `Category` to `shared` schema AND adds the `@relation` on both models simultaneously

No `@relation` = no Prisma join validation on `categoryId`, which is fine since it's nullable and existing Category UUIDs are valid.

### Migration SQL — Complete Reference

```sql
-- Story 2.1: Create shared schema and catalog_items table
-- Migrates existing public.products → shared.catalog_items (same UUIDs)
-- public.products remains intact for backward compat until Story 2.2

-- Step 1: Create shared schema
CREATE SCHEMA IF NOT EXISTS "shared";

-- Step 2: Create catalog_items table
CREATE TABLE "shared"."catalog_items" (
    "id"                 UUID        NOT NULL DEFAULT gen_random_uuid(),
    "name"               TEXT        NOT NULL,
    "price"              DECIMAL(10,2) NOT NULL,
    "barcode"            TEXT,
    "item_type"          TEXT        NOT NULL DEFAULT 'physical',
    "category_id"        UUID,
    "tenant_id"          UUID        NOT NULL,
    "is_deleted"         BOOLEAN     NOT NULL DEFAULT false,
    "created_at"         TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"         TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "supplier_reference" UUID,

    CONSTRAINT "catalog_items_pkey" PRIMARY KEY ("id")
);

-- Step 3: Data migration — copy public.products → shared.catalog_items
-- Preserves UUIDs so existing client references (sync state) remain valid
INSERT INTO "shared"."catalog_items" (
    "id", "name", "price", "barcode",
    "item_type", "category_id", "tenant_id",
    "is_deleted", "created_at", "updated_at",
    "supplier_reference"
)
SELECT
    "id",
    "name",
    "price",
    "barcode",
    'physical'   AS "item_type",
    "category_id",
    "tenant_id",
    "is_deleted",
    "created_at",
    "updated_at",
    NULL         AS "supplier_reference"
FROM "public"."products"
WHERE "is_deleted" = false OR "is_deleted" = true;  -- Include all rows, even soft-deleted

-- Step 4: Create indexes for performance (NFR1: barcode <100ms, delta sync)
CREATE INDEX "catalog_items_tenant_id_updated_at_idx"
    ON "shared"."catalog_items"("tenant_id", "updated_at");

CREATE INDEX "catalog_items_tenant_id_category_id_idx"
    ON "shared"."catalog_items"("tenant_id", "category_id");

CREATE INDEX "catalog_items_barcode_idx"
    ON "shared"."catalog_items"("barcode");

-- Step 5: Update trigger for updated_at (auto-update on row change)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER "catalog_items_updated_at"
    BEFORE UPDATE ON "shared"."catalog_items"
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- NOTE: public.products is NOT dropped — backward compat until Story 2.2
-- NOTE: RLS policy added in Story 2.2 with full catalog API
-- NOTE: supplier_reference is nullable with no FK constraint (Phase 3 Connect — no tenants table yet in Connect)
```

**CRITICAL:** Do NOT include any DROP TABLE, DROP SCHEMA, or breaking changes. This migration is purely additive.

### Existing Product Model — What Maps to CatalogItem

Current `public.products` fields vs target `shared.catalog_items`:

| public.products | shared.catalog_items | Notes |
|---|---|---|
| `id` | `id` | Same UUID — preserves client sync state |
| `name` | `name` | Identical |
| `price` | `price` | Identical (Decimal 10,2) |
| `barcode` | `barcode` | Identical |
| `category_id` | `category_id` | Identical UUID |
| `tenant_id` | `tenant_id` | Identical UUID |
| `is_deleted` | `is_deleted` | Identical |
| `created_at` | `created_at` | Identical |
| `updated_at` | `updated_at` | Identical |
| `stock_quantity` | _(not migrated)_ | Goes to `RetailProduct` in Epic 6 |
| _(new)_ | `item_type` | Set to 'physical' for all existing rows |
| _(new)_ | `supplier_reference` | NULL for all existing rows |

`stock_quantity` from `public.products` is intentionally NOT copied to `catalog_items` — it belongs in `RetailProduct` (Epic 6 extension table). The existing `public.products.stock_quantity` data remains in place until Epic 6.

### itemType Discriminator

`item_type` is a String field with 3 valid values (not a Prisma enum — uses String for flexibility):

| Value | Description | Stock Tracking | Retail Use |
|---|---|---|---|
| `'physical'` | Tangible product | Yes (StockMovement) | Default for all MVP products |
| `'bookable'` | Appointment/service | No | Phase 2+ (calendar UI) |
| `'service'` | Intangible fee | No | Phase 2+ (fee selector) |

All existing products from `public.products` get `item_type = 'physical'`.

### Learnings from Story 1.6 (apply here)

- **`prisma migrate dev` is blocked** in non-interactive environment. Use `prisma migrate diff --script` to verify SQL, then create migration file manually.
- **Migration naming:** Use `YYYYMMDDHHMMSS_description` format. Previous: `20260315030000_phase3_anticipation_fields`. This story: `20260315040000_shared_schema_catalogitem`.
- **`prisma generate` works fine** — run it after updating schema.prisma to verify no syntax errors and regenerate client types.
- **Self-referential or cross-schema FKs** — store as raw `String?` without `@relation` to avoid Prisma validation issues. Add `@relation` when both models are in the same schema.
- **Schema-only stories have 0 regressions** — existing mock-based unit tests are unaffected by additive schema changes.

### Prisma Multi-Schema: shared vs public

Currently in schema.prisma, `Category` and `Product` use `@@schema("public")`. Do NOT change those models in Story 2.1. They will be updated in Story 2.2 (Category → `@@schema("shared")`) and Story 6 (Product decomposed into CatalogItem + RetailProduct).

The `shared` schema in PostgreSQL must be explicitly created by the migration (`CREATE SCHEMA IF NOT EXISTS "shared"`) before tables can be created in it.

### StockMovement Cross-Reference

The current `StockMovement` model references `Product` via `productId`. This remains unchanged in Story 2.1. In Epic 5 (Inventory Module), `StockMovement` will be updated to reference `CatalogItem` (shared) instead of `Product` (public).

### Project Structure Notes

Files to modify/create:
```
apps/backend/prisma/
├── schema.prisma                          [MODIFY — add "shared" to datasource + add CatalogItem model]
└── migrations/
    └── 20260315040000_shared_schema_catalogitem/
        └── migration.sql                  [NEW — CREATE SCHEMA + CREATE TABLE + data migration]
```

No other files. Not `src/`, not any controller/service/module.

### References

- Architecture §5.1 (Shared schema + CatalogItem model): `docs/architecture-scalario-2026-03-08.md`
- Architecture §5.3 (Multi-schema datasource): `docs/architecture-scalario-2026-03-08.md`
- Architecture §6.1 (Cross-schema relations): `docs/architecture-scalario-2026-03-08.md`
- Architecture §AD8 (Phase 3 anticipation — supplier_reference): `docs/architecture-scalario-2026-03-08.md`
- Story 1.6 deferred fields: `_bmad-output/implementation-artifacts/1-6-phase3-db-anticipation-fields.md` (Completion Notes)
- Epic 2 ACs: `_bmad-output/planning-artifacts/epics.md` (Story 2.1 section)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Schema-only story — 0 service/guard/controller changes, 0 new test files.
- **AC1 (shared schema + catalog_items):** `shared` schema added to datasource. `CatalogItem` model added with all required fields: `id`, `name`, `price`, `barcode`, `itemType` (default 'physical'), `categoryId` (raw String? — no relation), `tenantId`, `isDeleted`, `createdAt`, `updatedAt`, `supplierReference` (Phase 3).
- **AC2 (data migration):** Migration SQL includes `INSERT INTO shared.catalog_items SELECT ... FROM public.products` preserving UUIDs. `stock_quantity` intentionally excluded (belongs in RetailProduct, Epic 6).
- **AC3 (indexes):** 3 indexes created: `(tenantId, updatedAt)`, `(tenantId, categoryId)`, `(barcode)`.
- **AC4 (datasource updated):** `schemas = ["kernel", "shared", "public"]`. `prisma generate` succeeded — `prisma.catalogItem` accessor confirmed available.
- **AC5 (public.products intact):** No DROP on `public.products`. Migration is purely additive. Existing services continue to read from `public.products` unchanged.
- **AC6 (0 regressions):** 110/110 tests passing.
- **supplier_reference:** Included as nullable UUID with `///` Phase 3 comment — fulfills Story 1.6 deferred obligation.
- **categoryId as raw String?:** No `@relation` to `Category` — Category remains in `public` schema until Story 2.2. Cross-schema FK constraint added in Story 2.2.
- **Migration note:** `prisma migrate dev` blocked in non-interactive env. Created migration file manually. Used `grep` to confirm zero executable DROP/TRUNCATE/ALTER DROP statements.
- **updated_at trigger:** DB-level trigger added (`shared_update_updated_at_column`) as backup to Prisma `@updatedAt` for direct SQL updates.

### File List

**Modified files:**
- `apps/backend/prisma/schema.prisma` — added `"shared"` to datasource schemas array; added `CatalogItem` model with `@@schema("shared")` in new SHARED SCHEMA section

**New files:**
- `apps/backend/prisma/migrations/20260315040000_shared_schema_catalogitem/migration.sql` — CREATE SCHEMA, CREATE TABLE, data migration INSERT, 3 indexes, updated_at trigger
