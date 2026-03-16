import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReportingService {
  constructor(private readonly prisma: PrismaService) {}

  // ── AC1 — Sales consolidation report ─────────────────────────────────────

  async getSalesReport(params: {
    tenantId: string;
    from?: string;
    to?: string;
    groupBy?: string;
  }) {
    const { tenantId, from, to } = params;
    const createdAtFilter = this.buildDateRange(from, to);

    const [transactions, inventoryMovements] = await Promise.all([
      this.prisma.transaction.findMany({
        where: { tenantId, ...(createdAtFilter ? { createdAt: createdAtFilter } : {}) },
      }),
      this.prisma.inventoryMovement.findMany({
        where: {
          tenantId,
          type: { in: ['LOSS', 'TRANSFER_IN', 'TRANSFER_OUT'] },
          ...(createdAtFilter ? { createdAt: createdAtFilter } : {}),
        },
      }),
    ]);

    const totalRevenue = transactions.reduce(
      (sum, tx) => sum + Number(tx.totalAmount),
      0,
    );
    const saleCount = transactions.length;

    const breakdownByPaymentMethod: Record<string, number> = {};
    for (const tx of transactions) {
      const method = tx.paymentMethod || 'UNKNOWN';
      breakdownByPaymentMethod[method] =
        (breakdownByPaymentMethod[method] || 0) + Number(tx.totalAmount);
    }

    const losses = inventoryMovements.filter((m) => m.type === 'LOSS');
    const totalLosses = losses.reduce((sum, m) => sum + Number(m.quantity), 0);

    const transferMovements = inventoryMovements.filter((m) =>
      ['TRANSFER_IN', 'TRANSFER_OUT'].includes(m.type),
    );
    const totalTransferVariances = transferMovements.length;

    return {
      totalRevenue,
      saleCount,
      breakdownByPaymentMethod,
      totalLosses,
      totalTransferVariances,
      from: from ?? null,
      to: to ?? null,
    };
  }

  // ── AC2 — Session closure report ─────────────────────────────────────────

  async getSessionReport(params: {
    tenantId: string;
    from?: string;
    to?: string;
  }) {
    const { tenantId, from, to } = params;
    const closedAtFilter = this.buildDateRange(from, to);

    const where: any = { tenantId, status: 'CLOSED' };
    if (closedAtFilter) where.closedAt = closedAtFilter;

    const sessions = await this.prisma.posSession.findMany({
      where,
      orderBy: { closedAt: 'desc' },
    });

    const totalVariance = sessions.reduce(
      (sum, s) => sum + (s.variance ? Number(s.variance) : 0),
      0,
    );

    return { sessions, totalVariance };
  }

  // ── AC3 — Inventory consolidation report ──────────────────────────────────

  async getInventoryReport(params: {
    tenantId: string;
    from?: string;
    to?: string;
  }) {
    const { tenantId, from, to } = params;
    const createdAtFilter = this.buildDateRange(from, to);

    const movements = await this.prisma.inventoryMovement.findMany({
      where: {
        tenantId,
        ...(createdAtFilter ? { createdAt: createdAtFilter } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });

    return {
      deliveries: movements.filter((m) => m.type === 'DELIVERY'),
      transfersIn: movements.filter((m) => m.type === 'TRANSFER_IN'),
      transfersOut: movements.filter((m) => m.type === 'TRANSFER_OUT'),
      losses: movements.filter((m) => m.type === 'LOSS'),
      adjustments: movements.filter((m) => m.type === 'ADJUSTMENT'),
    };
  }

  // ── AC1 (7.2) — Owner dashboard stats ────────────────────────────────────

  async getSalesStats(params: { tenantId: string; from?: string; to?: string }) {
    const { tenantId, from, to } = params;
    const dateFilter = this.buildDateRange(from, to);

    const [transactions, lossMovements, sessions, expenses] = await Promise.all([
      this.prisma.transaction.findMany({
        where: { tenantId, ...(dateFilter ? { createdAt: dateFilter } : {}) },
      }),
      this.prisma.inventoryMovement.findMany({
        where: { tenantId, type: 'LOSS', ...(dateFilter ? { createdAt: dateFilter } : {}) },
      }),
      this.prisma.posSession.findMany({
        where: {
          tenantId,
          status: 'CLOSED',
          ...(dateFilter ? { closedAt: dateFilter } : {}),
        },
      }),
      this.prisma.expense.findMany({
        where: {
          tenantId,
          isDeleted: false,
          ...(dateFilter ? { date: dateFilter } : {}),
        },
      }),
    ]);

    const totalRevenue = transactions.reduce((sum, tx) => sum + Number(tx.totalAmount), 0);
    const saleCount = transactions.length;
    const avgTransactionValue = saleCount > 0 ? totalRevenue / saleCount : 0;

    // Top 3 products by sales volume (parsed from itemsJson)
    const productVolume: Record<string, { name: string; quantity: number }> = {};
    for (const tx of transactions) {
      const items = tx.itemsJson as any[];
      if (Array.isArray(items)) {
        for (const item of items) {
          const key = item.productId || item.name || 'UNKNOWN';
          if (!productVolume[key]) productVolume[key] = { name: item.name || key, quantity: 0 };
          productVolume[key].quantity += Number(item.quantity);
        }
      }
    }
    const top3Products = Object.entries(productVolume)
      .sort((a, b) => b[1].quantity - a[1].quantity)
      .slice(0, 3)
      .map(([id, v]) => ({ id, name: v.name, quantity: v.quantity }));

    const totalLosses = lossMovements.reduce((sum, m) => sum + Number(m.quantity), 0);
    const totalCashVariance = sessions.reduce(
      (sum, s) => sum + (s.variance ? Number(s.variance) : 0),
      0,
    );
    const totalExpenses = expenses.reduce((sum, e) => sum + Number(e.amount), 0);
    const netProfit = totalRevenue - totalExpenses;

    return {
      totalRevenue,
      saleCount,
      avgTransactionValue,
      top3Products,
      totalLosses,
      totalCashVariance,
      totalExpenses,
      netProfit,
      from: from ?? null,
      to: to ?? null,
    };
  }

  // ── AC2 (7.2) — Critical stock levels ────────────────────────────────────

  async getCriticalStock(tenantId: string) {
    const allProducts = await this.prisma.retailProduct.findMany({
      where: { catalogItem: { tenantId } },
      include: { catalogItem: true },
    });

    const toItem = (p: any) => ({
      id: p.id,
      name: p.catalogItem.name,
      barcode: p.catalogItem.barcode ?? null,
      stockQuantity: Number(p.stockQuantity),
      minStockLevel: p.minStockLevel !== null ? Number(p.minStockLevel) : null,
    });

    const criticalItems = allProducts
      .filter((p) => p.minStockLevel !== null && p.stockQuantity.lte(p.minStockLevel))
      .map(toItem);

    const allItems = allProducts.map((p) => ({
      ...toItem(p),
      isCritical: p.minStockLevel !== null && p.stockQuantity.lte(p.minStockLevel),
    }));

    return { criticalItems, allItems };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  private buildDateRange(
    from?: string,
    to?: string,
  ): { gte?: Date; lte?: Date } | undefined {
    if (!from && !to) return undefined;
    const filter: { gte?: Date; lte?: Date } = {};
    if (from) filter.gte = new Date(from);
    if (to) {
      const toDate = new Date(to);
      toDate.setUTCHours(23, 59, 59, 999);
      filter.lte = toDate;
    }
    return filter;
  }
}
