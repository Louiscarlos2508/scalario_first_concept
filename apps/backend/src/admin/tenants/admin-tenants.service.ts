import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  UnprocessableEntityException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SupabaseAdminService } from '../services/supabase-admin.service';
import { ModuleRegistryService } from '../../kernel/modules/module-registry.service';
import { BusinessTypeService } from '../business-type/business-type.service';

const VALID_STATUSES = ['active', 'suspended', 'archived'] as const;
type TenantStatus = (typeof VALID_STATUSES)[number];

export class CreateTenantDto {
  name: string;
  ownerEmail: string;
  ownerPassword: string;
  currency?: string;
  timezone?: string;
  billingStatus?: 'trial' | 'active';
  plan?: string;
  businessType?: string;
  vertical?: string;
}

export class UpdateTenantDto {
  name?: string;
  currency?: string;
  timezone?: string;
  status?: string;
}

@Injectable()
export class AdminTenantsService {
  private readonly logger = new Logger(AdminTenantsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly supabaseAdmin: SupabaseAdminService,
    private readonly moduleRegistry: ModuleRegistryService,
    private readonly businessTypeService: BusinessTypeService,
  ) {}

  async createTenant(dto: CreateTenantDto) {
    // Validate inputs
    if (!dto.name || dto.name.trim() === '') {
      throw new BadRequestException('name is required');
    }
    if (!dto.ownerPassword || dto.ownerPassword.length < 8) {
      throw new BadRequestException('ownerPassword must be at least 8 characters');
    }

    const vertical = dto.vertical ?? 'retail';
    const businessType = dto.businessType ?? 'generaliste';

    // Validate businessType belongs to the requested vertical
    const btDef = await this.prisma.businessTypeDefinition.findUnique({
      where: { code: businessType },
    });
    if (!btDef || !btDef.isActive || btDef.vertical !== vertical) {
      throw new BadRequestException('Business type invalide pour ce vertical');
    }

    // Step 1 — Create Supabase Auth user
    let userId: string;
    try {
      userId = await this.supabaseAdmin.createUser(dto.ownerEmail, dto.ownerPassword);
    } catch (err: any) {
      throw new UnprocessableEntityException(
        err?.message ?? 'Failed to create Supabase Auth user',
      );
    }

    // Step 2 — Create tenant in Prisma (with compensation on failure)
    let tenant: { id: string; name: string; currency: string; timezone: string; status: string; businessType: string; vertical: string };
    try {
      const billingStatus = dto.billingStatus ?? 'trial';
      const plan = dto.plan ?? 'standard';
      const trialEndsAt = billingStatus === 'trial'
        ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        : null;
      tenant = await this.prisma.tenant.create({
        data: {
          name: dto.name.trim(),
          currency: dto.currency ?? 'XOF',
          timezone: dto.timezone ?? 'Africa/Ouagadougou',
          status: 'active',
          plan,
          billingStatus,
          trialEndsAt,
          businessType,
          vertical,
        },
      });
    } catch (err) {
      // Compensate: remove Supabase user
      await this.supabaseAdmin.deleteUser(userId).catch(() => {});
      throw new InternalServerErrorException('Failed to create tenant');
    }

    // Step 3 — Link owner role
    try {
      const ownerRole = await this.prisma.role.findUnique({
        where: { name_vertical: { name: 'owner', vertical: 'retail' } },
      });

      if (!ownerRole) {
        throw new Error('Owner role not seeded');
      }

      await this.prisma.organizationMember.create({
        data: {
          organizationId: tenant.id,
          userId,
          roleId: ownerRole.id,
        },
      });

      // Step 4 — Activate default modules
      // Trial → always activate STANDARD modules regardless of chosen plan
      // Enterprise → Carlos activates manually from the panel
      const planForModules = (dto.billingStatus ?? 'trial') === 'trial'
        ? 'standard'
        : (dto.plan ?? 'standard');
      if (planForModules !== 'enterprise') {
        await this.moduleRegistry.activateDefaultModulesForTenant(tenant.id, planForModules);
      }
    } catch (err) {
      // Compensate: delete tenant and Supabase user
      await this.prisma.tenant
        .update({ where: { id: tenant.id }, data: { status: 'archived' } })
        .catch(() => {});
      await this.supabaseAdmin.deleteUser(userId).catch(() => {});
      throw new InternalServerErrorException(
        'Failed to complete tenant setup — rolled back',
      );
    }

    // Step 5 — Seed suggested categories for the business type (non-blocking)
    this.businessTypeService
      .seedCategories(tenant.id, businessType)
      .catch((err) =>
        this.logger.warn(`seedCategories failed for tenant ${tenant.id}: ${err.message}`),
      );

    return {
      tenantId: tenant.id,
      userId,
      name: tenant.name,
      currency: tenant.currency,
      timezone: tenant.timezone,
      status: tenant.status,
      businessType: tenant.businessType,
      modulesActivated: ['catalog', 'inventory', 'transactions', 'retail'],
    };
  }

  async listTenants() {
    const tenants = await this.prisma.tenant.findMany({
      where: { plan: { not: 'free' } }, // exclut les tenants internes (Scalario Platform)
      include: {
        _count: { select: { members: true } },
        tenantModules: {
          include: { module: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return tenants.map((t) => ({
      id: t.id,
      name: t.name,
      status: t.status,
      currency: t.currency,
      timezone: t.timezone,
      createdAt: t.createdAt,
      membersCount: t._count.members,
      activeModules: t.tenantModules
        .filter((tm) => tm.status === 'active')
        .map((tm) => tm.module.code),
      plan: t.plan,
      billingStatus: t.billingStatus,
      trialEndsAt: t.trialEndsAt,
      paidUntil: (t as any).paidUntil ?? null,
      businessType: t.businessType,
      vertical: t.vertical,
    }));
  }

  async updateTenant(id: string, dto: UpdateTenantDto) {
    if (dto.status !== undefined) {
      if (!VALID_STATUSES.includes(dto.status as TenantStatus)) {
        throw new BadRequestException(
          `status must be one of: ${VALID_STATUSES.join(', ')}`,
        );
      }
    }

    // Build update data from only provided fields
    const data: Record<string, unknown> = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.currency !== undefined) data.currency = dto.currency;
    if (dto.timezone !== undefined) data.timezone = dto.timezone;
    if (dto.status !== undefined) data.status = dto.status;

    const tenant = await this.prisma.tenant.update({
      where: { id },
      data,
    });

    return {
      id: tenant.id,
      name: tenant.name,
      status: tenant.status,
      currency: tenant.currency,
      timezone: tenant.timezone,
      createdAt: tenant.createdAt,
    };
  }
}
