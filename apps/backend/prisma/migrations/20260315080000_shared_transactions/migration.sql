-- Story 4.1: Create shared.transactions table
-- Migrates existing public.orders → shared.transactions (same UUIDs)
-- public.orders remains intact for backward compat until Story 4.2
-- shared schema already exists from Stories 2.1, 3.1

-- Step 1: Create shared.transactions table
CREATE TABLE "shared"."transactions" (
    "id"               UUID            NOT NULL DEFAULT gen_random_uuid(),
    "total_amount"     DECIMAL(10,2)   NOT NULL,
    "items_json"       JSONB           NOT NULL,
    "payment_method"   TEXT,
    "payment_splits"   JSONB,
    "lifecycle_type"   TEXT            NOT NULL DEFAULT 'instant',
    "transaction_type" TEXT            NOT NULL DEFAULT 'sale',
    "customer_id"      UUID,
    "session_id"       UUID,
    "tenant_id"        UUID            NOT NULL,
    "created_at"       TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"       TIMESTAMPTZ(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- Step 2: Indexes (tenant isolation + customer lookup)
CREATE INDEX "transactions_tenant_id_created_at_idx"
    ON "shared"."transactions"("tenant_id", "created_at");

CREATE INDEX "transactions_customer_id_idx"
    ON "shared"."transactions"("customer_id");

-- Step 3: Data migration — copy public.orders → shared.transactions
-- Preserves UUIDs so existing client offline sync state remains valid
INSERT INTO "shared"."transactions" (
    "id",
    "total_amount",
    "items_json",
    "payment_method",
    "payment_splits",
    "lifecycle_type",
    "transaction_type",
    "customer_id",
    "session_id",
    "tenant_id",
    "created_at",
    "updated_at"
)
SELECT
    "id",
    "total_amount",
    "items_json",
    "payment_method",
    "payment_splits",
    'instant'                                   AS "lifecycle_type",
    'sale'                                      AS "transaction_type",
    "customer_id",
    "session_id",
    "tenant_id",
    "created_at",
    COALESCE("created_at", CURRENT_TIMESTAMP)   AS "updated_at"
FROM "public"."orders";

-- Step 4: updated_at auto-update trigger (consistent with Story 2.1 and 3.1 patterns)
CREATE OR REPLACE FUNCTION shared_transactions_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER "transactions_updated_at_trigger"
    BEFORE UPDATE ON "shared"."transactions"
    FOR EACH ROW EXECUTE FUNCTION shared_transactions_update_updated_at();

-- NOTE: public.orders is NOT dropped (backward compat — Story 4.2 handles the switch)
-- NOTE: transaction_type 'transfer_inter_tenant' is a valid value reserved for Phase 3 Connect (FR55)
-- NOTE: customer_id references shared.contacts.id (same UUIDs from Story 3.1 migration)
