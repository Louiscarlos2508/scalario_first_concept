import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../../prisma/prisma.service';
import { NotificationsService } from '../notifications.service';
import { StockAlertsService } from '../../stock-alerts/stock-alerts.service';

@Injectable()
export class DailySummaryJob {
  private readonly logger = new Logger(DailySummaryJob.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly stockAlerts: StockAlertsService,
  ) {}

  /**
   * Runs every minute. Evaluates which tenants are due for their daily summary
   * and sends an in-app notification to all owners.
   */
  @Cron('* * * * *', { name: 'daily-summary-job' })
  async run() {
    const now = new Date();
    const todayDate = now.toISOString().slice(0, 10); // YYYY-MM-DD

    const tenants = await this.prisma.tenant.findMany({
      where: { dailySummaryEnabled: true },
      select: {
        id: true,
        timezone: true,
        dailySummaryTime: true,
        notificationChannel: true,
        lastSummarySentDate: true,
      },
    });

    for (const tenant of tenants) {
      try {
        // Idempotence check — only once per day
        if (tenant.lastSummarySentDate) {
          const lastSent = tenant.lastSummarySentDate.toISOString().slice(0, 10);
          if (lastSent === todayDate) continue;
        }

        // Timezone-aware hour:minute check
        const localTime = now.toLocaleTimeString('fr-FR', {
          timeZone: tenant.timezone,
          hour: '2-digit',
          minute: '2-digit',
          hour12: false,
        });
        if (localTime !== tenant.dailySummaryTime) continue;

        await this.sendSummary(tenant.id, tenant.notificationChannel);

        await this.prisma.tenant.update({
          where: { id: tenant.id },
          data: { lastSummarySentDate: now },
        });
      } catch (err) {
        this.logger.error(`DailySummaryJob failed for tenant ${tenant.id}: ${err}`);
      }
    }
  }

  private async sendSummary(tenantId: string, channel: string) {
    if (channel === 'whatsapp') {
      this.logger.warn('WhatsApp channel not yet implemented — fallback to in_app');
    }

    // Collect metrics
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [transactionCount, totalRevenueRows, alertCount, pendingPOs] = await Promise.all([
      this.prisma.transaction.count({ where: { tenantId, createdAt: { gte: today } } }),
      this.prisma.transaction.aggregate({
        where: { tenantId, createdAt: { gte: today } },
        _sum: { totalAmount: true },
      }),
      this.stockAlerts.getAlertsCount(tenantId),
      this.prisma.purchaseOrder.count({ where: { tenantId, status: { in: ['draft', 'confirmed', 'partially_received'] } } }),
    ]);

    const totalRevenue = Number(totalRevenueRows._sum?.totalAmount ?? 0);
    const body =
      `Ventes : ${transactionCount} — CA : ${totalRevenue.toFixed(0)} FCFA` +
      ` | Stock critique : ${alertCount}` +
      ` | Commandes en attente : ${pendingPOs}`;

    // Find owners for this tenant
    const ownerRole = await this.prisma.role.findUnique({
      where: { name_vertical: { name: 'owner', vertical: 'retail' } },
    });
    if (!ownerRole) return;

    const members = await this.prisma.organizationMember.findMany({
      where: { organizationId: tenantId, roleId: ownerRole.id },
      select: { userId: true },
    });
    if (members.length === 0) return;

    await this.prisma.notification.createMany({
      data: members.map((m) => ({
        tenantId,
        userId: m.userId,
        type: 'daily_summary',
        title: 'Résumé quotidien',
        body,
      })),
      skipDuplicates: true,
    });

    this.logger.log(`Daily summary sent for tenant ${tenantId}`);
  }
}
