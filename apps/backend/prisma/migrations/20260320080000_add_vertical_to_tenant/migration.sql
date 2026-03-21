-- Add vertical column to tenants table (Epic 29 — Phase 3+ discriminator)
ALTER TABLE "kernel"."tenants"
  ADD COLUMN IF NOT EXISTS "vertical" TEXT NOT NULL DEFAULT 'retail';
