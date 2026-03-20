import { Body, Controller, Get, Post } from '@nestjs/common';
import { Roles } from '../../kernel/rbac/roles.decorator';
import { CurrentTenant } from '../../kernel/tenancy/tenant.decorator';
import { BillingEventsService } from './billing-events.service';

@Controller('settings/billing')
export class SettingsBillingController {
  constructor(private readonly billingEventsService: BillingEventsService) {}

  @Get()
  @Roles('owner')
  getMySubscription(@CurrentTenant() tenantId: string) {
    return this.billingEventsService.getOwnerBilling(tenantId);
  }

  @Post('upgrade-request')
  @Roles('owner')
  requestUpgrade(
    @CurrentTenant() tenantId: string,
    @Body('message') message?: string,
  ) {
    return this.billingEventsService.createUpgradeRequest(tenantId, message);
  }
}
