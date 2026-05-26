import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Anticipation Phase 4 (Scalario Network) — STORY-V14-013.
 * Ajoute handle, network_public, network_profile sans aucun impact Phase 1-3
 * (valeurs desactivees par defaut, pas de routes reseau exposes).
 */
export class AddTenantHandleNetwork1700000000009 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS handle TEXT;
      CREATE UNIQUE INDEX IF NOT EXISTS idx_tenants_handle ON public.tenants(handle) WHERE handle IS NOT NULL;
      ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS network_public BOOLEAN NOT NULL DEFAULT FALSE;
      ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS network_profile JSONB NOT NULL DEFAULT '{}'::jsonb;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE public.tenants DROP COLUMN IF EXISTS handle;
      ALTER TABLE public.tenants DROP COLUMN IF EXISTS network_public;
      ALTER TABLE public.tenants DROP COLUMN IF EXISTS network_profile;
    `);
  }
}
