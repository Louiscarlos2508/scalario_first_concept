import { JwtService } from '@nestjs/jwt';
import type { Repository } from 'typeorm';
import { AbilityFactory } from '../ability.factory';
import { AbilityMiddleware } from '../middleware/ability.middleware';
import { CaslAbacEngine } from '../engines/casl.engine';
import { FakeRedisService } from '../../../cache/__tests__/fake-redis';
import type { RedisService } from '../../../cache/services/redis.service';
import type { Tenant } from '../../../auth/entities/tenant.entity';

const SECRET = 'middleware-secret-middleware-secret-32chars';
const jwt = new JwtService({ secret: SECRET, signOptions: { algorithm: 'HS256' } });

function tenant(): Tenant {
  return {
    id: 't-1',
    name: 'Acme',
    slug: 'acme',
    is_active: true,
    config: {
      roles: ['MANAGER'],
      version: 1,
      abac_rules: [{ action: 'read', subject: 'Invoice', roles: ['MANAGER'] }] as never,
    } as Tenant['config'],
    created_at: new Date(),
    updated_at: new Date(),
  };
}

function factory(t: Tenant | null) {
  const engine = new CaslAbacEngine();
  const redis = new FakeRedisService();
  const repo = {
    findOne: jest.fn(async () => t),
  } as unknown as Repository<Tenant>;
  return new AbilityFactory(engine, repo, redis as unknown as RedisService);
}

describe('AbilityMiddleware', () => {
  it('skips when no Authorization header and no req.user is present', async () => {
    const mw = new AbilityMiddleware(jwt, factory(tenant()));
    const req = { headers: {} } as Record<string, unknown>;
    const next = jest.fn();
    await mw.use(req as never, undefined as never, next);
    expect(next).toHaveBeenCalled();
    expect((req as { ability?: unknown }).ability).toBeUndefined();
  });

  it('builds ability from a valid bearer token', async () => {
    const mw = new AbilityMiddleware(jwt, factory(tenant()));
    const token = jwt.sign({
      sub: 'u-1',
      tenant_id: 't-1',
      roles: ['MANAGER'],
      department_id: null,
      jti: 'jti-1',
    });
    const req = { headers: { authorization: `Bearer ${token}` } } as Record<string, unknown>;
    const next = jest.fn();
    await mw.use(req as never, undefined as never, next);
    expect(next).toHaveBeenCalled();
    expect((req as { ability?: unknown }).ability).toBeDefined();
  });

  it('skips on invalid bearer token (JwtAuthGuard will produce the 401)', async () => {
    const mw = new AbilityMiddleware(jwt, factory(tenant()));
    const req = { headers: { authorization: 'Bearer not-a-jwt' } } as Record<string, unknown>;
    const next = jest.fn();
    await mw.use(req as never, undefined as never, next);
    expect(next).toHaveBeenCalled();
    expect((req as { ability?: unknown }).ability).toBeUndefined();
  });

  it('skips when tenant is not found', async () => {
    const mw = new AbilityMiddleware(jwt, factory(null));
    const token = jwt.sign({
      sub: 'u-1',
      tenant_id: 't-1',
      roles: ['MANAGER'],
      department_id: null,
      jti: 'jti-1',
    });
    const req = { headers: { authorization: `Bearer ${token}` } } as Record<string, unknown>;
    const next = jest.fn();
    await mw.use(req as never, undefined as never, next);
    expect(next).toHaveBeenCalled();
    expect((req as { ability?: unknown }).ability).toBeUndefined();
  });

  it('uses req.user when present (downstream worker / test inject)', async () => {
    const mw = new AbilityMiddleware(jwt, factory(tenant()));
    const req = {
      headers: {},
      user: {
        user_id: 'u-1',
        tenant_id: 't-1',
        roles: ['MANAGER'],
        department_id: null,
      },
    } as Record<string, unknown>;
    const next = jest.fn();
    await mw.use(req as never, undefined as never, next);
    expect((req as { ability?: unknown }).ability).toBeDefined();
  });
});
