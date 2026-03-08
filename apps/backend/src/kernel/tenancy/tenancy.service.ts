import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class TenancyService {
  constructor(private readonly prisma: PrismaService) {}

  async validateTenantAccess(
    tenantId: string,
    userId: string,
  ): Promise<boolean> {
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(tenantId) || !uuidRegex.test(userId)) {
      return false;
    }

    const member = await this.prisma.organizationMember.findUnique({
      where: {
        organizationId_userId: {
          organizationId: tenantId,
          userId: userId,
        },
      },
    });

    return !!member;
  }

  async getTenantConfig(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
    });

    if (!tenant) return null;

    return {
      id: tenant.id,
      name: tenant.name,
      currency: tenant.currency,
      timezone: tenant.timezone,
      fiscalJurisdiction: tenant.fiscalJurisdiction,
      status: tenant.status,
      sessionTimeoutMinutes: tenant.sessionTimeoutMinutes,
    };
  }

  async createTenant(data: {
    name: string;
    currency?: string;
    timezone?: string;
    fiscalJurisdiction?: string;
  }) {
    return this.prisma.tenant.create({
      data: {
        name: data.name,
        currency: data.currency ?? 'XOF',
        timezone: data.timezone ?? 'Africa/Abidjan',
        fiscalJurisdiction: data.fiscalJurisdiction,
      },
    });
  }

  async updateTenantConfig(
    tenantId: string,
    data: {
      name?: string;
      currency?: string;
      timezone?: string;
      fiscalJurisdiction?: string;
      status?: string;
      sessionTimeoutMinutes?: number;
    },
  ) {
    return this.prisma.tenant.update({
      where: { id: tenantId },
      data,
    });
  }
}
