import { ConflictException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BillingGuard } from '../../kernel/billing/billing.guard';
import { ModuleRegistryService } from '../../kernel/modules/module-registry.service';
import { CreateBillingEventDto } from './dto/create-billing-event.dto';
import { UpdateBillingDto } from './dto/update-billing.dto';
import { ActivateTenantDto } from './dto/activate-tenant.dto';
import { RecordPaymentDto } from './dto/record-payment.dto';
import { MarkFeePaidDto } from './dto/mark-fee-paid.dto';

function calcPaidUntil(
  billingStatus: string,
  trialEndsAt: Date | null,
  currentPaidUntil: Date | null,
  monthsPaid: number,
): Date {
  const now = new Date();
  let base: Date;
  if (billingStatus === 'trial' && trialEndsAt && trialEndsAt > now) {
    // Start the day after trial ends
    const next = new Date(trialEndsAt);
    next.setDate(next.getDate() + 1);
    base = next;
  } else if (currentPaidUntil && currentPaidUntil > now) {
    base = currentPaidUntil;
  } else {
    base = now;
  }
  return new Date(base.getTime() + monthsPaid * 30 * 24 * 60 * 60 * 1000);
}

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
      const newPaidUntil = calcPaidUntil(tenant.billingStatus, tenant.trialEndsAt, tenantAny.paidUntil ?? null, months);

      await this.prisma.tenant.update({
        where: { id: tenantId },
        data: {
          billingStatus: 'active',
          trialEndsAt: null,
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

    const startDate = dto.billingStartDate ? new Date(dto.billingStartDate) : new Date();
    const months = dto.months ?? 1;
    const paidUntil = calcPaidUntil('trial', tenant.trialEndsAt, null, months);

    const result = await this.prisma.$transaction(async (tx) => {
      const updated = await (tx as any).tenant.update({
        where: { id: tenantId },
        data: {
          billingStatus: 'active',
          trialEndsAt: null,
          plan: dto.planCode,
          maxUsers: plan.maxUsers,
          installationFee: dto.installationFee != null ? String(dto.installationFee) : tenant.installationFee,
          trainingFee: dto.trainingFee != null ? String(dto.trainingFee) : tenant.trainingFee,
          billingStartDate: startDate,
          paidUntil,
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
    const startOfYear = new Date(now.getFullYear(), 0, 1);

    const [monthlyRevenueResult, annualRevenueResult] = await Promise.all([
      (this.prisma as any).billingEvent.aggregate({
        where: {
          type: { in: ['subscription', 'payment', 'activation', 'installation', 'training'] },
          status: 'paid',
          paidAt: { gte: startOfMonth, lte: endOfMonth },
          amount: { gt: 0 },
        },
        _sum: { amount: true },
      }),
      (this.prisma as any).billingEvent.aggregate({
        where: {
          type: { in: ['subscription', 'payment', 'activation', 'installation', 'training'] },
          status: 'paid',
          paidAt: { gte: startOfYear },
          amount: { gt: 0 },
        },
        _sum: { amount: true },
      }),
    ]);

    const [activeClients, trialClients, overdueClients] = await Promise.all([
      this.prisma.tenant.count({ where: { billingStatus: 'active', plan: { not: 'free' } } }),
      this.prisma.tenant.count({ where: { billingStatus: 'trial', plan: { not: 'free' } } }),
      this.prisma.tenant.count({ where: { billingStatus: 'overdue', plan: { not: 'free' } } }),
    ]);

    const activeTenants = await this.prisma.tenant.findMany({
      where: { billingStatus: 'active', plan: { not: 'free' } },
      select: { plan: true },
    });

    const [planPrices, oneTimePaidThisMonth] = await Promise.all([
      this.prisma.planDefinition.findMany({ select: { code: true, monthlyPrice: true } }),
      (this.prisma as any).billingEvent.aggregate({
        where: {
          type: { in: ['installation', 'training'] },
          status: 'paid',
          paidAt: { gte: startOfMonth, lte: endOfMonth },
          amount: { gt: 0 },
        },
        _sum: { amount: true },
      }),
    ]);
    const priceMap = new Map(planPrices.map((p) => [p.code, Number(p.monthlyPrice)]));

    const mrrSubscriptions = activeTenants.reduce((sum, t) => sum + (priceMap.get(t.plan) ?? 0), 0);
    const mrr = mrrSubscriptions + Number(oneTimePaidThisMonth._sum.amount ?? 0);

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
      arr: Number(annualRevenueResult._sum.amount ?? 0),
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

  async recordPayment(tenantId: string, dto: RecordPaymentDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const tenantAny = tenant as any;
    const paymentDate = dto.paymentDate ? new Date(dto.paymentDate) : new Date();

    // Calculate new paidUntil period
    const newPaidUntil = calcPaidUntil(
      tenant.billingStatus,
      tenant.trialEndsAt,
      tenantAny.paidUntil ?? null,
      dto.months,
    );

    // Generate receipt number
    const month = paymentDate.getMonth() + 1;
    const year = paymentDate.getFullYear();
    const receiptCount = await (this.prisma as any).billingEvent.count({
      where: { receiptNumber: { not: null } },
    });
    const receiptNumber = `REC-${year}-${String(month).padStart(2, '0')}-${String(receiptCount + 1).padStart(3, '0')}`;

    await this.prisma.$transaction(async (tx) => {
      // Create subscription event
      await (tx as any).billingEvent.create({
        data: {
          tenantId,
          type: 'subscription',
          amount: dto.amount,
          description: dto.description ?? `Abonnement — ${dto.months} mois`,
          status: 'paid',
          paidAt: paymentDate,
          paymentMethod: dto.paymentMethod,
          paymentRef: dto.paymentRef ?? null,
          monthsPaid: dto.months,
          receiptNumber,
        },
      });

      // Mark existing pending installation event as paid
      if (dto.includeInstallation) {
        const existingInstall = await (tx as any).billingEvent.findFirst({
          where: { tenantId, type: 'installation', status: 'pending' },
        });
        if (existingInstall) {
          await (tx as any).billingEvent.update({
            where: { id: existingInstall.id },
            data: { status: 'paid', paidAt: paymentDate, paymentMethod: dto.paymentMethod },
          });
        }
      }

      // Mark existing pending training event as paid
      if (dto.includeTraining) {
        const existingTraining = await (tx as any).billingEvent.findFirst({
          where: { tenantId, type: 'training', status: 'pending' },
        });
        if (existingTraining) {
          await (tx as any).billingEvent.update({
            where: { id: existingTraining.id },
            data: { status: 'paid', paidAt: paymentDate, paymentMethod: dto.paymentMethod },
          });
        }
      }

      // Update tenant
      await this.prisma.tenant.update({
        where: { id: tenantId },
        data: {
          billingStatus: 'active',
          trialEndsAt: null,
          paidUntil: newPaidUntil,
          billingStartDate: tenant.billingStartDate ?? paymentDate,
          ...(dto.includeInstallation ? { installationPaid: true } : {}),
          ...(dto.includeTraining ? { trainingPaid: true } : {}),
        },
      });
    });

    this.billingGuard?.invalidate(tenantId);

    return {
      receiptNumber,
      date: paymentDate.toISOString(),
      tenant: { name: tenant.name },
      amount: Number(dto.amount),
      description: dto.description ?? `Abonnement — ${dto.months} mois`,
      paymentMethod: dto.paymentMethod,
      paymentRef: dto.paymentRef ?? null,
    };
  }

  async generateReceiptData(eventId: string, paymentDetails: {
    paymentMethod: string;
    paymentRef?: string;
    paymentDate?: string;
  }) {
    const event = await (this.prisma as any).billingEvent.findUnique({
      where: { id: eventId },
      include: { tenant: true },
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

    // Side-effect: subscription event marked paid → activate / renew tenant
    if (event.type === 'subscription') {
      const months = (event.monthsPaid as number | null) ?? 1;
      const newPaidUntil = calcPaidUntil(
        event.tenant.billingStatus,
        event.tenant.trialEndsAt,
        (event.tenant as any).paidUntil ?? null,
        months,
      );

      await this.prisma.tenant.update({
        where: { id: event.tenantId },
        data: {
          billingStatus: 'active',
          trialEndsAt: null,
          billingStartDate: event.tenant.billingStartDate ?? now,
          paidUntil: newPaidUntil,
        },
      });
      this.billingGuard?.invalidate(event.tenantId);
    }

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

  async markFeePaid(tenantId: string, dto: MarkFeePaidDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException(`Tenant introuvable`);

    const tenantAny = tenant as any;
    const paidFlag = dto.feeType === 'installation' ? 'installationPaid' : 'trainingPaid';
    if (tenantAny[paidFlag]) throw new ConflictException(`${dto.feeType} déjà marqué payé`);

    const feeAmount = dto.feeType === 'installation' ? tenantAny.installationFee : tenantAny.trainingFee;
    const paymentDate = dto.paymentDate ? new Date(dto.paymentDate) : new Date();
    const month = paymentDate.getMonth() + 1;
    const year = paymentDate.getFullYear();

    const receiptCount = await (this.prisma as any).billingEvent.count({
      where: { receiptNumber: { not: null } },
    });
    const receiptNumber = `REC-${year}-${String(month).padStart(2, '0')}-${String(receiptCount + 1).padStart(3, '0')}`;

    const description = dto.feeType === 'installation' ? "Frais d'installation" : 'Frais de formation';

    // Find existing pending event or create one
    let feeEvent = await (this.prisma as any).billingEvent.findFirst({
      where: { tenantId, type: dto.feeType, status: 'pending' },
    });

    if (feeEvent) {
      feeEvent = await (this.prisma as any).billingEvent.update({
        where: { id: feeEvent.id },
        data: {
          status: 'paid',
          paidAt: paymentDate,
          paymentMethod: dto.paymentMethod,
          paymentRef: dto.paymentRef ?? null,
          receiptNumber,
        },
      });
    } else {
      feeEvent = await (this.prisma as any).billingEvent.create({
        data: {
          tenantId,
          type: dto.feeType,
          amount: feeAmount ?? '0',
          description,
          status: 'paid',
          paidAt: paymentDate,
          paymentMethod: dto.paymentMethod,
          paymentRef: dto.paymentRef ?? null,
          receiptNumber,
        },
      });
    }

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { [paidFlag]: true },
    });

    return {
      receiptNumber,
      date: paymentDate.toISOString(),
      tenant: { name: tenant.name },
      amount: Number(feeEvent.amount),
      description: feeEvent.description,
      paymentMethod: dto.paymentMethod,
      paymentRef: dto.paymentRef ?? null,
    };
  }
}
