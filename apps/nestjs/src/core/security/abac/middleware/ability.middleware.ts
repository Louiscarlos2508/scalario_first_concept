import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request, Response, NextFunction } from 'express';
import type { JwtPayload } from '../../../auth/interfaces/jwt-payload.interface';
import { AbilityFactory } from '../ability.factory';
import type { AbacAbility, AbacUser } from '../types';

interface MaybeAuthedRequest extends Request {
  user?: {
    user_id?: string;
    tenant_id?: string;
    roles?: string[];
    department_id?: string | null;
    metadata?: Record<string, unknown>;
  };
  ability?: AbacAbility;
}

/**
 * STORY-019 — populates `req.ability` for downstream guards/services.
 *
 * Runs in the express middleware phase (before guards), so we re-decode
 * the bearer JWT ourselves to extract user attributes. JwtAuthGuard
 * remains the authoritative signature check ; this middleware never
 * accepts an unsigned/tampered token because we use `verify`, not
 * `decode`.
 *
 * Failure modes are silent : without a token, without a tenant, or on
 * a transient build error, we leave `req.ability` unset. AbacGuard
 * fails closed in that case for routes decorated with `@AbacAction`.
 */
@Injectable()
export class AbilityMiddleware implements NestMiddleware {
  private readonly logger = new Logger(AbilityMiddleware.name);

  constructor(
    private readonly jwt: JwtService,
    private readonly factory: AbilityFactory,
  ) {}

  async use(req: MaybeAuthedRequest, _res: Response, next: NextFunction): Promise<void> {
    const user = this.extractUser(req);
    if (!user) return next();

    try {
      const tenant = await this.factory.findTenant(user.tenant_id);
      if (!tenant) return next();
      req.ability = await this.factory.createForUser(user, tenant);
    } catch (err) {
      this.logger.warn(`ability build failed: ${(err as Error).message}`);
    }
    next();
  }

  private extractUser(req: MaybeAuthedRequest): AbacUser | null {
    if (req.user?.user_id && req.user.tenant_id && Array.isArray(req.user.roles)) {
      return {
        user_id: req.user.user_id,
        tenant_id: req.user.tenant_id,
        roles: req.user.roles,
        department_id: req.user.department_id ?? null,
        metadata: req.user.metadata,
      };
    }

    const header = req.headers?.authorization;
    if (!header || typeof header !== 'string' || !header.startsWith('Bearer ')) return null;
    const token = header.slice('Bearer '.length).trim();
    if (!token) return null;

    try {
      const payload = this.jwt.verify<JwtPayload>(token);
      if (!payload?.tenant_id || !payload.sub || !Array.isArray(payload.roles)) return null;
      return {
        user_id: payload.sub,
        tenant_id: payload.tenant_id,
        roles: payload.roles,
        department_id: payload.department_id ?? null,
      };
    } catch {
      return null;
    }
  }
}
