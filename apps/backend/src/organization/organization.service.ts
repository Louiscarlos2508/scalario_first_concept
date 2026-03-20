import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../kernel/auth/supabase.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditLogService } from '../kernel/audit/audit-log.service';
import { ModuleRegistryService } from '../kernel/modules/module-registry.service';

@Injectable()
export class OrganizationService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly moduleRegistryService: ModuleRegistryService,
  ) {}

  async createOrganization(name: string, userId: string) {
    const supabase = this.supabaseService.getClient();

    // 1. Create Tenant via Supabase (keeps RLS context consistent)
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .insert({ name })
      .select()
      .single();

    if (tenantError) {
      throw new InternalServerErrorException(
        'Failed to create organization: ' + tenantError.message,
      );
    }

    // 2. Look up the Owner role FK (seeded in migration + seed script)
    const ownerRole = await this.prisma.role.findUnique({
      where: { name_vertical: { name: 'owner', vertical: 'retail' } },
    });

    if (!ownerRole) {
      throw new InternalServerErrorException(
        'Owner role not seeded — run prisma db seed before creating organizations',
      );
    }

    // 3. Create OrganizationMember with role FK (not string role)
    await this.prisma.organizationMember.create({
      data: {
        organizationId: tenant.id,
        userId,
        roleId: ownerRole.id,
      },
    });

    // 4. Audit log: record tenant creation
    await this.auditLogService.log({
      tenantId: tenant.id,
      userId,
      action: 'CREATE',
      entity: 'Tenant',
      entityId: tenant.id,
      before: null,
      after: { id: tenant.id, name: tenant.name },
    });

    // 5. Auto-activate shared + retail modules for the new tenant
    await this.moduleRegistryService.activateDefaultModulesForTenant(tenant.id, tenant.plan ?? 'free');

    return tenant;
  }

  async updateNotificationSettings(
    tenantId: string,
    data: {
      dailySummaryEnabled?: boolean;
      dailySummaryTime?: string;
      notificationChannel?: string;
    },
  ) {
    return this.prisma.tenant.update({
      where: { id: tenantId },
      data: {
        ...(data.dailySummaryEnabled !== undefined && { dailySummaryEnabled: data.dailySummaryEnabled }),
        ...(data.dailySummaryTime !== undefined && { dailySummaryTime: data.dailySummaryTime }),
        ...(data.notificationChannel !== undefined && { notificationChannel: data.notificationChannel }),
      },
      select: {
        id: true,
        dailySummaryEnabled: true,
        dailySummaryTime: true,
        notificationChannel: true,
      },
    });
  }

  async updateFreshnessThresholds(
    tenantId: string,
    data: { greenThreshold?: number; orangeThreshold?: number },
  ) {
    return this.prisma.tenant.update({
      where: { id: tenantId },
      data: {
        ...(data.greenThreshold !== undefined && { freshnessGreenThreshold: data.greenThreshold }),
        ...(data.orangeThreshold !== undefined && { freshnessOrangeThreshold: data.orangeThreshold }),
      },
      select: {
        id: true,
        freshnessGreenThreshold: true,
        freshnessOrangeThreshold: true,
      },
    });
  }

  async addMember(
    tenantId: string,
    userId: string,
    roleName: 'owner' | 'manager' | 'commercial',
  ) {
    const role = await this.prisma.role.findUnique({
      where: { name_vertical: { name: roleName, vertical: 'retail' } },
    });

    if (!role) {
      throw new InternalServerErrorException(
        `Role "${roleName}" not found — ensure RBAC seed has run`,
      );
    }

    const member = await this.prisma.organizationMember.create({
      data: {
        organizationId: tenantId,
        userId,
        roleId: role.id,
      },
    });

    // Audit log: record member addition
    await this.auditLogService.log({
      tenantId,
      userId,
      action: 'CREATE',
      entity: 'OrganizationMember',
      entityId: member.id,
      before: null,
      after: { id: member.id, userId, roleId: role.id },
    });

    return member;
  }
}
