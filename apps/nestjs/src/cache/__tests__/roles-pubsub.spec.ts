import { Tenant } from '../../auth/entities/tenant.entity';
import { RolesService } from '../../security/services/roles.service';
import { RedisService } from '../services/redis.service';
import { pair } from './fake-redis';

const flush = () => new Promise<void>((r) => setImmediate(r));

/**
 * STORY-018 — AC-19 / AC-21. Two `RolesService` instances share a
 * single Redis backend (simulating two NestJS nodes). When one
 * invalidates the cache, the other must drop its L1 entry by the next
 * tick.
 */
describe('RolesService — cross-node invalidation (STORY-018)', () => {
  it('invalidate on node B clears node A L1 via pub/sub', async () => {
    const { a, b } = pair();

    const tenant: Tenant = {
      id: 't1',
      name: 'Acme',
      slug: 'acme',
      is_active: true,
      config: { roles: ['OWNER', 'MANAGER'] },
      created_at: new Date(),
      updated_at: new Date(),
    };

    const repoA = {
      findOne: jest.fn(async () => tenant),
      update: jest.fn(),
    };
    const repoB = {
      findOne: jest.fn(async () => tenant),
      update: jest.fn(),
    };

    const nodeA = new RolesService(repoA as never, a as unknown as RedisService);
    const nodeB = new RolesService(repoB as never, b as unknown as RedisService);

    await nodeA.onModuleInit();
    await nodeB.onModuleInit();

    // Prime node A's L1.
    expect(await nodeA.getRolesForTenant('t1')).toEqual(['OWNER', 'MANAGER']);
    expect(repoA.findOne).toHaveBeenCalledTimes(1);

    // Node B mutates and invalidates. Node A must observe the change.
    tenant.config = { roles: ['OWNER', 'MANAGER', 'LIVREUR'] };
    await nodeB.invalidateCache('t1');

    await flush();
    await flush();

    expect(await nodeA.getRolesForTenant('t1')).toEqual(['OWNER', 'MANAGER', 'LIVREUR']);
    // Node A re-hit the DB after L1 was wiped by the pub/sub message.
    expect(repoA.findOne).toHaveBeenCalledTimes(2);
  });
});
