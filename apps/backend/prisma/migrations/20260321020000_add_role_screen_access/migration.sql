-- Epic 30: FR112 — roleScreenAccess on BusinessTypeDefinition
ALTER TABLE kernel.business_type_definitions
ADD COLUMN IF NOT EXISTS role_screen_access JSONB NOT NULL DEFAULT '{}';
