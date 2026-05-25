import { ForbiddenException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { tenantContext } from '../../../../common/context/tenant-context';
import { TenantsService } from '../../../../tenants/tenants.service';
import { TenantMiddleware } from '../tenant.middleware';

describe('TenantMiddleware', () => {
  const JWT_SECRET = 'test-secret-test-secret-test-secret-32+chars';
  let jwt: JwtService;
  let dataSource: { isInitialized: boolean; query: jest.Mock };
  let tenants: jest.Mocked<Pick<TenantsService, 'getActive'>>;
  let middleware: TenantMiddleware;

  function build(tenantsImpl: Partial<TenantsService> = {}): TenantMiddleware {
    dataSource = { isInitialized: true, query: jest.fn().mockResolvedValue([]) };
    tenants = {
      getActive: jest.fn(async (id: string) => id),
      ...tenantsImpl,
    } as never;
    return new TenantMiddleware(dataSource as never, tenants as unknown as TenantsService, jwt);
  }

  beforeAll(() => {
    process.env.JWT_SECRET = JWT_SECRET;
    jwt = new JwtService({ secret: JWT_SECRET, signOptions: { algorithm: 'HS256' } });
  });

  it('AC-06 — public route (no token) → skip, no context opened', async () => {
    middleware = build();
    const next = jest.fn();
    await middleware.use({ headers: {} } as never, {} as never, next);
    expect(next).toHaveBeenCalledTimes(1);
    expect(tenants.getActive).not.toHaveBeenCalled();
  });

  it('AC-02 / AC-05 — bearer token opens context with tenant_id', async () => {
    middleware = build();
    const token = jwt.sign({ sub: 'u1', tenant_id: 'tenant-A', roles: ['OWNER'] });
    let seen: string | undefined;
    const next = jest.fn(() => {
      seen = tenantContext.get()?.tenant_id;
    });
    await middleware.use(
      { headers: { authorization: `Bearer ${token}` } } as never,
      {} as never,
      next,
    );
    expect(seen).toBe('tenant-A');
    expect(dataSource.query).toHaveBeenCalledWith(expect.stringContaining('set_config'), [
      'tenant-A',
    ]);
  });

  it('AC-08 — disabled tenant → 403 ForbiddenException', async () => {
    middleware = build({ getActive: jest.fn(async () => null) as never });
    const token = jwt.sign({ sub: 'u1', tenant_id: 'tenant-X', roles: ['OWNER'] });
    await expect(
      middleware.use(
        { headers: { authorization: `Bearer ${token}` } } as never,
        {} as never,
        jest.fn(),
      ),
    ).rejects.toThrow(ForbiddenException);
  });

  it('invalid bearer → skipped (JwtAuthGuard will return 401)', async () => {
    middleware = build();
    const next = jest.fn();
    await middleware.use(
      { headers: { authorization: 'Bearer not-a-jwt' } } as never,
      {} as never,
      next,
    );
    expect(next).toHaveBeenCalled();
    expect(tenants.getActive).not.toHaveBeenCalled();
  });

  it('AC-11 — context isolated across two consecutive requests', async () => {
    middleware = build();
    const tokA = jwt.sign({ sub: 'u1', tenant_id: 'A', roles: [] });
    const tokB = jwt.sign({ sub: 'u2', tenant_id: 'B', roles: [] });
    const seen: string[] = [];
    await middleware.use(
      { headers: { authorization: `Bearer ${tokA}` } } as never,
      {} as never,
      () => {
        seen.push(tenantContext.getOrThrow().tenant_id);
      },
    );
    await middleware.use(
      { headers: { authorization: `Bearer ${tokB}` } } as never,
      {} as never,
      () => {
        seen.push(tenantContext.getOrThrow().tenant_id);
      },
    );
    expect(seen).toEqual(['A', 'B']);
    // After both requests, the storage chain is empty again.
    expect(tenantContext.get()).toBeUndefined();
  });

  it('AC-23 — 100 parallel requests A/B never leak across each other', async () => {
    middleware = build();
    const tokA = jwt.sign({ sub: 'u1', tenant_id: 'A', roles: [] });
    const tokB = jwt.sign({ sub: 'u2', tenant_id: 'B', roles: [] });
    const seen: string[] = [];
    // Express middleware does not await `next()`, so we wire each `next`
    // to a deferred that resolves after the body runs. That way the
    // outer `Promise.all` can wait on real completion, while still
    // exercising the real (non-awaited) middleware flow.
    const handlers = Array.from({ length: 100 }, (_, i) => {
      const tok = i % 2 === 0 ? tokA : tokB;
      const want = i % 2 === 0 ? 'A' : 'B';
      let done!: () => void;
      const settled = new Promise<void>((resolve) => {
        done = resolve;
      });
      const start = middleware.use(
        { headers: { authorization: `Bearer ${tok}` } } as never,
        {} as never,
        () => {
          // Defer to interleave with siblings, then read the ALS slot.
          setImmediate(() => {
            const got = tenantContext.getOrThrow().tenant_id;
            expect(got).toBe(want);
            seen.push(got);
            done();
          });
        },
      );
      return Promise.all([start, settled]);
    });
    await Promise.all(handlers);
    expect(seen).toHaveLength(100);
    expect(seen.filter((t) => t === 'A')).toHaveLength(50);
    expect(seen.filter((t) => t === 'B')).toHaveLength(50);
  });
});
