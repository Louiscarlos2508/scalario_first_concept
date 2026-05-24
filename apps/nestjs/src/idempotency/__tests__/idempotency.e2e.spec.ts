/* eslint-disable @typescript-eslint/no-explicit-any */
import {
  Body,
  Controller,
  INestApplication,
  Module,
  Post,
  Req,
  ExecutionContext,
  CanActivate,
} from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { IdempotencyInterceptor } from '../idempotency.interceptor';
import { IdempotencyCacheService } from '../idempotency-cache.service';
import { RedisService } from '../../cache/services/redis.service';
import { FakeRedisService } from '../../cache/__tests__/fake-redis';

const TENANT_A = 'tenant-A';
const TENANT_B = 'tenant-B';
const USER_A1 = 'user-A1';
const USER_A2 = 'user-A2';
const VALID_KEY_1 = '11111111-2222-4333-8444-555555555551';
const VALID_KEY_2 = '11111111-2222-4333-8444-555555555552';

let counter = 0;

@Controller()
class TestController {
  @Post('api/v1/:tenant/sync/mutations')
  syncMutations(@Body() body: any, @Req() req: any) {
    counter++;
    return {
      sale_id: `sale-${counter}`,
      tenant: req.params.tenant,
      received: body,
    };
  }

  @Post('api/v1/:tenant/:moduleId/action')
  moduleAction(@Body() body: any, @Req() req: any) {
    counter++;
    return {
      action_id: `act-${counter}`,
      module: req.params.moduleId,
      received: body,
    };
  }
}

class FakeAuthGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest();
    const tenantHeader = req.headers['x-test-tenant'] as string | undefined;
    const userHeader = req.headers['x-test-user'] as string | undefined;
    if (tenantHeader && userHeader) {
      req.user = { tenant_id: tenantHeader, user_id: userHeader };
    }
    return true;
  }
}

function makeTestModule(fake: FakeRedisService) {
  @Module({
    controllers: [TestController],
    providers: [
      { provide: RedisService, useValue: fake },
      IdempotencyCacheService,
      {
        provide: APP_INTERCEPTOR,
        useFactory: (cache: IdempotencyCacheService) => new IdempotencyInterceptor(cache),
        inject: [IdempotencyCacheService],
      },
    ],
  })
  class DynamicTestModule {}
  return DynamicTestModule;
}

describe('Idempotency E2E (HTTP)', () => {
  let app: INestApplication;
  let server: ReturnType<INestApplication['getHttpServer']>;
  let fakeRedis: FakeRedisService;

  beforeAll(async () => {
    fakeRedis = new FakeRedisService();
    const moduleRef = await Test.createTestingModule({
      imports: [makeTestModule(fakeRedis)],
    }).compile();

    app = moduleRef.createNestApplication();
    // Mimic the FakeAuthGuard order: register it globally so req.user
    // is set before our interceptor runs.
    app.useGlobalGuards(new FakeAuthGuard());
    await app.init();
    server = app.getHttpServer();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    counter = 0;
    fakeRedis.reset();
  });

  it('AC-16 — POST + identical re-POST returns cached body with X-Idempotency-Replay header (no double execution)', async () => {
    const res1 = await request(server)
      .post(`/api/v1/${TENANT_A}/sync/mutations`)
      .set('x-test-tenant', TENANT_A)
      .set('x-test-user', USER_A1)
      .set('X-Client-Mutation-Id', VALID_KEY_1)
      .send({ mutations: [{ id: 'm1' }] })
      .expect(201);

    expect(res1.body.sale_id).toBe('sale-1');
    expect(res1.headers['x-idempotency-replay']).toBeUndefined();

    const res2 = await request(server)
      .post(`/api/v1/${TENANT_A}/sync/mutations`)
      .set('x-test-tenant', TENANT_A)
      .set('x-test-user', USER_A1)
      .set('X-Client-Mutation-Id', VALID_KEY_1)
      .send({ mutations: [{ id: 'm1' }] })
      .expect(201);

    expect(res2.body.sale_id).toBe('sale-1'); // same body
    expect(res2.headers['x-idempotency-replay']).toBe('true');
    expect(counter).toBe(1); // controller hit ONCE despite 2 POSTs
  });

  it('AC-18 — same key from different tenants does NOT collide (tenant-scoped)', async () => {
    await request(server)
      .post(`/api/v1/${TENANT_A}/sync/mutations`)
      .set('x-test-tenant', TENANT_A)
      .set('x-test-user', USER_A1)
      .set('X-Client-Mutation-Id', VALID_KEY_1)
      .send({})
      .expect(201);

    const resB = await request(server)
      .post(`/api/v1/${TENANT_B}/sync/mutations`)
      .set('x-test-tenant', TENANT_B)
      .set('x-test-user', USER_A1)
      .set('X-Client-Mutation-Id', VALID_KEY_1) // same key!
      .send({})
      .expect(201);

    expect(resB.body.tenant).toBe(TENANT_B);
    expect(resB.headers['x-idempotency-replay']).toBeUndefined();
    expect(counter).toBe(2); // both tenants executed independently
  });

  it('AC-19 — missing X-Client-Mutation-Id returns 400 missing_idempotency_key', async () => {
    const res = await request(server)
      .post(`/api/v1/${TENANT_A}/sync/mutations`)
      .set('x-test-tenant', TENANT_A)
      .set('x-test-user', USER_A1)
      .send({})
      .expect(400);

    expect(res.body.error).toBe('missing_idempotency_key');
    expect(res.body.field).toBe('X-Client-Mutation-Id');
    expect(counter).toBe(0);
  });

  it('AC-20 — non-UUID key returns 400 invalid_idempotency_key', async () => {
    const res = await request(server)
      .post(`/api/v1/${TENANT_A}/sync/mutations`)
      .set('x-test-tenant', TENANT_A)
      .set('x-test-user', USER_A1)
      .set('X-Client-Mutation-Id', 'abc-not-a-uuid')
      .send({})
      .expect(400);

    expect(res.body.error).toBe('invalid_idempotency_key');
  });

  it('AC-12 — same key replayed by different user within same tenant → 409', async () => {
    await request(server)
      .post(`/api/v1/${TENANT_A}/sync/mutations`)
      .set('x-test-tenant', TENANT_A)
      .set('x-test-user', USER_A1)
      .set('X-Client-Mutation-Id', VALID_KEY_2)
      .send({})
      .expect(201);

    const res = await request(server)
      .post(`/api/v1/${TENANT_A}/sync/mutations`)
      .set('x-test-tenant', TENANT_A)
      .set('x-test-user', USER_A2) // different user, same tenant
      .set('X-Client-Mutation-Id', VALID_KEY_2)
      .send({})
      .expect(409);

    expect(res.body.error).toBe('idempotency_user_mismatch');
  });

  it('module action endpoint also enforces idempotency', async () => {
    const res1 = await request(server)
      .post(`/api/v1/${TENANT_A}/caisse/action`)
      .set('x-test-tenant', TENANT_A)
      .set('x-test-user', USER_A1)
      .set('X-Client-Mutation-Id', VALID_KEY_1)
      .send({ action: 'create_sale' })
      .expect(201);

    const res2 = await request(server)
      .post(`/api/v1/${TENANT_A}/caisse/action`)
      .set('x-test-tenant', TENANT_A)
      .set('x-test-user', USER_A1)
      .set('X-Client-Mutation-Id', VALID_KEY_1)
      .send({ action: 'create_sale' })
      .expect(201);

    expect(res1.body.action_id).toBe(res2.body.action_id);
    expect(res2.headers['x-idempotency-replay']).toBe('true');
    expect(counter).toBe(1);
  });

  it('non-allowlisted POST endpoint is NOT intercepted (no header required)', async () => {
    // /auth/login style endpoint — not in allowlist
    @Controller()
    class FreeController {
      @Post('api/v1/auth/login')
      login(@Body() body: any) {
        return { ok: true, body };
      }
    }
    const moduleRef = await Test.createTestingModule({
      controllers: [FreeController],
      providers: [
        { provide: RedisService, useValue: fakeRedis },
        IdempotencyCacheService,
        {
          provide: APP_INTERCEPTOR,
          useFactory: (cache: IdempotencyCacheService) => new IdempotencyInterceptor(cache),
          inject: [IdempotencyCacheService],
        },
      ],
    }).compile();
    const freeApp = moduleRef.createNestApplication();
    await freeApp.init();
    const freeServer = freeApp.getHttpServer();

    const res = await request(freeServer)
      .post('/api/v1/auth/login')
      .send({ email: 'a@b.com' })
      .expect(201);

    expect(res.body.ok).toBe(true);
    await freeApp.close();
  });
});
