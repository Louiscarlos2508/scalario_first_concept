import { Body, Controller, Get, Patch } from '@nestjs/common';
import { Roles } from '../kernel/rbac/roles.decorator';
import { CurrentTenant } from '../kernel/tenancy/tenant.decorator';
import { TenantService, UpdateMyInfoDto } from './tenant.service';

@Controller('tenant')
export class TenantController {
  constructor(private readonly tenantService: TenantService) {}

  /** GET /tenant/my-info — owner + manager */
  @Get('my-info')
  @Roles('owner', 'manager')
  getMyInfo(@CurrentTenant() tenantId: string) {
    return this.tenantService.getMyInfo(tenantId);
  }

  /** PATCH /tenant/my-info — owner only */
  @Patch('my-info')
  @Roles('owner')
  updateMyInfo(
    @CurrentTenant() tenantId: string,
    @Body() dto: UpdateMyInfoDto,
  ) {
    return this.tenantService.updateMyInfo(tenantId, dto);
  }

  /** GET /tenant/my-users — owner only */
  @Get('my-users')
  @Roles('owner')
  getMyUsers(@CurrentTenant() tenantId: string) {
    return this.tenantService.getMyUsers(tenantId);
  }
}
