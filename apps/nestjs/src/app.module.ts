import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { CacheModule } from './cache/cache.module';
import { DatabaseModule } from './common/database.module';
import { TenantAwareQueryRunner } from './common/database/tenant-aware-query-runner';
import { TenantIsolationFilter } from './common/filters/tenant-isolation.filter';
import { RedactInterceptor } from './common/interceptors/redact.interceptor';
import { TenantMiddleware } from './security/middleware/tenant.middleware';
import { AbilityMiddleware } from './security/abac/middleware/ability.middleware';
import { AbacModule } from './security/abac/abac.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
import { BduiModule } from './bdui/bdui.module';
import { ModuleEngineModule } from './module-engine/module-engine.module';
import { WorkflowModule } from './workflow/workflow.module';
import { CatalogueModule } from './catalogue/catalogue.module';
import { TenantsModule } from './tenants/tenants.module';
import { SecurityModule } from './security/security.module';
import { SyncModule } from './sync/sync.module';
import { AuditModule } from './audit/audit.module';
import { AiRelayModule } from './ai-relay/ai-relay.module';
import { RealtimeModule } from './realtime/realtime.module';
import { IdempotencyModule } from './idempotency/idempotency.module';
import { IdempotencyInterceptor } from './idempotency/idempotency.interceptor';

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
