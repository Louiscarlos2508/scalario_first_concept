import { BadRequestException, Injectable, NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { EventBusService } from '../../kernel/events/event-bus.service';
import { CreatePurchaseOrderDto } from './dto/create-purchase-order.dto';
import { ReceivePurchaseOrderDto } from './dto/receive-purchase-order.dto';

const VALID_STATUSES = ['draft', 'confirmed', 'partially_received', 'received', 'cancelled'] as const;

// Valid forward transitions only
const ALLOWED_TRANSITIONS: Record<string, string[]> = {
  draft: ['confirmed', 'cancelled'],
  confirmed: ['partially_received', 'received', 'cancelled'],
  partially_received: ['received', 'cancelled'],
  received: [],
  cancelled: [],
};

@Injectable()
export class PurchaseOrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLog: AuditLogService,
    private readonly eventBus: EventBusService,
  ) {}

  async createPurchaseOrder(data: CreatePurchaseOrderDto, userId?: string | null) {
    const po = await this.prisma.purchaseOrder.create({
      data: {
        tenantId: data.tenantId,
        supplierId: data.supplierId ?? null,
        expectedDate: data.expectedDate ? new Date(data.expectedDate) : null,
        notes: data.notes ?? null,
        status: 'draft',
        createdBy: userId ?? null,
        lines: {
          create: data.lines.map((l) => ({
            catalogItemId: l.catalogItemId,
            expectedQuantity: l.expectedQuantity,
          })),
        },
      },
      include: { lines: true, supplier: true },
    });

    await this.auditLog.log({
      tenantId: data.tenantId,
      userId: userId ?? null,
      action: 'CREATE',
      entity: 'PurchaseOrder',
      entityId: po.id,
      after: { status: 'draft', lineCount: data.lines.length },
    });

    return po;
  }

  async listPurchaseOrders(params: {
    tenantId?: string;
    status?: string;
    supplierId?: string;
    from?: string;
    to?: string;
    page?: number;
    limit?: number;
  }) {
    const { tenantId, status, supplierId, from, to, page = 1, limit = 50 } = params;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (tenantId) where.tenantId = tenantId;
    if (status) where.status = status;
    if (supplierId) where.supplierId = supplierId;
    if (from || to) {
      where.createdAt = {};
      if (from) where.createdAt.gte = new Date(from);
      if (to) where.createdAt.lte = new Date(to);
    }

    const [items, total] = await Promise.all([
      this.prisma.purchaseOrder.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          supplier: { select: { name: true } },
          _count: { select: { lines: true } },
        },
      }),
      this.prisma.purchaseOrder.count({ where }),
    ]);

    return {
      items: items.map((po) => ({
        id: po.id,
        status: po.status,
        expectedDate: po.expectedDate,
        supplierName: po.supplier?.name ?? null,
        lineCount: po._count.lines,
        tenantId: po.tenantId,
        createdAt: po.createdAt,
      })),
      meta: { total, page, limit, hasMore: skip + items.length < total },
    };
  }

  async getPurchaseOrder(id: string, tenantId?: string) {
    const where: any = { id };
    if (tenantId) where.tenantId = tenantId;

    const po = await this.prisma.purchaseOrder.findFirst({
      where,
      include: {
        supplier: true,
        lines: {
          include: { catalogItem: { select: { name: true } } },
        },
      },
    });

    if (!po) throw new NotFoundException(`PurchaseOrder ${id} not found`);

    return {
      ...po,
      lines: po.lines.map((l) => ({
        id: l.id,
        catalogItemId: l.catalogItemId,
        itemName: l.catalogItem?.name ?? null,
        expectedQuantity: l.expectedQuantity,
        receivedQuantity: l.receivedQuantity,
        qualityNotes: l.qualityNotes,
      })),
    };
  }

  async updateStatus(id: string, newStatus: string, tenantId?: string, userId?: string | null) {
    const po = await this.prisma.purchaseOrder.findFirst({
      where: { id, ...(tenantId ? { tenantId } : {}) },
    });
    if (!po) throw new NotFoundException(`PurchaseOrder ${id} not found`);

    const allowed = ALLOWED_TRANSITIONS[po.status] ?? [];
    if (!allowed.includes(newStatus)) {
      throw new UnprocessableEntityException(
        `Invalid status transition: ${po.status} → ${newStatus}. Allowed: ${allowed.join(', ') || 'none'}`,
      );
    }

    const updated = await this.prisma.purchaseOrder.update({
      where: { id },
      data: { status: newStatus },
      include: { lines: true, supplier: true },
    });

    await this.auditLog.log({
      tenantId: po.tenantId,
      userId: userId ?? null,
      action: 'UPDATE',
      entity: 'PurchaseOrder',
      entityId: id,
      before: { status: po.status },
      after: { status: newStatus },
    });

    return updated;
  }

  async receivePurchaseOrder(
    id: string,
    dto: ReceivePurchaseOrderDto,
    tenantId?: string,
    userId?: string | null,
  ) {
    const po = await this.prisma.purchaseOrder.findFirst({
      where: { id, ...(tenantId ? { tenantId } : {}) },
      include: { lines: true },
    });
    if (!po) throw new NotFoundException(`PurchaseOrder ${id} not found`);

    if (!['confirmed', 'partially_received'].includes(po.status)) {
      throw new UnprocessableEntityException(
        `Cannot receive on a PurchaseOrder with status: ${po.status}`,
      );
    }

    const receivedLines: any[] = [];

    for (const input of dto.lines) {
      const line = po.lines.find((l) => l.id === input.purchaseOrderLineId);
      if (!line) continue;

      await this.prisma.purchaseOrderLine.update({
        where: { id: line.id },
        data: {
          receivedQuantity: input.receivedQuantity,
          qualityNotes: input.qualityNotes ?? null,
        },
      });

      const variance = Number(input.receivedQuantity) - Number(line.expectedQuantity);

      if (input.receivedQuantity > 0 && line.catalogItemId) {
        await this.prisma.inventoryMovement.create({
          data: {
            catalogItemId: line.catalogItemId,
            quantity: input.receivedQuantity,
            type: 'DELIVERY',
            reason: `PO reception ${id}`,
            tenantId: po.tenantId,
            userId: userId ?? null,
            referenceId: id,
          },
        });
      }

      receivedLines.push({
        lineId: line.id,
        catalogItemId: line.catalogItemId,
        expectedQuantity: Number(line.expectedQuantity),
        receivedQuantity: input.receivedQuantity,
        variance,
      });
    }

    // Recalculate status from all lines
    const updatedLines = await this.prisma.purchaseOrderLine.findMany({
      where: { purchaseOrderId: id },
    });

    const allReceived = updatedLines.every((l) => l.receivedQuantity !== null);
    const anyReceived = updatedLines.some((l) => l.receivedQuantity !== null);

    const newStatus = allReceived ? 'received' : anyReceived ? 'partially_received' : po.status;

    const updated = await this.prisma.purchaseOrder.update({
      where: { id },
      data: { status: newStatus },
      include: { lines: true },
    });

    this.eventBus.publish('delivery.received', {
      purchaseOrderId: id,
      tenantId: po.tenantId,
      lines: receivedLines,
    });

    await this.auditLog.log({
      tenantId: po.tenantId,
      userId: userId ?? null,
      action: 'UPDATE',
      entity: 'PurchaseOrder',
      entityId: id,
      before: { status: po.status },
      after: { status: newStatus, receivedLines: receivedLines.length },
    });

    return updated;
  }

  async getStats(tenantId: string) {
    const [confirmed, partiallyReceived] = await Promise.all([
      this.prisma.purchaseOrder.count({ where: { tenantId, status: 'confirmed' } }),
      this.prisma.purchaseOrder.count({ where: { tenantId, status: 'partially_received' } }),
    ]);

    return { confirmed, partiallyReceived, total: confirmed + partiallyReceived };
  }
}
