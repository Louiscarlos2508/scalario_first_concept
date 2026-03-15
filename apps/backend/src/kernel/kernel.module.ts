import { Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { TenancyModule } from './tenancy/tenancy.module';
import { RbacModule } from './rbac/rbac.module';
import { ModulesModule } from './modules/modules.module';
import { AuditLogModule } from './audit/audit-log.module';
import { EventsModule } from './events/events.module';
import { AuthGuard } from './auth/auth.guard';
import { TenantGuard } from './tenancy/tenant.guard';
import { ModuleGuard } from './modules/module.guard';
import { RolesGuard } from './rbac/roles.guard';

@Global()
@Module({
  imports: [AuthModule, TenancyModule, RbacModule, ModulesModule, AuditLogModule, EventsModule],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_GUARD, useClass: TenantGuard },
    { provide: APP_GUARD, useClass: ModuleGuard }, // Auth → Tenant → Module → Roles
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
  exports: [AuthModule, TenancyModule, RbacModule, ModulesModule, AuditLogModule, EventsModule],
})
export class KernelModule {}
