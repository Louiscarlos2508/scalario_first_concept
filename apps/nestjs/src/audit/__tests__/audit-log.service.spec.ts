import { DataSource } from 'typeorm';
import { tenantContext } from '../../common/context/tenant-context';
import { AUDIT_ACTIONS, AUDIT_BUFFER, SYNC_AUDIT_ACTIONS } from '../constants';
import { AuditLogService } from '../services/audit-log.service';

/**
 * STORY-020 — Unit tests for AuditLogService.
 *
 * We don't touch a real Postgres here. The test fakes a DataSource that
 * captures every batch insert, lets us assert on order, batching,
 * sync vs async paths, hash format, and crash-safety.
 */

interface CapturedInsert {
  values: Array<Record<string, unknown>>;
}

function makeFakeDs(opts: { fail?: boolean } = {}): { ds: DataSource; captured: CapturedInsert[] } {
  const captured: CapturedInsert[] = [];
  const builder = {
    insert: () => builder,
    into: () => builder,
    values: (v: unknown) => {
      const arr = Array.isArray(v) ? v : [v];
      captured.push({ values: arr as Array<Record<string, unknown>> });
      return builder;
    },
    execute: async () => {
      if (opts.fail) throw new Error('synthetic db failure');
    },
  } as unknown as ReturnType<DataSource['createQueryBuilder']>;
  const ds = {
    createQueryBuilder: () => builder,
  } as unknown as DataSource;
  return { ds, captured };
}

describe('AuditLogService', () => {
  it('hashPayload — produces a 64-char SHA-256 hex digest', () => {
    const h = AuditLogService.hashPayload({ a: 1, b: 'x' });
    expect(h).toMatch(/^[a-f0-9]{64}$/);
  });

  it('hashPayload — stable for equal payloads, different for different ones', () => {
    expect(AuditLogService.hashPayload({ a: 1 })).toEqual(AuditLogService.hashPayload({ a: 1 }));
    expect(AuditLogService.hashPayload({ a: 1 })).not.toEqual(
      AuditLogService.hashPayload({ a: 2 }),
    );
  });

  it('auto-fills tenant_id + user_id from tenantContext', async () => {
    const { ds, captured } = makeFakeDs();
    const svc = new AuditLogService(ds);
    await tenantContext.run({ tenant_id: 'T1', user_id: 'U1' }, async () => {
      await svc.log({ action: AUDIT_ACTIONS.AUTH_LOGOUT });
    });
    await svc.flush();
    expect(captured.at(-1)?.values[0]).toMatchObject({
      tenant_id: 'T1',
      user_id: 'U1',
      action: AUDIT_ACTIONS.AUTH_LOGOUT,
    });
    await svc.onModuleDestroy();
  });

  it('payload is hashed, never persisted', async () => {
    const { ds, captured } = makeFakeDs();
    const svc = new AuditLogService(ds);
    await svc.log({
      action: AUDIT_ACTIONS.AUTH_LOGOUT,
      tenant_id: 'T',
      user_id: 'U',
      payload: { secret: 'top' },
    });
    await svc.flush();
    const row = captured.at(-1)?.values[0] as Record<string, unknown>;
    expect(row.payload_hash).toMatch(/^[a-f0-9]{64}$/);
    expect(JSON.stringify(row)).not.toContain('top');
  });

  it('SYNC_AUDIT_ACTIONS — inserts synchronously (one row per call)', async () => {
    expect(SYNC_AUDIT_ACTIONS.has(AUDIT_ACTIONS.RLS_BYPASS_USED)).toBe(true);
    const { ds, captured } = makeFakeDs();
    const svc = new AuditLogService(ds);
    await svc.log({
      action: AUDIT_ACTIONS.RLS_BYPASS_USED,
      tenant_id: 'T',
      user_id: 'U',
    });
    // No flush required for sync events — the row is already written.
    expect(captured).toHaveLength(1);
    expect(captured[0].values[0]).toMatchObject({ action: AUDIT_ACTIONS.RLS_BYPASS_USED });
    await svc.onModuleDestroy();
  });

  it('async events — buffered and flushed in one batch', async () => {
    const { ds, captured } = makeFakeDs();
    const svc = new AuditLogService(ds);
    for (let i = 0; i < 5; i++) {
      await svc.log({ action: AUDIT_ACTIONS.AUTH_LOGOUT, tenant_id: 'T', user_id: 'U' });
    }
    expect(captured).toHaveLength(0); // nothing flushed yet
    await svc.flush();
    expect(captured).toHaveLength(1);
    expect(captured[0].values).toHaveLength(5);
    await svc.onModuleDestroy();
  });

  it('forced flush at MAX_SIZE threshold', async () => {
    const { ds, captured } = makeFakeDs();
    const svc = new AuditLogService(ds);
    for (let i = 0; i < AUDIT_BUFFER.MAX_SIZE; i++) {
      await svc.log({ action: AUDIT_ACTIONS.AUTH_LOGOUT, tenant_id: 'T', user_id: 'U' });
    }
    expect(captured).toHaveLength(1);
    expect(captured[0].values).toHaveLength(AUDIT_BUFFER.MAX_SIZE);
    await svc.onModuleDestroy();
  });

  it('never throws if DB is down — async path', async () => {
    const { ds, captured } = makeFakeDs({ fail: true });
    const svc = new AuditLogService(ds);
    await expect(
      svc.log({ action: AUDIT_ACTIONS.AUTH_LOGOUT, tenant_id: 'T', user_id: 'U' }),
    ).resolves.toBeUndefined();
    await expect(svc.flush()).resolves.toBe(0);
    expect(captured.length).toBeGreaterThanOrEqual(1); // attempt was made
    await svc.onModuleDestroy();
  });

  it('never throws if DB is down — sync (critical) path', async () => {
    const { ds } = makeFakeDs({ fail: true });
    const svc = new AuditLogService(ds);
    await expect(
      svc.log({
        action: AUDIT_ACTIONS.RLS_BYPASS_USED,
        tenant_id: 'T',
        user_id: 'U',
      }),
    ).resolves.toBeUndefined();
    await svc.onModuleDestroy();
  });
});
