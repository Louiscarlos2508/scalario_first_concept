import { Module } from '@nestjs/common';
import { SuperAdminGuard } from './guards/super-admin.guard';
import { SupabaseAdminService } from './services/supabase-admin.service';
import { AdminTenantsController } from './tenants/admin-tenants.controller';
import { AdminTenantsService } from './tenants/admin-tenants.service';
import { AdminModulesController } from './modules/admin-modules.controller';
import { AdminModulesService } from './modules/admin-modules.service';
import { AdminUsersController } from './users/admin-users.controller';
import { AdminUsersService } from './users/admin-users.service';
import { AdminMonitoringController } from './monitoring/admin-monitoring.controller';
import { AdminMonitoringService } from './monitoring/admin-monitoring.service';
import { ModulesModule } from '../kernel/modules/modules.module';
import { BillingModule } from './billing/billing.module';
import { BusinessTypeModule } from './business-type/business-type.module';

@Module({
  imports: [ModulesModule, BillingModule, BusinessTypeModule],
  controllers: [AdminTenantsController, AdminModulesController, AdminUsersController, AdminMonitoringController],
  providers: [SuperAdminGuard, SupabaseAdminService, AdminTenantsService, AdminModulesService, AdminUsersService, AdminMonitoringService],
  exports: [SupabaseAdminService],
})
export class AdminModule {}
