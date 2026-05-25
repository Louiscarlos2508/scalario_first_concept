import { CallHandler, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable, of, throwError } from 'rxjs';
import { lastValueFrom } from 'rxjs';
import { AUDITED_KEY } from '../decorators/audited.decorator';
import { AuditInterceptor } from '../interceptors/audit.interceptor';
import { AuditLogService } from '../services/audit-log.service';

function makeCtx(handler: () => unknown, req: Record<string, unknown>): ExecutionContext {
  return {
    getHandler: () => handler,
    getClass: () => class {},
    switchToHttp: () => ({ getRequest: () => req }),
  } as unknown as ExecutionContext;
}

function makeReflector(action: string | undefined): Reflector {
  return {
    getAllAndOverride: <T>(key: string): T | undefined => {
      if (key === AUDITED_KEY && action) {
        return { action, moduleIdParam: 'moduleId', entityIdParam: 'id' } as unknown as T;
      }
      return undefined;
    },
  } as unknown as Reflector;
}

describe('AuditInterceptor', () => {
  it('skips routes without @Audited() metadata', async () => {
    const audit = { log: jest.fn() } as unknown as AuditLogService;
    const interceptor = new AuditInterceptor(makeReflector(undefined), audit);
    const handler: CallHandler = { handle: () => of({ id: 'x' }) };
    const res = await lastValueFrom(
      interceptor.intercept(
        makeCtx(() => undefined, {}),
        handler,
      ) as Observable<unknown>,
    );
    expect(res).toEqual({ id: 'x' });
    expect(audit.log).not.toHaveBeenCalled();
  });

  it('logs result=success with latency on completion', async () => {
    const audit = { log: jest.fn(async () => undefined) } as unknown as AuditLogService;
    const interceptor = new AuditInterceptor(makeReflector('CREATE_THING'), audit);
    const handler: CallHandler = { handle: () => of({ id: 'thing-1' }) };
    await lastValueFrom(
      interceptor.intercept(
        makeCtx(() => undefined, { params: { moduleId: 'mod' }, body: { foo: 1 } }),
        handler,
      ) as Observable<unknown>,
    );
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'CREATE_THING',
        module_id: 'mod',
        entity_id: 'thing-1',
        payload: { foo: 1 },
        metadata: expect.objectContaining({ result: 'success' }),
      }),
    );
  });

  it('logs result=error with error_code when downstream throws', async () => {
    const audit = { log: jest.fn(async () => undefined) } as unknown as AuditLogService;
    const interceptor = new AuditInterceptor(makeReflector('CREATE_THING'), audit);
    const err: Error & { status?: number } = Object.assign(new Error('bad input'), { status: 400 });
    const handler: CallHandler = { handle: () => throwError(() => err) };
    await expect(
      lastValueFrom(
        interceptor.intercept(
          makeCtx(() => undefined, { params: {}, body: { foo: 1 } }),
          handler,
        ) as Observable<unknown>,
      ),
    ).rejects.toBe(err);
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'CREATE_THING',
        metadata: expect.objectContaining({ result: 'error', error_code: 400 }),
      }),
    );
  });
});
