import { Global, Logger, Module, OnModuleInit } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

export const ADMIN_DATA_SOURCE = 'ADMIN_DATA_SOURCE';

/**
 * STORY-017 — Two-pool DataSource.
 *
 *   - `TypeOrmModule.forRootAsync` (the default DataSource) connects as
 *     `scalario_app` via DATABASE_URL — NO BYPASSRLS, RLS enforced on
 *     every query. This is the user every controller/service/repository
 *     uses transparently.
 *
 *   - `ADMIN_DATA_SOURCE` (custom provider, tiny pool of 2) connects as
 *     `scalario_admin` via DATABASE_URL_ADMIN — BYPASSRLS. Reserved for
 *     the 3 whitelisted call sites guarded by `RlsBypassService`:
 *     tenants.service (provisioning), auth.service (super admin login),
 *     cron/cleanup.service (cross-tenant purge).
 *
 * The boot check (`onModuleInit`) refuses to start if the app DataSource
 * is connected as a role that has BYPASSRLS — that would silently defeat
 * Layer 5 and is a fatal misconfiguration.
 */
@Global()
@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      useFactory: () => ({
        type: 'postgres',
        url: process.env.DATABASE_URL,
        synchronize: false,
        migrationsRun: false,
        migrations: ['dist/migrations/*.js'],
        autoLoadEntities: true,
        extra: { max: 10 },
      }),
    }),
  ],
  providers: [
    {
      provide: ADMIN_DATA_SOURCE,
      useFactory: async (): Promise<DataSource> => {
        const adminUrl = process.env.DATABASE_URL_ADMIN ?? process.env.DATABASE_URL;
        if (!adminUrl) {
          throw new Error(
            'DATABASE_URL_ADMIN (or DATABASE_URL) must be set — required by RlsBypassService.',
          );
        }
        const ds = new DataSource({
          type: 'postgres',
          url: adminUrl,
          synchronize: false,
          migrationsRun: false,
          extra: { max: 2 },
        });
        await ds.initialize();
        return ds;
      },
    },
  ],
  exports: [TypeOrmModule, ADMIN_DATA_SOURCE],
})
export class DatabaseModule implements OnModuleInit {
  private readonly logger = new Logger(DatabaseModule.name);

  constructor(private readonly dataSource: DataSource) {}

  async onModuleInit(): Promise<void> {
    // Tests and one-off scripts can opt out of the check (they often
    // connect with the admin role since RLS is verified by dedicated
    // intrusion specs).
    if (process.env.NODE_ENV === 'test' || process.env.RLS_BOOT_CHECK === 'skip') {
      return;
    }
    if (!this.dataSource.isInitialized) return;

    try {
      const rows: Array<{ current_user: string; bypassrls: boolean }> = await this.dataSource.query(
        `SELECT current_user, rolbypassrls AS bypassrls
           FROM pg_roles WHERE rolname = current_user`,
      );
      const row = rows[0];
      if (!row) {
        this.logger.warn('Could not introspect current_user role — RLS boot check skipped.');
        return;
      }
      if (row.bypassrls) {
        throw new Error(
          `Fatal: app DataSource connected as '${row.current_user}' which has BYPASSRLS. ` +
            `RLS Layer 5 would be silently disabled. Point DATABASE_URL at scalario_app.`,
        );
      }
      this.logger.log(
        `RLS boot check OK — app DataSource connected as '${row.current_user}' (NOBYPASSRLS).`,
      );
    } catch (err) {
      // Re-throw only the BYPASSRLS error; transient query errors should
      // not crash boot (the connection will simply retry).
      if ((err as Error).message?.startsWith('Fatal:')) throw err;
      this.logger.warn(`RLS boot check failed to query pg_roles: ${(err as Error).message}`);
    }
  }
}
