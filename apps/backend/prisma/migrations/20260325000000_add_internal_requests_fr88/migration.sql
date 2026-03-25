-- Migration: FR88 — Circuit demande de réapprovisionnement interne

-- 1. Ajouter skip_manager_approval sur tenants
ALTER TABLE "kernel"."tenants"
  ADD COLUMN IF NOT EXISTS "skip_manager_approval" BOOLEAN NOT NULL DEFAULT false;

-- 2. Créer la table internal_requests dans shared schema
CREATE TABLE IF NOT EXISTS "shared"."internal_requests" (
  "id"              UUID        NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id"       UUID        NOT NULL,
  "catalog_item_id" UUID        NOT NULL,
  "quantity"        DECIMAL(10,2) NOT NULL,
  "status"          TEXT        NOT NULL DEFAULT 'pending',
  "urgency"         TEXT        NOT NULL DEFAULT 'normal',
  "requested_by"    UUID        NOT NULL,
  "prepared_by"     UUID,
  "approved_by"     UUID,
  "reason"          TEXT,
  "created_at"      TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  "updated_at"      TIMESTAMPTZ(6) NOT NULL DEFAULT now(),

  CONSTRAINT "internal_requests_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "internal_requests_tenant_id_fkey"
    FOREIGN KEY ("tenant_id") REFERENCES "kernel"."tenants"("id"),
  CONSTRAINT "internal_requests_catalog_item_id_fkey"
    FOREIGN KEY ("catalog_item_id") REFERENCES "shared"."catalog_items"("id")
);

CREATE INDEX IF NOT EXISTS "internal_requests_tenant_status_idx"
  ON "shared"."internal_requests"("tenant_id", "status");

CREATE INDEX IF NOT EXISTS "internal_requests_tenant_urgency_idx"
  ON "shared"."internal_requests"("tenant_id", "urgency");
