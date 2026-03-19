import { Controller, Get, Post, Param, Query, Req } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  // GET /notifications?tenantId=&unread=true&limit=&offset=
  @Get()
  @Roles('owner', 'manager')
  async getNotifications(
    @Req() req: any,
    @Query('tenantId') tenantId: string,
    @Query('unread') unread?: string,
    @Query('limit') limit = '50',
    @Query('offset') offset = '0',
  ) {
    const userId: string = req.user?.sub;
    return this.service.getUserNotifications(userId, tenantId, {
      unread: unread === 'true',
      limit: parseInt(limit),
      offset: parseInt(offset),
    });
  }

  // GET /notifications/unread-count?tenantId=
  @Get('unread-count')
  @Roles('owner', 'manager')
  async getUnreadCount(
    @Req() req: any,
    @Query('tenantId') tenantId: string,
  ) {
    const userId: string = req.user?.sub;
    const unreadCount = await this.service.getUnreadCount(userId, tenantId);
    return { unreadCount };
  }

  // POST /notifications/:id/read
  @Post(':id/read')
  @Roles('owner', 'manager')
  async markAsRead(@Param('id') id: string, @Req() req: any) {
    const userId: string = req.user?.sub;
    await this.service.markAsRead(id, userId);
    return { success: true };
  }
}
