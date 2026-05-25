import {
  BadRequestException,
  CallHandler,
  ConflictException,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import { IdempotencyCacheService } from './idempotency-cache.service';

const UUID_V4_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const MAX_KEY_LENGTH = 128;

const IDEMPOTENT_URL_PATTERNS: RegExp[] = [
  // /api/v1/{tenant}/sync/*
  /^\/api\/v1\/[^/]+\/sync\//,
  // /api/v1/{tenant}/{moduleId}/action
  /^\/api\/v1\/[^/]+\/[^/]+\/action(\?|$)/,
];

const HEADER = 'x-client-mutation-id';
const REPLAY_HEADER = 'X-Idempotency-Replay';

/**
 * STORY-036 — Global HTTP idempotency interceptor.
 *
 * Filters POST requests matching the allowlist (sync mutations + module
 * actions), validates `X-Client-Mutation-Id`, and short-circuits cached
 * responses. Cache is keyed by tenant_id from the JWT (not body) to
 * prevent cross-tenant replay attacks.
 *
 * Layering: this runs AFTER the global JwtAuthGuard, so `req.user` is
 * populated. Public endpoints (e.g. /auth/login) are not in the URL
 * allowlist, so they're skipped automatically.
 */
@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  private readonly logger = new Logger(IdempotencyInterceptor.name);

  constructor(private readonly cache: IdempotencyCacheService) {}

  async intercept(ctx: ExecutionContext, next: CallHandler): Promise<Observable<unknown>> {
    if (ctx.getType() !== 'http') return next.handle();

    const req = ctx.switchToHttp().getRequest();
    const res = ctx.switchToHttp().getResponse();

    if (req.method !== 'POST' || !this.shouldApply(req.url ?? req.originalUrl ?? '')) {
      return next.handle();
    }

    const rawKey = req.headers[HEADER];
    const key = Array.isArray(rawKey) ? rawKey[0] : rawKey;

    if (!key || typeof key !== 'string') {
      throw new BadRequestException({
        error: 'missing_idempotency_key',
        field: 'X-Client-Mutation-Id',
        message: 'X-Client-Mutation-Id header is required on this endpoint.',
      });
    }

    if (key.length > MAX_KEY_LENGTH || !UUID_V4_REGEX.test(key)) {
      throw new BadRequestException({
        error: 'invalid_idempotency_key',
        message: 'X-Client-Mutation-Id must be a UUID v4 (max 128 chars).',
      });
    }

    // req.user populated by JwtAuthGuard (global). If absent on a route
    // in the allowlist, that's a misconfiguration — fail safe.
    const tenantId = req.user?.tenant_id as string | undefined;
    const userId = req.user?.user_id as string | undefined;
    if (!tenantId) {
      // Not authenticated → skip idempotency, let downstream guards 401.
      return next.handle();
    }

    const cached = await this.cache.lookup(tenantId, key);
    if (cached) {
      // AC-12: detect cross-user replay within the same tenant.
      if (cached.userId && userId && cached.userId !== userId) {
        this.logger.warn(
          `idempotency.audit.user_mismatch tenant=${tenantId} key=${key} original_user=${cached.userId} replay_user=${userId}`,
        );
        throw new ConflictException({
          error: 'idempotency_user_mismatch',
          message: 'This mutation key was first used by a different user.',
        });
      }
      res.setHeader(REPLAY_HEADER, 'true');
      res.status(cached.status);
      return of(cached.body);
    }

    return next.handle().pipe(
      tap({
        next: async (body: unknown) => {
          const status = res.statusCode ?? 200;
          // AC-10: don't cache 5xx (transient); do cache 2xx + 4xx.
          if (status >= 500) return;
          await this.cache.store(tenantId, key, {
            status,
            body,
            contentType: 'application/json',
            capturedAt: new Date().toISOString(),
            userId,
          });
        },
        error: () => {
          // Controller threw → do not cache; let the client retry.
          // 4xx HttpExceptions are caught by Nest's exception filter
          // BEFORE this tap fires, so they won't be cached either at
          // this point. That's a known limitation: 4xx idempotence is
          // weaker (each retry re-validates), but determinism is
          // preserved because the same input produces the same 4xx.
        },
      }),
    );
  }

  private shouldApply(url: string): boolean {
    return IDEMPOTENT_URL_PATTERNS.some((p) => p.test(url));
  }
}
