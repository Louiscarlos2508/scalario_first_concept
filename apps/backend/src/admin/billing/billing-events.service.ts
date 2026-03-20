import { ConflictException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BillingGuard } from '../../kernel/billing/billing.guard';
import { CreateBillingEventDto } from './dto/create-billing-event.dto';
import { UpdateBillingDto } from './dto/update-billing.dto';

@Injectable()
export class BillingEventsService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly billingGuard: BillingGuard,
  ) {}

  async recordEvent(tenantId: string, dto: CreateBillingEventDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const event = await (this.prisma as any).billingEvent.create({
      data: {
        tenantId,
        type: dto.type,
        amount: dto.amount,
        description: dto.description ?? null,
        paidAt: dto.paidAt ? new Date(dto.paidAt) : null,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        paymentMethod: dto.paymentMethod ?? null,
        paymentRef: dto.paymentRef ?? null,
        status: dto.paidAt ? 'paid' : 'pending',
      },
    });

    // Side-effect: subscription paid → activate tenant
    if (dto.type === 'subscription' && dto.paidAt) {
      await this.prisma.tenant.update({
        where: { id: tenantId },
        data: {
          billingStatus: 'active',
          billingStartDate: tenant.billingStartDate ?? new Date(dto.paidAt),
        },
      });
    }

    return event;
  }

  async getHistory(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const events = await (this.prisma as any).billingEvent.findMany({
      where: { tenantId },
      orderBy: { createdAt: 'desc' },
    });

    return {
      tenant: {
        plan: tenant.plan,
        billingStatus: tenant.billingStatus,
        trialEndsAt: tenant.trialEndsAt,
        billingStartDate: tenant.billingStartDate,
        installationFee: tenant.installationFee,
        installationPaid: tenant.installationPaid,
        trainingFee: tenant.trainingFee,
        trainingPaid: tenant.trainingPaid,
        notes: tenant.notes,
      },
      events,
    };
  }

  async getOwnerBilling(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const plan = await this.prisma.planDefinition.findUnique({ where: { code: tenant.plan } });

    const events = await (this.prisma as any).billingEvent.findMany({
      where: { tenantId },
      orderBy: { createdAt: 'desc' },
    });

    return {
      plan: plan ?? { code: tenant.plan, name: tenant.plan, monthlyPrice: 0, maxUsers: tenant.maxUsers, includedModules: [] },
      billingStatus: tenant.billingStatus,
      trialEndsAt: tenant.trialEndsAt,
      billingStartDate: tenant.billingStartDate,
      events,
    };
  }

  async createUpgradeRequest(tenantId: string, message?: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    // In Phase 2a: record as a billing event of type upgrade_request
    const existing = await (this.prisma as any).billingEvent.findFirst({
      where: {
        tenantId,
        type: 'upgrade_request',
        status: 'pending',
        createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
      },
    });
    if (existing) {
      throw new ConflictException('Une demande a déjà été envoyée dans les dernières 24h');
    }

    await (this.prisma as any).billingEvent.create({
      data: {
        tenantId,
        type: 'upgrade_request',
        amount: 0,
        description: message ?? 'Demande de changement de plan',
        status: 'pending',
      },
    });

    return { message: 'Demande envoyée' };
  }

  async updateBilling(tenantId: string, dto: UpdateBillingDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const data: Record<string, unknown> = {};
    if (dto.installationFee !== undefined) data.installationFee = dto.installationFee;
    if (dto.installationPaid !== undefined) data.installationPaid = dto.installationPaid;
    if (dto.trainingFee !== undefined) data.trainingFee = dto.trainingFee;
    if (dto.trainingPaid !== undefined) data.trainingPaid = dto.trainingPaid;
    if (dto.notes !== undefined) data.notes = dto.notes;
    if (dto.billingStatus !== undefined) data.billingStatus = dto.billingStatus;

    const updated = await this.prisma.tenant.update({ where: { id: tenantId }, data });

    // Auto-create payment event when manually activating
    if (dto.billingStatus === 'active' && tenant.billingStatus !== 'active') {
      await (this.prisma as any).billingEvent.create({
        data: {
          tenantId,
          type: 'payment',
          amount: 0,
          description: 'Activation manuelle par superadmin',
          status: 'paid',
          paidAt: new Date(),
        },
      });
      // Invalidate billing guard cache so next request passes immediately
      this.billingGuard?.invalidate(tenantId);
    }

    return updated;
  }
}
