import {
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  Optional,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { IsNull, Repository } from 'typeorm';
import { Tenant } from './entities/tenant.entity';
import { User } from './entities/user.entity';
import { RefreshToken } from './entities/refresh-token.entity';
import type { AuthTokens } from './interfaces/auth-tokens.interface';
import type { JwtPayload } from './interfaces/jwt-payload.interface';
import { TokenBlacklistService } from '../cache/services/token-blacklist.service';
import { TTL_SECONDS } from '../cache/constants';
import { RolesService } from '../security/services/roles.service';
import { SUPER_ADMIN } from '../security/constants';
import { AuditLogService } from '../audit/services/audit-log.service';
import { AUDIT_ACTIONS } from '../audit/constants';

const BCRYPT_COST = 12;
const ACCESS_TTL_SECONDS = 15 * 60;
const REFRESH_TTL_MS = 7 * 24 * 3600 * 1000;
const REFRESH_TOKEN_BYTES = 64;
const DUMMY_BCRYPT_HASH = '$2b$12$CwTycUXWue0Thq9StjUM0uJ8/AlT9JqJzPgvE4r9zXf1xCJfTk5L2';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(Tenant) private readonly tenantRepo: Repository<Tenant>,
    @InjectRepository(User) private readonly userRepo: Repository<User>,
    @InjectRepository(RefreshToken)
    private readonly refreshRepo: Repository<RefreshToken>,
    private readonly jwt: JwtService,
    private readonly rolesService: RolesService,
    private readonly tokenBlacklist: TokenBlacklistService,
    @Optional() private readonly audit?: AuditLogService,
  ) {}

  /** Tiny helper — audit is optional in test wiring, so guard every call. */
  private async tryAudit(entry: Parameters<AuditLogService['log']>[0]): Promise<void> {
    if (this.audit) await this.audit.log(entry);
  }

  /**
   * Returns the subset of `user.roles` that are valid for `tenant_id` (i.e.
   * still present in `tenants.config.roles`) plus any system roles (e.g.
   * `SUPER_ADMIN`) the user holds. STORY-015 AC-11: a user whose only
   * business roles have been removed must be denied login.
   */
  async filterValidRoles(userRoles: string[], tenant_id: string): Promise<string[]> {
    const systemHeld = userRoles.filter((r) => r === SUPER_ADMIN);
    const tenantRoles = await this.rolesService.getRolesForTenant(tenant_id);
    const businessHeld = userRoles.filter((r) => tenantRoles.includes(r));
    return [...new Set([...systemHeld, ...businessHeld])];
  }

  static hashRefreshToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  static generateRefreshToken(): string {
    return crypto.randomBytes(REFRESH_TOKEN_BYTES).toString('hex');
  }

  static hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, BCRYPT_COST);
  }

  /**
   * Resolves and validates email+password+tenant_slug. Returns the user and
   * tenant on success. Uses a constant-time bcrypt compare against a dummy
   * hash when the user is absent — defeats user-enumeration via timing.
   */
  async validateLocalCredentials(input: {
    email: string;
    password: string;
    tenant_slug: string;
  }): Promise<{ user: User; tenant: Tenant }> {
    const tenant = await this.tenantRepo.findOne({
      where: { slug: input.tenant_slug, is_active: true },
    });
    if (!tenant) {
      // STORY-020 — sync audit (critical event).
      await this.tryAudit({
        action: AUDIT_ACTIONS.AUTH_LOGIN_FAIL,
        metadata: { reason: 'tenant_not_found', tenant_slug: input.tenant_slug },
      });
      throw new NotFoundException('Tenant not found');
    }

    const email = input.email.toLowerCase();
    const user = await this.userRepo.findOne({
      where: { tenant_id: tenant.id, email, is_active: true },
    });

    const hashToCompare = user?.password_hash ?? DUMMY_BCRYPT_HASH;
    const ok = await bcrypt.compare(input.password, hashToCompare);
    if (!user || !ok) {
      await this.tryAudit({
        action: AUDIT_ACTIONS.AUTH_LOGIN_FAIL,
        tenant_id: tenant.id,
        user_id: user?.id ?? null,
        metadata: {
          reason: user ? 'invalid_credentials' : 'user_not_found_or_disabled',
        },
      });
      throw new UnauthorizedException('Invalid credentials');
    }

    return { user, tenant };
  }

  async login(input: {
    email: string;
    password: string;
    tenant_slug: string;
  }): Promise<AuthTokens> {
    const { user, tenant } = await this.validateLocalCredentials(input);
    const tokens = await this.issueTokens(user, tenant);
    await this.tryAudit({
      action: AUDIT_ACTIONS.AUTH_LOGIN_SUCCESS,
      tenant_id: tenant.id,
      user_id: user.id,
      metadata: { roles: tokens.user.roles },
    });
    return tokens;
  }

  async issueTokens(user: User, tenant: Tenant): Promise<AuthTokens> {
    const now = Math.floor(Date.now() / 1000);
    const validRoles = await this.filterValidRoles(user.roles, tenant.id);
    if (validRoles.length === 0) {
      throw new ForbiddenException('No valid roles for this tenant');
    }
    const payload: JwtPayload = {
      sub: user.id,
      tenant_id: tenant.id,
      roles: validRoles,
      department_id: user.department_id,
      jti: crypto.randomUUID(),
      iat: now,
      exp: now + ACCESS_TTL_SECONDS,
    };
    const access_token = await this.jwt.signAsync(payload);

    const refresh_token = AuthService.generateRefreshToken();
    const token_hash = AuthService.hashRefreshToken(refresh_token);
    await this.refreshRepo.save(
      this.refreshRepo.create({
        user_id: user.id,
        tenant_id: tenant.id,
        token_hash,
        expires_at: new Date(Date.now() + REFRESH_TTL_MS),
      }),
    );

    return {
      access_token,
      refresh_token,
      expires_in: ACCESS_TTL_SECONDS,
      user: {
        id: user.id,
        email: user.email,
        roles: validRoles,
        department_id: user.department_id,
      },
    };
  }

  async refresh(refresh_token: string): Promise<AuthTokens> {
    const token_hash = AuthService.hashRefreshToken(refresh_token);
    const stored = await this.refreshRepo.findOne({ where: { token_hash } });

    if (!stored || stored.expires_at.getTime() < Date.now()) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (stored.revoked_at !== null) {
      // Reuse detected — revoke the entire family for this user.
      await this.refreshRepo.update(
        { user_id: stored.user_id, revoked_at: IsNull() },
        { revoked_at: new Date() },
      );
      this.logger.warn(`REFRESH_REUSE_DETECTED user_id=${stored.user_id} — family revoked`);
      // STORY-020 — sync audit (critical).
      await this.tryAudit({
        action: AUDIT_ACTIONS.AUTH_REFRESH_REUSE_DETECTED,
        tenant_id: stored.tenant_id,
        user_id: stored.user_id,
      });
      throw new UnauthorizedException('Token reuse detected');
    }

    await this.refreshRepo.update(stored.id, { revoked_at: new Date() });

    const user = await this.findUserById(stored.user_id, stored.tenant_id);
    if (!user) throw new UnauthorizedException('Invalid refresh token');
    const tenant = await this.tenantRepo.findOne({
      where: { id: stored.tenant_id, is_active: true },
    });
    if (!tenant) throw new UnauthorizedException('Invalid refresh token');

    const tokens = await this.issueTokens(user, tenant);
    await this.tryAudit({
      action: AUDIT_ACTIONS.AUTH_REFRESH,
      tenant_id: tenant.id,
      user_id: user.id,
    });
    return tokens;
  }

  /**
   * STORY-018 — Revokes the refresh token in DB AND pushes both the
   * refresh hash and the current access-token `jti` into the Redis
   * blacklist so reuse is rejected instantly (no 15-min wait on JWT
   * expiry). `access` is optional — when omitted (e.g. tests, or when
   * called without an authenticated request) only the refresh side is
   * blacklisted.
   */
  async logout(refresh_token: string, access?: { jti: string; exp: number }): Promise<void> {
    const token_hash = AuthService.hashRefreshToken(refresh_token);
    const stored = await this.refreshRepo.findOne({ where: { token_hash } });
    await this.refreshRepo.update({ token_hash, revoked_at: IsNull() }, { revoked_at: new Date() });

    if (stored && stored.revoked_at === null) {
      const ttl = Math.floor((stored.expires_at.getTime() - Date.now()) / 1000);
      await this.tokenBlacklist.add(token_hash, ttl);
    }
    if (access?.jti) {
      const now = Math.floor(Date.now() / 1000);
      const ttl = Math.min(TTL_SECONDS.ACCESS_MAX, Math.max(0, access.exp - now));
      await this.tokenBlacklist.add(access.jti, ttl);
    }
    // STORY-020 — async audit (best-effort).
    await this.tryAudit({
      action: AUDIT_ACTIONS.AUTH_LOGOUT,
      tenant_id: stored?.tenant_id ?? null,
      user_id: stored?.user_id ?? null,
    });
  }

  /**
   * Looks up a user by id, always scoped by tenant_id. Layer 4 RLS
   * (STORY-017) is the authoritative defense; this method is defense in
   * depth — never SELECT users by id alone.
   */
  async findUserById(user_id: string, tenant_id: string): Promise<User | null> {
    return this.userRepo.findOne({ where: { id: user_id, tenant_id } });
  }
}
