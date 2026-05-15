import { INestApplication } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import request from 'supertest';
import { AuthController } from '../auth.controller';
import { AuthService } from '../auth.service';
import { Tenant } from '../entities/tenant.entity';
import { User } from '../entities/user.entity';
import { RefreshToken } from '../entities/refresh-token.entity';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { JwtStrategy } from '../strategies/jwt.strategy';

const JWT_SECRET = 'test-secret-test-secret-test-secret-32+chars';

/**
 * In-memory e2e: login → me → refresh → logout → me-401. No real database;
 * repositories are tiny in-memory stand-ins. Validates the wired HTTP layer
 * (controllers, guards, passport, pipes) end-to-end.
 */
describe('Auth e2e (in-memory)', () => {
  let app: INestApplication;
  let server: ReturnType<INestApplication['getHttpServer']>;
  let tenants: Tenant[];
  let users: User[];
  let refreshTokens: RefreshToken[];

  beforeAll(async () => {
    process.env.JWT_SECRET = JWT_SECRET;

    tenants = [
      {
        id: 'tenant-A',
        name: 'Acme',
        slug: 'acme',
        is_active: true,
        created_at: new Date(),
        updated_at: new Date(),
      },
    ];
    users = [
      {
        id: 'user-A',
        tenant_id: 'tenant-A',
        email: 'alice@acme.test',
        password_hash: await bcrypt.hash('Secret123', 4),
        roles: ['OWNER'],
        department_id: null,
        is_active: true,
        created_at: new Date(),
        updated_at: new Date(),
      },
    ];
    refreshTokens = [];

    const tenantRepo = {
      findOne: jest.fn(async ({ where }: { where: Partial<Tenant> }) => {
        return (
          tenants.find(
            (t) =>
              (where.id === undefined || t.id === where.id) &&
              (where.slug === undefined || t.slug === where.slug) &&
              (where.is_active === undefined || t.is_active === where.is_active),
          ) ?? null
        );
      }),
    };
    const userRepo = {
      findOne: jest.fn(async ({ where }: { where: Partial<User> }) => {
        return (
          users.find(
            (u) =>
              (where.id === undefined || u.id === where.id) &&
              (where.tenant_id === undefined || u.tenant_id === where.tenant_id) &&
              (where.email === undefined || u.email === where.email) &&
              (where.is_active === undefined || u.is_active === where.is_active),
          ) ?? null
        );
      }),
    };
    const refreshRepo = {
      create: jest.fn((x: Partial<RefreshToken>) => x as RefreshToken),
      save: jest.fn(async (r: Partial<RefreshToken>) => {
        const row: RefreshToken = {
          id: `rt-${refreshTokens.length + 1}`,
          created_at: new Date(),
          revoked_at: null,
          user_id: r.user_id ?? '',
          tenant_id: r.tenant_id ?? '',
          token_hash: r.token_hash ?? '',
          expires_at: r.expires_at ?? new Date(),
        };
        refreshTokens.push(row);
        return row;
      }),
      findOne: jest.fn(
        async ({ where }: { where: { token_hash?: string } }) =>
          refreshTokens.find((r) => r.token_hash === where.token_hash) ?? null,
      ),
      update: jest.fn(
        async (criteria: Partial<RefreshToken> | string, patch: Partial<RefreshToken>) => {
          if (typeof criteria === 'string') {
            const row = refreshTokens.find((r) => r.id === criteria);
            if (row) Object.assign(row, patch);
          } else {
            for (const r of refreshTokens) {
              if (
                (criteria.id === undefined || r.id === criteria.id) &&
                (criteria.user_id === undefined || r.user_id === criteria.user_id) &&
                (criteria.token_hash === undefined || r.token_hash === criteria.token_hash) &&
                // IsNull() match — TypeORM passes a special object; we just treat undefined
                (criteria.revoked_at === undefined ? true : r.revoked_at === null)
              ) {
                Object.assign(r, patch);
              }
            }
          }
          return { affected: 1 };
        },
      ),
    };

    const moduleRef = await Test.createTestingModule({
      imports: [
        PassportModule.register({ defaultStrategy: 'jwt' }),
        JwtModule.register({
          secret: JWT_SECRET,
          signOptions: { algorithm: 'HS256' },
        }),
      ],
      controllers: [AuthController],
      providers: [
        AuthService,
        JwtStrategy,
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        { provide: getRepositoryToken(Tenant), useValue: tenantRepo },
        { provide: getRepositoryToken(User), useValue: userRepo },
        { provide: getRepositoryToken(RefreshToken), useValue: refreshRepo },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
    server = app.getHttpServer();
  });

  afterAll(async () => {
    await app.close();
  });

  it('login → me → refresh → logout → me-401', async () => {
    // Login
    const login = await request(server)
      .post('/auth/login')
      .send({ email: 'alice@acme.test', password: 'Secret123', tenant_slug: 'acme' })
      .expect(200);

    expect(login.body.access_token).toEqual(expect.any(String));
    expect(login.body.refresh_token).toMatch(/^[a-f0-9]{128}$/);
    expect(login.body.expires_in).toBe(900);
    expect(login.body.user).toEqual({
      id: 'user-A',
      email: 'alice@acme.test',
      roles: ['OWNER'],
      department_id: null,
    });

    const access_1 = login.body.access_token as string;
    const refresh_1 = login.body.refresh_token as string;

    // /me with valid access
    const me = await request(server)
      .get('/auth/me')
      .set('Authorization', `Bearer ${access_1}`)
      .expect(200);
    expect(me.body).toEqual({
      user_id: 'user-A',
      tenant_id: 'tenant-A',
      roles: ['OWNER'],
      department_id: null,
    });

    // /me without token → 401
    await request(server).get('/auth/me').expect(401);

    // Refresh → new pair
    const ref = await request(server)
      .post('/auth/refresh')
      .send({ refresh_token: refresh_1 })
      .expect(200);
    const refresh_2 = ref.body.refresh_token as string;
    expect(refresh_2).not.toBe(refresh_1);

    // Reusing refresh_1 now → 401 + family revoked
    await request(server).post('/auth/refresh').send({ refresh_token: refresh_1 }).expect(401);
    // All refresh tokens for this user are now revoked
    expect(refreshTokens.every((r) => r.revoked_at !== null)).toBe(true);

    // Logout (use access_1 just to be authenticated — token still in TTL)
    await request(server)
      .post('/auth/logout')
      .set('Authorization', `Bearer ${access_1}`)
      .send({ refresh_token: refresh_2 })
      .expect(204);

    // Tamper JWT: re-sign with different secret → 401
    const forged = new JwtService({ secret: 'completely-different-secret-32+chars-abc' }).sign({
      sub: 'user-A',
      tenant_id: 'tenant-A',
      roles: ['OWNER'],
      department_id: null,
    });
    await request(server).get('/auth/me').set('Authorization', `Bearer ${forged}`).expect(401);
  });

  it('login → 401 on wrong password (generic message)', async () => {
    const res = await request(server)
      .post('/auth/login')
      .send({ email: 'alice@acme.test', password: 'WRONG', tenant_slug: 'acme' })
      .expect(401);
    expect(res.body.message).toBe('Invalid credentials');
  });

  it('login → 401 on unknown email (no enumeration — same message)', async () => {
    const res = await request(server)
      .post('/auth/login')
      .send({ email: 'ghost@acme.test', password: 'x', tenant_slug: 'acme' })
      .expect(401);
    expect(res.body.message).toBe('Invalid credentials');
  });

  it('login → 404 on unknown tenant', async () => {
    await request(server)
      .post('/auth/login')
      .send({ email: 'alice@acme.test', password: 'Secret123', tenant_slug: 'no-such' })
      .expect(404);
  });

  it('login → 400 on invalid payload (Zod)', async () => {
    await request(server)
      .post('/auth/login')
      .send({ email: 'not-an-email', password: 'x', tenant_slug: 'acme' })
      .expect(400);
  });
});
