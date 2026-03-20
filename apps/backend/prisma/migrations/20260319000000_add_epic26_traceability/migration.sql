-- Epic 26: Traçabilité Articles & Configurations Métier
-- FR92: trackSerialNumbers + SerialRecord
-- FR93: warrantyMonths
-- FR94: requiresPrescription
-- FR95: bestBeforeDate on ProductBatch
-- FR96: dynamicPricing + PriceHistory
-- FR97: isUnique

-- AlterTable catalog_items
ALTER TABLE "shared"."catalog_items"
  ADD COLUMN "track_serial_numbers" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "warranty_months" INTEGER,
  ADD COLUMN "requires_prescription" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "dynamic_pricing" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "is_unique" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable prod_batches
ALTER TABLE "shared"."prod_batches"
  ADD COLUMN "best_before_date" TIMESTAMPTZ(6);

-- CreateTable serial_records
CREATE TABLE "shared"."serial_records" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "catalog_item_id" UUID NOT NULL,
    "serial" TEXT NOT NULL,
    "sold_at" TIMESTAMPTZ(6),
    "warranty_until" TIMESTAMPTZ(6),
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "serial_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "serial_records_catalog_item_id_idx" ON "shared"."serial_records"("catalog_item_id");

-- CreateUniqueIndex
CREATE UNIQUE INDEX "serial_records_tenant_id_serial_key" ON "shared"."serial_records"("tenant_id", "serial");

-- AddForeignKey
ALTER TABLE "shared"."serial_records"
  ADD CONSTRAINT "serial_records_catalog_item_id_fkey"
  FOREIGN KEY ("catalog_item_id") REFERENCES "shared"."catalog_items"("id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- CreateTable price_history
CREATE TABLE "shared"."price_history" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "catalog_item_id" UUID NOT NULL,
    "price" DECIMAL(12,2) NOT NULL,
    "effective_from" TIMESTAMPTZ(6) NOT NULL,
    "reason" TEXT,
    "tenant_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "price_history_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "price_history_catalog_item_id_effective_from_idx" ON "shared"."price_history"("catalog_item_id", "effective_from");

-- CreateIndex
CREATE INDEX "price_history_tenant_id_idx" ON "shared"."price_history"("tenant_id");

-- AddForeignKey
ALTER TABLE "shared"."price_history"
  ADD CONSTRAINT "price_history_catalog_item_id_fkey"
  FOREIGN KEY ("catalog_item_id") REFERENCES "shared"."catalog_items"("id")
  ON DELETE RESTRICT ON UPDATE CASCADE;
