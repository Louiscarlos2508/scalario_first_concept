import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class SerialsService {
  constructor(private readonly prisma: PrismaService) {}

  async createSerial(
    tenantId: string,
    catalogItemId: string,
    dto: { serial: string; soldAt?: string; warrantyUntil?: string },
  ) {
    // Verify catalog item exists and belongs to tenant
    const item = await this.prisma.catalogItem.findFirst({
      where: { id: catalogItemId, tenantId },
    });
    if (!item) throw new NotFoundException(`CatalogItem ${catalogItemId} not found`);

    // Check uniqueness
    const existing = await this.prisma.serialRecord.findUnique({
      where: { tenantId_serial: { tenantId, serial: dto.serial } },
    });
    if (existing) {
      throw new ConflictException(`Serial number "${dto.serial}" already exists for this tenant`);
    }

    return this.prisma.serialRecord.create({
      data: {
        catalogItemId,
        serial: dto.serial,
        soldAt: dto.soldAt ? new Date(dto.soldAt) : null,
        warrantyUntil: dto.warrantyUntil ? new Date(dto.warrantyUntil) : null,
        tenantId,
      },
    });
  }

  async listSerials(
    tenantId: string,
    catalogItemId: string,
    page = 1,
    limit = 20,
  ) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.serialRecord.findMany({
        where: { tenantId, catalogItemId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.serialRecord.count({ where: { tenantId, catalogItemId } }),
    ]);
    return { items, meta: { total, page, limit, hasMore: skip + items.length < total } };
  }

  async searchSerials(tenantId: string, query: string) {
    const records = await this.prisma.serialRecord.findMany({
      where: {
        tenantId,
        serial: { contains: query, mode: 'insensitive' },
      },
      include: { catalogItem: { select: { id: true, name: true } } },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return records.map((r) => ({ ...r, warrantyNumber: this._warrantyNumber(tenantId, r.serial, r.soldAt, r.warrantyUntil) }));
  }

  /** AC3 — Deterministic warranty certificate number, re-calculated on demand. */
  private _warrantyNumber(
    tenantId: string,
    serial: string,
    soldAt: Date | null,
    warrantyUntil: Date | null,
  ): string | null {
    if (!warrantyUntil || !soldAt) return null;
    const tenantCode = tenantId.substring(0, 4).toUpperCase();
    const yyyymm = `${soldAt.getFullYear()}${String(soldAt.getMonth() + 1).padStart(2, '0')}`;
    return `WAR-${tenantCode}-${serial}-${yyyymm}`;
  }

  async createSerialForSale(
    tenantId: string,
    catalogItemId: string,
    serial: string,
    warrantyMonths?: number | null,
  ) {
    const soldAt = new Date();
    let warrantyUntil: Date | null = null;
    if (warrantyMonths && warrantyMonths > 0) {
      warrantyUntil = new Date(soldAt);
      warrantyUntil.setMonth(warrantyUntil.getMonth() + warrantyMonths);
    }

    // Check for duplicate — throw ConflictException propagated to transaction
    const existing = await this.prisma.serialRecord.findUnique({
      where: { tenantId_serial: { tenantId, serial } },
    });
    if (existing) {
      throw new ConflictException(`Serial "${serial}" already sold in this tenant`);
    }

    return this.prisma.serialRecord.create({
      data: { catalogItemId, serial, soldAt, warrantyUntil, tenantId },
    });
  }
}
