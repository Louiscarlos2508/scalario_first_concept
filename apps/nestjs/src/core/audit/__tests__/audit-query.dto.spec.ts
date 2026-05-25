import { AuditQuerySchema, decodeCursor, encodeCursor } from '../dto/audit-query.dto';

describe('AuditQuerySchema', () => {
  it('coerces limit string → number, default 100', () => {
    const parsed = AuditQuerySchema.parse({});
    expect(parsed.limit).toBe(100);
  });

  it('rejects malformed action', () => {
    const r = AuditQuerySchema.safeParse({ action: 'lower_case' });
    expect(r.success).toBe(false);
  });

  it('accepts ISO datetime for from/to', () => {
    const r = AuditQuerySchema.parse({ from: '2026-05-01T00:00:00Z' });
    expect(r.from).toBe('2026-05-01T00:00:00Z');
  });

  it('caps limit at 500', () => {
    const r = AuditQuerySchema.safeParse({ limit: 1000 });
    expect(r.success).toBe(false);
  });
});

describe('cursor codec', () => {
  it('round-trips a payload', () => {
    const payload = {
      created_at: '2026-05-15T12:00:00.000Z',
      id: '00000000-0000-0000-0000-000000000001',
    };
    const enc = encodeCursor(payload);
    expect(decodeCursor(enc)).toEqual(payload);
  });

  it('rejects garbage', () => {
    expect(decodeCursor('not-base64')).toBeNull();
    expect(decodeCursor('YWJj' /* base64 'abc' */)).toBeNull();
  });
});
