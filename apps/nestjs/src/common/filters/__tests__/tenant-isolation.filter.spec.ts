import { QueryFailedError } from 'typeorm';
import { TenantIsolationFilter } from '../tenant-isolation.filter';

function makeHost() {
  const json = jest.fn();
  const status = jest.fn(() => ({ json }));
  return {
    switchToHttp: () => ({
      getResponse: () => ({ status }),
    }),
    status,
    json,
  } as never;
}

function rlsError(): QueryFailedError {
  const err = new QueryFailedError('select 1', [], new Error('rls'));
  // TypeORM forwards the driver error under `driverError`.
  (err as unknown as { driverError: { code: string } }).driverError = { code: '42501' };
  return err;
}

describe('TenantIsolationFilter (AC-19)', () => {
  const filter = new TenantIsolationFilter();

  it('converts PostgreSQL 42501 to a sanitized 403', () => {
    const host = makeHost();
    filter.catch(rlsError(), host);
    const h = host as unknown as { status: jest.Mock; json: jest.Mock };
    expect(h.status).toHaveBeenCalledWith(403);
    expect(h.json).toHaveBeenCalledTimes(1);
    const body = h.json.mock.calls[0][0] as { message?: string };
    expect(body.message).toBe('Tenant isolation violation');
    // Sanitized — no SQL leak.
    const serialized = JSON.stringify(body);
    expect(serialized).not.toContain('select 1');
    expect(serialized).not.toContain('42501');
  });

  it('re-throws non-RLS QueryFailedError', () => {
    const other = new QueryFailedError('insert into x', [], new Error('dup'));
    (other as unknown as { driverError: { code: string } }).driverError = { code: '23505' };
    expect(() => filter.catch(other, makeHost())).toThrow(QueryFailedError);
  });
});
