-- Story 2.1: Create shared schema and catalog_items table
-- Migrates existing public.products → shared.catalog_items (same UUIDs, preserving client sync state)
-- public.products remains intact for backward compat until Story 2.2 (API switch)
-- Pure additive migration: no DROP TABLE, no DROP SCHEMA, no breaking changes.

-- Step 1: Create shared schema
CREATE SCHEMA IF NOT EXISTS "shared";

-- Step 2: Create catalog_items table in shared schema
CREATE TABLE "shared"."catalog_items" (
    "id"                 UUID            NOT NULL DEFAULT gen_random_uuid(),
    "name"               TEXT            NOT NULL,
    "price"              DECIMAL(10,2)   NOT NULL,
    "barcode"            TEXT,
    "item_type"          TEXT            NOT NULL DEFAULT 'physical',
    "category_id"        UUID,
    "tenant_id"          UUID            NOT NULL,
    "is_deleted"         BOOLEAN         NOT NULL DEFAULT false,
    "created_at"         TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"         TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "supplier_reference" UUID,

    CONSTRAINT "catalog_items_pkey" PRIMARY KEY ("id")
);

-- Step 3: Data migration — copy public.products → shared.catalog_items
-- Preserves UUIDs so existing client sync state remains valid
-- stock_quantity is intentionally NOT migrated (belongs in RetailProduct, Epic 6)
INSERT INTO "shared"."catalog_items" (
    "id",
    "name",
    "price",
    "barcode",
    "item_type",
    "category_id",
    "tenant_id",
    "is_deleted",
    "created_at",
    "updated_at",
    "supplier_reference"
)
SELECT
    "id",
    "name",
    "price",
    "barcode",
    'physical'      AS "item_type",
    "category_id",
    "tenant_id",
    "is_deleted",
    "created_at",
    "updated_at",
    NULL            AS "supplier_reference"
FROM "public"."products";

-- Step 4: Create performance indexes (NFR1: barcode <100ms, delta sync)
CREATE INDEX "catalog_items_tenant_id_updated_at_idx"
    ON "shared"."catalog_items"("tenant_id", "updated_at");

CREATE INDEX "catalog_items_tenant_id_category_id_idx"
    ON "shared"."catalog_items"("tenant_id", "category_id");

CREATE INDEX "catalog_items_barcode_idx"
    ON "shared"."catalog_items"("barcode");

-- Step 5: updated_at auto-update trigger
-- (Prisma @updatedAt handles this at ORM level; trigger ensures DB-level consistency for direct SQL updates)
CREATE OR REPLACE FUNCTION shared_update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER "catalog_items_updated_at_trigger"
    BEFORE UPDATE ON "shared"."catalog_items"
    FOR EACH ROW EXECUTE FUNCTION shared_update_updated_at_column();

-- NOTE: public.products is NOT dropped (backward compat — Story 2.2 handles the switch)
-- NOTE: public.categories is NOT touched (Category moves to shared in Story 2.2)
-- NOTE: RLS policy on catalog_items added in Story 2.2 with full catalog API
-- NOTE: supplier_reference is nullable, no FK constraint (Phase 3 Connect field — no target table yet)
-- NOTE: category_id is nullable, no FK constraint (Category moves to shared in Story 2.2)
