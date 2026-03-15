import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';

@Injectable()
export class CatalogService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLog: AuditLogService,
  ) {}

  async getCategories(tenantId: string, since?: string) {
    const where: any = since
      ? { tenantId, updatedAt: { gt: new Date(since) } }
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
        include: { retailProduct: true },
      }),
      this.prisma.catalogItem.count({ where }),
    ]);

    const mappedItems = items.map((item) => {
      const { retailProduct, ...rest } = item as any;
      return {
        ...rest,
        stockQuantity: retailProduct?.stockQuantity ?? null,
        weightUnit: retailProduct?.weightUnit ?? null,
        minStockLevel: retailProduct?.minStockLevel ?? null,
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

  async syncItems(items: Array<{ id: string; [key: string]: any }>) {
    return Promise.all(
      items.map((item) =>
        this.prisma.catalogItem.upsert({
          where: { id: item.id },
          update: item,
          create: item,
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
    },
    userId: string | null,
  ) {
    const newItem = await this.prisma.catalogItem.create({
      data: {
        name: data.name,
        price: data.price,
        tenantId: data.tenantId,
        barcode: data.barcode,
        categoryId: data.categoryId,
        itemType: data.itemType ?? 'physical',
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
        tenantId: newItem.tenantId,
      },
    });

    return newItem;
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
}
