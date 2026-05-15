-- STORY-017 — emergency RLS rollback.
--
-- WARNING. Running this disables Layer 5 tenant isolation. Any
-- application bug that omits `WHERE tenant_id = ?` will leak cross-tenant
-- data once these statements run. Procedure:
--
--   1. Get explicit ops sign-off (the runbook reference is
--      `apps/nestjs/docs/migrations-tenant-scoped.md`).
--   2. Connect as `scalario_admin` (the only role with permission to
--      disable RLS on these tables).
--   3. Run the file, then `\q`.
--   4. File an incident ticket within 1 hour — RLS must be re-enabled
--      with a corrective migration before the next deploy window.
--
-- To re-enable after fixing the broken migration:
--   pnpm --filter @scalario/nestjs run migration:run

BEGIN;

ALTER TABLE users           DISABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens  DISABLE ROW LEVEL SECURITY;
ALTER TABLE screen_configs  DISABLE ROW LEVEL SECURITY;
ALTER TABLE entities        DISABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_states DISABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs      DISABLE ROW LEVEL SECURITY;
ALTER TABLE sync_mutations  DISABLE ROW LEVEL SECURITY;
ALTER TABLE embeddings      DISABLE ROW LEVEL SECURITY;

-- Sanity print so the operator sees the new state before commit.
SELECT relname, relrowsecurity, relforcerowsecurity
FROM pg_class
WHERE relname IN (
  'users','refresh_tokens','screen_configs','entities',
  'workflow_states','audit_logs','sync_mutations','embeddings'
)
ORDER BY relname;

COMMIT;
