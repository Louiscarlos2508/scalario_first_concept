-- Story 5.1: Create shared.stock_movements table
-- public.stock_movements kept intact for backward compat (dropped in Story 5.2)
-- shared schema already exists from Stories 2.1, 3.1, 4.1

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
-- product_id is used as catalog_item_id (best-effort; NULLs accepted for legacy records
-- where catalog_item IDs may differ from product IDs)
INSERT INTO "shared"."stock_movements" (
    "id", "catalog_item_id", "quantity", "type", "reason",
    "tenant_id", "user_id", "reference_id", "created_at"
)
SELECT
    "id",
    "product_id"                        AS "catalog_item_id",
    "quantity",
    COALESCE("type", 'ADJUSTMENT')      AS "type",
    "reason",
    "tenant_id",
    NULL                                AS "user_id",
    NULL                                AS "reference_id",
    "created_at"
FROM "public"."stock_movements";

-- NOTE: public.stock_movements is NOT dropped (backward compat — Story 5.2 handles the switch)
-- NOTE: catalog_item_id is nullable to accommodate legacy records with product UUIDs
-- NOTE: reference_id reserved for Story 5.3 TRANSFER_OUT/TRANSFER_IN linking
