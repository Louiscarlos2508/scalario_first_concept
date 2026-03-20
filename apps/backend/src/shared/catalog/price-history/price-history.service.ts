import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class PriceHistoryService {
  constructor(private readonly prisma: PrismaService) {}

  async recordPrice(tenantId: string, catalogItemId: string, price: number | string, reason?: string) {
    return this.prisma.priceHistory.create({
      data: {
        catalogItemId,
        price: Number(price),
        effectiveFrom: new Date(),
        reason: reason ?? null,
        tenantId,
      },
    });
  }

  async getPriceHistory(tenantId: string, catalogItemId: string) {
    return this.prisma.priceHistory.findMany({
      where: { tenantId, catalogItemId },
      orderBy: { effectiveFrom: 'desc' },
    });
  }
}
