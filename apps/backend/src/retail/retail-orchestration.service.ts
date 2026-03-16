import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { EventBusService } from '../kernel/events/event-bus.service';

@Injectable()
export class RetailOrchestrationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventBus: EventBusService,
  ) {}

  /**
   * AC2 — Atomic sale: Transaction + RetailSale in one prisma.$transaction.
   * After commit: emits transaction.created (stock decrement handled by InventoryService @OnEvent).
   * Credit payment: emits credit.applied event.
   */
  async createSale(data: {
    transactionId?: string;
    totalAmount: number;
    items?: any[];
    paymentMethod?: string;
    paymentSplits?: any;
    customerId?: string | null;
    sessionId?: string | null;
    receiptNumber?: string;
    cashierId?: string;
    tenantId: string;
    userId?: string | null;
  }) {
    const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const toUuid = (v?: string | null) => (v && UUID_RE.test(v) ? v : null);

    const txId = data.transactionId ?? randomUUID();
    const receiptNumber = data.receiptNumber ?? `RCP-${Date.now()}`;
    const cashierId = toUuid(data.cashierId) ?? toUuid(data.userId);

    // Validate sessionId: only pass to retailSale if the session exists in pos_sessions
    // (device may send a local UUID that was never pushed to the backend)
    const sessionIdUuid = toUuid(data.sessionId);
    const retailSessionId = sessionIdUuid
      ? (await this.prisma.posSession.findUnique({ where: { id: sessionIdUuid } }))?.id ?? null
      : null;

    // Atomic: Transaction + RetailSale in one DB transaction
    const result = await this.prisma.$transaction(async (tx) => {
      const transaction = await tx.transaction.create({
        data: {
          id: txId,
          totalAmount: data.totalAmount,
          itemsJson: data.items ?? [],
          paymentMethod: data.paymentMethod ?? null,
          paymentSplits: data.paymentSplits ?? null,
          customerId: toUuid(data.customerId),
          sessionId: sessionIdUuid,
          tenantId: data.tenantId,
        },
      });

      const retailSale = await tx.retailSale.create({
        data: {
          transactionId: transaction.id,
          sessionId: retailSessionId,
          receiptNumber,
          cashierId,
        },
      });

      return { transaction, retailSale };
    });

    // Post-commit: stock update via event (InventoryService @OnEvent('transaction.created'))
    this.eventBus.publish('transaction.created', {
      transactionId: result.transaction.id,
      tenantId: data.tenantId,
    });

    // Credit balance update via event
    if (
      (data.paymentMethod === 'CREDIT' || data.paymentMethod === 'SPLIT') &&
      data.customerId
    ) {
      this.eventBus.publish('credit.applied', {
        customerId: data.customerId,
        amount: data.totalAmount,
        transactionId: result.transaction.id,
        tenantId: data.tenantId,
      });
    }

    return result;
  }
}
