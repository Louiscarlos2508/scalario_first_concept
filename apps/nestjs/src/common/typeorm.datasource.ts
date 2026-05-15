import 'reflect-metadata';
import { DataSource } from 'typeorm';

/**
 * TypeORM CLI DataSource — used by `migration:generate|run|revert` scripts.
 * Production runtime uses `TypeOrmModule.forRootAsync` in `database.module.ts`.
 */
export const AppDataSource = new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL,
  entities: ['src/**/*.entity.ts'],
  migrations: ['migrations/*.ts'],
  synchronize: false,
  migrationsRun: false,
});
