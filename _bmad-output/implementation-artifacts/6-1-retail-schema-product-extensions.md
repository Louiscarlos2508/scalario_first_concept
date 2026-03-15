# Story 6.1: Retail Schema & Product Extensions

Status: review

## Story

As a system architect,
I want the retail-specific product fields extracted into a RetailProduct extension table,
so that the shared CatalogItem stays clean and other verticals can add their own extensions.

## Acceptance Criteria

1. **AC1 — retail schema + retail_products table:** Given the shared catalog_items table exists, when the retail schema migration runs, then the `retail` schema is created with `retail_products` table containing: `id`, `catalog_item_id` (unique FK → catalog_items), `stock_quantity` (Decimal 10,2, default 0), `weight_unit` (nullable, for future weight-based sales), `min_stock_level` (nullable, Decimal 10,2).

2. **AC2 — Data migration from public.products:** Given existing Product records that had stock-related fields, when the data migration runs, then RetailProduct records are created for each CatalogItem with `stock_quantity` and `min_stock_level` values migrated from the old Product model. Zero data loss verified.

3. **AC3 — GET /api/v1/catalog/items joins RetailProduct:** Given a `GET /api/v1/catalog/items` request from a retail tenant, when the API response is built, then the response joins CatalogItem + RetailProduct and returns a flat object (name, price, barcode, stockQuantity, weightUnit, minStockLevel) — the client stores this denormalized shape directly in Isar.

4. **AC4 — Regression: 0 failures on existing tests:** Given the existing test suite, when Story 6.1 changes are applied, all existing tests continue to pass.

## Tasks / Subtasks

### Phase 1 — Database: retail schema + retail_products migration (AC1, AC2)

- [x] **1.1** Add `retail` schema datasource to `apps/backend/prisma/schema.prisma`:
  - Add `retail` to the `schemas` array in the datasource block
  - Add `RetailProduct` model with `@@schema("retail")`:
    ```prisma
    model RetailProduct {
      id            String      @id @default(uuid())
      catalogItemId String      @unique
      catalogItem   CatalogItem @relation(fields: [catalogItemId], references: [id])
      stockQuantity Decimal     @default(0) @db.Decimal(10, 2)
      weightUnit    String?
      minStockLevel Decimal?    @db.Decimal(10, 2)
      createdAt     DateTime    @default(now())
      updatedAt     DateTime    @updatedAt
      @@map("retail_products")
      @@schema("retail")
    }
    ```
  - Add `retailProduct RetailProduct?` relation to `CatalogItem` model

- [x] **1.2** Create manual SQL migration `apps/backend/prisma/migrations/20260315120000_retail_schema_retail_products/migration.sql`:
  ```sql
  CREATE SCHEMA IF NOT EXISTS retail;

  CREATE TABLE retail.retail_products (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    catalog_item_id UUID NOT NULL UNIQUE REFERENCES shared.catalog_items(id) ON DELETE CASCADE,
    stock_quantity  DECIMAL(10,2) NOT NULL DEFAULT 0,
    weight_unit     TEXT,
    min_stock_level DECIMAL(10,2),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
  );

  CREATE INDEX ON retail.retail_products (catalog_item_id);
  ```

- [x] **1.3** Create data migration `apps/backend/prisma/migrations/20260315130000_migrate_product_stock_to_retail/migration.sql`:
  - Joins `shared.catalog_items` to `public.products` by (name, tenantId) to create RetailProduct rows
  - Uses `DO $$ ... $$` block with `GET DIAGNOSTICS` to log migrated and skipped counts
  - Zero data loss: only skips CatalogItems with no matching Product (no stock data to migrate)

### Phase 2 — Prisma: RetailProduct model + CatalogModule join (AC3)

- [x] **2.1** Updated `CatalogService.getItems()` in `apps/backend/src/shared/catalog/catalog.service.ts`:
  - Added `include: { retailProduct: true }` to `findMany` call
  - Maps each item to flatten RetailProduct fields: `stockQuantity`, `weightUnit`, `minStockLevel` (null if no RetailProduct)
  - Removes nested `retailProduct` object from response (denormalized flat shape)

- [x] **2.2** Catalog item response now returns flat shape with retail fields included.

### Phase 3 — Tests (AC3, AC4)

- [x] **3.1** Updated `catalog.service.spec.ts`:
  - Updated existing test: mock includes `retailProduct: null`; assertion updated to flat shape with null retail fields
  - Added test: flattens RetailProduct fields when retailProduct exists (stockQuantity: 42.5, minStockLevel: 10)
  - Added test: returns null retail fields when no RetailProduct (service items type = 'service' etc.)

- [x] **3.2** Run `npx jest --no-coverage` — 215/215 tests pass, 0 regressions (AC4).

## Dev Notes

### retail schema in Prisma multiSchema

The datasource already uses `schemas = ["kernel", "shared", "public"]`. Added `"retail"` as fourth schema.

Models in the retail schema use `@@schema("retail")`.

### Prisma relation across schemas

Prisma supports cross-schema relations in multiSchema mode. The `CatalogItem` model (in `@@schema("shared")`) has a relation to `RetailProduct` (in `@@schema("retail")`).

### Flat response shape for Isar

The Flutter client stores catalog items denormalized in Isar. The API returns:
```json
{
  "id": "...",
  "name": "Coca-Cola 50cl",
  "price": 500,
  "barcode": "...",
  "categoryId": "...",
  "stockQuantity": 42.5,
  "weightUnit": null,
  "minStockLevel": 10.0
}
```

### Manual migrations (no prisma migrate dev)

Always create `.sql` files manually. Do NOT run `prisma migrate dev`. Apply migrations via:
```bash
psql $DATABASE_URL -f apps/backend/prisma/migrations/YYYYMMDD_*/migration.sql
```

### References

- [Story 2.1 — CatalogItem schema](2-1-shared-schema-catalogitem-entity.md)
- [Story 2.2 — Catalog API](2-2-category-management-catalog-api.md)
- [epics.md — Epic 6 AC](../../planning-artifacts/epics.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None.

### Completion Notes List

- **retail schema added to Prisma multiSchema:** Added `"retail"` to `datasource.schemas` array. All retail models use `@@schema("retail")`.
- **RetailProduct model created:** `retail.retail_products` table — `id`, `catalog_item_id` (unique FK → shared.catalog_items), `stock_quantity` (Decimal 10,2, default 0), `weight_unit` (nullable), `min_stock_level` (nullable Decimal 10,2). Cross-schema relation to CatalogItem (AC1).
- **CatalogItem.retailProduct relation:** Added `retailProduct RetailProduct?` optional relation to `CatalogItem` model (shared schema). Prisma multiSchema supports cross-schema relations.
- **SQL migration 20260315120000:** Creates `retail` schema and `retail.retail_products` table with FK to `shared.catalog_items` ON DELETE CASCADE and index on `catalog_item_id` (AC1).
- **Data migration 20260315130000:** Joins `shared.catalog_items` to `public.products` by (name, tenantId), creates `retail.retail_products` rows with `stock_quantity` migrated. Logs migrated count and skipped count via RAISE NOTICE. `min_stock_level` set to NULL (no source data in old Product model) (AC2).
- **CatalogService.getItems() updated:** Added `include: { retailProduct: true }` to Prisma findMany. Maps each item to flatten RetailProduct: `stockQuantity`, `weightUnit`, `minStockLevel` (null when no RetailProduct). Nested `retailProduct` object removed from response via destructuring (AC3).
- **2 new catalog.service.spec.ts tests:** "flattens RetailProduct fields" + "returns null retail fields when no RetailProduct". 1 existing test updated to expect flat shape (AC3, AC4). 215/215 tests pass, 0 regressions.

### File List

- apps/backend/prisma/schema.prisma [MODIFIED — retail schema added, RetailProduct model, CatalogItem.retailProduct relation]
- apps/backend/prisma/migrations/20260315120000_retail_schema_retail_products/migration.sql [NEW — retail schema + retail_products DDL]
- apps/backend/prisma/migrations/20260315130000_migrate_product_stock_to_retail/migration.sql [NEW — data migration from public.products]
- apps/backend/src/shared/catalog/catalog.service.ts [MODIFIED — getItems() includes retailProduct, maps flat response]
- apps/backend/src/shared/catalog/catalog.service.spec.ts [MODIFIED — updated existing test + 2 new RetailProduct tests]

## Change Log

- 2026-03-15: Story 6.1 created — retail schema + RetailProduct extension table + CatalogItem join response.
- 2026-03-15: Story 6.1 implemented — retail schema in Prisma, RetailProduct model, SQL migrations (DDL + data), CatalogService.getItems() flattens RetailProduct, 215/215 tests pass.
