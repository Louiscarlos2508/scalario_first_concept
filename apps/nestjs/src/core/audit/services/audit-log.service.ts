import { Inject, Injectable, Logger, OnModuleDestroy, Optional } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { DataSource } from 'typeorm';
import { ADMIN_DATA_SOURCE } from '../../../common/database.module';
import { tenantContext } from '../../../common/context/tenant-context';
import { AUDIT_BUFFER, SYNC_AUDIT_ACTIONS } from '../constants';
import type { AuditEntry, AuditEntryInput } from '../interfaces/audit-entry.interface';

/**
 * STORY-020 — Insert-only audit log writer.
 *
 * Design points:
 *
 *   1. **Auto-fill from `tenantContext`.** Callers usually omit
 *      `tenant_id` / `user_id`; the request-scoped ALS context fills
 *      them in. Worker / cron paths must provide them explicitly.
 *
 *   2. **SHA-256 hash, never the payload.** `payload` (arbitrary input)
 *      is hashed before insert. The raw payload is dropped — we still
 *      get duplicate detection without persisting PII (architecture
 *      line 836).
 *
 *   3. **Async batching for throughput, sync for critical events.**
 *      Most events join a tiny in-memory buffer that flushes every
 *      second (or when 100 entries pile up). Critical events
 *      (`SYNC_AUDIT_ACTIONS`) block the caller until the row hits
 *      Postgres — losing them on a crash defeats forensics.
 *
 *   4. **Audit never crashes the app.** Every DB write is wrapped
 *      in try/catch; on failure we log to console / Sentry and keep
 *      going. Audit is a forensic tool, not a hard dependency.
 *
 *   5. **Uses ADMIN_DATA_SOURCE on purpose.** `audit_logs` has RLS
 *      enabled (STORY-017): inserting via `scalario_app` requires
 *      `app.current_tenant_id` to be set, which is fine for request
 *      paths but breaks for fire-and-forget flushes that run after
 *      the request ALS scope has closed. Using the admin pool avoids
 *      the GUC ordering trap. Every audit row still carries an
 *      explicit `tenant_id` column, so cross-tenant queries through
 *      the GET endpoint stay RLS-protected (that path goes through
 *      the app pool with `tenant_id` filter in the WHERE).
 */
@Injectable()
export class AuditLogService implements OnModuleDestroy {
  private readonly logger = new Logger(AuditLogService.name);
  private buffer: AuditEntry[] = [];
  private flushTimer: NodeJS.Timeout | null = null;
  private dropWarned = false;

  constructor(
    @Inject(ADMIN_DATA_SOURCE) private readonly ds: DataSource,
    @Optional() flushIntervalMs?: number,
  ) {
    const interval = flushIntervalMs ?? AUDIT_BUFFER.FLUSH_INTERVAL_MS;
    // In NODE_ENV=test we don't start the timer — tests call flush() manually
    // so they don't leak open handles. Production starts the periodic flush.
    if (process.env.NODE_ENV !== 'test' && interval > 0) {
      this.flushTimer = setInterval(() => {
        void this.flush();
      }, interval);
      // Don't keep the event loop alive on shutdown.
      this.flushTimer.unref?.();
    }
  }

  /**
   * Persist an audit entry. Auto-fills `tenant_id` / `user_id` from
   * `tenantContext` if omitted. Returns when the entry has been
   * either buffered (async) or persisted (sync) — never throws.
   */
  async log(entry: AuditEntryInput): Promise<void> {
    const enriched = this.enrich(entry);

    if (SYNC_AUDIT_ACTIONS.has(entry.action)) {
      await this.insertOne(enriched);
      return;
    }

    if (this.buffer.length >= AUDIT_BUFFER.DROP_THRESHOLD) {
      // DB is unhealthy — drop oldest to bound memory. Log loudly once.
      this.buffer.shift();
      if (!this.dropWarned) {
        this.dropWarned = true;
        this.logger.error(
          `Audit buffer overflow (>${AUDIT_BUFFER.DROP_THRESHOLD}) — oldest entries dropped. Is the DB down?`,
        );
      }
    }

    this.buffer.push(enriched);

    if (this.buffer.length >= AUDIT_BUFFER.MAX_SIZE) {
      await this.flush();
    }
  }

  /**
   * Explicit flush — exposed for tests, graceful shutdown, and
   * E2E scenarios that need a deterministic order.
   */
  async flush(): Promise<number> {
    if (this.buffer.length === 0) return 0;
    const toInsert = this.buffer.splice(0);
    try {
      await this.ds.createQueryBuilder().insert().into('audit_logs').values(toInsert).execute();
      this.dropWarned = false;
      return toInsert.length;
    } catch (err) {
      // Never crash. Phase 2: Sentry + Redis Streams write-ahead log.
      this.logger.error(`Audit batch flush failed (${toInsert.length} entries)`, err as Error);
      return 0;
    }
  }

  private enrich(entry: AuditEntryInput): AuditEntry {
    const ctx = tenantContext.get();
    return {
      action: entry.action,
      tenant_id: entry.tenant_id ?? ctx?.tenant_id ?? null,
      user_id: entry.user_id ?? ctx?.user_id ?? null,
      module_id: entry.module_id ?? null,
      entity_id: entry.entity_id ?? null,
      payload_hash:
        entry.payload === undefined || entry.payload === null
          ? null
          : AuditLogService.hashPayload(entry.payload),
      metadata: entry.metadata ?? {},
      created_at: new Date(),
    };
  }

  private async insertOne(entry: AuditEntry): Promise<void> {
    try {
      await this.ds.createQueryBuilder().insert().into('audit_logs').values(entry).execute();
    } catch (err) {
      this.logger.error(`Audit sync insert failed action=${entry.action}`, err as Error);
    }
  }

  /** SHA-256 of a JSON-serializable payload — one-way, PII-safe. */
  static hashPayload(payload: unknown): string {
    let serialized: string;
    try {
      serialized = typeof payload === 'string' ? payload : JSON.stringify(payload);
    } catch {
      // Cyclic / unserializable — fall back to a tagged string so we still
      // produce a stable hash without leaking object shape.
      serialized = '[unserializable]';
    }
    return createHash('sha256').update(serialized).digest('hex');
  }

  async onModuleDestroy(): Promise<void> {
    if (this.flushTimer) clearInterval(this.flushTimer);
    await this.flush();
  }
}
