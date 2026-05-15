import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * STORY-016 — Multi-tenant isolation infrastructure (DB side).
 *
 * Phase 1 is `shared schema, RLS-isolated`. At this point in the codebase
 * no business tables exist yet — Auth tables (`tenants`, `users`,
 * `refresh_tokens`) carry their own `tenant_id` already, and the AuditLog
 * (STORY-020) will be created with `tenant_id` in its own migration.
 *
 * This migration is therefore intentionally minimal: it documents the
 * convention via a no-op DO block + creates the
 * `app.current_tenant_id` GUC default so that connections that bypass
 * the middleware fail closed (RLS in STORY-017 will then deny). The
 * setting is intentionally `''` (empty) so a UUID cast on the RLS side
 * fails predictably rather than silently matching some random tenant.
 *
 * When EPIC-004+ adds the first real business table, the migration that
 * creates it MUST:
 *   - Add `tenant_id UUID NOT NULL`.
 *   - Create composite index `(tenant_id, <hot_query_column>)`.
 *   - Add an RLS policy in the STORY-017 follow-up migration.
 */
export class TenantIdDefault1700000000003 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Set a database-wide default for app.current_tenant_id. Without this,
    // `current_setting('app.current_tenant_id', false)` would raise on
    // any connection that skipped TenantMiddleware — we want it to return
    // an empty string and have RLS deny instead (clearer failure mode).
    await queryRunner.query(`
      DO $$
      BEGIN
        BEGIN
          EXECUTE format('ALTER DATABASE %I SET app.current_tenant_id = %L', current_database(), '');
        EXCEPTION WHEN insufficient_privilege THEN
          -- Managed databases (RDS, Supabase, etc.) often forbid ALTER DATABASE.
          -- The middleware re-sets the value per connection, so this is a
          -- defense-in-depth nice-to-have, not a requirement.
          RAISE NOTICE 'Skipped ALTER DATABASE SET app.current_tenant_id (insufficient privilege).';
        END;
      END $$;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DO $$
      BEGIN
        BEGIN
          EXECUTE format('ALTER DATABASE %I RESET app.current_tenant_id', current_database());
        EXCEPTION WHEN insufficient_privilege THEN
          NULL;
        END;
      END $$;
    `);
  }
}
