-- Epic 27: Retours Articles & Réservations (FR98)
-- Story 27-1: ReturnRecord model + Tenant return policy fields

-- AlterTable tenants — return policy fields
ALTER TABLE "kernel"."tenants"
  ADD COLUMN "return_policy_days" INTEGER NOT NULL DEFAULT 30,
  ADD COLUMN "return_requires_reason" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN "return_requires_approval" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable return_records
CREATE TABLE "shared"."return_records" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "original_tx_id" UUID,
    "catalog_item_id" UUID NOT NULL,
    "variant_id" UUID,
    "quantity" DECIMAL(10,4) NOT NULL,
    "unit_price" DECIMAL(10,2) NOT NULL,
    "resolution" VARCHAR NOT NULL,
    "reason" TEXT,
    "approved_by" UUID,
    "tenant_id" UUID NOT NULL,
    "created_by" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "return_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "return_records_tenant_id_created_at_idx" ON "shared"."return_records"("tenant_id", "created_at");
CREATE INDEX "return_records_original_tx_id_idx" ON "shared"."return_records"("original_tx_id");
