import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventBusService } from '../kernel/events/event-bus.service';
import { Prisma } from '@prisma/client';
import { ReturnsService } from '../shared/returns/returns.service';

@Injectable()
export class PosSessionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventBus: EventBusService,
    private readonly returnsService: ReturnsService,
  ) {}

  // AC2 — open session; reject if user already has OPEN session
  async openSession(data: { userId: string; tenantId: string; openingBalance: number; deviceId?: string; uuid?: string }) {
    // Idempotent via client UUID — return the existing record if already pushed.
    if (data.uuid && this.isValidUuid(data.uuid)) {
      const byUuid = await this.prisma.posSession.findUnique({ where: { id: data.uuid } });
      if (byUuid) return byUuid;
    }

    // One active session per user at a time (regardless of device).
    const existingSession = await this.prisma.posSession.findFirst({
      where: { userId: data.userId, tenantId: data.tenantId, status: 'OPEN' },
    });

    if (existingSession) {
      throw new BadRequestException('An active session already exists for this user.');
    }

    return this.prisma.posSession.create({
      data: {
        ...(data.uuid && this.isValidUuid(data.uuid) ? { id: data.uuid } : {}),
        userId: data.userId,
        tenantId: data.tenantId,
        openingBalance: new Prisma.Decimal(data.openingBalance),
        status: 'OPEN',
        deviceId: data.deviceId ?? null,
      },
    });
  }

  // AC3 — close session with variance logic + mandatory explanation when variance != 0
  async closeSession(
    sessionId: string,
    closingBalance: number,
    varianceExplanation?: string,
  ) {
    const session = await this.prisma.posSession.findUnique({
      where: { id: sessionId },
    });

    if (!session || session.status !== 'OPEN') {
      throw new BadRequestException('Session not found or already closed.');
    }

    const summary = await this.getSessionSummary(sessionId);
    const theoreticalBalance = summary.theoreticalCash;
    const variance = closingBalance - theoreticalBalance;

    if (variance !== 0 && (!varianceExplanation || varianceExplanation.trim() === '')) {
      throw new BadRequestException('variance_explanation is required when variance is non-zero');
    }

    const updated = await this.prisma.posSession.update({
      where: { id: sessionId },
      data: {
        closingBalance: new Prisma.Decimal(closingBalance),
        theoreticalBalance: new Prisma.Decimal(theoreticalBalance),
        variance: new Prisma.Decimal(variance),
        varianceExplanation: varianceExplanation ?? null,
        status: 'PENDING_MANAGER',
        closedAt: new Date(),
      },
    });

    this.eventBus.publish('session.closed', {
      sessionId: session.id,
      tenantId: session.tenantId,
      userId: session.userId,
      variance,
      closedAt: updated.closedAt?.toISOString(),
    });

    return updated;
  }

  async getSessionById(id: string) {
    return this.prisma.posSession.findUnique({ where: { id } });
  }

  async getActiveSession(userId: string, tenantId: string) {
    return this.prisma.posSession.findFirst({
      where: { userId, tenantId, status: 'OPEN' },
    });
  }

  // AC4/AC6 — session summary; fixed: uses transaction.findMany (not order.findMany)
  async getSessionSummary(sessionId: string) {
    if (!this.isValidUuid(sessionId)) {
      throw new BadRequestException('Invalid session ID format.');
    }

    const session = await this.prisma.posSession.findUnique({
      where: { id: sessionId },
    });

    if (!session) {
      throw new BadRequestException('Session not found.');
    }

    // AC6 fix: replaced prisma.order.findMany (removed in Story 4.2) with prisma.transaction.findMany
    const [transactions, movements] = await Promise.all([
      this.prisma.transaction.findMany({
        where: { sessionId },
        orderBy: { createdAt: 'asc' },
        select: {
          id: true,
          totalAmount: true,
          paymentMethod: true,
          paymentSplits: true,
          transactionType: true,
          createdAt: true,
          itemsJson: true,
        },
      }),
      this.prisma.cashMovement.findMany({
        where: { sessionId },
        orderBy: { createdAt: 'asc' },
      }),
    ]);

    const totalsByMethod: Record<string, number> = {};
    let totalSales = 0;

    for (const tx of transactions) {
      const amount = Number(tx.totalAmount);
      const method = tx.paymentMethod || 'UNKNOWN';
      totalsByMethod[method] = (totalsByMethod[method] || 0) + amount;
      totalSales += amount;
    }

    const openingBalance = Number(session.openingBalance);

    // Story 27-3 — Returns summary for session window
    const closedAt = session.closedAt ?? new Date();
    const returnsSummary = await this.returnsService.getReturnsSummaryForSession(
      session.tenantId,
      session.openedAt,
      closedAt,
    );
    const returnsAmount = Number(returnsSummary.amount);
    const cashRefundAmount = Number(returnsSummary.cashRefundAmount);

    const grossSalesAmount = totalSales;
    const netSalesAmount = grossSalesAmount - returnsAmount;

    // Cash movements: paid-in increases expected cash, paid-out decreases it
    const movementsIn  = movements.filter(m => m.type === 'IN').reduce((s, m) => s + Number(m.amount), 0);
    const movementsOut = movements.filter(m => m.type === 'OUT').reduce((s, m) => s + Number(m.amount), 0);

    return {
      session,
      totalsByMethod,
      totalSales,
      grossSales: { count: transactions.length, amount: grossSalesAmount },
      returns: { count: returnsSummary.count, amount: returnsAmount },
      netSales: { amount: netSalesAmount },
      theoreticalCash:
        openingBalance +
        (totalsByMethod['CASH'] || 0) -
        cashRefundAmount +
        movementsIn -
        movementsOut,
      openingBalance,
      closingBalance: session.closingBalance !== null ? Number(session.closingBalance) : null,
      theoreticalBalance: session.theoreticalBalance !== null ? Number(session.theoreticalBalance) : null,
      variance: session.variance !== null ? Number(session.variance) : null,
      varianceExplanation: session.varianceExplanation ?? null,
      // Cash movements log (paid-in / paid-out)
      cashMovements: movements.map(m => ({
        ...m,
        amount: Number(m.amount),
      })),
      cashMovementsSummary: { in: movementsIn, out: movementsOut, net: movementsIn - movementsOut },
      // Individual transactions
      transactions: transactions.map(tx => ({
        ...tx,
        totalAmount: Number(tx.totalAmount),
      })),
      // 3-step workflow audit trail
      managerNote: (session as any).managerNote ?? null,
      managerId: (session as any).managerId ?? null,
      managerValidatedAt: (session as any).managerValidatedAt ?? null,
      ownerNote: (session as any).ownerNote ?? null,
      ownerSignedAt: (session as any).ownerSignedAt ?? null,
    };
  }

  // Step 2 — manager validates or rejects the cashier's submission
  async validateSession(
    sessionId: string,
    managerId: string,
    note: string | undefined,
    approved: boolean,
  ) {
    const session = await this.prisma.posSession.findUnique({ where: { id: sessionId } });
    if (!session || session.status !== 'PENDING_MANAGER') {
      throw new BadRequestException('Session not found or not awaiting manager validation.');
    }

    const nextStatus = approved ? 'PENDING_OWNER' : 'REJECTED';
    return this.prisma.posSession.update({
      where: { id: sessionId },
      data: {
        status: nextStatus,
        managerId,
        managerNote: note ?? null,
        managerValidatedAt: new Date(),
      },
    });
  }

  // Step 3 — owner signs or rejects
  async signSession(sessionId: string, note: string | undefined, approved: boolean) {
    const session = await this.prisma.posSession.findUnique({ where: { id: sessionId } });
    if (!session || session.status !== 'PENDING_OWNER') {
      throw new BadRequestException('Session not found or not awaiting owner signature.');
    }

    if (approved) {
      return this.prisma.posSession.update({
        where: { id: sessionId },
        data: {
          status: 'CLOSED',
          ownerNote: note ?? null,
          ownerSignedAt: new Date(),
          // closedAt is set by closeSession() (step 1) and must not be overwritten —
          // it records when the cashier physically closed the drawer.
        },
      });
    } else {
      // Rejected by owner → back to PENDING_MANAGER
      return this.prisma.posSession.update({
        where: { id: sessionId },
        data: { status: 'PENDING_MANAGER', ownerNote: note ?? null },
      });
    }
  }

  // AC5 — session reports: all non-OPEN sessions for tenant, optional date range.
  // Includes sessions at every stage of the validation workflow so the history
  // shows sessions as soon as the cashier closes them, not only after full sign-off.
  // Date filter uses openedAt (always set) — closedAt was historically not written.
  async getSessionReports(tenantId: string, from?: string, to?: string) {
    const where: any = {
      tenantId,
      status: { in: ['PENDING_MANAGER', 'PENDING_OWNER', 'CLOSED'] },
    };
    if (from || to) {
      where.openedAt = {};
      if (from) where.openedAt.gte = new Date(from);
      if (to) where.openedAt.lte = new Date(to + 'T23:59:59.999Z');
    }
    const sessions = await this.prisma.posSession.findMany({
      where,
      orderBy: { openedAt: 'desc' },
    });
    return this.enrichWithSalesStats(sessions);
  }

  async getPendingSessions(tenantId: string) {
    const sessions = await this.prisma.posSession.findMany({
      where: { tenantId, status: { in: ['PENDING_MANAGER', 'PENDING_OWNER'] } },
      orderBy: { closedAt: 'desc' },
    });
    return this.enrichWithSalesStats(sessions);
  }

  // Backoffice — GET /retail/sessions/active: all OPEN sessions for tenant
  async getActiveSessionsByTenant(tenantId: string) {
    const sessions = await this.prisma.posSession.findMany({
      where: { tenantId, status: 'OPEN' },
      orderBy: { openedAt: 'desc' },
    });
    return this.enrichWithSalesStats(sessions);
  }

  // ── Cash movements (paid-in / paid-out) ─────────────────────────────────────

  async addCashMovement(data: {
    sessionId: string;
    tenantId: string;
    userId: string;
    type: 'IN' | 'OUT';
    amount: number;
    reason: string;
  }) {
    const session = await this.prisma.posSession.findUnique({ where: { id: data.sessionId } });
    if (!session || session.status !== 'OPEN') {
      throw new BadRequestException('Cash movements can only be added to an open session.');
    }
    return this.prisma.cashMovement.create({
      data: {
        sessionId: data.sessionId,
        tenantId: data.tenantId,
        userId: data.userId,
        type: data.type,
        amount: new Prisma.Decimal(data.amount),
        reason: data.reason,
      },
    });
  }

  async getCashMovements(sessionId: string) {
    return this.prisma.cashMovement.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'asc' },
    });
  }

  // Enrich a list of sessions with totalRevenue and saleCount.
  // Single groupBy query instead of N individual findMany calls.
  private async enrichWithSalesStats(sessions: any[]) {
    if (sessions.length === 0) return [];
    const ids = sessions.map((s) => s.id);
    const stats = await this.prisma.transaction.groupBy({
      by: ['sessionId'],
      where: { sessionId: { in: ids } },
      _count: { id: true },
      _sum: { totalAmount: true },
    });
    const statsMap = new Map(stats.map((s) => [s.sessionId, s]));
    return sessions.map((session) => ({
      ...session,
      totalRevenue: Number(statsMap.get(session.id)?._sum?.totalAmount ?? 0),
      saleCount: statsMap.get(session.id)?._count?.id ?? 0,
    }));
  }

  async syncSession(data: any) {
    const remoteId = data.remoteId || data.id;

    if (remoteId && this.isValidUuid(remoteId)) {
      return this.prisma.posSession.upsert({
        where: { id: remoteId },
        update: {
          openingBalance: data.openingBalance != null ? new Prisma.Decimal(data.openingBalance) : undefined,
          closingBalance: data.closingBalance != null ? new Prisma.Decimal(data.closingBalance) : undefined,
          status: data.status,
          closedAt: data.closedAt ? new Date(data.closedAt) : null,
          deviceId: data.deviceId ?? undefined,
        },
        create: {
          id: remoteId,
          userId: data.userId,
          tenantId: data.tenantId,
          openingBalance: new Prisma.Decimal(data.openingBalance || 0),
          closingBalance: data.closingBalance != null ? new Prisma.Decimal(data.closingBalance) : null,
          status: data.status || 'OPEN',
          openedAt: data.openedAt ? new Date(data.openedAt) : new Date(),
          closedAt: data.closedAt ? new Date(data.closedAt) : null,
          deviceId: data.deviceId ?? null,
        },
      });
    }

    return this.prisma.posSession.create({
      data: {
        userId: data.userId,
        tenantId: data.tenantId,
        openingBalance: new Prisma.Decimal(data.openingBalance || 0),
        closingBalance: data.closingBalance != null ? new Prisma.Decimal(data.closingBalance) : null,
        status: data.status || 'OPEN',
        openedAt: data.openedAt ? new Date(data.openedAt) : new Date(),
        closedAt: data.closedAt ? new Date(data.closedAt) : null,
        deviceId: data.deviceId ?? null,
      },
    });
  }

  private isValidUuid(id: string): boolean {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return uuidRegex.test(id);
  }
}
