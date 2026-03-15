-- Migration: Add variance_explanation to public.pos_sessions + composite index
-- Story 6.3: Cash Session Management
-- Decision: Keep PosSession in public schema (Option A), add column only.

ALTER TABLE public.pos_sessions ADD COLUMN IF NOT EXISTS variance_explanation TEXT;

CREATE INDEX IF NOT EXISTS pos_sessions_tenant_user_status_idx
  ON public.pos_sessions (tenant_id, user_id, status);
