import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class PromotionsService {
  constructor(private readonly prisma: PrismaService) {}

  async createPromotion(
    tenantId: string,
    data: {
      type: string;
      scope: string;
      scopeId: string;
      value: Record<string, unknown>;
      startDate: string;
      endDate: string;
      conflictRule?: string;
    },
  ) {
    return this.prisma.promotion.create({
      data: {
        tenantId,
        type: data.type,
        scope: data.scope,
        scopeId: data.scopeId,
        value: data.value as Prisma.InputJsonValue,
        startDate: new Date(data.startDate),
        endDate: new Date(data.endDate),
        status: 'active',
        conflictRule: data.conflictRule ?? 'BEST',
      },
    });
  }

  async listPromotions(tenantId: string, filters?: { status?: string; type?: string }) {
    const where: any = { tenantId };
    if (filters?.status) where.status = filters.status;
    if (filters?.type) where.type = filters.type;
    return this.prisma.promotion.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
  }

  async updatePromotion(id: string, tenantId: string, data: Partial<{
    status: string;
    startDate: string;
    endDate: string;
    value: Record<string, unknown>;
    conflictRule: string;
  }>) {
    const promo = await this.prisma.promotion.findFirst({ where: { id, tenantId } });
    if (!promo) throw new NotFoundException(`Promotion ${id} not found`);

    const updateData: any = {};
    if (data.status !== undefined) updateData.status = data.status;
    if (data.startDate !== undefined) updateData.startDate = new Date(data.startDate);
    if (data.endDate !== undefined) updateData.endDate = new Date(data.endDate);
    if (data.value !== undefined) updateData.value = data.value;
    if (data.conflictRule !== undefined) updateData.conflictRule = data.conflictRule;

    return this.prisma.promotion.update({ where: { id }, data: updateData });
  }

  async deletePromotion(id: string, tenantId: string) {
    const promo = await this.prisma.promotion.findFirst({ where: { id, tenantId } });
    if (!promo) throw new NotFoundException(`Promotion ${id} not found`);
    return this.prisma.promotion.update({ where: { id }, data: { status: 'inactive' } });
  }

  async getActivePromotionsForItem(
    tenantId: string,
    catalogItemId: string,
    categoryId?: string | null,
  ) {
    const now = new Date();
    const promos = await this.prisma.promotion.findMany({
      where: {
        tenantId,
        status: 'active',
        startDate: { lte: now },
        endDate: { gte: now },
      },
    });
    return promos.filter(
      (p) =>
        (p.scope === 'ITEM' && p.scopeId === catalogItemId) ||
        (p.scope === 'CATEGORY' && categoryId && p.scopeId === categoryId),
    );
  }
}
