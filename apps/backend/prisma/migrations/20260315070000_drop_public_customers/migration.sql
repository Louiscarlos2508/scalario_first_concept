-- Story 3.2: Drop public.customers after migration to shared.contacts (Story 3.1)
-- All customer data is now in shared.contacts (same UUIDs migrated in Story 3.1)
-- orders.customer_id remains as a raw UUID column — no DB-level FK required

-- Optional: Verify row counts match before dropping (uncomment for live DB execution)
-- DO $$
-- DECLARE
--   src_count INTEGER;
--   dst_count INTEGER;
-- BEGIN
--   SELECT COUNT(*) INTO src_count FROM "public"."customers";
--   SELECT COUNT(*) INTO dst_count FROM "shared"."contacts" WHERE contact_type = 'customer';
--   IF src_count != dst_count THEN
--     RAISE EXCEPTION 'Row count mismatch: customers=% contacts=%', src_count, dst_count;
--   END IF;
-- END $$;

-- Step 1: Drop orders.customer_id FK before dropping customers table
ALTER TABLE "public"."orders" DROP CONSTRAINT IF EXISTS "orders_customer_id_fkey";

-- Step 2: Drop public.customers (CASCADE removes any remaining dependent objects)
DROP TABLE "public"."customers" CASCADE;

-- NOTE: orders.customer_id column remains as raw UUID — existing order records still have
--       the UUID values that now correspond to shared.contacts.id (same UUIDs from Story 3.1)
