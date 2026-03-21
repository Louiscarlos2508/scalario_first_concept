-- Phase 3+ anticipation: vertical discriminator on business_type_definitions
-- Allows future artisan / restaurant / services types without schema change
ALTER TABLE "kernel"."business_type_definitions"
  ADD COLUMN IF NOT EXISTS "vertical" TEXT NOT NULL DEFAULT 'retail';

-- Backfill existing rows (all current types are retail)
UPDATE "kernel"."business_type_definitions" SET "vertical" = 'retail' WHERE "vertical" = 'retail';
