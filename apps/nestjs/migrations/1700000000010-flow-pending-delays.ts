import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateFlowPendingDelays1700000000010 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE flow_pending_delays (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        flow_id TEXT NOT NULL,
        step_id TEXT NOT NULL,
        tenant_id UUID NOT NULL,
        user_id TEXT NOT NULL DEFAULT '',
        context JSONB NOT NULL DEFAULT '{}'::jsonb,
        flow_definition JSONB NOT NULL DEFAULT '{}'::jsonb,
        resume_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
      CREATE INDEX idx_pending_delays_resume_at ON flow_pending_delays(resume_at);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS flow_pending_delays;`);
  }
}
