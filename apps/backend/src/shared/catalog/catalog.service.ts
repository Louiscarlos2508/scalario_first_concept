import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { PriceHistoryService } from './price-history/price-history.service';

const VALID_UNIT_TYPES = ['piece', 'weight', 'volume', 'length'] as const;

@Injectable()
export class CatalogService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLog: AuditLogService,
    private readonly priceHistoryService: PriceHistoryService,
  ) {}

  async getCategories(tenantId: string, since?: string) {
    const where: any = since
      ? { tenantId, createdAt: { gt: new Date(since) } }
      : { tenantId };
    return this.prisma.category.findMany({
      where,
      orderBy: { name: 'asc' },
    });
  }

  async createCategory(data: { name: string; tenantId: string }) {
    return this.prisma.category.create({
      data: {
        name: data.name,
        tenantId: data.tenantId,
      },
    });
  }

  async deleteCategory(id: string) {
    return this.prisma.category.delete({
      where: { id },
    });
  }

  async getItems(params: {
    tenantId?: string;
    query?: string;
    page?: number;
    limit?: number;
    since?: string;
  }) {
    const { tenantId, query, page = 1, limit = 100, since } = params;
    const skip = (page - 1) * limit;

    const where: any = since
      ? { updatedAt: { gt: new Date(since) } }
      : { isDeleted: false };

    if (tenantId) where.tenantId = tenantId;

    if (query) {
      where.OR = [
        { name: { contains: query, mode: 'insensitive' } },
        { barcode: { contains: query, mode: 'insensitive' } },
      ];
    }

    const serverTime = new Date().toISOString();

    const [items, total] = await Promise.all([
      this.prisma.catalogItem.findMany({
        where,
        orderBy: { updatedAt: 'asc' },
        skip,
        take: limit,
        include: {
          retailProduct: true,
          variants: { where: { isActive: true }, select: { stockQuantity: true } },
        },
      }),
      this.prisma.catalogItem.count({ where }),
    ]);

    const mappedItems = items.map((item) => {
      const { retailProduct, variants, ...rest } = item as any;
      // AC3 — aggregate stock from variants when hasVariants is true
      const totalStockQuantity = rest.hasVariants
        ? (variants as Array<{ stockQuantity: any }>).reduce((s, v) => s + Number(v.stockQuantity), 0)
        : null;
      return {
        ...rest,
        stockQuantity: retailProduct?.stockQuantity ?? null,
        weightUnit: retailProduct?.weightUnit ?? null,
        minStockLevel: retailProduct?.minStockLevel ?? null,
        ...(rest.hasVariants ? { totalStockQuantity } : {}),
      };
    });

    return {
      items: mappedItems,
      meta: {
        total,
        page,
        limit,
        hasMore: skip + items.length < total,
        serverTime,
      },
    };
  }

  // AC4 — Barcode lookup: check variant barcodes first
  async getByBarcode(barcode: string, tenantId: string) {
    // First try to find a variant with this barcode
    const variant = await this.prisma.productVariant.findFirst({
      where: { barcode, tenantId, isActive: true },
      include: { catalogItem: { include: { retailProduct: true } } },
    });

    if (variant) {
      const { catalogItem, ...variantRest } = variant as any;
      const { retailProduct, variants: _v, ...itemRest } = catalogItem as any;
      return {
        ...itemRest,
        stockQuantity: retailProduct?.stockQuantity ?? null,
        weightUnit: retailProduct?.weightUnit ?? null,
        minStockLevel: retailProduct?.minStockLevel ?? null,
        matchedVariant: {
          id: variantRest.id,
          attributes: variantRest.attributes,
          price: variantRest.price,
          stockQuantity: variantRest.stockQuantity,
          sku: variantRest.sku,
          barcode: variantRest.barcode,
        },
      };
    }

    // Fallback: find catalog item by barcode
    const item = await this.prisma.catalogItem.findFirst({
      where: { barcode, tenantId, isDeleted: false },
      include: { retailProduct: true },
    });
    if (!item) return null;

    const { retailProduct, ...rest } = item as any;
    return {
      ...rest,
      stockQuantity: retailProduct?.stockQuantity ?? null,
      weightUnit: retailProduct?.weightUnit ?? null,
      minStockLevel: retailProduct?.minStockLevel ?? null,
    };
  }

  async syncItems(items: Array<{ id: string; [key: string]: any }>) {
    return Promise.all(
      items.map((item) =>
        this.prisma.catalogItem.upsert({
          where: { id: item.id },
          update: item as unknown as Prisma.CatalogItemUpdateInput,
          create: item as unknown as Prisma.CatalogItemCreateInput,
        }),
      ),
    );
  }

  async createItem(
    data: {
      name: string;
      price: number | string;
      tenantId: string;
      barcode?: string;
      categoryId?: string;
      itemType?: string;
      unitType?: string;
      pricePerUnit?: number | null;
      conversionRate?: number | null;
      isUnique?: boolean;
      imageUrl?: string | null;
    },
    userId: string | null,
  ) {
    // Validate unitType
    const unitType = data.unitType ?? 'piece';
    if (!VALID_UNIT_TYPES.includes(unitType as any)) {
      throw new BadRequestException(
        `Invalid unitType '${unitType}'. Must be one of: ${VALID_UNIT_TYPES.join(', ')}`,
      );
    }

    const newItem = await this.prisma.catalogItem.create({
      data: {
        name: data.name,
        price: data.price,
        tenantId: data.tenantId,
        barcode: data.barcode,
        categoryId: data.categoryId,
        itemType: data.itemType ?? 'physical',
        unitType,
        pricePerUnit: data.pricePerUnit ?? null,
        conversionRate: data.conversionRate ?? null,
        isUnique: data.isUnique ?? false,
        imageUrl: data.imageUrl ?? null,
      },
    });

    await this.auditLog.log({
      tenantId: data.tenantId,
      userId,
      action: 'CREATE',
      entity: 'CatalogItem',
      entityId: newItem.id,
      before: null,
      after: {
        name: newItem.name,
        price: String(newItem.price),
        itemType: newItem.itemType,
        unitType: newItem.unitType,
        tenantId: newItem.tenantId,
      },
    });

    return newItem;
  }

  async updateItem(
    id: string,
    data: {
      name?: string;
      price?: number | string;
      barcode?: string;
      categoryId?: string;
      itemType?: string;
      unitType?: string;
      pricePerUnit?: number | null;
      conversionRate?: number | null;
      minStockLevel?: number | null;
      parentItemId?: string | null;
      // Epic 26 — Traçabilité
      trackSerialNumbers?: boolean;
      warrantyMonths?: number | null;
      requiresPrescription?: boolean;
      dynamicPricing?: boolean;
      isUnique?: boolean;
      imageUrl?: string | null;
      reason?: string; // for price history
    },
    userId: string | null,
    tenantId: string,
  ) {
    // Validate unitType if provided
    if (data.unitType !== undefined && !VALID_UNIT_TYPES.includes(data.unitType as any)) {
      throw new BadRequestException(
        `Invalid unitType '${data.unitType}'. Must be one of: ${VALID_UNIT_TYPES.join(', ')}`,
      );
    }

    // AC2 — Validate parent-child relationship
    if (data.parentItemId != null) {
      if (data.conversionRate != null && (data.conversionRate <= 0 || data.conversionRate > 1)) {
        throw new BadRequestException('conversionRate must be > 0 and ≤ 1 for child items');
      }

      const parent = await this.prisma.catalogItem.findUnique({
        where: { id: data.parentItemId },
        select: { id: true, tenantId: true, parentItemId: true },
      });
      if (!parent) throw new NotFoundException(`Parent item ${data.parentItemId} not found`);
      if (parent.tenantId !== tenantId) {
        throw new BadRequestException('Parent item must belong to the same tenant');
      }
      if (parent.parentItemId != null) {
        throw new BadRequestException('Parent item cannot itself be a child (max depth 1)');
      }
      if (data.parentItemId === id) {
        throw new BadRequestException('Circular reference: item cannot be its own parent');
      }
    }

    const updateData: any = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.price !== undefined) updateData.price = data.price;
    if (data.barcode !== undefined) updateData.barcode = data.barcode;
    if (data.categoryId !== undefined) updateData.categoryId = data.categoryId;
    if (data.itemType !== undefined) updateData.itemType = data.itemType;
    if (data.unitType !== undefined) updateData.unitType = data.unitType;
    if ('parentItemId' in data) updateData.parentItemId = data.parentItemId;
    if ('pricePerUnit' in data) updateData.pricePerUnit = data.pricePerUnit;
    if ('conversionRate' in data) updateData.conversionRate = data.conversionRate;
    // Epic 26 — Traçabilité fields
    if (data.trackSerialNumbers !== undefined) updateData.trackSerialNumbers = data.trackSerialNumbers;
    if ('warrantyMonths' in data) updateData.warrantyMonths = data.warrantyMonths;
    if (data.requiresPrescription !== undefined) updateData.requiresPrescription = data.requiresPrescription;
    if (data.dynamicPricing !== undefined) updateData.dynamicPricing = data.dynamicPricing;
    if (data.isUnique !== undefined) updateData.isUnique = data.isUnique;
    if ('imageUrl' in data) updateData.imageUrl = data.imageUrl;

    const updated = await this.prisma.catalogItem.update({
      where: { id },
      data: updateData,
      include: { retailProduct: true },
    });

    // AC2 (Story 26-5) — Record price history when dynamicPricing is enabled
    if (data.price !== undefined && updated.dynamicPricing) {
      await this.priceHistoryService.recordPrice(tenantId, id, Number(data.price), data.reason);
    }

    // minStockLevel lives on RetailProduct, not CatalogItem
    if ('minStockLevel' in data) {
      await this.prisma.retailProduct.upsert({
        where: { catalogItemId: id },
        update: { minStockLevel: data.minStockLevel ?? null },
        create: { catalogItemId: id, minStockLevel: data.minStockLevel ?? null },
      });
    }

    await this.auditLog.log({
      tenantId,
      userId,
      action: 'UPDATE',
      entity: 'CatalogItem',
      entityId: id,
      before: null,
      after: { ...updateData, minStockLevel: data.minStockLevel },
    });

    const { retailProduct, ...rest } = updated as any;
    return {
      ...rest,
      stockQuantity: retailProduct?.stockQuantity ?? null,
      minStockLevel: ('minStockLevel' in data ? data.minStockLevel : retailProduct?.minStockLevel) ?? null,
    };
  }

  /**
   * AC4 — Returns all child articles of a parent item for the given tenant.
   */
  async getChildren(parentId: string, tenantId: string) {
    return this.prisma.catalogItem.findMany({
      where: { parentItemId: parentId, tenantId, isDeleted: false },
      select: {
        id: true,
        name: true,
        unitType: true,
        pricePerUnit: true,
        conversionRate: true,
        parentItemId: true,
      },
    });
  }

  // AC4 (Story 26-6) — Duplicate a catalog item (copy, no stock/serials/price history)
  async duplicateCatalogItem(id: string, tenantId: string, userId: string | null) {
    const original = await this.prisma.catalogItem.findFirst({
      where: { id, tenantId },
    });
    if (!original) throw new NotFoundException(`Item ${id} not found`);

    const copy = await this.prisma.catalogItem.create({
      data: {
        name: `${original.name} (copie)`,
        price: original.price,
        tenantId: original.tenantId,
        barcode: null,
        categoryId: original.categoryId,
        itemType: original.itemType,
        unitType: original.unitType,
        pricePerUnit: original.pricePerUnit,
        conversionRate: original.conversionRate,
        trackSerialNumbers: original.trackSerialNumbers,
        warrantyMonths: original.warrantyMonths,
        requiresPrescription: original.requiresPrescription,
        dynamicPricing: original.dynamicPricing,
        isUnique: original.isUnique,
        imageUrl: original.imageUrl,
      },
    });

    await this.auditLog.log({
      tenantId,
      userId,
      action: 'CREATE',
      entity: 'CatalogItem',
      entityId: copy.id,
      before: null,
      after: { duplicatedFrom: id, name: copy.name },
    });

    return copy;
  }

  async deleteItem(id: string, userId: string | null, tenantId: string) {
    const updated = await this.prisma.catalogItem.update({
      where: { id },
      data: { isDeleted: true },
    });

    await this.auditLog.log({
      tenantId,
      userId,
      action: 'DELETE',
      entity: 'CatalogItem',
      entityId: id,
      before: { isDeleted: false },
      after: { isDeleted: true },
    });

    return updated;
  }

  /**
   * Apply conversionRate to a sale quantity.
   * If conversionRate is null/undefined, returns quantity unchanged.
   * Used by TransactionsService when creating inventory movements for weight/volume items.
   */
  applyConversionRate(quantity: number, conversionRate: number | null | undefined): number {
    if (conversionRate == null) return quantity;
    return quantity * conversionRate;
  }
}
