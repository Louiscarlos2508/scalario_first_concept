import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Auth tables — STORY-014.
 * Crée tenants / users / refresh_tokens conformément à l'architecture
 * (section Security, lines 705-754). RLS activée sur `users` avec policy
 * placeholder ; les policies définitives sont câblées en STORY-017.
 */
export class AuthTables1700000000001 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS tenants (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT tenants_slug_format CHECK (slug ~ '^[a-z0-9-]{3,63}$')
      );
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        email TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        roles JSONB NOT NULL DEFAULT '[]'::jsonb,
        department_id UUID NULL,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT users_email_lowercase CHECK (email = lower(email)),
        CONSTRAINT users_tenant_email_unique UNIQUE (tenant_id, email)
      );
    `);

    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);`,
    );

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS refresh_tokens (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
        token_hash TEXT NOT NULL UNIQUE,
        expires_at TIMESTAMPTZ NOT NULL,
        revoked_at TIMESTAMPTZ NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens(token_hash);`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);`,
    );

    // RLS placeholder — final policies live in STORY-017.
    await queryRunner.query(`ALTER TABLE users ENABLE ROW LEVEL SECURITY;`);
    await queryRunner.query(`
      CREATE POLICY user_tenant_isolation ON users
        USING (
          tenant_id::text = current_setting('app.current_tenant_id', true)
          OR current_setting('app.current_tenant_id', true) = ''
        );
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP POLICY IF EXISTS user_tenant_isolation ON users;`,
    );
    await queryRunner.query(`ALTER TABLE users DISABLE ROW LEVEL SECURITY;`);
    await queryRunner.query(`DROP TABLE IF EXISTS refresh_tokens;`);
    await queryRunner.query(`DROP TABLE IF EXISTS users;`);
    await queryRunner.query(`DROP TABLE IF EXISTS tenants;`);
  }
}
