import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class VariantsService {
  constructor(private readonly prisma: PrismaService) {}

  async createVariant(
    catalogItemId: string,
    tenantId: string,
    data: {
      sku?: string;
      barcode?: string;
      price: number | string;
      stockQuantity?: number | string;
      attributes?: Record<string, unknown>;
    },
  ) {
    const item = await this.prisma.catalogItem.findUnique({ where: { id: catalogItemId } });
    if (!item || item.tenantId !== tenantId) {
      throw new NotFoundException(`CatalogItem ${catalogItemId} not found`);
    }

    const variant = await this.prisma.productVariant.create({
      data: {
        catalogItemId,
        tenantId,
        sku: data.sku ?? null,
        barcode: data.barcode ?? null,
        price: data.price,
        stockQuantity: data.stockQuantity ?? 0,
        attributes: (data.attributes ?? {}) as any,
      },
    });

    // AC2 — Set hasVariants = true on parent if first active variant
    await this.prisma.catalogItem.update({
      where: { id: catalogItemId },
      data: { hasVariants: true },
    });

    return variant;
  }

  async getVariants(catalogItemId: string, tenantId: string) {
    return this.prisma.productVariant.findMany({
      where: { catalogItemId, tenantId, isActive: true },
      orderBy: { createdAt: 'asc' },
    });
  }

  async updateVariant(
    catalogItemId: string,
    variantId: string,
    tenantId: string,
    data: {
      sku?: string;
      barcode?: string;
      price?: number | string;
      stockQuantity?: number | string;
      attributes?: Record<string, unknown>;
    },
  ) {
    const variant = await this.prisma.productVariant.findFirst({
      where: { id: variantId, catalogItemId, tenantId },
    });
    if (!variant) throw new NotFoundException(`Variant ${variantId} not found`);

    const updateData: any = {};
    if (data.sku !== undefined) updateData.sku = data.sku;
    if (data.barcode !== undefined) updateData.barcode = data.barcode;
    if (data.price !== undefined) updateData.price = data.price;
    if (data.stockQuantity !== undefined) updateData.stockQuantity = data.stockQuantity;
    if (data.attributes !== undefined) updateData.attributes = data.attributes;

    return this.prisma.productVariant.update({ where: { id: variantId }, data: updateData });
  }

  async deleteVariant(catalogItemId: string, variantId: string, tenantId: string) {
    const variant = await this.prisma.productVariant.findFirst({
      where: { id: variantId, catalogItemId, tenantId },
    });
    if (!variant) throw new NotFoundException(`Variant ${variantId} not found`);

    const updated = await this.prisma.productVariant.update({
      where: { id: variantId },
      data: { isActive: false },
    });

    // If no active variants remain, reset hasVariants on parent
    const remaining = await this.prisma.productVariant.count({
      where: { catalogItemId, tenantId, isActive: true },
    });
    if (remaining === 0) {
      await this.prisma.catalogItem.update({
        where: { id: catalogItemId },
        data: { hasVariants: false },
      });
    }

    return updated;
  }
}
