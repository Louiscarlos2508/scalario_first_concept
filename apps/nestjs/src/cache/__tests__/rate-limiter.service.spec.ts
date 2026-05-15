import { RateLimiterService } from '../services/rate-limiter.service';
import { RedisService } from '../services/redis.service';
import { FakeRedisService } from './fake-redis';

describe('RateLimiterService (AC-22 stub)', () => {
  let fake: FakeRedisService;
  let svc: RateLimiterService;

  beforeEach(() => {
    fake = new FakeRedisService();
    svc = new RateLimiterService(fake as unknown as RedisService);
  });

  it('increments and returns the running count', async () => {
    expect(await svc.increment('user-1', 60)).toBe(1);
    expect(await svc.increment('user-1', 60)).toBe(2);
    expect(await svc.increment('user-1', 60)).toBe(3);
  });

  it('check() returns true while under limit, false once exceeded', async () => {
    expect(await svc.check('k', 2, 60)).toBe(true); // count 1
    expect(await svc.check('k', 2, 60)).toBe(true); // count 2
    expect(await svc.check('k', 2, 60)).toBe(false); // count 3
  });

  it('returns 0 when Redis is unavailable (Phase 2 wiring stub)', async () => {
    const downSvc = new RateLimiterService({
      isAvailable: () => false,
    } as unknown as RedisService);
    expect(await downSvc.increment('k', 60)).toBe(0);
  });
});
