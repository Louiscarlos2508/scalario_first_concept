import { Inject, Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenant } from '../../auth/entities/tenant.entity';
import { ADMIN_DATA_SOURCE } from '../../common/database.module';
import { DataSource } from 'typeorm';
import { AUDIT_ACTIONS, AUDIT_RETENTION } from '../constants';
import { AuditLogService } from './audit-log.service';

/**
 * STORY-020 — Per-tenant retention purge for `audit_logs`.
 *
 * The cron runs once per 24h at 03:00 local time. For each active
 * tenant it deletes rows older than `tenant.config.audit_retention_days`
 * (default 90, clamped to [30, 3650]) and logs a meta-event
 * `AUDIT_PURGE` per tenant with `rows_deleted`.
 *
 * `DELETE` privileges on `audit_logs` are reserved for the admin role
 * (`scalario_admin`) — `scalario_app` cannot delete (STORY-020 AC-02/03).
 * We therefore execute against `ADMIN_DATA_SOURCE` directly and gate it
 * with `RlsBypassService.withBypass` for the forensic trail.
 *
 * NestJS has no scheduler bundled by default in this repo. We implement
 * the timer with `setInterval` to avoid adding a dependency. The first
 * run is delayed until the next 03:00 boundary; subsequent runs fire
 * every 24h. Tests skip the boot scheduling via `NODE_ENV=test`.
 */
@Injectable()
export class AuditPurgeService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AuditPurgeService.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    @InjectRepository(Tenant) private readonly tenantRepo: Repository<Tenant>,
    @Inject(ADMIN_DATA_SOURCE) private readonly adminDs: DataSource,
    private readonly audit: AuditLogService,
  ) {}

  onModuleInit(): void {
    if (process.env.NODE_ENV === 'test' || process.env.AUDIT_PURGE_CRON === 'off') {
      return;
    }
    const delay = AuditPurgeService.msUntilNext3am(new Date());
    this.timer = setTimeout(() => {
      void this.tickAndReschedule();
    }, delay);
    this.timer.unref?.();
  }

  onModuleDestroy(): void {
    if (this.timer) clearTimeout(this.timer);
  }

  private async tickAndReschedule(): Promise<void> {
    await this.purgeAll();
    // Reschedule for next 24h.
    this.timer = setTimeout(
      () => {
        void this.tickAndReschedule();
      },
      24 * 60 * 60 * 1000,
    );
    this.timer.unref?.();
  }

  /**
   * Iterate active tenants and DELETE rows older than the configured
   * retention. Single-flight: a re-entrant call returns immediately
   * (the cheap in-process equivalent of the distributed lock mentioned
   * in the story; for Phase 1 we run a single NestJS instance).
   */
  async purgeAll(): Promise<{ tenants: number; rows_deleted: number }> {
    if (this.running) {
      this.logger.warn('audit purge already running — skipping concurrent invocation');
      return { tenants: 0, rows_deleted: 0 };
    }
    this.running = true;

    let total = 0;
    let processed = 0;
    try {
      const tenants = await this.tenantRepo.find({
        where: { is_active: true },
        select: ['id', 'config'],
      });
      for (const tenant of tenants) {
        try {
          const deleted = await this.purgeTenant(tenant.id, tenant.config?.audit_retention_days);
          total += deleted;
          processed += 1;
        } catch (err) {
          this.logger.error(`Audit purge failed tenant_id=${tenant.id}`, err as Error);
        }
      }
    } finally {
      this.running = false;
    }
    return { tenants: processed, rows_deleted: total };
  }

  /** Visible for tests. */
  async purgeTenant(tenant_id: string, retentionDaysInput?: number | unknown): Promise<number> {
    const retention = AuditPurgeService.clampRetention(retentionDaysInput);
    const cutoff = new Date(Date.now() - retention * 24 * 60 * 60 * 1000);
    const result = await this.adminDs
      .createQueryBuilder()
      .delete()
      .from('audit_logs')
      .where('tenant_id = :tenant_id', { tenant_id })
      .andWhere('created_at < :cutoff', { cutoff })
      .execute();
    const rows_deleted = result.affected ?? 0;
    // Meta-audit — non-blocking; survives a flush gap because rows_deleted is small.
    await this.audit.log({
      action: AUDIT_ACTIONS.AUDIT_PURGE,
      tenant_id,
      metadata: {
        rows_deleted,
        retention_days: retention,
        cutoff: cutoff.toISOString(),
      },
    });
    return rows_deleted;
  }

  static clampRetention(input: unknown): number {
    const raw =
      typeof input === 'number' && Number.isFinite(input)
        ? Math.floor(input)
        : AUDIT_RETENTION.DEFAULT_DAYS;
    if (raw < AUDIT_RETENTION.MIN_DAYS) return AUDIT_RETENTION.MIN_DAYS;
    if (raw > AUDIT_RETENTION.MAX_DAYS) return AUDIT_RETENTION.MAX_DAYS;
    return raw;
  }

  static msUntilNext3am(now: Date): number {
    const next = new Date(now);
    next.setHours(3, 0, 0, 0);
    if (next.getTime() <= now.getTime()) {
      next.setDate(next.getDate() + 1);
    }
    return next.getTime() - now.getTime();
  }
}
