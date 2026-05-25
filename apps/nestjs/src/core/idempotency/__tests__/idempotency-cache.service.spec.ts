import { IdempotencyCacheService } from '../idempotency-cache.service';
import { RedisService } from '../../cache/services/redis.service';
import { FakeRedisService } from '../../cache/__tests__/fake-redis';

describe('IdempotencyCacheService', () => {
  let fake: FakeRedisService;
  let svc: IdempotencyCacheService;

  beforeEach(() => {
    fake = new FakeRedisService();
    svc = new IdempotencyCacheService(fake as unknown as RedisService);
  });

  afterEach(() => fake.reset());

  it('AC-04 — lookup() returns null on miss', async () => {
    expect(await svc.lookup('tenant-1', 'key-1')).toBeNull();
  });

  it('AC-04 — store() then lookup() round-trips response', async () => {
    await svc.store('tenant-1', 'key-1', {
      status: 200,
      body: { id: 42 },
      contentType: 'application/json',
      capturedAt: '2026-05-21T10:00:00Z',
    });
    const got = await svc.lookup('tenant-1', 'key-1');
    expect(got).toEqual({
      status: 200,
      body: { id: 42 },
      contentType: 'application/json',
      capturedAt: '2026-05-21T10:00:00Z',
    });
  });

  it('AC-11 — keys are scoped by tenant_id', async () => {
    await svc.store('tenant-A', 'shared-key', {
      status: 200,
      body: { tenant: 'A' },
      contentType: 'application/json',
      capturedAt: '2026-05-21T10:00:00Z',
    });
    // Tenant B with same key sees no cache.
    expect(await svc.lookup('tenant-B', 'shared-key')).toBeNull();
    // Tenant A still sees its own.
    expect(await svc.lookup('tenant-A', 'shared-key')).not.toBeNull();
  });

  it('AC-05 — collision (same key, different body) keeps the first cached response', async () => {
    await svc.store('t', 'k', {
      status: 200,
      body: { v: 1 },
      contentType: 'application/json',
      capturedAt: '2026-05-21T10:00:00Z',
    });
    await svc.store('t', 'k', {
      status: 200,
      body: { v: 2 }, // different payload
      contentType: 'application/json',
      capturedAt: '2026-05-21T10:00:01Z',
    });
    const got = await svc.lookup('t', 'k');
    expect((got?.body as { v: number }).v).toBe(1);
    expect(svc.getMetrics().collisions).toBe(1);
  });

  it('AC-05 — idempotent store (same body) does not increment collisions', async () => {
    const payload = {
      status: 200,
      body: { v: 1 },
      contentType: 'application/json',
      capturedAt: '2026-05-21T10:00:00Z',
    };
    await svc.store('t', 'k', payload);
    await svc.store('t', 'k', payload);
    expect(svc.getMetrics().collisions).toBe(0);
  });

  it('fail-open on Redis unavailability', async () => {
    const unavailable = {
      isAvailable: () => false,
      getClient: () => {
        throw new Error('boom');
      },
    } as unknown as RedisService;
    const failOpenSvc = new IdempotencyCacheService(unavailable);
    expect(await failOpenSvc.lookup('t', 'k')).toBeNull();
    await expect(
      failOpenSvc.store('t', 'k', {
        status: 200,
        body: {},
        contentType: 'application/json',
        capturedAt: 'now',
      }),
    ).resolves.toBeUndefined();
  });

  it('tracks hit/miss counters', async () => {
    await svc.lookup('t', 'missing-1'); // miss
    await svc.lookup('t', 'missing-2'); // miss
    await svc.store('t', 'k', {
      status: 200,
      body: {},
      contentType: 'application/json',
      capturedAt: 'now',
    });
    await svc.lookup('t', 'k'); // hit
    const m = svc.getMetrics();
    expect(m.hits).toBe(1);
    expect(m.misses).toBe(2);
  });
});
