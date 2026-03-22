import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { EventBusService } from '../../kernel/events/event-bus.service';
import { ContactsService } from '../contacts/contacts.service';
import { PaymentsService } from '../payments/payments.service';
import { SerialsService } from '../catalog/serials/serials.service';

@Injectable()
export class TransactionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLog: AuditLogService,
    private readonly eventBus: EventBusService,
    private readonly contactsService: ContactsService,
    private readonly paymentsService: PaymentsService,
    private readonly serialsService: SerialsService,
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
    // Date de vente locale du device POS — préserve la vraie date même après un sync différé.
    createdAt?: string | Date;
    // Epic 26 — Serial number tracking
    serialNumbers?: Array<{ catalogItemId: string; serial: string }>;
    // Epic 26 — Prescription
    prescriptionNumber?: string | null;
    prescriberName?: string | null;
  }, userId: string | null) {
    // Idempotent: return existing if UUID already in use
    const existing = await this.prisma.transaction.findUnique({ where: { id: data.id } });
    if (existing) return existing;

    const roundedTotal = this.paymentsService.roundTotal(Number(data.totalAmount));

    const prescriptionMeta = data.prescriptionNumber
      ? { prescription: { number: data.prescriptionNumber, prescriber: data.prescriberName ?? '' } }
      : undefined;

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
        metadata: prescriptionMeta ?? Prisma.JsonNull,
        // Preserve the device sale timestamp so reports show the real sale date,
        // not the sync date.
        ...(data.createdAt ? { createdAt: new Date(data.createdAt) } : {}),
      },
    });

    // Epic 26 — Create SerialRecord for each item with a serial number
    if (data.serialNumbers && data.serialNumbers.length > 0) {
      for (const sn of data.serialNumbers) {
        const catalogItem = await this.prisma.catalogItem.findFirst({
          where: { id: sn.catalogItemId, tenantId: data.tenantId },
          select: { warrantyMonths: true },
        });
        await this.serialsService.createSerialForSale(
          data.tenantId,
          sn.catalogItemId,
          sn.serial,
          catalogItem?.warrantyMonths,
        );
      }
    }

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
    from?: string;
    to?: string;
    userId?: string;
    paymentMethod?: string;
    search?: string;
    page?: number;
    limit?: number;
  } = {}) {
    const { tenantId, since, from, to, userId, paymentMethod, search, page = 1, limit = 50 } = params;
    const skip = (page - 1) * limit;

    const where: any = { AND: [] };
    if (tenantId) where.tenantId = tenantId;
    if (paymentMethod) where.paymentMethod = paymentMethod;

    // Date range — prefer from/to over legacy since
    if (from || to) {
      const createdAt: any = {};
      if (from) createdAt.gte = new Date(from);
      if (to) createdAt.lte = new Date(`${to}T23:59:59.999Z`);
      where.createdAt = createdAt;
    } else if (since) {
      where.createdAt = { gt: new Date(since) };
    }

    // Nested retailSale filters (cashier + receipt number search)
    const retailSaleFilter: any = {};
    if (userId) retailSaleFilter.cashierId = userId;
    if (search) retailSaleFilter.receiptNumber = { contains: search, mode: 'insensitive' };
    if (Object.keys(retailSaleFilter).length > 0) {
      where.retailSale = retailSaleFilter;
    }

    // Clean up AND if unused
    if (where.AND.length === 0) delete where.AND;

    const [items, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where,
        include: {
          retailSale: { select: { receiptNumber: true, cashierId: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.transaction.count({ where }),
    ]);

    // Batch-fetch customer names for transactions that have a customerId
    const customerIds = [...new Set(
      items.map(i => i.customerId).filter((id): id is string => id != null)
    )];
    const customerMap = new Map<string, { name: string; phone: string | null }>();
    if (customerIds.length > 0) {
      const contacts = await this.prisma.contact.findMany({
        where: { id: { in: customerIds } },
        select: { id: true, name: true, phone: true },
      });
      for (const c of contacts) customerMap.set(c.id, { name: c.name, phone: c.phone });
    }

    const itemsWithCustomer = items.map(item => ({
      ...item,
      customer: item.customerId ? (customerMap.get(item.customerId) ?? null) : null,
    }));

    const hasMore = skip + items.length < total;

    return {
      items: itemsWithCustomer,
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
