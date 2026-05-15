import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Tenant config.roles — STORY-015.
 * Adds a JSONB `config` column to tenants and backfills `roles=["OWNER"]`
 * for existing rows. Per-tenant roles are stored data-driven; the NestJS
 * code never hardcodes a business role name.
 */
export class TenantRoles1700000000002 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE tenants
        ADD COLUMN IF NOT EXISTS config JSONB NOT NULL DEFAULT '{"roles":["OWNER"]}'::jsonb;
    `);

    // Backfill roles=["OWNER"] when missing.
    await queryRunner.query(`
      UPDATE tenants
        SET config = jsonb_set(COALESCE(config, '{}'::jsonb), '{roles}', '["OWNER"]'::jsonb, true)
      WHERE config IS NULL OR NOT (config ? 'roles');
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE tenants DROP COLUMN IF EXISTS config;`);
  }
}
