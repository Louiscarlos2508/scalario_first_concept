import { ForbiddenException } from '@nestjs/common';
import { RlsBypassService } from '../rls-bypass.service';

/**
 * STORY-017 — Whitelist enforcement for `RlsBypassService.withBypass`.
 *
 * The service runtime-rejects any caller not in `ALLOWED_CALLERS`. The
 * QueryRunner / audit path is exercised by `rls-intrusion.e2e.spec.ts`
 * against a real DB — here we only assert the gate itself, which is the
 * piece reviewers add or remove most often during refactors.
 */
describe('RlsBypassService — whitelist gate', () => {
  let service: RlsBypassService;

  beforeEach(() => {
    // Admin DataSource is never touched if the gate throws first.
    service = new RlsBypassService({} as never);
  });

  it('rejects a non-whitelisted caller before opening a connection', async () => {
    await expect(
      service.withBypass(
        { caller: 'EvilService.exfiltrate' as never, reason: 'attempted exploit' },
        async () => 'should-never-run',
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('error message lists the full whitelist (defender visibility)', async () => {
    try {
      await service.withBypass(
        { caller: 'EvilService.exfiltrate' as never, reason: 'x' },
        async () => 'x',
      );
      fail('expected ForbiddenException');
    } catch (err) {
      expect((err as Error).message).toMatch(/TenantsService\.provision/);
      expect((err as Error).message).toMatch(/AuthService\.superAdminLogin/);
      expect((err as Error).message).toMatch(/CleanupService\.purge/);
    }
  });
});
