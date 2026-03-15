import { BadRequestException, Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { EventBusService } from '../../kernel/events/event-bus.service';

@Injectable()
export class InventoryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLog: AuditLogService,
    private readonly eventBus: EventBusService,
  ) {}

  async createMovement(data: {
    catalogItemId?: string | null;
    quantity: number;
    type: string;
    reason?: string | null;
    tenantId: string;
    userId?: string | null;
    referenceId?: string | null;
  }) {
    // AC1 — reason is mandatory for LOSS movements
    if (data.type === 'LOSS' && (!data.reason || data.reason.trim() === '')) {
      throw new BadRequestException('reason is required for LOSS movements');
    }

    const movement = await this.prisma.inventoryMovement.create({
      data: {
        catalogItemId: data.catalogItemId ?? null,
        quantity: data.quantity,
        type: data.type,
        reason: data.reason ?? null,
        tenantId: data.tenantId,
        userId: data.userId ?? null,
        referenceId: data.referenceId ?? null,
      },
    });

    await this.auditLog.log({
      tenantId: data.tenantId,
      userId: data.userId ?? null,
      action: 'CREATE',
      entity: 'InventoryMovement',
      entityId: movement.id,
      after: {
        catalogItemId: data.catalogItemId ?? null,
        quantity: data.quantity,
        type: data.type,
        reason: data.reason ?? null,
      },
    });

    this.eventBus.publish('stock.adjusted', {
      movementId: movement.id,
      catalogItemId: data.catalogItemId ?? null,
      type: data.type,
      tenantId: data.tenantId,
    });

    return movement;
  }

  async createTransferOut(data: {
    catalogItemId?: string | null;
    quantity: number;
    reason?: string | null;
    tenantId: string;
    userId?: string | null;
  }) {
    const referenceId = randomUUID();
    const movement = await this.prisma.inventoryMovement.create({
      data: {
        catalogItemId: data.catalogItemId ?? null,
        quantity: data.quantity,
        type: 'TRANSFER_OUT',
        reason: data.reason ?? null,
        tenantId: data.tenantId,
        userId: data.userId ?? null,
        referenceId,
      },
    });

    await this.auditLog.log({
      tenantId: data.tenantId,
      userId: data.userId ?? null,
      action: 'CREATE',
      entity: 'InventoryMovement',
      entityId: movement.id,
      after: { type: 'TRANSFER_OUT', quantity: data.quantity, referenceId },
    });

    this.eventBus.publish('transfer.created', {
      referenceId,
      tenantId: data.tenantId,
      status: 'pending',
    });

    return movement;
  }

  async confirmTransferIn(data: {
    referenceId: string;
    catalogItemId?: string | null;
    quantity: number;
    tenantId: string;
    userId?: string | null;
  }) {
    const outMovement = await this.prisma.inventoryMovement.findFirst({
      where: { referenceId: data.referenceId, type: 'TRANSFER_OUT' },
    });

    if (!outMovement) {
      throw new Error(`No TRANSFER_OUT found for referenceId: ${data.referenceId}`);
    }

    const sentQty = Number(outMovement.quantity);
    const receivedQty = Number(data.quantity);
    const variance = sentQty - receivedQty;
    const reason = variance !== 0 ? `Variance: ${variance}` : null;

    const inMovement = await this.prisma.inventoryMovement.create({
      data: {
        catalogItemId: data.catalogItemId ?? outMovement.catalogItemId,
        quantity: receivedQty,
        type: 'TRANSFER_IN',
        reason,
        tenantId: data.tenantId,
        userId: data.userId ?? null,
        referenceId: data.referenceId,
      },
    });

    await this.auditLog.log({
      tenantId: data.tenantId,
      userId: data.userId ?? null,
      action: 'CREATE',
      entity: 'InventoryMovement',
      entityId: inMovement.id,
      after: { type: 'TRANSFER_IN', quantity: receivedQty, referenceId: data.referenceId, variance },
    });

    this.eventBus.publish('transfer.confirmed', {
      referenceId: data.referenceId,
      sent: sentQty,
      received: receivedQty,
      variance,
      tenantId: data.tenantId,
    });

    return inMovement;
  }

  async getCurrentStock(catalogItemId: string, tenantId: string): Promise<number> {
    const movements = await this.prisma.inventoryMovement.findMany({
      where: { catalogItemId, tenantId },
      select: { type: true, quantity: true },
    });

    let stock = 0;
    for (const m of movements) {
      const qty = Number(m.quantity);
      switch (m.type) {
        case 'DELIVERY':
        case 'TRANSFER_IN':
          stock += qty;
          break;
        case 'SALE':
        case 'TRANSFER_OUT':
        case 'LOSS':
          stock -= qty;
          break;
        case 'ADJUSTMENT':
          stock += qty; // signed — positive=increase, negative=decrease
          break;
      }
    }
    return stock;
  }

  async adjustInventory(data: {
    catalogItemId: string;
    countedQuantity: number;
    reason?: string | null;
    tenantId: string;
    userId?: string | null;
  }) {
    const currentStock = await this.getCurrentStock(data.catalogItemId, data.tenantId);
    const variance = data.countedQuantity - currentStock;

    if (variance === 0) {
      return { adjusted: false, catalogItemId: data.catalogItemId, tenantId: data.tenantId };
    }

    if (!data.reason || data.reason.trim() === '') {
      throw new BadRequestException('reason is required for non-zero adjustments');
    }

    const movement = await this.createMovement({
      type: 'ADJUSTMENT',
      quantity: variance, // signed: positive = counted more, negative = counted less
      reason: data.reason,
      catalogItemId: data.catalogItemId,
      tenantId: data.tenantId,
      userId: data.userId ?? null,
    });

    return { adjusted: true, catalogItemId: data.catalogItemId, tenantId: data.tenantId, variance, movement };
  }

  async getMovements(params: {
    tenantId?: string;
    since?: string;
    referenceId?: string;
    page?: number;
    limit?: number;
  }) {
    const { tenantId, since, referenceId, page = 1, limit = 100 } = params;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (tenantId) where.tenantId = tenantId;
    if (since) where.createdAt = { gt: new Date(since) };
    if (referenceId) where.referenceId = referenceId;

    const [items, total] = await Promise.all([
      this.prisma.inventoryMovement.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.inventoryMovement.count({ where }),
    ]);

    return {
      items,
      meta: {
        total,
        page,
        limit,
        hasMore: skip + items.length < total,
        serverTime: new Date().toISOString(),
      },
    };
  }

  @OnEvent('transaction.created')
  async handleTransactionCreated(payload: { transactionId: string; tenantId: string }) {
    const tx = await this.prisma.transaction.findUnique({
      where: { id: payload.transactionId },
    });
    if (!tx) return;

    const items = Array.isArray(tx.itemsJson) ? (tx.itemsJson as any[]) : [];
    for (const item of items) {
      const qty = Number(item.quantity ?? item.qty ?? 1);
      if (qty <= 0) continue;
      await this.createMovement({
        catalogItemId: item.catalogItemId ?? item.productId ?? null,
        quantity: qty,
        type: 'SALE',
        tenantId: payload.tenantId,
      });
    }
  }
}
