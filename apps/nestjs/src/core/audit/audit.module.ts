import { Global, Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Tenant } from '../auth/entities/tenant.entity';
import { AuditController } from './controllers/audit.controller';
import { AuditLog } from './entities/audit-log.entity';
import { AuditInterceptor } from './interceptors/audit.interceptor';
import { AuditLogService } from './services/audit-log.service';
import { AuditPurgeService } from './services/audit-purge.service';

/**
 * STORY-020 — Audit log infrastructure.
 *
 * `@Global` because every module (auth, security, tenants, future
 * business modules) needs `AuditLogService.log(...)`. Forcing each
 * importer to re-import would mean dozens of redundant lines.
 *
 * `AuditInterceptor` is registered as `APP_INTERCEPTOR` — it runs on
 * every route, but immediately exits when `@Audited()` metadata is
 * absent, so the overhead on non-audited routes is one Reflector
 * lookup per request.
 */
@Global()
@Module({
  imports: [TypeOrmModule.forFeature([AuditLog, Tenant])],
  controllers: [AuditController],
  providers: [
    AuditLogService,
    AuditPurgeService,
    { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
  ],
  exports: [AuditLogService, AuditPurgeService],
})
export class AuditModule {}
