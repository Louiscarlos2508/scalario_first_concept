import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Decimal } from '@prisma/client/runtime/library';
import { PrismaService } from '../../prisma/prisma.service';
import { InventoryService } from '../inventory/inventory.service';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { CompleteReservationDto } from './dto/complete-reservation.dto';
import { CancelReservationDto } from './dto/cancel-reservation.dto';

@Injectable()
export class ReservationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly inventoryService: InventoryService,
  ) {}

  async createReservation(tenantId: string, userId: string, dto: CreateReservationDto) {
    // Validate customer exists in tenant
    const contact = await this.prisma.contact.findFirst({
      where: { id: dto.customerId, tenantId },
    });
    if (!contact) {
      throw new NotFoundException('Client introuvable');
    }

    // Validate deposit range 10%–50%
    const minDeposit = dto.totalAmount * 0.1;
    const maxDeposit = dto.totalAmount * 0.5;
    if (dto.depositAmount < minDeposit || dto.depositAmount > maxDeposit) {
      throw new BadRequestException("L'acompte doit être compris entre 10 % et 50 % du total");
    }

    const remainingAmount = dto.totalAmount - dto.depositAmount;

    // Create transaction for deposit
    const depositTx = await this.prisma.transaction.create({
      data: {
        totalAmount: new Decimal(dto.depositAmount),
        itemsJson: dto.items as any,
        paymentMethod: dto.paymentMethod,
        transactionType: 'reservation_deposit',
        tenantId,
        createdBy: userId,
        customerId: dto.customerId,
      } as any,
    });

    const reservation = await this.prisma.reservation.create({
      data: {
        customerId: dto.customerId,
        itemsJson: dto.items as any,
        totalAmount: new Decimal(dto.totalAmount),
        depositAmount: new Decimal(dto.depositAmount),
        remainingAmount: new Decimal(remainingAmount),
        status: 'pending',
        depositTransactionId: depositTx.id,
        tenantId,
        createdBy: userId,
      },
    });

    return reservation;
  }

  async completeReservation(tenantId: string, id: string, dto: CompleteReservationDto) {
    const reservation = await this.prisma.reservation.findFirst({
      where: { id, tenantId },
    });
    if (!reservation) throw new NotFoundException('Réservation introuvable');
    if (reservation.status !== 'pending') {
      throw new BadRequestException('Cette réservation ne peut plus être modifiée');
    }
    if (dto.amount < Number(reservation.remainingAmount)) {
      throw new BadRequestException('Le montant est insuffisant pour solder la réservation');
    }

    // Create completion transaction
    const completionTx = await this.prisma.transaction.create({
      data: {
        totalAmount: new Decimal(dto.amount),
        itemsJson: reservation.itemsJson as any,
        paymentMethod: dto.paymentMethod,
        transactionType: 'reservation_completion',
        tenantId,
        customerId: reservation.customerId,
      } as any,
    });

    // Decrement stock for each reserved item
    const items = Array.isArray(reservation.itemsJson) ? (reservation.itemsJson as any[]) : [];
    for (const item of items) {
      await this.inventoryService.createMovement({
        type: 'SALE',
        quantity: Number(item.quantity ?? 1),
        catalogItemId: item.catalogItemId ?? null,
        variantId: item.variantId ?? null,
        tenantId,
        referenceId: reservation.id,
      });
    }

    return this.prisma.reservation.update({
      where: { id },
      data: {
        status: 'completed',
        completionTransactionId: completionTx.id,
        completedAt: new Date(),
      },
    });
  }

  async cancelReservation(
    tenantId: string,
    userId: string,
    id: string,
    dto: CancelReservationDto,
    userRole: string,
  ) {
    if (userRole !== 'manager' && userRole !== 'owner') {
      throw new ForbiddenException('Seuls les managers et owners peuvent annuler une réservation');
    }

    const reservation = await this.prisma.reservation.findFirst({
      where: { id, tenantId },
    });
    if (!reservation) throw new NotFoundException('Réservation introuvable');
    if (reservation.status !== 'pending') {
      throw new BadRequestException('Cette réservation ne peut plus être modifiée');
    }

    if (dto.depositResolution === 'credit_note') {
      await this.prisma.contact.update({
        where: { id: reservation.customerId },
        data: { balance: { increment: reservation.depositAmount } },
      });
    } else {
      // cash_refund — create audit transaction
      await this.prisma.transaction.create({
        data: {
          totalAmount: reservation.depositAmount,
          itemsJson: [],
          paymentMethod: 'cash_refund',
          transactionType: 'reservation_refund',
          tenantId,
          customerId: reservation.customerId,
        } as any,
      });
    }

    return this.prisma.reservation.update({
      where: { id },
      data: { status: 'cancelled' },
    });
  }

  async listReservations(
    tenantId: string,
    params: { status?: string; customerId?: string; page?: number; limit?: number },
  ) {
    const { status, customerId, page = 1, limit = 20 } = params;
    const skip = (page - 1) * limit;

    const where: any = { tenantId };
    if (status) where.status = status;
    if (customerId) where.customerId = customerId;

    const [items, total] = await Promise.all([
      this.prisma.reservation.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.reservation.count({ where }),
    ]);

    return { items, meta: { total, page, limit, hasMore: skip + items.length < total } };
  }

  async getKpi(tenantId: string) {
    const [pendingCount, aggregate] = await Promise.all([
      this.prisma.reservation.count({ where: { tenantId, status: 'pending' } }),
      this.prisma.reservation.aggregate({
        where: { tenantId, status: 'pending' },
        _sum: { depositAmount: true },
      }),
    ]);

    return {
      pendingCount,
      totalDepositAmount: Number(aggregate._sum.depositAmount ?? 0),
    };
  }
}
