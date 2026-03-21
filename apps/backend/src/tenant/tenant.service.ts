import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SupabaseAdminService } from '../admin/services/supabase-admin.service';

export class UpdateMyInfoDto {
  name?: string;
  address?: string;
  phone?: string;
}

@Injectable()
export class TenantService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly supabaseAdmin: SupabaseAdminService,
  ) {}

  async getMyInfo(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant introuvable');

    const businessTypeDef = await this.prisma.businessTypeDefinition.findUnique({
      where: { code: tenant.businessType },
      select: { name: true },
    });

    const t = tenant as any;
    return {
      id: tenant.id,
      name: tenant.name,
      address: t.address ?? null,
      phone: t.phone ?? null,
      businessType: tenant.businessType,
      businessTypeName: businessTypeDef?.name ?? tenant.businessType,
      currency: tenant.currency,
      plan: tenant.plan,
    };
  }

  async updateMyInfo(tenantId: string, dto: UpdateMyInfoDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant introuvable');

    const data: Record<string, unknown> = {};
    if (dto.name !== undefined && dto.name.trim() !== '') data.name = dto.name.trim();
    if (dto.address !== undefined) data.address = dto.address.trim() || null;
    if (dto.phone !== undefined) data.phone = dto.phone.trim() || null;

    const updated = await this.prisma.tenant.update({ where: { id: tenantId }, data });
    const u = updated as any;

    return {
      id: updated.id,
      name: updated.name,
      address: u.address ?? null,
      phone: u.phone ?? null,
    };
  }

  async getMyUsers(tenantId: string) {
    const members = await this.prisma.organizationMember.findMany({
      where: { organizationId: tenantId },
      include: { role: { select: { name: true } } },
      orderBy: { createdAt: 'asc' },
    });

    const enriched = await Promise.all(
      members.map(async (m) => {
        const supabaseUser = await this.supabaseAdmin.getUserById(m.userId);
        return {
          userId: m.userId,
          email: supabaseUser?.email ?? '',
          fullName: supabaseUser?.fullName ?? null,
          role: m.role.name,
          createdAt: m.createdAt,
        };
      }),
    );

    return enriched;
  }
}
