-- Story 5.2: Drop public.stock_movements after migration to shared.stock_movements (Story 5.1)
-- All data has been migrated to shared.stock_movements in Story 5.1

-- Drop FKs before dropping table
ALTER TABLE "public"."stock_movements" DROP CONSTRAINT IF EXISTS "stock_movements_product_id_fkey";
ALTER TABLE "public"."stock_movements" DROP CONSTRAINT IF EXISTS "stock_movements_tenant_id_fkey";

-- Drop public.stock_movements (CASCADE removes any remaining dependent objects)
DROP TABLE "public"."stock_movements" CASCADE;
