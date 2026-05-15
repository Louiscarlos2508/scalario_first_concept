import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { Observable, tap } from 'rxjs';

const SECRET_KEYS = new Set([
  'password',
  'password_hash',
  'refresh_token',
  'access_token',
  'owner_password',
  'token_hash',
]);

export function redact(value: unknown): unknown {
  if (value === null || value === undefined) return value;
  if (Array.isArray(value)) return value.map(redact);
  if (typeof value === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = SECRET_KEYS.has(k) ? '[REDACTED]' : redact(v);
    }
    return out;
  }
  return value;
}

/**
 * Application-wide request logger that strips sensitive fields from bodies
 * before they reach the log stream. AC-28: `password`, `password_hash`,
 * `refresh_token`, `access_token` never appear in logs.
 */
@Injectable()
export class RedactInterceptor implements NestInterceptor {
  private readonly logger = new Logger('Http');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = context.switchToHttp();
    const req = http.getRequest<{ method?: string; url?: string; body?: unknown }>();
    const start = Date.now();
    const redactedBody = redact(req.body);
    return next.handle().pipe(
      tap(() => {
        const ms = Date.now() - start;
        this.logger.log(
          `${req.method ?? '?'} ${req.url ?? '?'} ${ms}ms body=${JSON.stringify(redactedBody)}`,
        );
      }),
    );
  }
}
