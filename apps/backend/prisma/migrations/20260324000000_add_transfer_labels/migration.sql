-- Migration: add transfer_labels column to business_type_definitions
ALTER TABLE "kernel"."business_type_definitions"
  ADD COLUMN IF NOT EXISTS "transfer_labels" JSONB NOT NULL DEFAULT '{}';
