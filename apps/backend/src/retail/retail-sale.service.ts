import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventBusService } from '../kernel/events/event-bus.service';

@Injectable()
export class RetailSaleService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventBus: EventBusService,
  ) {}

  /**
   * Creates a RetailSale record atomically linked to an existing Transaction.
   * The transaction must already exist (created by TransactionsService).
   * For fully atomic Transaction + RetailSale creation, use RetailOrchestrationService
   * which wraps both in a single prisma.$transaction (Story 6.4).
   */
  async createRetailSale(data: {
    transactionId: string;
    sessionId?: string | null;
    receiptNumber: string;
    cashierId: string;
    tenantId: string;
  }) {
    const retailSale = await this.prisma.$transaction(async (tx) => {
      return tx.retailSale.create({
        data: {
          transactionId: data.transactionId,
          sessionId: data.sessionId ?? null,
          receiptNumber: data.receiptNumber,
          cashierId: data.cashierId,
        },
      });
    });

    this.eventBus.publish('retail.sale.created', {
      retailSaleId: retailSale.id,
      transactionId: data.transactionId,
      sessionId: data.sessionId ?? null,
      tenantId: data.tenantId,
    });

    return retailSale;
  }
}
