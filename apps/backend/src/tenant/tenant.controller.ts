import { Body, Controller, Get, Patch, Req } from '@nestjs/common';
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

  /** GET /tenant/payment-methods — all authenticated roles (needed by POS) */
  @Get('payment-methods')
  getPaymentMethods(@CurrentTenant() tenantId: string) {
    return this.tenantService.getPaymentMethods(tenantId);
  }

  /** GET /tenant/my-users — owner + manager (manager needs it for cashier filter in history) */
  @Get('my-users')
  @Roles('owner', 'manager')
  getMyUsers(@CurrentTenant() tenantId: string) {
    return this.tenantService.getMyUsers(tenantId);
  }

  /** GET /tenant/loss-locations — FR87: all roles (needed by POS loss form) */
  @Get('loss-locations')
  getLossLocations(@CurrentTenant() tenantId: string) {
    return this.tenantService.getLossLocations(tenantId);
  }

  /** PATCH /tenant/loss-locations — FR87: owner only */
  @Patch('loss-locations')
  @Roles('owner')
  updateLossLocations(
    @CurrentTenant() tenantId: string,
    @Body() body: { locations: string[] },
  ) {
    return this.tenantService.updateLossLocations(tenantId, body.locations);
  }
}
