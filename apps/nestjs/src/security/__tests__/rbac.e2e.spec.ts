import { Controller, Get, INestApplication } from '@nestjs/common';
import { APP_GUARD, Reflector } from '@nestjs/core';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import request from 'supertest';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { JwtStrategy } from '../../auth/strategies/jwt.strategy';
import { Tenant } from '../../auth/entities/tenant.entity';
import { User } from '../../auth/entities/user.entity';
import { Roles } from '../../common/decorators/roles.decorator';
import { SUPER_ADMIN } from '../constants';
import { RbacGuard } from '../guards/rbac.guard';
import { RolesService } from '../services/roles.service';

const JWT_SECRET = 'test-secret-test-secret-test-secret-32+chars';

@Controller('demo')
class DemoController {
  @Get('owner-only')
  @Roles('OWNER')
  ownerOnly() {
    return { ok: 'owner' };
  }

  @Get('owner-or-manager')
  @Roles('OWNER', 'MANAGER')
  ownerOrManager() {
    return { ok: 'owner-or-manager' };
  }

  @Get('livreur-only')
  @Roles('LIVREUR')
  livreurOnly() {
    return { ok: 'livreur' };
  }

  @Get('no-decorator')
  noDecorator() {
    return { ok: 'no-decorator' };
  }
}

/**
 * STORY-015 — full RBAC chain e2e. Validates JwtAuthGuard (Layer 1) and
 * RbacGuard (Layer 2) running together in the order configured by
 * `AppModule`, against a fake DemoController exercising AC-04…AC-07,
 * AC-21, AC-22, and the SUPER_ADMIN bypass (AC-17/AC-18).
 */
describe('RBAC e2e (Layer 1 + Layer 2)', () => {
  let app: INestApplication;
  let server: ReturnType<INestApplication['getHttpServer']>;
  let jwt: JwtService;
  let tenant: Tenant;

  const tenantRepo = {
    findOne: jest.fn(async ({ where }: { where: Partial<Tenant> }) => {
      if (where.id === tenant.id || where.slug === tenant.slug) return tenant;
      return null;
    }),
    update: jest.fn(async (_id: unknown, patch: Partial<Tenant>) => {
      Object.assign(tenant, patch);
      return { affected: 1 };
    }),
  };

  beforeAll(async () => {
    process.env.JWT_SECRET = JWT_SECRET;

    tenant = {
      id: 'tenant-A',
      name: 'Acme',
      slug: 'acme',
      is_active: true,
      config: { roles: ['OWNER', 'MANAGER', 'COMMERCIAL'] },
      created_at: new Date(),
      updated_at: new Date(),
    };

    const moduleRef = await Test.createTestingModule({
      imports: [
        PassportModule.register({ defaultStrategy: 'jwt' }),
        JwtModule.register({
          secret: JWT_SECRET,
          signOptions: { algorithm: 'HS256' },
        }),
      ],
      controllers: [DemoController],
      providers: [
        Reflector,
        JwtStrategy,
        RolesService,
        { provide: getRepositoryToken(Tenant), useValue: tenantRepo },
        { provide: getRepositoryToken(User), useValue: { findOne: jest.fn() } },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        { provide: APP_GUARD, useClass: RbacGuard },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
    server = app.getHttpServer();
    jwt = new JwtService({ secret: JWT_SECRET, signOptions: { algorithm: 'HS256' } });
  });

  afterAll(async () => app.close());

  function token(roles: string[], opts: { tenant_id?: string } = {}) {
    return jwt.sign({
      sub: 'u1',
      tenant_id: opts.tenant_id ?? tenant.id,
      roles,
      department_id: null,
    });
  }

  it('401 when no Authorization header is provided', async () => {
    await request(server).get('/demo/owner-only').expect(401);
  });

  it('AC-04 — COMMERCIAL on @Roles("OWNER") → 403', async () => {
    await request(server)
      .get('/demo/owner-only')
      .set('Authorization', `Bearer ${token(['COMMERCIAL'])}`)
      .expect(403);
  });

  it('AC-21 — OWNER on @Roles("OWNER") → 200', async () => {
    await request(server)
      .get('/demo/owner-only')
      .set('Authorization', `Bearer ${token(['OWNER'])}`)
      .expect(200, { ok: 'owner' });
  });

  it('AC-05 — MANAGER on @Roles("OWNER","MANAGER") → 200', async () => {
    await request(server)
      .get('/demo/owner-or-manager')
      .set('Authorization', `Bearer ${token(['MANAGER'])}`)
      .expect(200);
  });

  it('AC-06 — multi-role user with OWNER hits @Roles("OWNER") → 200', async () => {
    await request(server)
      .get('/demo/owner-only')
      .set('Authorization', `Bearer ${token(['OWNER', 'COMMERCIAL'])}`)
      .expect(200);
  });

  it('passes through unprotected route to JwtAuthGuard-only behaviour', async () => {
    await request(server)
      .get('/demo/no-decorator')
      .set('Authorization', `Bearer ${token(['COMMERCIAL'])}`)
      .expect(200, { ok: 'no-decorator' });
  });

  it('SUPER_ADMIN bypasses tenant role intersection', async () => {
    await request(server)
      .get('/demo/owner-only')
      .set('Authorization', `Bearer ${token([SUPER_ADMIN])}`)
      .expect(200);
  });

  it('AC-22 — adding LIVREUR runtime makes @Roles("LIVREUR") reachable, no restart', async () => {
    // Before: user has LIVREUR in JWT but tenant config does NOT — must 403.
    await request(server)
      .get('/demo/livreur-only')
      .set('Authorization', `Bearer ${token(['LIVREUR'])}`)
      .expect(403);

    // Admin patches the tenant config (we simulate by mutating + invalidating).
    const rolesService = app.get(RolesService);
    tenant.config = { roles: ['OWNER', 'MANAGER', 'COMMERCIAL', 'LIVREUR'] };
    rolesService.invalidateCache(tenant.id);

    // After: same JWT now succeeds (zero deploy, zero re-login).
    await request(server)
      .get('/demo/livreur-only')
      .set('Authorization', `Bearer ${token(['LIVREUR'])}`)
      .expect(200);
  });

  it('AC-23 — JWT with stale role removed from tenant config is denied next call', async () => {
    // OWNER + LIVREUR works…
    await request(server)
      .get('/demo/livreur-only')
      .set('Authorization', `Bearer ${token(['LIVREUR'])}`)
      .expect(200);

    // …admin removes LIVREUR from config…
    const rolesService = app.get(RolesService);
    tenant.config = { roles: ['OWNER', 'MANAGER', 'COMMERCIAL'] };
    rolesService.invalidateCache(tenant.id);

    // …next request with the SAME JWT is rejected.
    await request(server)
      .get('/demo/livreur-only')
      .set('Authorization', `Bearer ${token(['LIVREUR'])}`)
      .expect(403);
  });
});
