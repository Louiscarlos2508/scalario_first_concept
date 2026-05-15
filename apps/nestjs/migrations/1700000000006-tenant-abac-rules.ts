import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * tenant.config.abac_rules — STORY-019.
 *
 * Phase 1 default = `[]` (permissive : no ABAC rule → manage all, RBAC
 * Layer 2 + RLS Layer 5 remain the safety net). Templates ship their own
 * abac_rules set; tenants opt in by editing config or applying a template.
 */
export class TenantAbacRules1700000000006 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE tenants
        SET config = jsonb_set(COALESCE(config, '{}'::jsonb), '{abac_rules}', '[]'::jsonb, true)
      WHERE config IS NULL OR NOT (config ? 'abac_rules');
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE tenants
        SET config = config - 'abac_rules'
      WHERE config ? 'abac_rules';
    `);
  }
}
