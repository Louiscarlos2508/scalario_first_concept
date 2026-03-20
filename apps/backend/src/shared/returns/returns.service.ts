import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Decimal } from '@prisma/client/runtime/library';
import { PrismaService } from '../../prisma/prisma.service';
import { InventoryService } from '../inventory/inventory.service';
import { CreateReturnDto } from './dto/create-return.dto';

@Injectable()
export class ReturnsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly inventoryService: InventoryService,
  ) {}

  async createReturn(
    tenantId: string,
    userId: string,
    dto: CreateReturnDto,
  ) {
    // Validate return policy (delay window)
    if (dto.originalTxId) {
      const tenant = await this.prisma.tenant.findUnique({
        where: { id: tenantId },
        select: { returnPolicyDays: true, returnRequiresReason: true },
      });

      const tx = await this.prisma.transaction.findFirst({
        where: { id: dto.originalTxId, tenantId },
      });
      if (!tx) {
        throw new NotFoundException('Transaction originale introuvable');
      }

      const policyDays = tenant?.returnPolicyDays ?? 30;
      const ageMs = Date.now() - tx.createdAt.getTime();
      const ageDays = ageMs / (1000 * 60 * 60 * 24);
      if (ageDays > policyDays) {
        throw new BadRequestException(
          `Le délai de retour est dépassé (politique : ${policyDays} jours)`,
        );
      }

      if (tenant?.returnRequiresReason && (!dto.reason || dto.reason.trim() === '')) {
        throw new BadRequestException('Le motif du retour est obligatoire');
      }
    }

    // Create return record
    const returnRecord = await this.prisma.returnRecord.create({
      data: {
        originalTxId: dto.originalTxId ?? null,
        catalogItemId: dto.catalogItemId,
        variantId: dto.variantId ?? null,
        quantity: dto.quantity,
        unitPrice: dto.unitPrice,
        resolution: dto.resolution,
        reason: dto.reason ?? null,
        tenantId,
        createdBy: userId,
      },
    });

    // Reinstate stock
    await this.inventoryService.createMovement({
      type: 'RETURN',
      quantity: dto.quantity,
      catalogItemId: dto.catalogItemId,
      variantId: dto.variantId ?? null,
      reason: dto.reason ?? 'RETURN',
      tenantId,
      userId,
      referenceId: returnRecord.id,
    });

    // If credit_note: increment contact balance
    if (dto.resolution === 'credit_note' && dto.originalTxId) {
      const tx = await this.prisma.transaction.findFirst({
        where: { id: dto.originalTxId, tenantId },
        select: { customerId: true },
      });
      if (tx?.customerId) {
        const refundAmount = new Decimal(dto.quantity).mul(new Decimal(dto.unitPrice));
        await this.prisma.contact.update({
          where: { id: tx.customerId },
          data: { balance: { increment: refundAmount } },
        });
      }
    }

    return returnRecord;
  }

  async listReturns(
    tenantId: string,
    params: { page?: number; limit?: number; originalTxId?: string },
  ) {
    const { page = 1, limit = 20, originalTxId } = params;
    const skip = (page - 1) * limit;

    const where: any = { tenantId };
    if (originalTxId) where.originalTxId = originalTxId;

    const [items, total] = await Promise.all([
      this.prisma.returnRecord.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.returnRecord.count({ where }),
    ]);

    return {
      items,
      meta: { total, page, limit, hasMore: skip + items.length < total },
    };
  }

  async getReturnsSummaryForSession(
    tenantId: string,
    openedAt: Date,
    closedAt: Date,
  ): Promise<{ count: number; amount: Decimal; cashRefundAmount: Decimal }> {
    const records = await this.prisma.returnRecord.findMany({
      where: {
        tenantId,
        createdAt: { gte: openedAt, lte: closedAt },
      },
      select: { quantity: true, unitPrice: true, resolution: true },
    });

    let amount = new Decimal(0);
    let cashRefundAmount = new Decimal(0);

    for (const r of records) {
      const lineAmount = new Decimal(r.quantity).mul(new Decimal(r.unitPrice));
      amount = amount.add(lineAmount);
      if (r.resolution === 'cash_refund') {
        cashRefundAmount = cashRefundAmount.add(lineAmount);
      }
    }

    return { count: records.length, amount, cashRefundAmount };
  }
}
