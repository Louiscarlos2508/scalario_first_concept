import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * STORY-017 — Create the `scalario_app` PostgreSQL role.
 *
 * The migration runner connects as `scalario_admin` (DATABASE_URL_ADMIN —
 * usually the Postgres superuser created by the Docker image). NestJS
 * runtime connects as `scalario_app` (DATABASE_URL), which deliberately
 * has neither SUPERUSER nor BYPASSRLS — so even a compromised process can
 * never read cross-tenant rows.
 *
 * Password comes from `process.env.SCALARIO_APP_DB_PASSWORD`. The role is
 * created idempotently: re-running the migration only updates the
 * password (rotation use-case) and re-applies grants.
 *
 * Lint check: `scalario_app` must NOT have BYPASSRLS — enforced by a
 * runtime guard in DatabaseModule (boot check) and by the
 * `rls-intrusion.e2e-spec.ts` suite.
 */
export class RlsAppUser1700000000005 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    const password = process.env.SCALARIO_APP_DB_PASSWORD;
    if (!password || password.length < 12) {
      throw new Error(
        'SCALARIO_APP_DB_PASSWORD must be set (>= 12 chars) before running migrations.',
      );
    }
    // Escape single quotes for SQL literal injection-safety. Role name is
    // a fixed identifier so no further sanitisation needed.
    const safePwd = password.replace(/'/g, "''");

    await queryRunner.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'scalario_app') THEN
          EXECUTE format('CREATE ROLE scalario_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS PASSWORD %L', '${safePwd}');
        ELSE
          EXECUTE format('ALTER ROLE scalario_app WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS PASSWORD %L', '${safePwd}');
        END IF;
      END $$;
    `);

    // Allow scalario_app to connect to the current database explicitly —
    // managed Postgres setups (RDS/Supabase) revoke PUBLIC CONNECT.
    await queryRunner.query(`
      DO $$
      BEGIN
        EXECUTE format('GRANT CONNECT ON DATABASE %I TO scalario_app', current_database());
      END $$;
    `);

    await queryRunner.query(`GRANT USAGE ON SCHEMA public TO scalario_app;`);

    // Existing tables: full DML on tenant-scoped tables, INSERT/SELECT only
    // on audit_logs (insert-only, see STORY-020).
    await queryRunner.query(`
      GRANT SELECT, INSERT, UPDATE, DELETE ON
        tenants, users, refresh_tokens, screen_configs, entities,
        workflow_states, sync_mutations, embeddings
      TO scalario_app;
    `);
    await queryRunner.query(
      `GRANT SELECT, INSERT ON audit_logs TO scalario_app;`,
    );

    // Sequences for serial columns (none in current schema, but future-proof).
    await queryRunner.query(
      `GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO scalario_app;`,
    );

    // Future tables: any table created later by the admin role grants the
    // same DML automatically. Run AFTER the bulk grant so existing tables
    // keep their explicit grants.
    await queryRunner.query(`
      ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO scalario_app;
    `);
    await queryRunner.query(`
      ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT USAGE, SELECT ON SEQUENCES TO scalario_app;
    `);

    // Allow scalario_app to issue `SET app.current_tenant_id` — by default
    // unprivileged users CAN set their own GUC variables in the `app.*`
    // namespace (PostgreSQL treats custom variables as session-local
    // unless explicitly restricted via pg_db_role_setting). No extra grant
    // needed, but a comment for future readers:
    //   - `SET row_security = OFF` requires SUPERUSER → denied (✓)
    //   - `SET app.current_tenant_id = '<uuid>'` allowed (✓)
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Revoke + drop role. Order matters: dependent privileges first.
    await queryRunner.query(`
      DO $$
      BEGIN
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'scalario_app') THEN
          REVOKE ALL ON ALL TABLES IN SCHEMA public FROM scalario_app;
          REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM scalario_app;
          REVOKE ALL ON SCHEMA public FROM scalario_app;
          EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM scalario_app', current_database());
          ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM scalario_app;
          ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM scalario_app;
          DROP ROLE scalario_app;
        END IF;
      END $$;
    `);
  }
}
