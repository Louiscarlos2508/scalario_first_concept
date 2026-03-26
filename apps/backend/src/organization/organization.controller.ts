import { Body, Controller, Param, Patch, Post } from '@nestjs/common';
import { OrganizationService } from './organization.service';
import { CurrentUser } from '../kernel/auth/auth.decorator';
import { CurrentTenant } from '../kernel/tenancy/tenant.decorator';
import { Roles } from '../kernel/rbac/roles.decorator';

@Controller('organizations')
export class OrganizationController {
  constructor(private readonly organizationService: OrganizationService) {}

  @Post()
  async create(@Body('name') name: string, @CurrentUser() user: any) {
    return this.organizationService.createOrganization(name, user.id);
  }

  /**
   * Add a member to an organization with a specified role.
   * Only owners can manage team membership.
   */
  // PATCH /organizations/notification-settings
  @Patch('notification-settings')
  @Roles('owner')
  async updateNotificationSettings(
    @Body() dto: { dailySummaryEnabled?: boolean; dailySummaryTime?: string; notificationChannel?: string },
    @CurrentTenant() tenantId: string,
  ) {
    return this.organizationService.updateNotificationSettings(tenantId, dto);
  }

  @Patch('freshness-thresholds')
  @Roles('owner')
  async updateFreshnessThresholds(
    @Body() dto: { greenThreshold?: number; orangeThreshold?: number },
    @CurrentTenant() tenantId: string,
  ) {
    return this.organizationService.updateFreshnessThresholds(tenantId, dto);
  }

  @Post(':id/members')
  @Roles('owner')
  async addMember(
    @Param('id') _tenantId: string,
    @Body('userId') userId: string,
    @Body('role') role: 'owner' | 'manager' | 'commercial',
    @CurrentTenant() tenantId: string,
  ) {
    // Use authenticated tenant context (from TenantGuard), not URL param
    return this.organizationService.addMember(tenantId, userId, role);
  }

  @Patch('return-policy')
  @Roles('owner')
  async updateReturnPolicy(
    @Body() dto: { returnPolicyDays?: number; returnRequiresReason?: boolean; returnRequiresApproval?: boolean },
    @CurrentTenant() tenantId: string,
  ) {
    return this.organizationService.updateReturnPolicy(tenantId, dto);
  }

  @Post(':id/invite')
  @Roles('owner')
  async inviteMember(
    @Param('id') _tenantId: string,
    @Body() dto: { email: string; role: string; fullName?: string },
    @CurrentTenant() tenantId: string,
    @CurrentUser() user: any,
  ) {
    return this.organizationService.inviteMember(tenantId, dto, user.id);
  }

  @Patch(':id/members/:userId')
  @Roles('owner')
  async changeMemberRole(
    @Param('id') _tenantId: string,
    @Param('userId') userId: string,
    @Body('role') role: string,
    @CurrentTenant() tenantId: string,
    @CurrentUser() user: any,
  ) {
    return this.organizationService.changeMemberRole(tenantId, userId, role, user.id);
  }
}
