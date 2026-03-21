-- Epic 30: FR109, FR111 — roleLabels + documentType on BusinessTypeDefinition
-- Story 30-2: Additive migration — no data loss, safe for production

-- Add role_labels column (jsonb, default {})
ALTER TABLE "kernel"."business_type_definitions"
    ADD COLUMN IF NOT EXISTS "role_labels" JSONB NOT NULL DEFAULT '{}';

-- Add document_type column (text, default 'receipt')
ALTER TABLE "kernel"."business_type_definitions"
    ADD COLUMN IF NOT EXISTS "document_type" TEXT NOT NULL DEFAULT 'receipt';
