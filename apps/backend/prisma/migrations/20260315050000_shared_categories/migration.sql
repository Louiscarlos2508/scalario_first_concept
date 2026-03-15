-- Story 2.2: Migrate public.categories → shared.categories
-- shared schema already exists from Story 2.1 (catalog_items migration)
-- public.products remains intact (decomposed in Epic 6)
-- Pure additive table creation + UUID-preserving data migration + FK + DROP old table

-- Step 1: Create shared.categories table
CREATE TABLE "shared"."categories" (
    "id"         UUID            NOT NULL DEFAULT gen_random_uuid(),
    "name"       TEXT            NOT NULL,
    "tenant_id"  UUID            NOT NULL,
    "created_at" TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- Step 2: Index on tenant_id for tenant-scoped query performance
CREATE INDEX "shared_categories_tenant_id_idx"
    ON "shared"."categories"("tenant_id");

-- Step 3: Data migration — preserve UUIDs for catalog_items FK integrity
-- All category UUIDs referenced by catalog_items.category_id must exist in shared.categories
INSERT INTO "shared"."categories" ("id", "name", "tenant_id", "created_at")
SELECT "id", "name", "tenant_id", "created_at"
FROM "public"."categories";

-- Step 4: Add FK constraint on catalog_items.category_id → shared.categories.id
-- Must be added AFTER data migration so existing category_id values are valid
ALTER TABLE "shared"."catalog_items"
    ADD CONSTRAINT "catalog_items_category_id_fkey"
    FOREIGN KEY ("category_id")
    REFERENCES "shared"."categories"("id")
    ON DELETE SET NULL;

-- Step 5: Drop public.categories
-- CASCADE removes DB-level FK from public.products.category_id → public.categories.id
-- public.products.category_id column itself is NOT dropped (stays as raw UUID column until Epic 6)
DROP TABLE "public"."categories" CASCADE;

-- NOTE: public.products is NOT dropped (backward compat — decomposed in Epic 6)
-- NOTE: shared.catalog_items is NOT dropped (Story 2.1 table, now has FK to shared.categories)
-- NOTE: Product.categoryId data in DB remains valid as raw UUID after CASCADE drop
-- NOTE: RLS policy on shared.categories deferred to Story 2.3+
