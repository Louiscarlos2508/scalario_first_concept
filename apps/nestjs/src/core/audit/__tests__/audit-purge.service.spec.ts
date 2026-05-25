import { AUDIT_RETENTION } from '../constants';
import { AuditPurgeService } from '../services/audit-purge.service';

describe('AuditPurgeService — pure helpers', () => {
  it('clampRetention — defaults to 90 when input is missing or not a number', () => {
    expect(AuditPurgeService.clampRetention(undefined)).toBe(AUDIT_RETENTION.DEFAULT_DAYS);
    expect(AuditPurgeService.clampRetention('30' as unknown as number)).toBe(
      AUDIT_RETENTION.DEFAULT_DAYS,
    );
    expect(AuditPurgeService.clampRetention(NaN)).toBe(AUDIT_RETENTION.DEFAULT_DAYS);
  });

  it('clampRetention — clamps below MIN', () => {
    expect(AuditPurgeService.clampRetention(0)).toBe(AUDIT_RETENTION.MIN_DAYS);
    expect(AuditPurgeService.clampRetention(15)).toBe(AUDIT_RETENTION.MIN_DAYS);
  });

  it('clampRetention — clamps above MAX', () => {
    expect(AuditPurgeService.clampRetention(99999)).toBe(AUDIT_RETENTION.MAX_DAYS);
  });

  it('clampRetention — preserves valid values', () => {
    expect(AuditPurgeService.clampRetention(60)).toBe(60);
    expect(AuditPurgeService.clampRetention(365)).toBe(365);
  });

  it('msUntilNext3am — schedules tonight if before 3am, tomorrow if after', () => {
    const before = new Date('2026-05-15T02:30:00');
    const ms1 = AuditPurgeService.msUntilNext3am(before);
    expect(ms1).toBe(30 * 60 * 1000); // 30 min

    const after = new Date('2026-05-15T03:00:01');
    const ms2 = AuditPurgeService.msUntilNext3am(after);
    // ~24h minus 1s.
    expect(ms2).toBeGreaterThan(23 * 60 * 60 * 1000);
    expect(ms2).toBeLessThanOrEqual(24 * 60 * 60 * 1000);
  });
});
