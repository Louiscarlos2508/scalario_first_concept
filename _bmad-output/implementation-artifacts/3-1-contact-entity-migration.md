# Story 3.1: Contact Entity & Migration

Status: done

## Story

As a system architect,
I want the Customer entity migrated to a shared Contact with contactType support,
so that the contact system supports customers, suppliers, and future contact types across verticals.

## Acceptance Criteria

1. **AC1 — shared.contacts table:** Given the shared schema exists from Epic 2, when the contacts migration runs, then `shared.contacts` is created with: `id` (UUID PK), `name` (TEXT NOT NULL), `phone` (TEXT nullable), `email` (TEXT nullable), `address` (TEXT nullable), `contact_type` (TEXT NOT NULL default 'customer'), `balance` (DECIMAL(10,2) NOT NULL default 0), `tenant_id` (UUID NOT NULL), `is_deleted` (BOOLEAN NOT NULL default false), `created_at` (TIMESTAMPTZ default now()), `updated_at` (TIMESTAMPTZ default now()), `linked_tenant_id` (UUID nullable — Phase 3 Connect anticipation field from Story 1.6 AC4).

2. **AC2 — Indexes on shared.contacts:** Given the `shared.contacts` table exists, when indexes are created, then:
   - Index on `(tenant_id)` for tenant-scoped queries
   - Index on `(tenant_id, phone)` for phone lookup/dedup
   - Index on `(tenant_id, updated_at)` for delta sync queries

3. **AC3 — Data migration from public.customers:** Given existing Customer records in `public.customers`, when the migration runs, then all rows are copied to `shared.contacts` with:
   - Same UUID (preserving all existing client references)
   - `contact_type = 'customer'` for all rows
   - `balance` preserved from `public.customers.balance`
   - `is_deleted = false` for all rows (no soft-delete on customers yet)
   - `linked_tenant_id = NULL` for all rows
   - Zero data loss verified by row count

4. **AC4 — public.customers retained for backward compat:** Given existing CustomerService/CustomerController read from `public.customers`, when this migration runs, then `public.customers` remains intact and all existing Customer API endpoints continue to work unchanged. Story 3.2 handles the API switch and public.customers drop.

5. **AC5 — Prisma Contact model added to shared schema:** Given the migration is applied, when `prisma generate` runs, then:
   - `Contact` model added with `@@schema("shared")`
   - `prisma.contact` accessor is available in the generated client
   - `Customer` model in `@@schema("public")` is unchanged

6. **AC6 — updated_at auto-update trigger:** Given the `shared.contacts` table, when a row is updated via direct SQL, then `updated_at` is automatically refreshed by a DB-level trigger (consistent with `catalog_items` trigger pattern from Story 2.1).

7. **AC7 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 3.1 changes are applied, all existing tests continue to pass with zero regressions.

## Tasks / Subtasks

### Phase 1 — Prisma schema update (AC5)

- [x] **1.1** Add `Contact` model to `apps/backend/prisma/schema.prisma` in the SHARED SCHEMA section (after CatalogItem):
  ```prisma
  model Contact {
    id              String   @id @default(uuid()) @db.Uuid
    name            String
    phone           String?
    email           String?
    address         String?
    contactType     String   @default("customer") @map("contact_type")
    // Valid values: 'customer' | 'supplier' (Phase 3+)
    balance         Decimal  @default(0) @db.Decimal(10, 2)
    tenantId        String   @map("tenant_id") @db.Uuid
    isDeleted       Boolean  @default(false) @map("is_deleted")
    createdAt       DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
    updatedAt       DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)

    /// Phase 3 — Scalario Connect. Links this contact to a supplier Tenant on the B2B network.
    linkedTenantId  String?  @map("linked_tenant_id") @db.Uuid

    @@index([tenantId])
    @@index([tenantId, phone])
    @@index([tenantId, updatedAt])
    @@map("contacts")
    @@schema("shared")
  }
  ```
  **Do NOT add `@relation` to Tenant** — use raw `tenantId String` (consistent with CatalogItem pattern). Cross-schema kernel→shared `@relation` can be added later if needed.

- [x] **1.2** Run `npx prisma generate` from `apps/backend/` — verify schema is valid and `prisma.contact` accessor appears in generated types.

### Phase 2 — Migration file (AC1–AC3, AC6)

- [x] **2.1** Create directory: `apps/backend/prisma/migrations/20260315060000_shared_contacts/`

- [x] **2.2** Create `migration.sql` (see Dev Notes for complete SQL). The migration must:
  - CREATE `shared.contacts` table with all fields from AC1
  - CREATE 3 indexes from AC2
  - INSERT data from `public.customers` → `shared.contacts` (same UUIDs, contact_type='customer', is_deleted=false, linked_tenant_id=NULL)
  - CREATE `updated_at` auto-update trigger (same pattern as Story 2.1)
  - NOT drop `public.customers` (Story 3.2 handles the switch)

- [x] **2.3** Verify migration SQL: grep for `DROP TABLE` — must only appear in comments, not executable statements. `public.customers` must remain intact.

### Phase 3 — Regression check (AC7)

- [x] **3.1** Run `npx jest --no-coverage` from `apps/backend/` — verify all existing tests pass (0 regressions). Schema change is purely additive.

## Dev Notes

### Scope Boundary — What Story 3.1 Does NOT Do

| Out of Scope | When | Story |
|---|---|---|
| ContactsService + REST API | Story 3.2 | When contacts endpoints built |
| Delta sync endpoint | Story 3.2 | Part of contacts API |
| Drop `public.customers` | Story 3.2 | After API switch |
| CustomerController proxy to ContactsService | Story 3.2 | After API built |
| ContactsModule DynamicModule registration | Story 3.2 | When module built |
| RLS policy on shared.contacts | Story 3.2+ | After API |
| Supplier contact type (`contact_type='supplier'` usage) | Epic 5 | Inventory module |
| `linked_tenant_id` FK activation | Phase 3 | Scalario Connect epic |

### Critical: linked_tenant_id MUST Be Included Here

Story 1.6 AC4 explicitly deferred this field to Story 3.1:
> `shared.contacts.linked_tenant_id` — add when `Contact` model is created in Epic 3, Story 3-1

From Story 1.6 Completion Notes:
> `contacts.linked_tenant_id` ... deferred to Epics 2–4 (models don't exist yet). Cross-references documented in story Dev Notes.

This field is a Phase 3 Scalario Connect anticipation field. Like `catalog_items.supplier_reference`, it must be included at model creation time to avoid a breaking migration at Phase 3 launch.

### contactType Discriminator

String field (not Prisma enum — same pattern as `itemType` in CatalogItem):

| Value | Description | When |
|---|---|---|
| `'customer'` | Regular customer / buyer | MVP — all migrated rows |
| `'supplier'` | Supplier / vendor | Phase 3 — Scalario Connect |

All existing `public.customers` rows → `contact_type = 'customer'`.

### Migration SQL — Complete Reference

```sql
-- Story 3.1: Create shared.contacts table
-- Migrates existing public.customers → shared.contacts (same UUIDs)
-- public.customers remains intact for backward compat until Story 3.2
-- shared schema already exists from Story 2.1

-- Step 1: Create shared.contacts table
CREATE TABLE "shared"."contacts" (
    "id"               UUID            NOT NULL DEFAULT gen_random_uuid(),
    "name"             TEXT            NOT NULL,
    "phone"            TEXT,
    "email"            TEXT,
    "address"          TEXT,
    "contact_type"     TEXT            NOT NULL DEFAULT 'customer',
    "balance"          DECIMAL(10,2)   NOT NULL DEFAULT 0,
    "tenant_id"        UUID            NOT NULL,
    "is_deleted"       BOOLEAN         NOT NULL DEFAULT false,
    "created_at"       TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"       TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Phase 3 — Scalario Connect: links this contact to a supplier Tenant on the B2B network
    "linked_tenant_id" UUID,

    CONSTRAINT "contacts_pkey" PRIMARY KEY ("id")
);

-- Step 2: Indexes (NFR: delta sync, tenant isolation, phone lookup)
CREATE INDEX "contacts_tenant_id_idx"
    ON "shared"."contacts"("tenant_id");

CREATE INDEX "contacts_tenant_id_phone_idx"
    ON "shared"."contacts"("tenant_id", "phone");

CREATE INDEX "contacts_tenant_id_updated_at_idx"
    ON "shared"."contacts"("tenant_id", "updated_at");

-- Step 3: Data migration — copy public.customers → shared.contacts
-- Preserves UUIDs so existing client sync state remains valid
INSERT INTO "shared"."contacts" (
    "id",
    "name",
    "phone",
    "email",
    "address",
    "contact_type",
    "balance",
    "tenant_id",
    "is_deleted",
    "created_at",
    "updated_at",
    "linked_tenant_id"
)
SELECT
    "id",
    "name",
    "phone",
    "email",
    "address",
    'customer'  AS "contact_type",
    "balance",
    "tenant_id",
    false       AS "is_deleted",
    "created_at",
    "updated_at",
    NULL        AS "linked_tenant_id"
FROM "public"."customers";

-- Step 4: updated_at auto-update trigger (consistent with catalog_items pattern)
CREATE OR REPLACE FUNCTION shared_contacts_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER "contacts_updated_at_trigger"
    BEFORE UPDATE ON "shared"."contacts"
    FOR EACH ROW EXECUTE FUNCTION shared_contacts_update_updated_at();

-- NOTE: public.customers is NOT dropped (backward compat — Story 3.2 handles the switch)
-- NOTE: linked_tenant_id is nullable, no FK constraint (Phase 3 Connect — no target table yet)
-- NOTE: RLS policy on contacts added in Story 3.2 with full contacts API
```

### Placement in schema.prisma

Insert `Contact` model in the SHARED SCHEMA section, after `CatalogItem`:

```
// KERNEL SCHEMA (kernel.*)
model Tenant { ... }
...
model AuditLog { ... }

// SHARED SCHEMA (shared.*)
model CatalogItem { ... @@schema("shared") }
model Contact { ... @@schema("shared") }   ← NEW HERE

// PUBLIC SCHEMA (public.*)
model Category { ... @@schema("shared") }  ← moved in Story 2.2
model Product { ... @@schema("public") }
model Order { ... }
model PosSession { ... }
model StockMovement { ... }
model Customer { ... @@schema("public") }  ← unchanged until Story 3.2
model TerminalStatus { ... }
```

### Existing Customer Model — What Maps to Contact

| public.customers | shared.contacts | Notes |
|---|---|---|
| `id` | `id` | Same UUID — preserves client sync state |
| `name` | `name` | Identical |
| `phone` | `phone` | Identical |
| `email` | `email` | Identical |
| `address` | `address` | Identical |
| `balance` | `balance` | Identical (Decimal 10,2) |
| `tenant_id` | `tenant_id` | Identical UUID |
| `created_at` | `created_at` | Identical |
| `updated_at` | `updated_at` | Identical |
| _(new)_ | `contact_type` | Set to 'customer' for all existing rows |
| _(new)_ | `is_deleted` | Set to false for all existing rows |
| _(new)_ | `linked_tenant_id` | NULL for all existing rows |

### prisma migrate dev Is Blocked

Same constraint as Stories 1.6, 2.1, 2.2 — `prisma migrate dev` is blocked in non-interactive environments. Create migration files manually:
1. Create directory: `apps/backend/prisma/migrations/20260315060000_shared_contacts/`
2. Write `migration.sql` manually (see complete SQL above)
3. Run `npx prisma generate` to validate schema

### Naming: Function Name Uniqueness

The updated_at trigger function is named `shared_contacts_update_updated_at` (distinct from `shared_update_updated_at_column` used for catalog_items in Story 2.1) to avoid naming conflicts in PostgreSQL. Each table can share a function if desired, but unique function names avoid cross-table dependency issues.

### Project Structure Notes

Files to modify/create:
```
apps/backend/prisma/
├── schema.prisma                                      [MODIFY — add Contact model in SHARED SCHEMA section]
└── migrations/
    └── 20260315060000_shared_contacts/
        └── migration.sql                              [NEW]
```

No changes to `src/` — no controllers, services, or modules.

### References

- [Architecture §5.3 Shared Contacts module](docs/architecture-scalario-2026-03-08.md)
- [Epic 3 Story 3.1 ACs](_bmad-output/planning-artifacts/epics.md)
- [Story 1.6 AC4 — linked_tenant_id deferred to Story 3.1](_bmad-output/implementation-artifacts/1-6-phase3-db-anticipation-fields.md)
- [Story 2.1 — migration pattern reference (trigger, INSERT SELECT, UUID preservation)](_bmad-output/implementation-artifacts/2-1-shared-schema-catalogitem-entity.md)
- [Customer model (public schema baseline)](apps/backend/prisma/schema.prisma)
- [CustomerService (proxy source for Story 3.2)](apps/backend/src/pos/customer.service.ts)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `Contact` model added to `shared` schema after `CatalogItem` — no `@relation` to Tenant (raw tenantId String, consistent with CatalogItem pattern)
- `prisma generate` succeeded — `prisma.contact` accessor available in generated client
- Migration SQL matches the Dev Notes reference exactly: CREATE TABLE, 3 indexes, INSERT SELECT from public.customers, updated_at trigger
- `shared_contacts_update_updated_at()` function name distinct from `shared_update_updated_at_column` (catalog_items) to avoid cross-table dependency
- No `DROP TABLE` in migration — `public.customers` preserved for backward compat (Story 3.2 handles the switch)
- `linked_tenant_id` included as nullable UUID with no FK constraint — Phase 3 anticipation field per Story 1.6 AC4 obligation
- 133/133 tests pass — schema change is purely additive, zero regressions

### File List

- `apps/backend/prisma/schema.prisma` — added Contact model in SHARED SCHEMA section
- `apps/backend/prisma/migrations/20260315060000_shared_contacts/migration.sql` — new migration
