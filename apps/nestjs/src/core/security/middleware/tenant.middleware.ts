import { ForbiddenException, Injectable, Logger, NestMiddleware } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { DataSource } from 'typeorm';
import { Request, Response, NextFunction } from 'express';
import { tenantContext, TenantStore } from '../../../common/context/tenant-context';
import { TenantsService } from '../../../tenants/tenants.service';
import type { JwtPayload } from '../../auth/interfaces/jwt-payload.interface';

interface MaybeAuthedRequest extends Request {
  user?: { user_id?: string; tenant_id?: string; roles?: string[] };
}

/**
 * STORY-016 — TenantMiddleware.
 *
 * NestJS middlewares run before guards, so `req.user` (set by Passport's
 * JwtAuthGuard) is not yet available. We do a lightweight JWT decode
 * here to lift `tenant_id` out of the token — JwtAuthGuard remains the
 * authoritative signature check, this middleware does NOT replace it.
 *
 * Responsibilities:
 *   1. If the request carries a valid bearer JWT, verify the tenant is
 *      still active (cached, TTL 5 min) and open an AsyncLocalStorage
 *      scope so services downstream can read `tenant_id` via
 *      `tenantContext.get()` without explicit plumbing.
 *   2. Seed the per-request PostgreSQL GUC `app.current_tenant_id` —
 *      the value RLS policies (STORY-017) match `tenant_id` against.
 *
 * Public routes (no/invalid JWT) pass through untouched; the
 * `@CurrentTenant()` decorator throws if a controller forgets to mark
 * a tenant-bound route as protected.
 */
@Injectable()
export class TenantMiddleware implements NestMiddleware {
  private readonly logger = new Logger(TenantMiddleware.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly tenantsService: TenantsService,
    private readonly jwt: JwtService,
  ) {}

  async use(req: MaybeAuthedRequest, _res: Response, next: NextFunction): Promise<void> {
    const store = this.extractStore(req);
    if (!store) {
      // Public route or unauthenticated — let JwtAuthGuard reject if needed.
      return next();
    }

    const activeId = await this.tenantsService.getActive(store.tenant_id);
    if (!activeId) {
      throw new ForbiddenException('Tenant disabled');
    }

    await this.setSessionGuc(store.tenant_id);

    tenantContext.run(store, () => next());
  }

  private extractStore(req: MaybeAuthedRequest): TenantStore | null {
    // Prefer a downstream-populated user (worker / test inject), otherwise
    // decode the bearer token. We use `verify`, not `decode`, so a
    // tampered token cannot fake `tenant_id`.
    if (req.user?.tenant_id && typeof req.user.tenant_id === 'string') {
      return {
        tenant_id: req.user.tenant_id,
        user_id: req.user.user_id,
        roles: req.user.roles,
      };
    }

    const header = req.headers?.authorization;
    if (!header || typeof header !== 'string' || !header.startsWith('Bearer ')) return null;

    const token = header.slice('Bearer '.length).trim();
    if (!token) return null;

    try {
      const payload = this.jwt.verify<JwtPayload>(token);
      if (!payload?.tenant_id || typeof payload.tenant_id !== 'string') return null;
      return {
        tenant_id: payload.tenant_id,
        user_id: payload.sub,
        roles: payload.roles ?? [],
      };
    } catch {
      // Bad/expired token — JwtAuthGuard will produce the canonical 401.
      return null;
    }
  }

  private async setSessionGuc(tenant_id: string): Promise<void> {
    if (!this.dataSource?.isInitialized) return;
    try {
      // is_local=false — survives across queries on this connection until
      // RESET (issued by TenantAwareQueryRunner on release).
      await this.dataSource.query("SELECT set_config('app.current_tenant_id', $1, false)", [
        tenant_id,
      ]);
    } catch (err) {
      this.logger.debug(`set_config skipped: ${(err as Error)?.message ?? 'unknown'}`);
    }
  }
}
