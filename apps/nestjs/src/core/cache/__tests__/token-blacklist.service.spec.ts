import { RedisService } from '../services/redis.service';
import { TokenBlacklistService } from '../services/token-blacklist.service';
import { FakeRedisService } from './fake-redis';

describe('TokenBlacklistService', () => {
  let fake: FakeRedisService;
  let service: TokenBlacklistService;

  beforeEach(() => {
    fake = new FakeRedisService();
    service = new TokenBlacklistService(fake as unknown as RedisService);
  });

  it('add() then isRevoked() returns true (AC-05/AC-06)', async () => {
    await service.add('jti-1', 60);
    expect(await service.isRevoked('jti-1')).toBe(true);
  });

  it('isRevoked() returns false for unknown key', async () => {
    expect(await service.isRevoked('never-added')).toBe(false);
  });

  it('add() with ttl <= 0 is a no-op (AC-09)', async () => {
    await service.add('jti-expired', 0);
    expect(await service.isRevoked('jti-expired')).toBe(false);
  });

  it('respects TTL — key disappears after expiry (AC-11)', async () => {
    jest.useFakeTimers();
    await service.add('jti-short', 1);
    expect(await service.isRevoked('jti-short')).toBe(true);
    jest.advanceTimersByTime(1100);
    // Flush any pending fake-timer callbacks (Store TTL eviction).
    expect(await service.isRevoked('jti-short')).toBe(false);
    jest.useRealTimers();
  });

  it('fail-open when Redis is unavailable (AC-28)', async () => {
    const downRedis = { isAvailable: () => false } as unknown as RedisService;
    const downService = new TokenBlacklistService(downRedis);
    await downService.add('jti-x', 60);
    expect(await downService.isRevoked('jti-x')).toBe(false);
  });

  it('fail-open when the client throws', async () => {
    const broken = {
      isAvailable: () => true,
      getClient: () => ({
        set: async () => {
          throw new Error('boom');
        },
        exists: async () => {
          throw new Error('boom');
        },
      }),
    } as unknown as RedisService;
    const brokenService = new TokenBlacklistService(broken);
    await brokenService.add('jti-x', 60);
    expect(await brokenService.isRevoked('jti-x')).toBe(false);
  });
});
