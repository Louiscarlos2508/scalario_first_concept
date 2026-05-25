import {
  BadRequestException,
  CallHandler,
  ConflictException,
  ExecutionContext,
} from '@nestjs/common';
import { Observable, of, lastValueFrom } from 'rxjs';
import { IdempotencyCacheService } from '../idempotency-cache.service';
import { IdempotencyInterceptor } from '../idempotency.interceptor';

function mockCtx(opts: {
  method?: string;
  url?: string;
  headers?: Record<string, string>;
  user?: { tenant_id?: string; user_id?: string };
}): ExecutionContext {
  const req = {
    method: opts.method ?? 'POST',
    url: opts.url ?? '/api/v1/acme/sync/mutations',
    headers: opts.headers ?? {},
    user: opts.user,
  };
  const res: {
    statusCode: number;
    headers: Record<string, string>;
    setHeader: (k: string, v: string) => void;
    status: (n: number) => void;
  } = {
    statusCode: 200,
    headers: {},
    setHeader: (k: string, v: string) => {
      res.headers[k] = v;
    },
    status: (n: number) => {
      res.statusCode = n;
    },
  };
  return {
    getType: () => 'http',
    switchToHttp: () => ({
      getRequest: () => req,
      getResponse: () => res,
    }),
  } as unknown as ExecutionContext;
}

function mockHandler(body: unknown): CallHandler {
  return { handle: () => of(body) as Observable<unknown> };
}

const VALID_KEY = '11111111-2222-4333-8444-555555555555';
const VALID_KEY_2 = '11111111-2222-4333-8444-555555555556';

describe('IdempotencyInterceptor', () => {
  let cache: jest.Mocked<IdempotencyCacheService>;
  let interceptor: IdempotencyInterceptor;

  beforeEach(() => {
    cache = {
      lookup: jest.fn().mockResolvedValue(null),
      store: jest.fn().mockResolvedValue(undefined),
      getMetrics: jest.fn().mockReturnValue({ hits: 0, misses: 0, collisions: 0 }),
    } as unknown as jest.Mocked<IdempotencyCacheService>;
    interceptor = new IdempotencyInterceptor(cache);
  });

  it('skips non-http context', async () => {
    const ctx = { getType: () => 'rpc' } as unknown as ExecutionContext;
    const obs = await interceptor.intercept(ctx, mockHandler('passthrough'));
    expect(await lastValueFrom(obs)).toBe('passthrough');
  });

  it('skips non-POST methods (GET, PUT, DELETE)', async () => {
    const ctx = mockCtx({ method: 'GET', url: '/api/v1/acme/sync/mutations' });
    const obs = await interceptor.intercept(ctx, mockHandler('pass'));
    expect(await lastValueFrom(obs)).toBe('pass');
    expect(cache.lookup).not.toHaveBeenCalled();
  });

  it('skips URLs not in allowlist', async () => {
    const ctx = mockCtx({ url: '/auth/login', method: 'POST' });
    const obs = await interceptor.intercept(ctx, mockHandler('pass'));
    expect(await lastValueFrom(obs)).toBe('pass');
    expect(cache.lookup).not.toHaveBeenCalled();
  });

  it('matches /api/v1/{tenant}/sync/mutations (after Nest strips global prefix)', async () => {
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: { 'x-client-mutation-id': VALID_KEY },
      user: { tenant_id: 'tenant-1', user_id: 'user-1' },
    });
    await interceptor.intercept(ctx, mockHandler({ ok: true }));
    expect(cache.lookup).toHaveBeenCalledWith('tenant-1', VALID_KEY);
  });

  it('matches /{tenant}/{moduleId}/action', async () => {
    const ctx = mockCtx({
      url: '/api/v1/acme/caisse/action',
      headers: { 'x-client-mutation-id': VALID_KEY },
      user: { tenant_id: 'tenant-1', user_id: 'user-1' },
    });
    await interceptor.intercept(ctx, mockHandler({ ok: true }));
    expect(cache.lookup).toHaveBeenCalled();
  });

  it('AC-01/AC-19 — missing header throws 400 missing_idempotency_key', async () => {
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: {},
      user: { tenant_id: 'tenant-1', user_id: 'user-1' },
    });
    await expect(interceptor.intercept(ctx, mockHandler({}))).rejects.toBeInstanceOf(
      BadRequestException,
    );
    await expect(interceptor.intercept(ctx, mockHandler({}))).rejects.toMatchObject({
      response: { error: 'missing_idempotency_key' },
    });
  });

  it('AC-02/AC-20 — invalid UUID throws 400 invalid_idempotency_key', async () => {
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: { 'x-client-mutation-id': 'abc' },
      user: { tenant_id: 'tenant-1', user_id: 'user-1' },
    });
    await expect(interceptor.intercept(ctx, mockHandler({}))).rejects.toMatchObject({
      response: { error: 'invalid_idempotency_key' },
    });
  });

  it('AC-03 — key longer than 128 chars rejected', async () => {
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: { 'x-client-mutation-id': VALID_KEY + 'x'.repeat(100) },
      user: { tenant_id: 'tenant-1', user_id: 'user-1' },
    });
    await expect(interceptor.intercept(ctx, mockHandler({}))).rejects.toMatchObject({
      response: { error: 'invalid_idempotency_key' },
    });
  });

  it('AC-08 — cache HIT returns cached body without invoking next, sets X-Idempotency-Replay', async () => {
    cache.lookup.mockResolvedValue({
      status: 201,
      body: { id: 'cached-entity' },
      contentType: 'application/json',
      capturedAt: '2026-05-21T10:00:00Z',
      userId: 'user-1',
    });
    const handler = mockHandler({ id: 'fresh-entity' });
    const handleSpy = jest.spyOn(handler, 'handle');
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: { 'x-client-mutation-id': VALID_KEY },
      user: { tenant_id: 'tenant-1', user_id: 'user-1' },
    });

    const obs = await interceptor.intercept(ctx, handler);
    const body = await lastValueFrom(obs);
    expect(body).toEqual({ id: 'cached-entity' });
    expect(handleSpy).not.toHaveBeenCalled();
    const res = ctx.switchToHttp().getResponse();
    expect(res.headers['X-Idempotency-Replay']).toBe('true');
    expect(res.statusCode).toBe(201);
  });

  it('AC-09 — cache MISS lets controller run and stores result', async () => {
    cache.lookup.mockResolvedValue(null);
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: { 'x-client-mutation-id': VALID_KEY },
      user: { tenant_id: 'tenant-1', user_id: 'user-1' },
    });
    const obs = await interceptor.intercept(ctx, mockHandler({ id: 'new' }));
    const body = await lastValueFrom(obs);
    expect(body).toEqual({ id: 'new' });
    expect(cache.store).toHaveBeenCalledWith(
      'tenant-1',
      VALID_KEY,
      expect.objectContaining({
        status: 200,
        body: { id: 'new' },
        userId: 'user-1',
      }),
    );
  });

  it('AC-10 — 5xx responses are NOT cached (transient errors)', async () => {
    cache.lookup.mockResolvedValue(null);
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: { 'x-client-mutation-id': VALID_KEY },
      user: { tenant_id: 'tenant-1', user_id: 'user-1' },
    });
    const res = ctx.switchToHttp().getResponse();
    res.statusCode = 503; // simulate downstream failure
    const obs = await interceptor.intercept(ctx, mockHandler({ degraded: true }));
    await lastValueFrom(obs);
    expect(cache.store).not.toHaveBeenCalled();
  });

  it('AC-12 — replayed key by different user within same tenant → 409', async () => {
    cache.lookup.mockResolvedValue({
      status: 200,
      body: { id: 1 },
      contentType: 'application/json',
      capturedAt: 'now',
      userId: 'user-A',
    });
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: { 'x-client-mutation-id': VALID_KEY },
      user: { tenant_id: 'tenant-1', user_id: 'user-B' },
    });
    await expect(interceptor.intercept(ctx, mockHandler({}))).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('AC-12 — same user replay is allowed (no 409)', async () => {
    cache.lookup.mockResolvedValue({
      status: 200,
      body: { id: 1 },
      contentType: 'application/json',
      capturedAt: 'now',
      userId: 'user-1',
    });
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: { 'x-client-mutation-id': VALID_KEY_2 },
      user: { tenant_id: 'tenant-1', user_id: 'user-1' },
    });
    const obs = await interceptor.intercept(ctx, mockHandler({}));
    expect(await lastValueFrom(obs)).toEqual({ id: 1 });
  });

  it('skips when req.user is missing (not yet authenticated)', async () => {
    const ctx = mockCtx({
      url: '/api/v1/acme/sync/mutations',
      headers: { 'x-client-mutation-id': VALID_KEY },
      user: undefined,
    });
    const obs = await interceptor.intercept(ctx, mockHandler({ ok: true }));
    expect(await lastValueFrom(obs)).toEqual({ ok: true });
    expect(cache.lookup).not.toHaveBeenCalled();
  });
});
