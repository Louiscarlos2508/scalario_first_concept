import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class PriceLevelsService {
  constructor(private readonly prisma: PrismaService) {}

  async createPriceLevel(
    catalogItemId: string,
    tenantId: string,
    data: {
      levelCode: string;
      label: string;
      price: number | string;
      minQty?: number | null;
      customerTypes?: string[];
    },
  ) {
    const item = await this.prisma.catalogItem.findUnique({ where: { id: catalogItemId } });
    if (!item || item.tenantId !== tenantId) {
      throw new NotFoundException(`CatalogItem ${catalogItemId} not found`);
    }
    return this.prisma.priceLevel.create({
      data: {
        catalogItemId,
        tenantId,
        levelCode: data.levelCode,
        label: data.label,
        price: data.price,
        minQty: data.minQty ?? null,
        customerTypes: data.customerTypes ?? [],
      },
    });
  }

  async getPriceLevels(catalogItemId: string, tenantId: string) {
    return this.prisma.priceLevel.findMany({
      where: { catalogItemId, tenantId, isActive: true },
      orderBy: { createdAt: 'asc' },
    });
  }

  async updatePriceLevel(
    catalogItemId: string,
    priceLevelId: string,
    tenantId: string,
    data: {
      levelCode?: string;
      label?: string;
      price?: number | string;
      minQty?: number | null;
      customerTypes?: string[];
    },
  ) {
    const pl = await this.prisma.priceLevel.findFirst({
      where: { id: priceLevelId, catalogItemId, tenantId },
    });
    if (!pl) throw new NotFoundException(`PriceLevel ${priceLevelId} not found`);

    const updateData: any = {};
    if (data.levelCode !== undefined) updateData.levelCode = data.levelCode;
    if (data.label !== undefined) updateData.label = data.label;
    if (data.price !== undefined) updateData.price = data.price;
    if ('minQty' in data) updateData.minQty = data.minQty;
    if (data.customerTypes !== undefined) updateData.customerTypes = data.customerTypes;

    return this.prisma.priceLevel.update({ where: { id: priceLevelId }, data: updateData });
  }

  async deletePriceLevel(catalogItemId: string, priceLevelId: string, tenantId: string) {
    const pl = await this.prisma.priceLevel.findFirst({
      where: { id: priceLevelId, catalogItemId, tenantId },
    });
    if (!pl) throw new NotFoundException(`PriceLevel ${priceLevelId} not found`);
    return this.prisma.priceLevel.update({ where: { id: priceLevelId }, data: { isActive: false } });
  }

  /**
   * AC3 — Resolve the best applicable price level for a given sale context.
   * Priority: lowest price among eligible levels.
   * Eligibility: minQty satisfied AND (customerTypes empty OR contact's type matches).
   */
  async resolvePriceLevel(
    catalogItemId: string,
    quantity: number,
    contactId: string | null,
    tenantId: string,
  ): Promise<{ levelCode: string; label: string; price: number } | null> {
    const levels = await this.prisma.priceLevel.findMany({
      where: { catalogItemId, tenantId, isActive: true },
    });
    if (levels.length === 0) return null;

    let contactType: string | null = null;
    if (contactId) {
      const contact = await this.prisma.contact.findUnique({
        where: { id: contactId },
        select: { contactType: true },
      });
      contactType = contact?.contactType ?? null;
    }

    const eligible = levels.filter((pl) => {
      const qtyOk = pl.minQty == null || quantity >= pl.minQty;
      const typeOk =
        !pl.customerTypes || pl.customerTypes.length === 0 || (contactType != null && pl.customerTypes.includes(contactType));
      return qtyOk && typeOk;
    });

    if (eligible.length === 0) return null;

    // Pick cheapest
    const best = eligible.reduce((a, b) => (Number(a.price) < Number(b.price) ? a : b));
    return { levelCode: best.levelCode, label: best.label, price: Number(best.price) };
  }
}
