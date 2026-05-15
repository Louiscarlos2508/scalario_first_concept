import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { DatabaseModule } from './common/database.module';
import { TenantAwareQueryRunner } from './common/database/tenant-aware-query-runner';
import { TenantIsolationFilter } from './common/filters/tenant-isolation.filter';
import { RedactInterceptor } from './common/interceptors/redact.interceptor';
import { TenantMiddleware } from './security/middleware/tenant.middleware';
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

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 1000 }]),
    DatabaseModule,
    HealthModule,
    AuthModule,
    BduiModule,
    ModuleEngineModule,
    WorkflowModule,
    CatalogueModule,
    TenantsModule,
    SecurityModule,
    SyncModule,
    AuditModule,
    AiRelayModule,
    RealtimeModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_INTERCEPTOR, useClass: RedactInterceptor },
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
  }
}
