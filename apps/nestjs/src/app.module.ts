import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from './common/database.module';
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
})
export class AppModule {}
