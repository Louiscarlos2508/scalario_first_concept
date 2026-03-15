import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventBusService } from '../kernel/events/event-bus.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PosSessionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventBus: EventBusService,
  ) {}

  // AC2 — open session; reject if user already has OPEN session
  async openSession(data: { userId: string; tenantId: string; openingBalance: number }) {
    const existingSession = await this.prisma.posSession.findFirst({
      where: { userId: data.userId, tenantId: data.tenantId, status: 'OPEN' },
    });

    if (existingSession) {
      throw new BadRequestException('An active session already exists for this user.');
    }

    return this.prisma.posSession.create({
      data: {
        userId: data.userId,
        tenantId: data.tenantId,
        openingBalance: new Prisma.Decimal(data.openingBalance),
        status: 'OPEN',
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
        status: 'CLOSED',
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
    const transactions = await this.prisma.transaction.findMany({
      where: { sessionId },
    });

    const totalsByMethod: Record<string, number> = {};
    let totalSales = 0;

    for (const tx of transactions) {
      const amount = Number(tx.totalAmount);
      const method = tx.paymentMethod || 'UNKNOWN';
      totalsByMethod[method] = (totalsByMethod[method] || 0) + amount;
      totalSales += amount;
    }

    const openingBalance = Number(session.openingBalance);

    return {
      session,
      totalsByMethod,
      totalSales,
      theoreticalCash: openingBalance + (totalsByMethod['CASH'] || 0),
      openingBalance,
      closingBalance: session.closingBalance !== null ? Number(session.closingBalance) : null,
      theoreticalBalance: session.theoreticalBalance !== null ? Number(session.theoreticalBalance) : null,
      variance: session.variance !== null ? Number(session.variance) : null,
      varianceExplanation: session.varianceExplanation ?? null,
    };
  }

  // AC5 — session reports: all CLOSED sessions for tenant
  async getSessionReports(tenantId: string) {
    return this.prisma.posSession.findMany({
      where: { tenantId, status: 'CLOSED' },
      orderBy: { closedAt: 'desc' },
    });
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
      },
    });
  }

  private isValidUuid(id: string): boolean {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return uuidRegex.test(id);
  }
}
