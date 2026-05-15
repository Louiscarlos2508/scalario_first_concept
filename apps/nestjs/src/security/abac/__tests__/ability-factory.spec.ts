import type { Repository } from 'typeorm';
import type { Tenant } from '../../../auth/entities/tenant.entity';
import { AbilityFactory } from '../ability.factory';
import { CaslAbacEngine } from '../engines/casl.engine';
import { FakeRedisService } from '../../../cache/__tests__/fake-redis';
import type { RedisService } from '../../../cache/services/redis.service';
import type { AbacUser } from '../types';

const USER: AbacUser = {
  user_id: 'u-1',
  tenant_id: 't-1',
  roles: ['MANAGER'],
  department_id: 'dept-A',
};

function tenant(overrides: Partial<Tenant> = {}): Tenant {
  return {
    id: 't-1',
    name: 'Acme',
    slug: 'acme',
    is_active: true,
    config: {
      roles: ['OWNER', 'MANAGER'],
      version: 1,
      abac_rules: [
        {
          action: 'read',
          subject: 'Invoice',
          roles: ['MANAGER'],
          conditions: { department_id: '$user.department_id' },
        },
      ],
    } as Tenant['config'],
    created_at: new Date(),
    updated_at: new Date(),
    ...overrides,
  };
}

describe('AbilityFactory', () => {
  it('builds an ability that honours conditions', async () => {
    const engine = new CaslAbacEngine();
    const redis = new FakeRedisService();
    const factory = new AbilityFactory(
      engine,
      {} as Repository<Tenant>,
      redis as unknown as RedisService,
    );
    const ability = await factory.createForUser(USER, tenant());
    expect(ability.can('read', { __type: 'Invoice', department_id: 'dept-A' } as never)).toBe(true);
    expect(ability.can('read', { __type: 'Invoice', department_id: 'dept-B' } as never)).toBe(
      false,
    );
  });

  it('caches the rules in Redis and serves them on the second call (AC-17)', async () => {
    const engine = new CaslAbacEngine();
    const buildSpy = jest.spyOn(engine, 'buildAbility');
    const redis = new FakeRedisService();
    const factory = new AbilityFactory(
      engine,
      {} as Repository<Tenant>,
      redis as unknown as RedisService,
    );

    await factory.createForUser(USER, tenant());
    await factory.createForUser(USER, tenant());

    expect(buildSpy).toHaveBeenCalledTimes(1);
  });

  it('config version bump busts the cache (AC-17)', async () => {
    const engine = new CaslAbacEngine();
    const buildSpy = jest.spyOn(engine, 'buildAbility');
    const redis = new FakeRedisService();
    const factory = new AbilityFactory(
      engine,
      {} as Repository<Tenant>,
      redis as unknown as RedisService,
    );

    const t1 = tenant();
    const t2 = tenant({
      config: { ...t1.config, version: 2 } as Tenant['config'],
    });

    await factory.createForUser(USER, t1);
    await factory.createForUser(USER, t2);

    expect(buildSpy).toHaveBeenCalledTimes(2);
  });

  it('fails open when Redis is unavailable (rebuilds every call)', async () => {
    const engine = new CaslAbacEngine();
    const buildSpy = jest.spyOn(engine, 'buildAbility');
    const redis = {
      isAvailable: () => false,
      getClient: () => {
        throw new Error('redis offline');
      },
    } as unknown as RedisService;
    const factory = new AbilityFactory(engine, {} as Repository<Tenant>, redis);

    await factory.createForUser(USER, tenant());
    await factory.createForUser(USER, tenant());

    expect(buildSpy).toHaveBeenCalledTimes(2);
  });
});
