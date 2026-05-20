import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * STORY-030 — Make entity_id nullable (some workflows aren't bound to an entity),
 * add triggered_by column, and change history from JSONB[] to JSONB
 * for proper TypeORM support.
 */
export class WorkflowExecutor1700000000008 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE workflow_states
        ALTER COLUMN entity_id DROP NOT NULL,
        ALTER COLUMN entity_id SET DEFAULT NULL;
    `);

    const hasTriggeredBy = await queryRunner.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'workflow_states' AND column_name = 'triggered_by'
    `);
    if (hasTriggeredBy.length === 0) {
      await queryRunner.query(`
        ALTER TABLE workflow_states
          ADD COLUMN triggered_by UUID NULL;
      `);
    }

    const historyType = await queryRunner.query(`
      SELECT data_type FROM information_schema.columns
      WHERE table_name = 'workflow_states' AND column_name = 'history'
    `);
    if (historyType.length > 0 && historyType[0].data_type === 'ARRAY') {
      await queryRunner.query(`
        ALTER TABLE workflow_states
          ALTER COLUMN history TYPE JSONB USING to_jsonb(history);
        ALTER TABLE workflow_states
          ALTER COLUMN history SET DEFAULT '[]'::jsonb;
      `);
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE workflow_states SET entity_id = '00000000-0000-0000-0000-000000000000' WHERE entity_id IS NULL;
    `);

    await queryRunner.query(`
      ALTER TABLE workflow_states
        ALTER COLUMN entity_id SET NOT NULL;
    `);

    const historyType = await queryRunner.query(`
      SELECT data_type FROM information_schema.columns
      WHERE table_name = 'workflow_states' AND column_name = 'history'
    `);
    if (historyType.length > 0 && historyType[0].data_type === 'jsonb') {
      await queryRunner.query(`
        ALTER TABLE workflow_states
          ALTER COLUMN history TYPE jsonb[] USING ARRAY(SELECT jsonb_array_elements(history));
        ALTER TABLE workflow_states
          ALTER COLUMN history SET DEFAULT '{}';
      `);
    }

    await queryRunner.query(`
      ALTER TABLE workflow_states
        DROP COLUMN IF EXISTS triggered_by;
    `);
  }
}