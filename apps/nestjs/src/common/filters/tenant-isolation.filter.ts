import { ArgumentsHost, Catch, ExceptionFilter, ForbiddenException, Logger } from '@nestjs/common';
import { QueryFailedError } from 'typeorm';
import { tenantContext } from '../context/tenant-context';

// PostgreSQL `insufficient_privilege` — emitted when RLS denies a row.
const PG_INSUFFICIENT_PRIVILEGE = '42501';

interface PgError {
  code?: string;
  message?: string;
}

/**
 * STORY-016 AC-19/AC-20.
 *
 * Catches a row-level-security denial bubbling up from TypeORM and
 * converts it to a sanitized 403 — never leaks SQL state or table
 * names. Emits an `TENANT_VIOLATION_DETECTED` log entry that STORY-020
 * will pipe into the audit log when that pipeline lands.
 */
@Catch(QueryFailedError)
export class TenantIsolationFilter implements ExceptionFilter {
  private readonly logger = new Logger(TenantIsolationFilter.name);

  catch(exception: QueryFailedError, host: ArgumentsHost): void {
    const driverError = (exception as unknown as { driverError?: PgError }).driverError;
    const code = driverError?.code ?? (exception as unknown as PgError).code;

    if (code !== PG_INSUFFICIENT_PRIVILEGE) {
      // Not an RLS denial — re-throw so the default Nest filter handles it.
      throw exception;
    }

    const ctx = tenantContext.get();
    this.logger.warn(
      `TENANT_VIOLATION_DETECTED tenant_id=${ctx?.tenant_id ?? 'unknown'} user_id=${
        ctx?.user_id ?? 'unknown'
      } code=${code}`,
    );

    const http = host.switchToHttp();
    const res = http.getResponse<{
      status: (code: number) => { json: (body: unknown) => void };
    }>();
    const sanitized = new ForbiddenException('Tenant isolation violation');
    res.status(sanitized.getStatus()).json(sanitized.getResponse());
  }
}
