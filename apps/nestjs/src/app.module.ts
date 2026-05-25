import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { CacheModule } from './core/cache/cache.module';
import { DatabaseModule } from './common/database.module';
import { TenantAwareQueryRunner } from './common/database/tenant-aware-query-runner';
import { TenantIsolationFilter } from './common/filters/tenant-isolation.filter';
import { RedactInterceptor } from './common/interceptors/redact.interceptor';
import { TenantMiddleware } from './core/security/middleware/tenant.middleware';
import { AbilityMiddleware } from './core/security/abac/middleware/ability.middleware';
import { AbacModule } from './core/security/abac/abac.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './core/auth/auth.module';
import { BduiModule } from './bdui/bdui.module';
import { ModuleEngineModule } from './engines/action/module-engine.module';
import { WorkflowModule } from './engines/workflow/workflow.module';
import { CatalogueModule } from './catalog-loader/catalogue.module';
import { TenantsModule } from './tenants/tenants.module';
import { SecurityModule } from './core/security/security.module';
import { SyncModule } from './sync/sync.module';
import { AuditModule } from './core/audit/audit.module';
import { AiRelayModule } from './ai-relay/ai-relay.module';
import { RealtimeModule } from './realtime/realtime.module';
import { IdempotencyModule } from './core/idempotency/idempotency.module';
import { IdempotencyInterceptor } from './core/idempotency/idempotency.interceptor';
import { PaymentModule } from './payment/payment.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 1000 }]),
    DatabaseModule,
    CacheModule,
    HealthModule,
    AuthModule,
    BduiModule,
    ModuleEngineModule,
    WorkflowModule,
    CatalogueModule,
    TenantsModule,
    SecurityModule,
    AbacModule,
    SyncModule,
    AuditModule,
    AiRelayModule,
    RealtimeModule,
    IdempotencyModule,
    PaymentModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_INTERCEPTOR, useClass: RedactInterceptor },
    // STORY-036 — global HTTP idempotency cache. Runs after RedactInterceptor
    // so cached bodies are already redacted. Filters POST + URL allowlist.
    { provide: APP_INTERCEPTOR, useClass: IdempotencyInterceptor },
    { provide: APP_FILTER, useClass: TenantIsolationFilter },
    TenantAwareQueryRunner,
  ],
  exports: [TenantAwareQueryRunner],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    // STORY-016 — runs after Passport's JwtAuthGuard (APP_GUARD), so
    // `req.user.tenant_id` is populated before this middleware reads it.
    consumer.apply(TenantMiddleware).forRoutes('*');
    // STORY-019 — AbilityMiddleware runs after TenantMiddleware so
    // `req.ability` is built once per request. AbacGuard reads from it.
    consumer.apply(AbilityMiddleware).forRoutes('*');
  }
}
