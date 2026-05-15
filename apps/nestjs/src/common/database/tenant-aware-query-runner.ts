import { Injectable } from '@nestjs/common';
import { DataSource, QueryRunner } from 'typeorm';
import { tenantContext } from '../context/tenant-context';

/**
 * STORY-016 AC-09/AC-10/AC-11 — pool-safe connection acquisition that
 * stamps `app.current_tenant_id` for the duration of the borrowed
 * connection and clears it on release so the next borrower of the same
 * connection cannot inherit a stale value.
 *
 * Use when a service needs raw SQL outside a TypeORM Repository (which
 * already runs inside the per-request context propagated by middleware).
 * STORY-017 will add a TypeORM `EntitySubscriber` that also pushes the
 * GUC on transactional queries.
 */
@Injectable()
export class TenantAwareQueryRunner {
  constructor(private readonly dataSource: DataSource) {}

  async withConnection<T>(fn: (qr: QueryRunner) => Promise<T>): Promise<T> {
    const ctx = tenantContext.get();
    const qr = this.dataSource.createQueryRunner();
    try {
      await qr.connect();
      if (ctx?.tenant_id) {
        // `SET LOCAL` requires a transaction; we want this setting to
        // outlive a single query (multiple statements in the same
        // borrowed connection), so use session-scoped `set_config`
        // with is_local=false and explicitly RESET on release.
        await qr.query("SELECT set_config('app.current_tenant_id', $1, false)", [ctx.tenant_id]);
      }
      return await fn(qr);
    } finally {
      try {
        await qr.query('RESET app.current_tenant_id');
      } catch {
        // Connection might already be dead — ignore so release still runs.
      }
      await qr.release();
    }
  }
}
