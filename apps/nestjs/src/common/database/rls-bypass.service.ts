import { ForbiddenException, Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { DataSource, QueryRunner } from 'typeorm';
import { ADMIN_DATA_SOURCE } from '../database.module';
import { tenantContext } from '../context/tenant-context';
import { AuditLogService } from '../../core/audit/services/audit-log.service';
import { AUDIT_ACTIONS } from '../../core/audit/constants';

/**
 * STORY-017 — `withBypass` is the ONLY legitimate way to read or write
 * cross-tenant. It opens a connection against `ADMIN_DATA_SOURCE`
 * (scalario_admin, BYPASSRLS) so the caller can see/modify rows of any
 * tenant — and immediately publishes an `audit_logs` row so the action is
 * traceable forever.
 *
 * Defense-in-depth:
 *   1. Whitelist check (runtime): only the 3 caller names below may use it.
 *   2. Audit log (mandatory): every invocation produces an immutable row.
 *   3. CI lint (apps/nestjs/scripts/check-rls-bypass-callers.sh): rejects
 *      a PR that adds a new call site outside the whitelist.
 *
 * The whitelist is intentionally a string equality check, not a regex —
 * a defender reading this file should see the exhaustive list at a glance.
 */
const ALLOWED_CALLERS = [
  'TenantsService.provision',
  'AuthService.superAdminLogin',
  'CleanupService.purge',
] as const;
export type RlsBypassCaller = (typeof ALLOWED_CALLERS)[number];

export interface RlsBypassOptions {
  /** Free-form reason, persisted in audit_logs.metadata.reason. */
  reason: string;
  /** Must be one of `ALLOWED_CALLERS` — otherwise the call throws. */
  caller: RlsBypassCaller;
  /**
   * Optional: if the bypass is scoped to a known tenant (e.g. provisioning
   * the row for tenant X), pass it here for the audit trail.
   */
  tenantFilter?: string;
}

@Injectable()
export class RlsBypassService {
  private readonly logger = new Logger(RlsBypassService.name);

  constructor(
    @Inject(ADMIN_DATA_SOURCE) private readonly adminDS: DataSource,
    @Optional() private readonly audit?: AuditLogService,
  ) {}

  async withBypass<T>(opts: RlsBypassOptions, fn: (qr: QueryRunner) => Promise<T>): Promise<T> {
    if (!ALLOWED_CALLERS.includes(opts.caller)) {
      throw new ForbiddenException(
        `RLS bypass not allowed from '${opts.caller}'. ` +
          `Whitelist: ${ALLOWED_CALLERS.join(', ')}.`,
      );
    }

    const ctx = tenantContext.get();
    const qr = this.adminDS.createQueryRunner();
    try {
      await qr.connect();

      // Audit FIRST (synchronous, critical event — see STORY-020
      // SYNC_AUDIT_ACTIONS) so a crashing `fn` still leaves a breadcrumb.
      const auditTenant = ctx?.tenant_id ?? opts.tenantFilter ?? null;
      const auditUser = ctx?.user_id ?? null;
      if (this.audit) {
        await this.audit.log({
          action: AUDIT_ACTIONS.RLS_BYPASS_USED,
          tenant_id: auditTenant,
          user_id: auditUser,
          metadata: {
            caller: opts.caller,
            reason: opts.reason,
            tenant_filter: opts.tenantFilter ?? null,
          },
        });
      } else {
        // Bootstrap path before AuditLogService is wired (tests / very
        // early provisioning). Fall back to direct SQL — non-fatal.
        if (auditTenant && auditUser) {
          try {
            await qr.query(
              `INSERT INTO audit_logs (tenant_id, user_id, action, metadata)
               VALUES ($1, $2, 'RLS_BYPASS_USED', $3::jsonb)`,
              [
                auditTenant,
                auditUser,
                JSON.stringify({
                  caller: opts.caller,
                  reason: opts.reason,
                  tenant_filter: opts.tenantFilter ?? null,
                }),
              ],
            );
          } catch (err) {
            this.logger.warn(`audit_logs insert skipped: ${(err as Error).message}`);
          }
        }
      }

      return await fn(qr);
    } finally {
      await qr.release();
    }
  }
}
