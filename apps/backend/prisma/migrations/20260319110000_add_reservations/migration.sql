-- Epic 27: Réservations avec acompte (FR99)
-- Story 27-4: Reservation model

-- CreateTable reservations
CREATE TABLE "shared"."reservations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "customer_id" UUID NOT NULL,
    "items_json" JSONB NOT NULL,
    "total_amount" DECIMAL(10,2) NOT NULL,
    "deposit_amount" DECIMAL(10,2) NOT NULL,
    "remaining_amount" DECIMAL(10,2) NOT NULL,
    "status" VARCHAR NOT NULL DEFAULT 'pending',
    "deposit_transaction_id" UUID,
    "completion_transaction_id" UUID,
    "tenant_id" UUID NOT NULL,
    "created_by" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMPTZ(6),

    CONSTRAINT "reservations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "reservations_tenant_id_status_idx" ON "shared"."reservations"("tenant_id", "status");
CREATE INDEX "reservations_customer_id_idx" ON "shared"."reservations"("customer_id");
