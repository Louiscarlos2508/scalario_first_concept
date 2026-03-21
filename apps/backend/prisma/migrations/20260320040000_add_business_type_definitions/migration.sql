-- Migration: add_business_type_definitions
-- Epic 29 — Types de Business Configurables (FR104–FR106)
-- Creates business_type_definitions table in kernel schema
-- Adds business_type column to tenants table

-- CreateTable: business_type_definitions (kernel schema)
CREATE TABLE IF NOT EXISTS "kernel"."business_type_definitions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "default_flags" JSONB NOT NULL DEFAULT '{}',
    "visible_sections" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    "suggested_categories" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    "icon" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "business_type_definitions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: unique code
CREATE UNIQUE INDEX IF NOT EXISTS "business_type_definitions_code_key" ON "kernel"."business_type_definitions"("code");

-- AlterTable: add business_type to tenants
ALTER TABLE "kernel"."tenants" ADD COLUMN IF NOT EXISTS "business_type" TEXT NOT NULL DEFAULT 'generaliste';
