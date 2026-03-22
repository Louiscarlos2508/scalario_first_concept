import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SupabaseAdminService } from '../admin/services/supabase-admin.service';

const DEFAULT_PAYMENT_METHODS = ['CASH', 'MOBILE_MONEY'];
const ALL_PAYMENT_METHODS = ['CASH', 'MOBILE_MONEY', 'CARD', 'TRANSFER', 'CREDIT', 'SPLIT'];

export class UpdateMyInfoDto {
  name?: string;
  address?: string;
  phone?: string;
  paymentMethods?: string[];
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
    const rawMethods = t.paymentMethods;
    const paymentMethods: string[] = Array.isArray(rawMethods) && rawMethods.length > 0
      ? rawMethods
      : DEFAULT_PAYMENT_METHODS;

    return {
      id: tenant.id,
      name: tenant.name,
      address: t.address ?? null,
      phone: t.phone ?? null,
      businessType: tenant.businessType,
      businessTypeName: businessTypeDef?.name ?? tenant.businessType,
      currency: tenant.currency,
      plan: tenant.plan,
      paymentMethods,
    };
  }

  async updateMyInfo(tenantId: string, dto: UpdateMyInfoDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant introuvable');

    const data: Record<string, unknown> = {};
    if (dto.name !== undefined && dto.name.trim() !== '') data.name = dto.name.trim();
    if (dto.address !== undefined) data.address = dto.address.trim() || null;
    if (dto.phone !== undefined) data.phone = dto.phone.trim() || null;
    if (dto.paymentMethods !== undefined) {
      const valid = dto.paymentMethods.filter(m => ALL_PAYMENT_METHODS.includes(m));
      // Always keep CASH active as a baseline
      data.paymentMethods = valid.includes('CASH') ? valid : ['CASH', ...valid];
    }

    const updated = await this.prisma.tenant.update({ where: { id: tenantId }, data });
    const u = updated as any;

    return {
      id: updated.id,
      name: updated.name,
      address: u.address ?? null,
      phone: u.phone ?? null,
    };
  }

  async getPaymentMethods(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    const t = tenant as any;
    const raw = t?.paymentMethods;
    const methods: string[] = Array.isArray(raw) && raw.length > 0 ? raw : DEFAULT_PAYMENT_METHODS;
    return { paymentMethods: methods, allMethods: ALL_PAYMENT_METHODS };
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
