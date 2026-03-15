-- Story 4.2: Drop public.orders after migration to shared.transactions (Story 4.1)
-- All data has been migrated to shared.transactions in Story 4.1 (migration 20260315080000)
-- Optional row-count verification (uncomment for live DB):
-- DO $$
-- DECLARE v_order_count INT; v_tx_count INT;
-- BEGIN
--   SELECT COUNT(*) INTO v_order_count FROM "public"."orders";
--   SELECT COUNT(*) INTO v_tx_count FROM "shared"."transactions";
--   IF v_order_count > v_tx_count THEN
--     RAISE EXCEPTION 'Data migration incomplete: % orders not yet in shared.transactions', (v_order_count - v_tx_count);
--   END IF;
-- END $$;

-- Drop PosSession.orders FK before dropping orders table
ALTER TABLE "public"."orders" DROP CONSTRAINT IF EXISTS "orders_session_id_fkey";
ALTER TABLE "public"."orders" DROP CONSTRAINT IF EXISTS "orders_tenant_id_fkey";

-- Drop public.orders (CASCADE removes any remaining dependent objects)
DROP TABLE "public"."orders" CASCADE;
