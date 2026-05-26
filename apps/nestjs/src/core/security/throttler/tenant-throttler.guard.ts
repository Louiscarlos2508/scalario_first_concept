import { ExecutionContext, Injectable, Logger } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerRequest } from '@nestjs/throttler';

interface TenantRequest {
  user?: { tenant_id?: string; sub?: string };
}

const ROUTE_LIMITS = {
  ai: { limit: 20, ttl: 60 },
  payments: { limit: 10, ttl: 60 },
  default: { limit: 200, ttl: 60 },
} as const;

/**
 * TenantThrottlerGuard — Phase 1 stub.
 *
 * Extends NestJS ThrottlerGuard with per-tenant + per-user + per-endpoint
 * rate limiting using the Redis key pattern:
 *   throttle:{tenant}:{user}:{endpoint}
 *
 * Limits:
 *   /api/ai/*        → 20 req / 60s
 *   /api/payments/*  → 10 req / 60s
 *   /api/* (default) → 200 req / 60s
 */
@Injectable()
export class TenantThrottlerGuard extends ThrottlerGuard {
  private readonly logger = new Logger(TenantThrottlerGuard.name);

  protected async getTracker(req: TenantRequest): Promise<string> {
    const tenant = req.user?.tenant_id ?? 'anon';
    const user = req.user?.sub ?? 'anon';
    return `throttle:${tenant}:${user}`;
  }

  protected getLimit(context: ExecutionContext) {
    const req = context.switchToHttp().getRequest<{ route?: { path?: string } }>();
    const path = req.route?.path ?? '';

    if (path.startsWith('/api/ai')) return ROUTE_LIMITS.ai;
    if (path.startsWith('/api/payments')) return ROUTE_LIMITS.payments;
    return ROUTE_LIMITS.default;
  }

  protected async handleRequest(requestProps: ThrottlerRequest): Promise<boolean> {
    const { context, limit, ttl } = requestProps;
    const tracker = await this.getTracker(
      context.switchToHttp().getRequest<TenantRequest>(),
    );
    const key = `${tracker}:${context.getClass().name}.${context.getHandler().name}`;
    this.logger.debug(`Throttle check: ${key} limit=${limit} ttl=${ttl}s`);
    return true; // Phase 1: always allow
  }
}
