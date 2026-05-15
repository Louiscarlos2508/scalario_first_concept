import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable, catchError, tap, throwError } from 'rxjs';
import { AUDITED_KEY, AuditedOptions } from '../decorators/audited.decorator';
import { AuditLogService } from '../services/audit-log.service';

interface AuditedRequest {
  params?: Record<string, string | undefined>;
  body?: unknown;
  user?: { tenant_id?: string; user_id?: string };
}

/**
 * STORY-020 — Auto-audit interceptor for routes decorated with
 * `@Audited('ACTION_NAME')`. Captures latency, success/error result,
 * `module_id` + `entity_id` from path params (override via decorator
 * options), and SHA-256 hashes the request body into `payload_hash`.
 *
 * Routes WITHOUT `@Audited()` pass through unchanged — we exit the
 * interceptor before subscribing to the observable, so there is zero
 * overhead on non-audited routes.
 */
@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(
    private readonly reflector: Reflector,
    private readonly audit: AuditLogService,
  ) {}

  intercept(ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    const meta = this.reflector.getAllAndOverride<AuditedOptions | undefined>(AUDITED_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (!meta) return next.handle();

    const req = ctx.switchToHttp().getRequest<AuditedRequest>();
    const start = Date.now();
    const moduleIdParam = meta.moduleIdParam ?? 'moduleId';
    const entityIdParam = meta.entityIdParam ?? 'id';
    const module_id = req.params?.[moduleIdParam] ?? null;
    const paramEntityId = req.params?.[entityIdParam] ?? null;

    return next.handle().pipe(
      tap((response: unknown) => {
        const entity_id = paramEntityId ?? this.extractId(response, entityIdParam) ?? null;
        void this.audit.log({
          action: meta.action,
          module_id,
          entity_id,
          payload: req.body,
          metadata: {
            result: 'success',
            latency_ms: Date.now() - start,
          },
        });
      }),
      catchError((err: unknown) => {
        const error = err as { status?: number; message?: string } & Record<string, unknown>;
        void this.audit.log({
          action: meta.action,
          module_id,
          entity_id: paramEntityId,
          payload: req.body,
          metadata: {
            result: 'error',
            error_code: error?.status ?? 500,
            error_message: (error?.message ?? '').toString().slice(0, 200),
            latency_ms: Date.now() - start,
          },
        });
        return throwError(() => err);
      }),
    );
  }

  private extractId(response: unknown, field: string): string | null {
    if (!response || typeof response !== 'object') return null;
    const obj = response as Record<string, unknown>;
    const value = obj[field];
    return typeof value === 'string' ? value : null;
  }
}
