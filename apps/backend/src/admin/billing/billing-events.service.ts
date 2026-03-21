import { ConflictException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BillingGuard } from '../../kernel/billing/billing.guard';
import { ModuleRegistryService } from '../../kernel/modules/module-registry.service';
import { CreateBillingEventDto } from './dto/create-billing-event.dto';
import { UpdateBillingDto } from './dto/update-billing.dto';
import { ActivateTenantDto } from './dto/activate-tenant.dto';

@Injectable()
export class BillingEventsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly moduleRegistry: ModuleRegistryService,
    @Optional() private readonly billingGuard: BillingGuard,
  ) {}

  async recordEvent(tenantId: string, dto: CreateBillingEventDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const paidAt = dto.paidAt ? new Date(dto.paidAt) : null;
    const monthsPaid = (dto as any).monthsPaid as number | undefined;
    const tenantAny = tenant as any;

    const event = await (this.prisma as any).billingEvent.create({
      data: {
        tenantId,
        type: dto.type,
        amount: dto.amount,
        description: dto.description ?? null,
        paidAt,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        paymentMethod: dto.paymentMethod ?? null,
        paymentRef: dto.paymentRef ?? null,
        status: paidAt ? 'paid' : 'pending',
        monthsPaid: monthsPaid ?? null,
      },
    });

    // Side-effect: subscription paid → activate or renew tenant
    if (dto.type === 'subscription' && paidAt) {
      const months = monthsPaid ?? 1;
      const currentPaidUntil: Date | null = tenantAny.paidUntil ?? null;
      const base = currentPaidUntil && currentPaidUntil > paidAt ? currentPaidUntil : paidAt;
      const newPaidUntil = new Date(base.getTime() + months * 30 * 24 * 60 * 60 * 1000);

      await (this.prisma as any).tenant.update({
        where: { id: tenantId },
        data: {
          billingStatus: 'active',
          billingStartDate: tenant.billingStartDate ?? paidAt,
          paidUntil: newPaidUntil,
        },
      });
      this.billingGuard?.invalidate(tenantId);
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

    const t = tenant as any;
    return {
      tenant: {
        plan: tenant.plan,
        billingStatus: tenant.billingStatus,
        trialEndsAt: tenant.trialEndsAt,
        billingStartDate: tenant.billingStartDate,
        paidUntil: t.paidUntil ?? null,
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
      paidUntil: (tenant as any).paidUntil ?? null,
      events,
    };
  }

  async createUpgradeRequest(tenantId: string, message?: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

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
      this.billingGuard?.invalidate(tenantId);
    }

    return updated;
  }

  // ── New endpoints ────────────────────────────────────────────────────────────

  async activateTenant(tenantId: string, dto: ActivateTenantDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const plan = await this.prisma.planDefinition.findUnique({ where: { code: dto.planCode } });
    if (!plan) throw new NotFoundException(`Plan "${dto.planCode}" introuvable`);

    const result = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.tenant.update({
        where: { id: tenantId },
        data: {
          billingStatus: 'active',
          plan: dto.planCode,
          maxUsers: plan.maxUsers,
          installationFee: dto.installationFee != null ? String(dto.installationFee) : tenant.installationFee,
          trainingFee: dto.trainingFee != null ? String(dto.trainingFee) : tenant.trainingFee,
          billingStartDate: dto.billingStartDate ? new Date(dto.billingStartDate) : new Date(),
        },
      });

      // Activate plan modules
      const includedModules = plan.includedModules as string[];
      for (const code of includedModules) {
        await this.moduleRegistry.setModuleStatus(tenantId, code, 'active');
      }

      // Create activation event
      await (tx as any).billingEvent.create({
        data: {
          tenantId,
          type: 'activation',
          amount: 0,
          description: `Activation plan ${dto.planCode}`,
          status: 'paid',
          paidAt: new Date(),
        },
      });

      // Create installation fee event if applicable
      if (dto.installationFee && dto.installationFee > 0) {
        await (tx as any).billingEvent.create({
          data: {
            tenantId,
            type: 'installation',
            amount: String(dto.installationFee),
            description: "Frais d'installation",
            status: 'pending',
          },
        });
      }

      // Create training fee event if applicable
      if (dto.trainingFee && dto.trainingFee > 0) {
        await (tx as any).billingEvent.create({
          data: {
            tenantId,
            type: 'training',
            amount: String(dto.trainingFee),
            description: 'Frais de formation',
            status: 'pending',
          },
        });
      }

      return updated;
    });

    this.billingGuard?.invalidate(tenantId);

    return { id: result.id, billingStatus: result.billingStatus, plan: result.plan };
  }

  async listAllEvents(filters: {
    tenantId?: string;
    type?: string;
    status?: string;
    from?: string;
    to?: string;
  }) {
    const where: Record<string, unknown> = {};
    if (filters.tenantId) where.tenantId = filters.tenantId;
    if (filters.type) where.type = filters.type;
    if (filters.status) where.status = filters.status;
    if (filters.from || filters.to) {
      const createdAt: Record<string, Date> = {};
      if (filters.from) createdAt.gte = new Date(filters.from);
      if (filters.to) createdAt.lte = new Date(filters.to);
      where.createdAt = createdAt;
    }

    return (this.prisma as any).billingEvent.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: { tenant: { select: { id: true, name: true } } },
      take: 200,
    });
  }

  async updateEventStatus(eventId: string, status: string) {
    const event = await (this.prisma as any).billingEvent.findUnique({ where: { id: eventId } });
    if (!event) throw new NotFoundException('Événement introuvable');

    return (this.prisma as any).billingEvent.update({
      where: { id: eventId },
      data: {
        status,
        paidAt: status === 'paid' ? new Date() : event.paidAt,
      },
    });
  }

  async getBillingSummary() {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    const monthlyRevenueResult = await (this.prisma as any).billingEvent.aggregate({
      where: {
        type: { in: ['subscription', 'payment', 'activation'] },
        status: 'paid',
        paidAt: { gte: startOfMonth, lte: endOfMonth },
        amount: { gt: 0 },
      },
      _sum: { amount: true },
    });

    const [activeClients, trialClients, overdueClients] = await Promise.all([
      this.prisma.tenant.count({ where: { billingStatus: 'active' } }),
      this.prisma.tenant.count({ where: { billingStatus: 'trial' } }),
      this.prisma.tenant.count({ where: { billingStatus: 'overdue' } }),
    ]);

    const activeTenants = await this.prisma.tenant.findMany({
      where: { billingStatus: 'active' },
      select: { plan: true },
    });

    const planPrices = await this.prisma.planDefinition.findMany({
      select: { code: true, monthlyPrice: true },
    });
    const priceMap = new Map(planPrices.map((p) => [p.code, Number(p.monthlyPrice)]));

    const mrr = activeTenants.reduce((sum, t) => sum + (priceMap.get(t.plan) ?? 0), 0);

    const pendingInvoicesCount = await (this.prisma as any).billingEvent.count({
      where: { type: 'invoice', status: 'pending' },
    });

    const totalUnpaidResult = await (this.prisma as any).billingEvent.aggregate({
      where: { status: 'pending', type: { not: 'invoice' } },
      _sum: { amount: true },
    });

    return {
      monthlyRevenue: Number(monthlyRevenueResult._sum.amount ?? 0),
      activeClients,
      trialClients,
      overdueClients,
      mrr,
      pendingInvoicesCount,
      totalUnpaid: Number(totalUnpaidResult._sum.amount ?? 0),
    };
  }

  async generateInvoiceData(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const plan = await this.prisma.planDefinition.findUnique({ where: { code: tenant.plan } });

    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();

    // Global sequence for invoices (all tenants combined)
    const invoiceCount = await (this.prisma as any).billingEvent.count({
      where: { invoiceNumber: { not: null } },
    });

    const pendingLines = await (this.prisma as any).billingEvent.findMany({
      where: {
        tenantId,
        type: { in: ['installation', 'training'] },
        status: 'pending',
      },
    });

    const monthlyAmount = plan ? Number(plan.monthlyPrice) : 0;
    const invoiceLines: Array<{ description: string; amount: number }> = [
      {
        description: `Abonnement ${tenant.plan} — ${String(month).padStart(2, '0')}/${year}`,
        amount: monthlyAmount,
      },
      ...pendingLines.map((e: any) => ({
        description: e.description ?? e.type,
        amount: Number(e.amount),
      })),
    ];

    const total = invoiceLines.reduce((sum, l) => sum + l.amount, 0);
    const invoiceNumber = `FAC-${year}-${String(month).padStart(2, '0')}-${String(invoiceCount + 1).padStart(3, '0')}`;

    const event = await (this.prisma as any).billingEvent.create({
      data: {
        tenantId,
        type: 'invoice',
        amount: String(total),
        description: `Facture ${invoiceNumber}`,
        status: 'pending',
        invoiceNumber,
      },
    });

    return {
      eventId: event.id,
      invoiceNumber,
      date: now.toISOString(),
      month,
      year,
      tenant: { name: tenant.name },
      plan: {
        code: tenant.plan,
        name: plan?.name ?? tenant.plan,
        monthlyPrice: monthlyAmount,
      },
      lines: invoiceLines,
      total,
    };
  }

  async generateReceiptData(eventId: string, paymentDetails: {
    paymentMethod: string;
    paymentRef?: string;
    paymentDate?: string;
  }) {
    const event = await (this.prisma as any).billingEvent.findUnique({
      where: { id: eventId },
      include: { tenant: { select: { id: true, name: true } } },
    });
    if (!event) throw new NotFoundException('Événement introuvable');

    const now = new Date(paymentDetails.paymentDate ?? new Date());
    const month = now.getMonth() + 1;
    const year = now.getFullYear();

    // Global sequence for receipts
    const receiptCount = await (this.prisma as any).billingEvent.count({
      where: { receiptNumber: { not: null } },
    });
    const receiptNumber = `REC-${year}-${String(month).padStart(2, '0')}-${String(receiptCount + 1).padStart(3, '0')}`;

    const updated = await (this.prisma as any).billingEvent.update({
      where: { id: eventId },
      data: {
        status: 'paid',
        paidAt: now,
        paymentMethod: paymentDetails.paymentMethod,
        paymentRef: paymentDetails.paymentRef ?? null,
        receiptNumber,
      },
    });

    return {
      receiptNumber,
      invoiceNumber: updated.invoiceNumber ?? null,
      date: now.toISOString(),
      tenant: { name: event.tenant.name },
      amount: Number(event.amount),
      description: event.description,
      paymentMethod: paymentDetails.paymentMethod,
      paymentRef: paymentDetails.paymentRef ?? null,
    };
  }
}
