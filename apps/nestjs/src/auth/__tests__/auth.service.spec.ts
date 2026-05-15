import { NotFoundException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import type { ObjectLiteral, Repository } from 'typeorm';
import { IsNull } from 'typeorm';
import { AuthService } from '../auth.service';
import { Tenant } from '../entities/tenant.entity';
import { User } from '../entities/user.entity';
import { RefreshToken } from '../entities/refresh-token.entity';
import type { JwtPayload } from '../interfaces/jwt-payload.interface';
import { RolesService } from '../../security/services/roles.service';
import { TokenBlacklistService } from '../../cache/services/token-blacklist.service';

const JWT_SECRET = 'test-secret-test-secret-test-secret-32+chars';

type Repo<T extends ObjectLiteral> = jest.Mocked<
  Pick<Repository<T>, 'findOne' | 'find' | 'save' | 'update' | 'create'>
>;

function makeRepo<T extends ObjectLiteral>(): Repo<T> {
  return {
    findOne: jest.fn(),
    find: jest.fn(),
    save: jest.fn(),
    update: jest.fn(),
    create: jest.fn((x) => x as T),
  } as unknown as Repo<T>;
}

describe('AuthService', () => {
  let service: AuthService;
  let tenantRepo: Repo<Tenant>;
  let userRepo: Repo<User>;
  let refreshRepo: Repo<RefreshToken>;
  let jwt: JwtService;

  const TENANT: Tenant = {
    id: 'tenant-A',
    name: 'Acme',
    slug: 'acme',
    is_active: true,
    config: { roles: ['OWNER', 'MANAGER', 'COMMERCIAL'] },
    created_at: new Date(),
    updated_at: new Date(),
  };

  const makeUser = async (overrides: Partial<User> = {}): Promise<User> => ({
    id: 'user-1',
    tenant_id: TENANT.id,
    email: 'alice@acme.test',
    password_hash: await bcrypt.hash('Secret123', 4),
    roles: ['OWNER'],
    department_id: null,
    is_active: true,
    created_at: new Date(),
    updated_at: new Date(),
    ...overrides,
  });

  beforeEach(async () => {
    tenantRepo = makeRepo<Tenant>();
    userRepo = makeRepo<User>();
    refreshRepo = makeRepo<RefreshToken>();

    const moduleRef = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: JwtService,
          useValue: new JwtService({
            secret: JWT_SECRET,
            signOptions: { algorithm: 'HS256' },
          }),
        },
        { provide: getRepositoryToken(Tenant), useValue: tenantRepo },
        { provide: getRepositoryToken(User), useValue: userRepo },
        { provide: getRepositoryToken(RefreshToken), useValue: refreshRepo },
        {
          provide: RolesService,
          useValue: {
            getRolesForTenant: jest.fn(async () => ['OWNER', 'MANAGER', 'COMMERCIAL']),
            invalidateCache: jest.fn(),
          },
        },
        {
          provide: TokenBlacklistService,
          useValue: { add: jest.fn(), isRevoked: jest.fn(async () => false) },
        },
      ],
    }).compile();
    service = moduleRef.get(AuthService);
    jwt = moduleRef.get(JwtService);
  });

  describe('static helpers', () => {
    it('hashRefreshToken is deterministic SHA-256 hex', () => {
      const h = AuthService.hashRefreshToken('abc');
      expect(h).toMatch(/^[a-f0-9]{64}$/);
      expect(AuthService.hashRefreshToken('abc')).toBe(h);
      expect(AuthService.hashRefreshToken('abd')).not.toBe(h);
    });

    it('generateRefreshToken produces 128-char hex (64 bytes)', () => {
      const t = AuthService.generateRefreshToken();
      expect(t).toMatch(/^[a-f0-9]{128}$/);
      expect(AuthService.generateRefreshToken()).not.toBe(t);
    });

    it('hashPassword uses bcrypt cost 12', async () => {
      const h = await AuthService.hashPassword('Secret123');
      expect(h.startsWith('$2b$12$')).toBe(true);
      expect(await bcrypt.compare('Secret123', h)).toBe(true);
    });
  });

  describe('validateLocalCredentials', () => {
    it('throws 404 if tenant not found', async () => {
      tenantRepo.findOne.mockResolvedValue(null);
      await expect(
        service.validateLocalCredentials({
          email: 'a@b.test',
          password: 'x',
          tenant_slug: 'unknown',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('throws 401 with generic message if user not found (no enumeration)', async () => {
      tenantRepo.findOne.mockResolvedValue(TENANT);
      userRepo.findOne.mockResolvedValue(null);
      await expect(
        service.validateLocalCredentials({
          email: 'ghost@acme.test',
          password: 'whatever',
          tenant_slug: 'acme',
        }),
      ).rejects.toMatchObject({ message: 'Invalid credentials' });
    });

    it('throws 401 if password mismatch', async () => {
      tenantRepo.findOne.mockResolvedValue(TENANT);
      const user = await makeUser();
      userRepo.findOne.mockResolvedValue(user);
      await expect(
        service.validateLocalCredentials({
          email: user.email,
          password: 'WRONG',
          tenant_slug: 'acme',
        }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('returns user + tenant on success', async () => {
      tenantRepo.findOne.mockResolvedValue(TENANT);
      const user = await makeUser();
      userRepo.findOne.mockResolvedValue(user);
      const result = await service.validateLocalCredentials({
        email: user.email,
        password: 'Secret123',
        tenant_slug: 'acme',
      });
      expect(result).toEqual({ user, tenant: TENANT });
    });

    it('queries user scoped by tenant_id + email + is_active=true', async () => {
      tenantRepo.findOne.mockResolvedValue(TENANT);
      userRepo.findOne.mockResolvedValue(await makeUser());
      await service.validateLocalCredentials({
        email: 'Alice@Acme.test',
        password: 'Secret123',
        tenant_slug: 'acme',
      });
      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { tenant_id: TENANT.id, email: 'alice@acme.test', is_active: true },
      });
    });
  });

  describe('login → issueTokens', () => {
    it('produces JWT with required claims and 15-min expiry', async () => {
      tenantRepo.findOne.mockResolvedValue(TENANT);
      const user = await makeUser({ roles: ['OWNER', 'MANAGER'], department_id: 'dept-1' });
      userRepo.findOne.mockResolvedValue(user);
      refreshRepo.save.mockImplementation(async (r) => r as RefreshToken);

      const tokens = await service.login({
        email: user.email,
        password: 'Secret123',
        tenant_slug: 'acme',
      });

      expect(tokens.expires_in).toBe(900);
      expect(tokens.refresh_token).toMatch(/^[a-f0-9]{128}$/);
      expect(tokens.user).toEqual({
        id: user.id,
        email: user.email,
        roles: user.roles,
        department_id: 'dept-1',
      });

      const payload = jwt.verify<JwtPayload>(tokens.access_token, { secret: JWT_SECRET });
      expect(payload.sub).toBe(user.id);
      expect(payload.tenant_id).toBe(TENANT.id);
      expect(payload.roles).toEqual(['OWNER', 'MANAGER']);
      expect(payload.department_id).toBe('dept-1');
      expect(payload.exp - payload.iat).toBe(900);
    });

    it('stores SHA-256 hash of refresh_token (never the raw token)', async () => {
      tenantRepo.findOne.mockResolvedValue(TENANT);
      userRepo.findOne.mockResolvedValue(await makeUser());
      let savedHash = '';
      refreshRepo.save.mockImplementation(async (r) => {
        savedHash = (r as RefreshToken).token_hash;
        return r as RefreshToken;
      });

      const tokens = await service.login({
        email: 'alice@acme.test',
        password: 'Secret123',
        tenant_slug: 'acme',
      });

      expect(savedHash).toBe(AuthService.hashRefreshToken(tokens.refresh_token));
      expect(savedHash).not.toBe(tokens.refresh_token);
    });

    it('refresh_token expires_at = now + 7 days', async () => {
      tenantRepo.findOne.mockResolvedValue(TENANT);
      userRepo.findOne.mockResolvedValue(await makeUser());
      let expiresAt: Date | null = null;
      refreshRepo.save.mockImplementation(async (r) => {
        expiresAt = (r as RefreshToken).expires_at;
        return r as RefreshToken;
      });
      const before = Date.now();
      await service.login({
        email: 'alice@acme.test',
        password: 'Secret123',
        tenant_slug: 'acme',
      });
      const after = Date.now();
      const sevenDays = 7 * 24 * 3600 * 1000;
      expect(expiresAt).not.toBeNull();
      expect((expiresAt as unknown as Date).getTime()).toBeGreaterThanOrEqual(
        before + sevenDays - 1000,
      );
      expect((expiresAt as unknown as Date).getTime()).toBeLessThanOrEqual(
        after + sevenDays + 1000,
      );
    });
  });

  describe('refresh — rotation & reuse detection', () => {
    const buildStored = (overrides: Partial<RefreshToken> = {}): RefreshToken => ({
      id: 'rt-1',
      user_id: 'user-1',
      tenant_id: TENANT.id,
      token_hash: 'will-be-overwritten',
      expires_at: new Date(Date.now() + 1000 * 3600),
      revoked_at: null,
      created_at: new Date(),
      ...overrides,
    });

    it('throws 401 if token unknown or expired', async () => {
      refreshRepo.findOne.mockResolvedValue(null);
      await expect(service.refresh('a'.repeat(128))).rejects.toBeInstanceOf(UnauthorizedException);

      refreshRepo.findOne.mockResolvedValue(
        buildStored({ expires_at: new Date(Date.now() - 1000) }),
      );
      await expect(service.refresh('a'.repeat(128))).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rotates: marks old refresh revoked + issues new pair', async () => {
      const stored = buildStored();
      refreshRepo.findOne.mockResolvedValue(stored);
      userRepo.findOne.mockResolvedValue(await makeUser());
      tenantRepo.findOne.mockResolvedValue(TENANT);
      refreshRepo.save.mockImplementation(async (r) => r as RefreshToken);

      const out = await service.refresh('raw-refresh-token-value');
      expect(refreshRepo.update).toHaveBeenCalledWith(stored.id, {
        revoked_at: expect.any(Date),
      });
      expect(out.access_token).toEqual(expect.any(String));
      expect(out.refresh_token).toMatch(/^[a-f0-9]{128}$/);
    });

    it('reuse detection — when revoked_at is set, revoke entire family', async () => {
      const stored = buildStored({ revoked_at: new Date(Date.now() - 5000) });
      refreshRepo.findOne.mockResolvedValue(stored);

      await expect(service.refresh('any')).rejects.toMatchObject({
        message: 'Token reuse detected',
      });

      // The family revoke call uses { user_id, revoked_at: IsNull() }.
      expect(refreshRepo.update).toHaveBeenCalledWith(
        { user_id: stored.user_id, revoked_at: IsNull() },
        { revoked_at: expect.any(Date) },
      );
      // And it must NOT have called update with the per-row rotation form.
      expect(refreshRepo.update).not.toHaveBeenCalledWith(stored.id, expect.anything());
    });
  });

  describe('logout', () => {
    it('sets revoked_at on the matching token hash', async () => {
      await service.logout('raw-token');
      expect(refreshRepo.update).toHaveBeenCalledWith(
        { token_hash: AuthService.hashRefreshToken('raw-token'), revoked_at: IsNull() },
        { revoked_at: expect.any(Date) },
      );
    });
  });

  describe('findUserById — defense in depth (always tenant-scoped)', () => {
    it('queries with tenant_id AND id (never id alone)', async () => {
      userRepo.findOne.mockResolvedValue(null);
      await service.findUserById('victim-user', 'attacker-tenant');
      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { id: 'victim-user', tenant_id: 'attacker-tenant' },
      });
    });
  });
});
