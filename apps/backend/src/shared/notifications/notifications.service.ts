import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationDto } from './dto/notification.dto';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  @OnEvent('LowStockDetected')
  async onLowStockDetected(payload: {
    tenantId: string;
    catalogItemId: string;
    itemName: string;
    stockQuantity: number;
    minStockLevel: number;
  }) {
    const { tenantId, catalogItemId, itemName, stockQuantity, minStockLevel } = payload;

    // Find all owner/manager roles for the retail vertical
    const roles = await this.prisma.role.findMany({
      where: { name: { in: ['owner', 'manager'] }, vertical: 'retail' },
      select: { id: true },
    });
    const roleIds = roles.map((r) => r.id);

    // Find members of this tenant with those roles
    const members = await this.prisma.organizationMember.findMany({
      where: { organizationId: tenantId, roleId: { in: roleIds } },
      select: { userId: true },
    });

    if (members.length === 0) return;

    const title = 'Stock critique';
    const body = `${itemName} — il reste ${stockQuantity} unité(s) (seuil : ${minStockLevel})`;

    await this.prisma.notification.createMany({
      data: members.map((m) => ({
        tenantId,
        userId: m.userId,
        type: 'low_stock',
        title,
        body,
        targetId: catalogItemId,
      })),
      skipDuplicates: true,
    });
  }

  async getUserNotifications(
    userId: string,
    tenantId: string,
    params: { unread?: boolean; limit?: number; offset?: number } = {},
  ): Promise<NotificationDto[]> {
    const { unread, limit = 50, offset = 0 } = params;
    const where: any = { userId, tenantId };
    if (unread) where.isRead = false;

    const rows = await this.prisma.notification.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });

    return rows.map((r) => ({
      id: r.id,
      title: r.title,
      body: r.body,
      type: r.type,
      targetId: r.targetId,
      createdAt: r.createdAt,
      isRead: r.isRead,
    }));
  }

  async markAsRead(id: string, userId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true },
    });
  }

  async getUnreadCount(userId: string, tenantId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { userId, tenantId, isRead: false },
    });
  }
}
