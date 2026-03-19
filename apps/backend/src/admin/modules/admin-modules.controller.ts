import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { SuperAdminGuard } from '../guards/super-admin.guard';
import { AdminModulesService } from './admin-modules.service';

@Controller('admin')
@UseGuards(SuperAdminGuard)
export class AdminModulesController {
  constructor(private readonly adminModulesService: AdminModulesService) {}

  @Get('modules')
  listModules() {
    return this.adminModulesService.listModules();
  }

  @Get('tenants/:tenantId/modules')
  listTenantModules(@Param('tenantId') tenantId: string) {
    return this.adminModulesService.listTenantModules(tenantId);
  }

  @Post('tenants/:tenantId/modules/:moduleCode/activate')
  activateModule(
    @Param('tenantId') tenantId: string,
    @Param('moduleCode') moduleCode: string,
  ) {
    return this.adminModulesService.activateModule(tenantId, moduleCode);
  }

  @Post('tenants/:tenantId/modules/:moduleCode/deactivate')
  deactivateModule(
    @Param('tenantId') tenantId: string,
    @Param('moduleCode') moduleCode: string,
  ) {
    return this.adminModulesService.deactivateModule(tenantId, moduleCode);
  }
}
