-- Add metadata JSONB column to shared.transactions (Epic 26 — prescription)
ALTER TABLE "shared"."transactions" ADD COLUMN IF NOT EXISTS "metadata" JSONB;
