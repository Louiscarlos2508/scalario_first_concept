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

-- Step 4: updated_at auto-update trigger (consistent with catalog_items pattern from Story 2.1)
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
