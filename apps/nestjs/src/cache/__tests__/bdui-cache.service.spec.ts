import { BdUiCacheService } from '../services/bdui-cache.service';
import { RedisService } from '../services/redis.service';
import { FakeRedisService, pair } from './fake-redis';

const flush = () => new Promise<void>((r) => setImmediate(r));

async function makeService(fake: FakeRedisService): Promise<BdUiCacheService> {
  const svc = new BdUiCacheService(fake as unknown as RedisService);
  await svc.onModuleInit();
  return svc;
}

describe('BdUiCacheService', () => {
  let fake: FakeRedisService;
  let svc: BdUiCacheService;

  beforeEach(async () => {
    fake = new FakeRedisService();
    svc = await makeService(fake);
  });

  afterEach(() => fake.reset());

  it('set + get round-trips small payloads (AC-12, AC-13)', async () => {
    await svc.set('acme', 'dashboard', 'OWNER', { hello: 'world' });
    expect(await svc.get('acme', 'dashboard', 'OWNER')).toEqual({ hello: 'world' });
  });

  it('get() returns null on miss', async () => {
    expect(await svc.get('acme', 'never', 'OWNER')).toBeNull();
  });

  it('gzips payloads > 10KB and decompresses on read', async () => {
    const big = { data: 'x'.repeat(20_000) };
    await svc.set('acme', 'big', 'OWNER', big);
    svc.clearLocal(); // force L2 (Redis) round-trip
    expect(await svc.get('acme', 'big', 'OWNER')).toEqual(big);
  });

  it('L1 hit avoids the L2 call', async () => {
    await svc.set('acme', 'd', 'OWNER', { v: 1 });
    const spy = jest.spyOn(fake.getClient(), 'getBuffer');
    expect(await svc.get('acme', 'd', 'OWNER')).toEqual({ v: 1 });
    expect(spy).not.toHaveBeenCalled();
  });

  it('invalidate(tenant, screen) deletes matching keys (AC-14)', async () => {
    await svc.set('acme', 'dashboard', 'OWNER', { a: 1 });
    await svc.set('acme', 'dashboard', 'MANAGER', { a: 2 });
    await svc.set('acme', 'orders', 'OWNER', { a: 3 });

    await svc.invalidate('acme', 'dashboard');
    svc.clearLocal();

    expect(await svc.get('acme', 'dashboard', 'OWNER')).toBeNull();
    expect(await svc.get('acme', 'dashboard', 'MANAGER')).toBeNull();
    expect(await svc.get('acme', 'orders', 'OWNER')).toEqual({ a: 3 });
  });

  it('invalidate(tenant) wipes the whole tenant', async () => {
    await svc.set('acme', 'a', 'OWNER', { x: 1 });
    await svc.set('acme', 'b', 'OWNER', { x: 2 });
    await svc.set('other', 'a', 'OWNER', { x: 3 });

    await svc.invalidate('acme');
    svc.clearLocal();

    expect(await svc.get('acme', 'a', 'OWNER')).toBeNull();
    expect(await svc.get('acme', 'b', 'OWNER')).toBeNull();
    expect(await svc.get('other', 'a', 'OWNER')).toEqual({ x: 3 });
  });
});

describe('BdUiCacheService — cross-process pub/sub (AC-17/18/19)', () => {
  it('publish on instance B invalidates L1 on instance A', async () => {
    const { a, b } = pair();
    const nodeA = await makeService(a);
    const nodeB = await makeService(b);

    await nodeA.set('acme', 'dashboard', 'OWNER', { node: 'A' });
    // L1 of A is populated. Now publish invalidation from B.
    await nodeB.invalidate('acme', 'dashboard');

    // Give the pub/sub setImmediate a chance to deliver to A.
    await flush();
    await flush();

    // A must not return its stale L1 — and L2 was wiped too.
    expect(await nodeA.get('acme', 'dashboard', 'OWNER')).toBeNull();
  });
});
