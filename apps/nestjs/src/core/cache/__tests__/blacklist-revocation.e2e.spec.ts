import { INestApplication } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import request from 'supertest';
import { AuthController } from '../../auth/auth.controller';
import { AuthService } from '../../auth/auth.service';
import { Tenant } from '../../auth/entities/tenant.entity';
import { User } from '../../auth/entities/user.entity';
import { RefreshToken } from '../../auth/entities/refresh-token.entity';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { JwtStrategy } from '../../auth/strategies/jwt.strategy';
import { RolesService } from '../../security/services/roles.service';
import { RedisService } from '../services/redis.service';
import { TokenBlacklistService } from '../services/token-blacklist.service';
import { FakeRedisService } from './fake-redis';

const JWT_SECRET = 'test-secret-test-secret-test-secret-32+chars';

/**
 * STORY-018 — AC-10 / AC-27. Wires the real `TokenBlacklistService` +
 * the real `JwtAuthGuard` against an in-memory Redis double. Asserts
 * the access token is rejected immediately after `/auth/logout`,
 * without waiting for the 15-min JWT expiry.
 */
describe('Auth — instant revocation via Redis blacklist (STORY-018)', () => {
  let app: INestApplication;
  let server: ReturnType<INestApplication['getHttpServer']>;
  const fake = new FakeRedisService();

  beforeAll(async () => {
    process.env.JWT_SECRET = JWT_SECRET;

    const tenants: Tenant[] = [
      {
        id: 'tenant-A',
        name: 'Acme',
        slug: 'acme',
        is_active: true,
        config: { roles: ['OWNER'] },
        created_at: new Date(),
        updated_at: new Date(),
      },
    ];
    const users: User[] = [
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
    const refreshTokens: RefreshToken[] = [];

    const tenantRepo = {
      findOne: jest.fn(
        async ({ where }: { where: Partial<Tenant> }) =>
          tenants.find(
            (t) =>
              (where.id === undefined || t.id === where.id) &&
              (where.slug === undefined || t.slug === where.slug) &&
              (where.is_active === undefined || t.is_active === where.is_active),
          ) ?? null,
      ),
    };
    const userRepo = {
      findOne: jest.fn(
        async ({ where }: { where: Partial<User> }) =>
          users.find(
            (u) =>
              (where.id === undefined || u.id === where.id) &&
              (where.tenant_id === undefined || u.tenant_id === where.tenant_id) &&
              (where.email === undefined || u.email === where.email) &&
              (where.is_active === undefined || u.is_active === where.is_active),
          ) ?? null,
      ),
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
          expires_at: r.expires_at ?? new Date(Date.now() + 86_400_000),
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
                (criteria.token_hash === undefined || r.token_hash === criteria.token_hash) &&
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
        TokenBlacklistService,
        { provide: RedisService, useValue: fake },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        { provide: getRepositoryToken(Tenant), useValue: tenantRepo },
        { provide: getRepositoryToken(User), useValue: userRepo },
        { provide: getRepositoryToken(RefreshToken), useValue: refreshRepo },
        {
          provide: RolesService,
          useValue: {
            getRolesForTenant: jest.fn(async () => ['OWNER']),
            invalidateCache: jest.fn(),
          },
        },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
    server = app.getHttpServer();
  });

  afterAll(async () => {
    await app.close();
    fake.reset();
  });

  it('login → /me OK → logout → /me 401 immediately (AC-10/AC-27)', async () => {
    const login = await request(server)
      .post('/auth/login')
      .send({ email: 'alice@acme.test', password: 'Secret123', tenant_slug: 'acme' })
      .expect(200);

    const access = login.body.access_token as string;
    const refresh = login.body.refresh_token as string;

    await request(server).get('/auth/me').set('Authorization', `Bearer ${access}`).expect(200);

    await request(server)
      .post('/auth/logout')
      .set('Authorization', `Bearer ${access}`)
      .send({ refresh_token: refresh })
      .expect(204);

    // Without waiting for 15-min JWT expiry — the access token is dead now.
    const res = await request(server)
      .get('/auth/me')
      .set('Authorization', `Bearer ${access}`)
      .expect(401);
    expect(res.body.message).toBe('Token revoked');
  });
});
