# Story 9.1: Migration Scripts & Dry Run Validation

Status: review

## Story

As a platform administrator,
I want migration scripts that move all data from public schema to kernel/shared/retail with rollback capability,
So that we can validate the migration on a cloned database before touching production.

## Acceptance Criteria

1. **AC1 — Full data migration:** Given the complete multi-schema architecture is deployed (Epics 1–8), when the migration script runs on a cloned production database, then all data is moved:
   - `public.products` → `shared.catalog_items` + `retail.retail_products`
   - `public.pos_sessions` schema annotation updated (data already compatible with new references)
   - `public.terminal_statuses` preserved / migrated to retail schema if applicable
   - All existing `shared.transactions`, `shared.contacts`, `shared.stock_movements`, `kernel.*` tables already populated by incremental Epics 1–8 — no re-migration needed for those.

2. **AC2 — Zero data loss verification:** Given the migration script completes, when row counts are compared (source vs destination), then every migrated table has identical row counts with zero data loss, and referential integrity is verified across all FK relationships.

3. **AC3 — Rollback on failure:** Given a migration step fails, when the rollback is triggered, then the database returns to its pre-migration state — old tables are intact, new tables are dropped/reverted.

4. **AC4 — Dry run report:** Given the dry run passes on the cloned database, when the migration report is generated, then it shows: tables migrated, row counts (source → destination), FK integrity status, estimated production migration time, and any warnings.

5. **AC5 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 9.1 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — Migration script: public.products → shared + retail (AC1)

- [x] **1.1** Create `apps/backend/scripts/migrate-products.ts`:
  - For each `public.products` row: upsert a `CatalogItem` (shared.catalog_items) with same id, name, price, tenantId, barcode, categoryId, createdAt
  - Upsert a `RetailProduct` (retail.retail_products) with catalogItemId = product.id, stockQuantity = product.stockQuantity
  - Use Prisma `upsert` (idempotent — safe to re-run)
  - Wrap in `prisma.$transaction` for atomicity per product

- [x] **1.2** Add dry-run flag: when `--dry-run` is passed, compute what would be migrated and print a preview without writing to DB.

### Phase 2 — Validation & report (AC2, AC4)

- [x] **2.1** Create `apps/backend/scripts/validate-migration.ts`:
  - Compare row counts: `public.products` vs `shared.catalog_items` + `retail.retail_products`
  - Verify FK integrity: every `RetailProduct.catalogItemId` exists in `catalog_items`; every `RetailSale.transactionId` exists in `transactions`; every `RetailSale.sessionId` exists in `pos_sessions`
  - Print structured report: table name, source count, destination count, status (OK / MISMATCH / FK_ERROR), warnings

- [x] **2.2** Print timing estimate: record wall-clock time of migration script; extrapolate for production row counts.

### Phase 3 — Rollback (AC3)

- [x] **3.1** Create `apps/backend/scripts/rollback-migration.ts`:
  - Delete all `retail.retail_products` rows whose `catalogItemId` was created during migration (i.e., ids matching `public.products`)
  - Delete corresponding `shared.catalog_items` rows
  - Print rollback report: rows deleted per table

### Phase 4 — Tests (AC4, AC5)

- [x] **4.1** Create `apps/backend/src/migration/migration-utils.spec.ts` (collocated test for the migration logic):
  - Unit test `buildMigrationReport()`: given mock source/destination counts, returns correct report structure
  - Unit test `validateFkIntegrity()`: detects missing FK references
  - Unit test row count comparison: MISMATCH detected when counts differ

- [x] **4.2** Run `npx jest --no-coverage` — all tests pass (277/277).

## Dev Notes

### Current schema state (as of Epic 8 completion)

The Prisma schema (`apps/backend/prisma/schema.prisma`) has:
- `@@schema("kernel")`: Tenant, OrganizationMember, Role, Permission, RolePermission, Module, TenantModule, AuditLog
- `@@schema("shared")`: CatalogItem, Category, Contact, Transaction, InventoryMovement
- `@@schema("public")` (legacy — still present): Product, PosSession, TerminalStatus
- `@@schema("retail")`: RetailProduct, RetailSale

**Key insight:** `public.pos_sessions` is already used by the new code (PosSession referenced by RetailSale). It stays in `public` schema until 9.2 removes it after full cleanup. Do NOT attempt to move PosSession data — it is already live.

### Product migration mapping

```
public.products (per row):
  → shared.catalog_items:
      id = product.id
      name = product.name
      price = product.price
      tenantId = product.tenantId
      barcode = product.barcode
      categoryId = product.categoryId
      createdAt = product.createdAt
      type = 'physical'   ← default for retail products

  → retail.retail_products:
      id = uuid()         ← new id
      catalogItemId = product.id
      stockQuantity = product.stockQuantity
      minStockLevel = null
      createdAt = product.createdAt
```

### Script execution pattern

```bash
# Dry run (no writes):
npx ts-node apps/backend/scripts/migrate-products.ts --dry-run

# Real migration on clone:
DATABASE_URL=<clone_url> npx ts-node apps/backend/scripts/migrate-products.ts

# Validate after migration:
DATABASE_URL=<clone_url> npx ts-node apps/backend/scripts/validate-migration.ts

# Rollback if needed:
DATABASE_URL=<clone_url> npx ts-node apps/backend/scripts/rollback-migration.ts
```

### Idempotency requirement

Scripts must be safe to re-run. Use `upsert` (not `create`) for CatalogItem and RetailProduct inserts, keyed on `id`.

### PrismaClient instantiation in scripts

Scripts are run outside NestJS context. Instantiate directly:
```typescript
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() { ... }
main().finally(() => prisma.$disconnect());
```

### References

- [Story 2.1 — CatalogItem entity](2-1-shared-schema-catalogitem-entity.md)
- [Story 6.1 — RetailProduct entity](6-1-retail-schema-product-extensions.md)
- [Story 6.2 — RetailSale entity](6-2-retailsale-extensions-session-scoping.md)
- [epics.md — Epic 9 AC](../../planning-artifacts/epics.md)
- Prisma schema: `apps/backend/prisma/schema.prisma`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- **Architecture decision:** Pure logic functions extracted to `src/migration/migration-utils.ts` so they can be unit-tested with Jest without a DB connection. Scripts in `scripts/` import from this module.
- **`migrate-products.ts`:** Iterates `public.products`, upserts each into `shared.catalog_items` (preserving same `id`) + `retail.retail_products` (with `catalogItemId = product.id`). Uses `prisma.$transaction` per product for atomicity. Idempotent (upsert, not insert).
- **`--dry-run` flag:** Detected via `process.argv.includes('--dry-run')`. Prints preview of what would migrate without touching DB (AC4 dry run).
- **`validate-migration.ts`:** Compares row counts (public.products vs catalog_items, retail_products). Runs 3 FK integrity `$queryRaw` checks (retail_products→catalog_items, retail_sales→transactions, retail_sales→pos_sessions). Prints formatted report with timing.
- **`rollback-migration.ts`:** Safe rollback — collects IDs from `public.products`, deletes child `retail_products` first (FK order), then `catalog_items`. Does NOT touch rows pre-existing before migration.
- **`migration-utils.ts`:** Pure functions: `compareRowCounts()`, `buildMigrationReport()`, `validateFkIntegrity()`, `formatReport()`. No DB dependency.
- **14 new unit tests** in `migration-utils.spec.ts` cover all pure functions. 277/277 total tests pass, 0 regressions.

### File List

- `apps/backend/src/migration/migration-utils.ts` [NEW — pure logic, testable]
- `apps/backend/src/migration/migration-utils.spec.ts` [NEW — 14 unit tests]
- `apps/backend/scripts/migrate-products.ts` [NEW — main migration script]
- `apps/backend/scripts/validate-migration.ts` [NEW — row count + FK integrity validation]
- `apps/backend/scripts/rollback-migration.ts` [NEW — safe rollback]

## Change Log

- 2026-03-15: Story 9.1 created — migration scripts (products → catalog_items + retail_products), dry run validation, rollback, row-count report.
- 2026-03-15: Story 9.1 implemented — migrate-products.ts (idempotent upsert, --dry-run), validate-migration.ts (row counts + 3 FK checks), rollback-migration.ts (safe, FK-ordered delete), migration-utils.ts (pure logic + 14 unit tests), 277/277 tests pass.
