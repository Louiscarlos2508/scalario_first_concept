import 'reflect-metadata';
import { DataSource } from 'typeorm';

/**
 * TypeORM CLI DataSource — used by `migration:generate|run|revert`.
 *
 * STORY-017: migrations must run as the BYPASSRLS admin role (otherwise
 * `CREATE ROLE`, `ALTER TABLE`, `FORCE ROW LEVEL SECURITY` are denied).
 * We pick `DATABASE_URL_ADMIN` first and fall back to `DATABASE_URL` so
 * a fresh checkout without admin credentials still boots (Phase 1 dev
 * Postgres ships a single superuser).
 *
 * Production runtime uses `TypeOrmModule.forRootAsync` in
 * `database.module.ts`, which always uses `DATABASE_URL` (scalario_app).
 */
export const AppDataSource = new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL_ADMIN ?? process.env.DATABASE_URL,
  entities: ['src/**/*.entity.ts'],
  migrations: ['migrations/*.ts'],
  synchronize: false,
  migrationsRun: false,
});
