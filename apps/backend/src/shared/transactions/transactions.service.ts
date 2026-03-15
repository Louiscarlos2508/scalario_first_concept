import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { EventBusService } from '../../kernel/events/event-bus.service';
import { ContactsService } from '../contacts/contacts.service';
import { PaymentsService } from '../payments/payments.service';

@Injectable()
export class TransactionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLog: AuditLogService,
    private readonly eventBus: EventBusService,
    private readonly contactsService: ContactsService,
    private readonly paymentsService: PaymentsService,
  ) {}

  async createTransaction(data: {
    id: string;
    totalAmount: number | string;
    itemsJson?: any;
    paymentMethod?: string;
    paymentSplits?: any;
    lifecycleType?: string;
    transactionType?: string;
    customerId?: string | null;
    sessionId?: string | null;
    tenantId: string;
  }, userId: string | null) {
    // Idempotent: return existing if UUID already in use
    const existing = await this.prisma.transaction.findUnique({ where: { id: data.id } });
    if (existing) return existing;

    const roundedTotal = this.paymentsService.roundTotal(Number(data.totalAmount));

    const newTx = await this.prisma.transaction.create({
      data: {
        id: data.id,
        totalAmount: roundedTotal,
        itemsJson: data.itemsJson ?? [],
        paymentMethod: data.paymentMethod ?? null,
        paymentSplits: data.paymentSplits ?? null,
        lifecycleType: data.lifecycleType ?? 'instant',
        transactionType: data.transactionType ?? 'sale',
        customerId: data.customerId ?? null,
        sessionId: data.sessionId ?? null,
        tenantId: data.tenantId,
      },
    });

    // Credit balance update
    if (data.paymentMethod === 'CREDIT' && data.customerId) {
      await this.contactsService.updateBalance(data.customerId, roundedTotal);
    } else if (data.paymentMethod === 'SPLIT' && data.paymentSplits && data.customerId) {
      const splits = typeof data.paymentSplits === 'string'
        ? JSON.parse(data.paymentSplits)
        : data.paymentSplits;
      if (splits['CREDIT']) {
        await this.contactsService.updateBalance(data.customerId, splits['CREDIT']);
      }
    }

    // Audit log
    await this.auditLog.log({
      tenantId: data.tenantId,
      userId,
      action: 'CREATE',
      entity: 'Transaction',
      entityId: newTx.id,
      before: null,
      after: { totalAmount: String(newTx.totalAmount), paymentMethod: newTx.paymentMethod },
    });

    // Domain event
    this.eventBus.publish('transaction.created', {
      transactionId: newTx.id,
      tenantId: newTx.tenantId,
    });

    return newTx;
  }

  async getTransactions(params: {
    tenantId?: string;
    since?: string;
    page?: number;
    limit?: number;
  } = {}) {
    const { tenantId, since, page = 1, limit = 100 } = params;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (tenantId) where.tenantId = tenantId;
    if (since) where.createdAt = { gt: new Date(since) };

    const [items, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.transaction.count({ where }),
    ]);

    const hasMore = skip + items.length < total;

    return {
      items,
      meta: {
        total,
        page,
        limit,
        hasMore,
        serverTime: new Date().toISOString(),
      },
    };
  }
}
