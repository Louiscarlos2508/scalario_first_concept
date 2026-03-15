import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../kernel/auth/supabase.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class OrganizationService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly prisma: PrismaService,
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

    return tenant;
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

    return this.prisma.organizationMember.create({
      data: {
        organizationId: tenantId,
        userId,
        roleId: role.id,
      },
    });
  }
}
