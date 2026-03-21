import { Injectable, NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { InventoryService } from '../inventory/inventory.service';
import { CreateClientOrderDto } from './dto/create-client-order.dto';

const ACTIVE_STATUSES = ['confirmed', 'in-progress', 'ready'] as const;

@Injectable()
export class ClientOrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly inventoryService: InventoryService,
  ) {}

  // ── CO-XXXX auto-numbering ─────────────────────────────────────────────────

  private async generateOrderNumber(tenantId: string): Promise<string> {
    const last = await this.prisma.clientOrder.findFirst({
      where: { tenantId },
      orderBy: { createdAt: 'desc' },
      select: { orderNumber: true },
    });
    if (!last) return 'CO-0001';
    const lastN = parseInt(last.orderNumber.replace('CO-', ''), 10);
    return `CO-${String(lastN + 1).padStart(4, '0')}`;
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  async createOrder(tenantId: string, userId: string, dto: CreateClientOrderDto) {
    const customer = await this.prisma.contact.findFirst({
      where: { id: dto.customerId, tenantId },
    });
    if (!customer) throw new NotFoundException('Client introuvable');

    if (!dto.lines || dto.lines.length === 0) {
      throw new UnprocessableEntityException('Au moins une ligne est requise');
    }

    const orderNumber = await this.generateOrderNumber(tenantId);

    return this.prisma.clientOrder.create({
      data: {
        orderNumber,
        tenantId,
        customerId: dto.customerId,
        depositAmount: dto.depositAmount ?? null,
        notes: dto.notes ?? null,
        desiredDeliveryDate: dto.desiredDeliveryDate ? new Date(dto.desiredDeliveryDate) : null,
        createdBy: userId,
        status: 'draft',
        lines: {
          create: dto.lines.map((l) => ({
            catalogItemId: l.catalogItemId,
            variantId: l.variantId ?? null,
            quantity: l.quantity,
            unitPrice: l.unitPrice,
          })),
        },
      },
      include: { lines: true },
    });
  }

  async listOrders(params: {
    tenantId: string;
    status?: string;
    customerId?: string;
    dateFrom?: string;
    dateTo?: string;
    page?: number;
    limit?: number;
  }) {
    const { tenantId, status, customerId, dateFrom, dateTo, page = 1, limit = 50 } = params;
    const skip = (page - 1) * limit;

    const where: any = { tenantId };
    if (status) where.status = status;
    if (customerId) where.customerId = customerId;
    if (dateFrom || dateTo) {
      where.createdAt = {};
      if (dateFrom) where.createdAt.gte = new Date(dateFrom);
      if (dateTo) where.createdAt.lte = new Date(dateTo);
    }

    const [items, total] = await Promise.all([
      this.prisma.clientOrder.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: { lines: true },
      }),
      this.prisma.clientOrder.count({ where }),
    ]);

    return { items, meta: { total, page, limit, hasMore: skip + items.length < total } };
  }

  async getOrder(id: string, tenantId: string) {
    const order = await this.prisma.clientOrder.findFirst({
      where: { id, tenantId },
      include: { lines: true },
    });
    if (!order) throw new NotFoundException(`ClientOrder ${id} not found`);
    return order;
  }

  // ── /confirm ──────────────────────────────────────────────────────────────

  async confirmOrder(id: string, tenantId: string, userId: string) {
    const order = await this.prisma.clientOrder.findFirst({
      where: { id, tenantId },
      include: { lines: true },
    });
    if (!order) throw new NotFoundException(`ClientOrder ${id} not found`);
    if (order.status !== 'draft') {
      throw new UnprocessableEntityException(
        `Transition invalide : ${order.status} → confirmed`,
      );
    }

    // Stock validation: available = physical - active reservations
    for (const line of order.lines) {
      const itemId = line.catalogItemId;

      const currentStock = await this.inventoryService.getCurrentStock(itemId, tenantId);

      const [reserved, released] = await Promise.all([
        this.prisma.inventoryMovement.aggregate({
          where: { catalogItemId: itemId, tenantId, type: 'RESERVATION' },
          _sum: { quantity: true },
        }),
        this.prisma.inventoryMovement.aggregate({
          where: { catalogItemId: itemId, tenantId, type: 'RESERVATION_RELEASE' },
          _sum: { quantity: true },
        }),
      ]);

      const effectiveReserved =
        Number(reserved._sum.quantity ?? 0) - Number(released._sum.quantity ?? 0);
      const available = currentStock - effectiveReserved;

      if (available < Number(line.quantity)) {
        throw new UnprocessableEntityException(
          `Stock insuffisant pour l'article ${itemId} : disponible ${available}, requis ${Number(line.quantity)}`,
        );
      }
    }

    // Create RESERVATION movement per line
    for (const line of order.lines) {
      await this.prisma.inventoryMovement.create({
        data: {
          catalogItemId: line.catalogItemId,
          variantId: line.variantId ?? null,
          quantity: line.quantity,
          type: 'RESERVATION',
          reason: `ClientOrder ${order.orderNumber}`,
          tenantId,
          userId,
          referenceId: order.id,
        },
      });
    }

    return this.prisma.clientOrder.update({
      where: { id },
      data: { status: 'confirmed' },
      include: { lines: true },
    });
  }

  // ── /cancel ───────────────────────────────────────────────────────────────

  async cancelOrder(id: string, tenantId: string, userId: string) {
    const order = await this.prisma.clientOrder.findFirst({
      where: { id, tenantId },
      include: { lines: true },
    });
    if (!order) throw new NotFoundException(`ClientOrder ${id} not found`);

    const cancellableStatuses = ['draft', 'confirmed'];
    if (!cancellableStatuses.includes(order.status)) {
      throw new UnprocessableEntityException(
        `Transition invalide : ${order.status} → cancelled`,
      );
    }

    // Release reservations if order was confirmed
    if (order.status === 'confirmed') {
      for (const line of order.lines) {
        await this.prisma.inventoryMovement.create({
          data: {
            catalogItemId: line.catalogItemId,
            variantId: line.variantId ?? null,
            quantity: line.quantity,
            type: 'RESERVATION_RELEASE',
            reason: `Cancel ClientOrder ${order.orderNumber}`,
            tenantId,
            userId,
            referenceId: order.id,
          },
        });
      }
    }

    return this.prisma.clientOrder.update({
      where: { id },
      data: { status: 'cancelled' },
      include: { lines: true },
    });
  }

  // ── /prepare ──────────────────────────────────────────────────────────────

  async prepareOrder(id: string, tenantId: string) {
    const order = await this.getOrder(id, tenantId);
    if (order.status !== 'confirmed') {
      throw new UnprocessableEntityException(
        `Transition invalide : ${order.status} → in-progress`,
      );
    }
    return this.prisma.clientOrder.update({
      where: { id },
      data: { status: 'in-progress' },
      include: { lines: true },
    });
  }

  // ── /mark-ready ───────────────────────────────────────────────────────────

  async markReady(id: string, tenantId: string) {
    const order = await this.getOrder(id, tenantId);
    if (order.status !== 'in-progress') {
      throw new UnprocessableEntityException(
        `Transition invalide : ${order.status} → ready`,
      );
    }
    return this.prisma.clientOrder.update({
      where: { id },
      data: { status: 'ready' },
      include: { lines: true },
    });
  }

  // ── /deliver ──────────────────────────────────────────────────────────────

  async deliverOrder(
    id: string,
    tenantId: string,
    userId: string,
    deliverLines: Array<{ lineId: string; deliveredQty: number }>,
  ) {
    const order = await this.getOrder(id, tenantId);
    if (order.status !== 'ready') {
      throw new UnprocessableEntityException(
        `Transition invalide : ${order.status} → delivered`,
      );
    }

    return this.prisma.$transaction(async (tx) => {
      let totalDelivered = 0;
      const itemsJson: any[] = [];

      for (const { lineId, deliveredQty } of deliverLines) {
        const line = order.lines.find((l) => l.id === lineId);
        if (!line) continue;

        await tx.clientOrderLine.update({
          where: { id: lineId },
          data: { deliveredQty },
        });

        const lineTotal = deliveredQty * Number(line.unitPrice);
        totalDelivered += lineTotal;
        itemsJson.push({
          catalogItemId: line.catalogItemId,
          variantId: line.variantId ?? null,
          quantity: deliveredQty,
          unitPrice: Number(line.unitPrice),
        });

        if (deliveredQty > 0) {
          await (tx as any).inventoryMovement.create({
            data: {
              catalogItemId: line.catalogItemId,
              variantId: line.variantId ?? null,
              quantity: deliveredQty,
              type: 'SALE',
              reason: `Delivery ClientOrder ${order.orderNumber}`,
              tenantId,
              userId,
              referenceId: order.id,
            },
          });
        }

        const remaining = Number(line.quantity) - deliveredQty;
        if (remaining > 0) {
          await (tx as any).inventoryMovement.create({
            data: {
              catalogItemId: line.catalogItemId,
              variantId: line.variantId ?? null,
              quantity: remaining,
              type: 'RESERVATION_RELEASE',
              reason: `Partial delivery release ClientOrder ${order.orderNumber}`,
              tenantId,
              userId,
              referenceId: order.id,
            },
          });
        }
      }

      await (tx as any).transaction.create({
        data: {
          id: randomUUID(),
          totalAmount: totalDelivered,
          itemsJson,
          transactionType: 'sale',
          lifecycleType: 'instant',
          customerId: order.customerId,
          tenantId,
        },
      });

      return (tx as any).clientOrder.update({
        where: { id },
        data: {
          status: 'delivered',
          deliveredBy: userId,
          deliveredAt: new Date(),
        },
        include: { lines: true },
      });
    });
  }

  // ── /invoice ──────────────────────────────────────────────────────────────

  async invoiceOrder(id: string, tenantId: string) {
    const order = await this.getOrder(id, tenantId);
    if (order.status !== 'delivered') {
      throw new UnprocessableEntityException(
        `Transition invalide : ${order.status} → invoiced`,
      );
    }
    return this.prisma.clientOrder.update({
      where: { id },
      data: { status: 'invoiced' },
      include: { lines: true },
    });
  }

  // ── /pay ──────────────────────────────────────────────────────────────────

  async payOrder(id: string, tenantId: string) {
    const order = await this.getOrder(id, tenantId);
    if (order.status !== 'invoiced') {
      throw new UnprocessableEntityException(
        `Transition invalide : ${order.status} → paid`,
      );
    }
    return this.prisma.clientOrder.update({
      where: { id },
      data: { status: 'paid' },
      include: { lines: true },
    });
  }

  // ── /kpis — declared before /:id in controller ───────────────────────────

  async getKpis(tenantId: string) {
    const activeOrders = await this.prisma.clientOrder.findMany({
      where: { tenantId, status: { in: [...ACTIVE_STATUSES] } },
      include: { lines: { select: { quantity: true, unitPrice: true } } },
    });

    const inProgressCount = activeOrders.length;
    const pendingRevenue = activeOrders.reduce(
      (sum, o) =>
        sum +
        o.lines.reduce(
          (s, l) => s + Number(l.quantity) * Number(l.unitPrice),
          0,
        ),
      0,
    );

    return { inProgressCount, pendingRevenue };
  }
}
