import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { PrismaService } from '../../prisma/prisma.service';
import { EventBusService } from '../../kernel/events/event-bus.service';
import { StockAlertDto } from './dto/stock-alert.dto';

const DECREMENT_TYPES = ['SALE', 'LOSS', 'ADJUSTMENT'];

@Injectable()
export class StockAlertsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventBus: EventBusService,
  ) {}

  /**
   * Returns all catalog items whose current stock is <= minStockLevel,
   * sorted by deficit descending (most critical first).
   */
  async getAlerts(
    tenantId: string,
    params: { limit?: number; offset?: number } = {},
  ): Promise<StockAlertDto[]> {
    const { limit = 50, offset = 0 } = params;

    const rows = await this.prisma.retailProduct.findMany({
      where: {
        minStockLevel: { not: null },
        catalogItem: { tenantId, isDeleted: false },
      },
      include: { catalogItem: { select: { id: true, name: true, tenantId: true } } },
      skip: offset,
      take: limit,
    });

    const alerts: StockAlertDto[] = rows
      .filter((r) => {
        const stock = Number(r.stockQuantity);
        const threshold = Number(r.minStockLevel!);
        return stock <= threshold;
      })
      .map((r) => {
        const stock = Number(r.stockQuantity);
        const threshold = Number(r.minStockLevel!);
        return {
          catalogItemId: r.catalogItemId,
          itemName: r.catalogItem.name,
          stockQuantity: stock,
          minStockLevel: threshold,
          deficit: threshold - stock,
          tenantId: r.catalogItem.tenantId,
        };
      })
      .sort((a, b) => b.deficit - a.deficit);

    return alerts;
  }

  /**
   * Returns count of items below their minimum stock level for the tenant.
   */
  async getAlertsCount(tenantId: string): Promise<number> {
    const rows = await this.prisma.retailProduct.findMany({
      where: {
        minStockLevel: { not: null },
        catalogItem: { tenantId, isDeleted: false },
      },
      select: { stockQuantity: true, minStockLevel: true },
    });

    return rows.filter((r) => Number(r.stockQuantity) <= Number(r.minStockLevel!)).length;
  }

  @OnEvent('stock.adjusted')
  async onStockAdjusted(payload: { catalogItemId: string; type: string; tenantId: string }) {
    if (payload.catalogItemId && DECREMENT_TYPES.includes(payload.type)) {
      await this.evaluateAfterMovement(payload.catalogItemId, payload.tenantId);
    }
  }

  @OnEvent('transfer.out.created')
  async onTransferOut(payload: { catalogItemId: string; tenantId: string }) {
    if (payload.catalogItemId) {
      await this.evaluateAfterMovement(payload.catalogItemId, payload.tenantId);
    }
  }

  /**
   * Evaluates whether a stock movement on a catalog item triggers a low-stock alert.
   * Called after SALE, LOSS, TRANSFER_OUT, ADJUSTMENT movements.
   */
  async evaluateAfterMovement(catalogItemId: string, tenantId: string) {
    if (!catalogItemId) return;

    const rp = await this.prisma.retailProduct.findUnique({
      where: { catalogItemId },
      include: { catalogItem: { select: { name: true } } },
    });

    if (!rp || rp.minStockLevel == null) return;

    const stockQuantity = Number(rp.stockQuantity);
    const minStockLevel = Number(rp.minStockLevel);

    if (stockQuantity <= minStockLevel) {
      this.eventBus.publish('LowStockDetected', {
        tenantId,
        catalogItemId,
        itemName: rp.catalogItem.name,
        stockQuantity,
        minStockLevel,
      });
    }
  }
}
