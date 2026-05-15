import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * STORY-017 — Layer 5: Row-Level Security on every tenant-scoped table.
 *
 * Drops the placeholder policy from STORY-014, creates the 6 business
 * tables that didn't exist yet (`screen_configs`, `entities`,
 * `workflow_states`, `audit_logs`, `sync_mutations`, `embeddings`),
 * enables `ROW LEVEL SECURITY` + `FORCE ROW LEVEL SECURITY` on all 8
 * tenant-scoped tables, and installs a uniform `<table>_tenant_isolation`
 * policy with USING + WITH CHECK both bound to
 * `current_setting('app.current_tenant_id', true)::uuid`.
 *
 * Fail-closed: the second argument `true` (missing_ok) means a connection
 * that never set the GUC returns NULL → `tenant_id = NULL` is UNKNOWN →
 * 0 rows visible. Forging cross-tenant INSERTs is rejected by WITH CHECK.
 *
 * Tables created here are skeletons — follow-up stories (EPIC-004+,
 * STORY-020 for audit_logs) own the column-level finishing touches.
 * The schema mirrors `_bmad-output/architecture-scalario-2026-05-09.md`
 * lines 757-880 verbatim where applicable.
 */

const TENANT_TABLES = [
  'users',
  'refresh_tokens',
  'screen_configs',
  'entities',
  'workflow_states',
  'audit_logs',
  'sync_mutations',
  'embeddings',
] as const;

export class RlsPolicies1700000000004 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // pgvector — required by `embeddings`. Idempotent.
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS vector;`);

    // --- 1. Create the 6 business tables that don't exist yet ----------
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS screen_configs (
        id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        screen_id       TEXT NOT NULL,
        role            TEXT NOT NULL DEFAULT '*',
        config          JSONB NOT NULL,
        schema_version  TEXT NOT NULL DEFAULT '1.0.0',
        is_active       BOOLEAN NOT NULL DEFAULT TRUE,
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (tenant_id, screen_id, role)
      );
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_screen_configs_tenant_screen ON screen_configs(tenant_id, screen_id);`,
    );

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS entities (
        id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        module_id       TEXT NOT NULL,
        entity_type     TEXT NOT NULL,
        data            JSONB NOT NULL DEFAULT '{}'::jsonb,
        status          TEXT NOT NULL DEFAULT 'active',
        version         INTEGER NOT NULL DEFAULT 1,
        vector_clock    JSONB,
        created_by      UUID REFERENCES users(id),
        updated_by      UUID REFERENCES users(id),
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_entities_tenant_module ON entities(tenant_id, module_id);`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_entities_tenant_type ON entities(tenant_id, entity_type);`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_entities_status ON entities(tenant_id, status);`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_entities_data_gin ON entities USING gin(data);`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_entities_created_at ON entities(tenant_id, created_at DESC);`,
    );

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS workflow_states (
        id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id     UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        entity_id     UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
        workflow_id   TEXT NOT NULL,
        current_state TEXT NOT NULL,
        history       JSONB[] NOT NULL DEFAULT '{}',
        created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (entity_id, workflow_id)
      );
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_workflow_states_entity ON workflow_states(entity_id);`,
    );

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id     UUID NOT NULL,
        user_id       UUID NOT NULL,
        action        TEXT NOT NULL,
        module_id     TEXT,
        entity_id     UUID,
        payload_hash  TEXT,
        metadata      JSONB NOT NULL DEFAULT '{}'::jsonb,
        created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_time ON audit_logs(tenant_id, created_at DESC);`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(tenant_id, user_id);`,
    );

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS sync_mutations (
        id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        client_mutation_id  UUID NOT NULL UNIQUE,
        tenant_id           UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        module_id           TEXT NOT NULL,
        action              TEXT NOT NULL,
        payload             JSONB NOT NULL DEFAULT '{}'::jsonb,
        result              JSONB,
        status              TEXT NOT NULL DEFAULT 'pending',
        conflict_data       JSONB,
        created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        processed_at        TIMESTAMPTZ
      );
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_sync_mutations_client_id ON sync_mutations(client_mutation_id);`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_sync_mutations_tenant_status ON sync_mutations(tenant_id, status);`,
    );

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS embeddings (
        id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        entity_id   UUID,
        content     TEXT NOT NULL,
        embedding   vector(1536),
        metadata    JSONB NOT NULL DEFAULT '{}'::jsonb,
        created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_embeddings_tenant ON embeddings(tenant_id);`,
    );
    // ivfflat index — created only on a populated table in prod (planner
    // needs samples). Phase 1 keeps the table empty; deferring is safe.

    // --- 2. Drop the legacy STORY-014 placeholder policy on users -----
    await queryRunner.query(
      `DROP POLICY IF EXISTS user_tenant_isolation ON users;`,
    );

    // --- 3. ENABLE + FORCE + uniform policy on every tenant-scoped table
    for (const table of TENANT_TABLES) {
      // Idempotent — re-applying the migration won't error on re-enable.
      await queryRunner.query(`ALTER TABLE ${table} ENABLE ROW LEVEL SECURITY;`);
      await queryRunner.query(`ALTER TABLE ${table} FORCE ROW LEVEL SECURITY;`);
      await queryRunner.query(
        `DROP POLICY IF EXISTS ${table}_tenant_isolation ON ${table};`,
      );
      await queryRunner.query(`
        CREATE POLICY ${table}_tenant_isolation ON ${table}
          USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid)
          WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
      `);
    }

    // --- 4. audit_logs: insert-only (STORY-020 will further restrict per-user)
    // Owners still need UPDATE/DELETE for migrations; we revoke from PUBLIC so
    // the future `scalario_app` grants can stay INSERT/SELECT only.
    await queryRunner.query(
      `REVOKE UPDATE, DELETE ON audit_logs FROM PUBLIC;`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Reverse order: drop policies + disable RLS first, then drop new tables.
    for (const table of TENANT_TABLES) {
      await queryRunner.query(
        `DROP POLICY IF EXISTS ${table}_tenant_isolation ON ${table};`,
      );
      await queryRunner.query(
        `ALTER TABLE ${table} DISABLE ROW LEVEL SECURITY;`,
      );
    }

    // Restore the STORY-014 placeholder so downgrading past this migration
    // leaves `users` with the same shape it had before.
    await queryRunner.query(`
      CREATE POLICY user_tenant_isolation ON users
        USING (
          tenant_id::text = current_setting('app.current_tenant_id', true)
          OR current_setting('app.current_tenant_id', true) = ''
        );
    `);
    await queryRunner.query(`ALTER TABLE users ENABLE ROW LEVEL SECURITY;`);

    // Drop business tables created by this migration (in FK-safe order).
    await queryRunner.query(`DROP TABLE IF EXISTS embeddings;`);
    await queryRunner.query(`DROP TABLE IF EXISTS sync_mutations;`);
    await queryRunner.query(`DROP TABLE IF EXISTS audit_logs;`);
    await queryRunner.query(`DROP TABLE IF EXISTS workflow_states;`);
    await queryRunner.query(`DROP TABLE IF EXISTS entities;`);
    await queryRunner.query(`DROP TABLE IF EXISTS screen_configs;`);
  }
}
