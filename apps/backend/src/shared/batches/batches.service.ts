import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class BatchesService {
  constructor(private readonly prisma: PrismaService) {}

  async getBatchesExpiring(tenantId: string, days: number) {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() + days);

    const batches = await this.prisma.productBatch.findMany({
      where: { tenantId, isDepleted: false, expiresAt: { lte: cutoff } },
      orderBy: { expiresAt: 'asc' },
      include: { catalogItem: { select: { name: true, expiryDays: true } } },
    });

    const now = new Date();
    return batches.map((b) => {
      const expiryDays = b.catalogItem.expiryDays ?? 0;
      const remainMs = b.expiresAt.getTime() - now.getTime();
      const remainingDays = Math.max(0, remainMs / (1000 * 60 * 60 * 24));
      const freshnessPercent =
        expiryDays > 0 ? Math.min(100, Math.round((remainingDays / expiryDays) * 100)) : 100;

      return {
        batchId: b.id,
        catalogItemId: b.catalogItemId,
        itemName: b.catalogItem.name,
        expiresAt: b.expiresAt,
        remainingQty: Number(b.remainingQty),
        freshnessPercent,
      };
    });
  }

  async depleteBatch(batchId: string, tenantId: string) {
    return this.prisma.productBatch.update({
      where: { id: batchId, tenantId },
      data: { isDepleted: true, remainingQty: 0 },
    });
  }

  async getExpiringCount(tenantId: string) {
    // Fetch all non-depleted batches (large window) then filter by urgency
    const all = await this.getBatchesExpiring(tenantId, 365);
    const urgentCount = all.filter((b) => b.freshnessPercent < 50).length;
    return { urgentCount };
  }
}
