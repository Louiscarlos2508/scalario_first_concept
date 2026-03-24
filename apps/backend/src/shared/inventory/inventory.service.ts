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
    variantId?: string | null;
    // Epic 26 — AC2 (Story 26-4): optional best-before date for DELIVERY batches
    bestBeforeDate?: string | null;
    // User-provided expiry date (overrides auto-calculation from expiryDays)
    expiresAt?: string | null;
    // Serial numbers to register on DELIVERY
    serialNumbers?: string[] | null;
  }) {
    // AC6 (Story 24-1) — Auto-reason NATURAL_VARIANCE for LOSS within shrinkage tolerance
    let resolvedReason = data.reason ?? null;
    if (data.type === 'LOSS' && data.catalogItemId && (!data.reason || data.reason.trim() === '')) {
      const item = await this.prisma.catalogItem.findUnique({
        where: { id: data.catalogItemId },
        select: { shrinkageTolerance: true },
      });
      if (item?.shrinkageTolerance != null) {
        const totalStock = await this.getCurrentStock(data.catalogItemId, data.tenantId);
        const toleranceQty = (Number(item.shrinkageTolerance) / 100) * totalStock;
        if (data.quantity <= toleranceQty) {
          resolvedReason = 'NATURAL_VARIANCE';
        }
      }
    }

    // AC1 — reason is mandatory for LOSS movements
    if (data.type === 'LOSS' && (!resolvedReason || resolvedReason.trim() === '')) {
      throw new BadRequestException('reason is required for LOSS movements');
    }

    // AC2 (Story 26-6) — isUnique items: stock cap ≤ 1 for inbound movements
    const isInbound =
      data.type === 'DELIVERY' ||
      data.type === 'TRANSFER_IN' ||
      (data.type === 'ADJUSTMENT' && data.quantity > 0);
    if (data.catalogItemId && isInbound) {
      const catalogItem = await this.prisma.catalogItem.findUnique({
        where: { id: data.catalogItemId },
        select: { isUnique: true },
      });
      if (catalogItem?.isUnique) {
        const currentStock = await this.getCurrentStock(data.catalogItemId, data.tenantId);
        if (currentStock + data.quantity > 1) {
          throw new BadRequestException('Article unique : le stock ne peut pas dépasser 1');
        }
      }
    }

    const movement = await this.prisma.inventoryMovement.create({
      data: {
        catalogItemId: data.catalogItemId ?? null,
        quantity: data.quantity,
        type: data.type,
        reason: resolvedReason,
        tenantId: data.tenantId,
        userId: data.userId ?? null,
        referenceId: data.referenceId ?? null,
        variantId: data.variantId ?? null,
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
        reason: resolvedReason,
      },
    });

    this.eventBus.publish('stock.adjusted', {
      movementId: movement.id,
      catalogItemId: data.catalogItemId ?? null,
      type: data.type,
      tenantId: data.tenantId,
    });

    if (data.type === 'DELIVERY' && data.catalogItemId) {
      // Create SerialRecords if serial numbers provided
      if (data.serialNumbers?.length) {
        for (const serial of data.serialNumbers) {
          await this.prisma.serialRecord.create({
            data: { catalogItemId: data.catalogItemId, serial, tenantId: data.tenantId },
          });
        }
      }

      // AC3 (Story 24-1) — Create ProductBatch on DELIVERY
      // User-provided expiresAt takes precedence; fallback to auto-calculation from expiryDays
      const providedExpiresAt = data.expiresAt ? new Date(data.expiresAt) : null;
      if (providedExpiresAt) {
        await this.prisma.productBatch.create({
          data: {
            catalogItemId: data.catalogItemId,
            tenantId: data.tenantId,
            expiresAt: providedExpiresAt,
            bestBeforeDate: data.bestBeforeDate ? new Date(data.bestBeforeDate) : null,
            initialQty: data.quantity,
            remainingQty: data.quantity,
            batchRef: data.referenceId ?? null,
          },
        });
      } else {
        const catalogItem = await this.prisma.catalogItem.findUnique({
          where: { id: data.catalogItemId },
          select: { expiryDays: true },
        });
        if (catalogItem?.expiryDays != null) {
          const autoExpiry = new Date();
          autoExpiry.setDate(autoExpiry.getDate() + catalogItem.expiryDays);
          await this.prisma.productBatch.create({
            data: {
              catalogItemId: data.catalogItemId,
              tenantId: data.tenantId,
              expiresAt: autoExpiry,
              bestBeforeDate: data.bestBeforeDate ? new Date(data.bestBeforeDate) : null,
              initialQty: data.quantity,
              remainingQty: data.quantity,
              batchRef: data.referenceId ?? null,
            },
          });
        }
      }
    }

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

    if (data.catalogItemId) {
      this.eventBus.publish('transfer.out.created', {
        catalogItemId: data.catalogItemId,
        tenantId: data.tenantId,
      });
    }

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
        case 'REPACKAGING':
          stock -= qty;
          break;
        case 'RETURN':
          stock += qty;
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

  /** AC4 (Story 24-1) — Deplete ProductBatches FIFO for a given item + qty. */
  private async depletesBatchesFifo(catalogItemId: string, qty: number, tenantId: string) {
    const activeBatches = await this.prisma.productBatch.findMany({
      where: { catalogItemId, tenantId, isDepleted: false },
      orderBy: { expiresAt: 'asc' },
    });

    let remaining = qty;
    for (const batch of activeBatches) {
      if (remaining <= 0) break;
      const batchRemaining = Number(batch.remainingQty);
      const deducted = Math.min(remaining, batchRemaining);
      const newRemaining = batchRemaining - deducted;
      await this.prisma.productBatch.update({
        where: { id: batch.id },
        data: { remainingQty: newRemaining, isDepleted: newRemaining <= 0 },
      });
      remaining -= deducted;
    }
  }

  async cancelTransfer(referenceId: string, tenantId: string, userId: string | null) {
    const movement = await this.prisma.inventoryMovement.findFirst({
      where: { referenceId, type: 'TRANSFER_OUT', tenantId },
    });
    if (!movement) {
      throw new Error(`No pending transfer found: ${referenceId}`);
    }
    await this.prisma.inventoryMovement.delete({ where: { id: movement.id } });
    await this.auditLog.log({
      tenantId,
      userId,
      action: 'DELETE',
      entity: 'InventoryMovement',
      entityId: movement.id,
      after: { cancelled: true, referenceId },
    });
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

      const catalogItemId: string | null = item.catalogItemId ?? item.productId ?? null;
      if (!catalogItemId) continue;

      // AC5 (Story 25-1) — If variantId provided, decrement variant stock
      const variantId: string | null = item.variantId ?? null;
      if (variantId) {
        await this.prisma.productVariant.update({
          where: { id: variantId },
          data: { stockQuantity: { decrement: qty } },
        });
        await this.prisma.inventoryMovement.create({
          data: {
            catalogItemId,
            quantity: qty,
            type: 'SALE',
            tenantId: payload.tenantId,
            variantId,
          },
        });
        continue;
      }

      // Epic 23 — Check if this is a child item (parent-child relationship)
      const catalogItem = await this.prisma.catalogItem.findUnique({
        where: { id: catalogItemId },
        select: { parentItemId: true, conversionRate: true },
      });

      if (catalogItem?.parentItemId) {
        // AC3 — Child item: decrement parent stock via REPACKAGING movement
        const convRate = Number(catalogItem.conversionRate ?? item.conversionRate ?? 1);
        const parentQty = qty * convRate;

        await this.createMovement({
          catalogItemId: catalogItem.parentItemId,
          quantity: parentQty,
          type: 'REPACKAGING',
          referenceId: payload.transactionId,
          tenantId: payload.tenantId,
        });
        // No SALE movement for the child — it has no independent stock
      } else {
        // AC4 (Story 20-1): Apply conversionRate when decrementing stock.
        const conversionRate = item.conversionRate != null ? Number(item.conversionRate) : null;
        const stockQty = conversionRate != null ? qty * conversionRate : qty;

        await this.createMovement({
          catalogItemId,
          quantity: stockQty,
          type: 'SALE',
          tenantId: payload.tenantId,
        });

        // AC4 (Story 24-1) — FIFO batch depletion
        await this.depletesBatchesFifo(catalogItemId, stockQty, payload.tenantId);

        // AC3 (Story 26-6) — Auto-archive isUnique items when stock reaches 0
        const soldItem = await this.prisma.catalogItem.findUnique({
          where: { id: catalogItemId },
          select: { isUnique: true },
        });
        if (soldItem?.isUnique) {
          const newStock = await this.getCurrentStock(catalogItemId, payload.tenantId);
          if (newStock <= 0) {
            await this.prisma.catalogItem.update({
              where: { id: catalogItemId },
              data: { isDeleted: true },
            });
          }
        }
      }
    }
  }
}
