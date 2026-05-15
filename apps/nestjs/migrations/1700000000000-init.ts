import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Init migration — STORY-013.
 * Active les extensions PostgreSQL requises Phase 1+2 (pgvector pour RAG,
 * pgcrypto pour gen_random_uuid). Aucune table métier — créées par les
 * stories suivantes (STORY-014..STORY-020).
 */
export class Init1700000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "vector";`);
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "pgcrypto";`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP EXTENSION IF EXISTS "pgcrypto";`);
    await queryRunner.query(`DROP EXTENSION IF EXISTS "vector";`);
  }
}
