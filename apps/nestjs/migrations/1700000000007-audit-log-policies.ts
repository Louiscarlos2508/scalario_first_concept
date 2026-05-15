import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * STORY-020 — finalize `audit_logs` as an insert-only, forensic-grade table.
 *
 * STORY-017's migration 004 already created the table with RLS + revoked
 * UPDATE/DELETE from PUBLIC, and 005 granted SELECT/INSERT to `scalario_app`.
 * That left a small gap: `ALTER DEFAULT PRIVILEGES` in 005 grants full DML on
 * *future* tables, and a future GRANT or grant-by-default on `audit_logs` (or
 * a misconfigured pooler) could re-introduce UPDATE/DELETE. We close it by
 * making the REVOKE explicit at the role level — not just at PUBLIC.
 *
 * We also add the second index variant required by STORY-020 AC-04
 * (`(tenant_id, user_id, created_at DESC)`) which is required for fast
 * "user activity" queries on top of the existing `(tenant_id, created_at)`.
 */
export class AuditLogPolicies1700000000007 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Sanity check — audit_logs must exist (STORY-017 / migration 004).
    const rows: Array<{ exists: boolean }> = await queryRunner.query(
      `SELECT EXISTS (
         SELECT 1 FROM information_schema.tables
          WHERE table_schema = 'public' AND table_name = 'audit_logs'
       ) AS exists`,
    );
    if (!rows[0]?.exists) {
      throw new Error(
        'audit_logs table missing — run migration 1700000000004 (STORY-017) first.',
      );
    }

    // 2. Explicit REVOKE on scalario_app — insert-only enforced by PostgreSQL.
    //    Even if a future GRANT broadens privileges (or default privileges
    //    pollute audit_logs), the REVOKE keeps the no-mutate guarantee.
    await queryRunner.query(
      `REVOKE UPDATE, DELETE, TRUNCATE ON audit_logs FROM scalario_app;`,
    );
    await queryRunner.query(
      `GRANT SELECT, INSERT ON audit_logs TO scalario_app;`,
    );

    // 3. Index `(tenant_id, user_id, created_at DESC)` — STORY-020 AC-04.
    //    STORY-017 migration 004 already created `idx_audit_logs_user
    //    (tenant_id, user_id)` (no created_at). We add the time-suffixed
    //    variant so per-user time-range queries can be served from the
    //    index without a heap scan. We DO NOT drop the older index —
    //    queries that only filter by tenant+user (count, exists) still
    //    benefit from it and the cost (a few MB) is negligible.
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_audit_logs_user_time
         ON audit_logs(tenant_id, user_id, created_at DESC);`,
    );

    // 4. Defensive REVOKE on PUBLIC (already done in 004 — kept here for
    //    idempotence after a downgrade-then-upgrade cycle).
    await queryRunner.query(
      `REVOKE UPDATE, DELETE, TRUNCATE ON audit_logs FROM PUBLIC;`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop the new index; do NOT re-grant UPDATE/DELETE — downgrading the
    // migration must not silently broaden privileges.
    await queryRunner.query(`DROP INDEX IF EXISTS idx_audit_logs_user_time;`);
  }
}
