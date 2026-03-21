import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class BillingSchedulerService {
  private readonly logger = new Logger(BillingSchedulerService.name);

  constructor(private readonly prisma: PrismaService) {}

  @Cron('0 1 * * *', { name: 'billing-status-check', timeZone: 'UTC' })
  async runBillingStatusCheck() {
    await this.checkTrialExpiry();
    await this.checkSubscriptionExpiry();
    await this.checkOverdueSuspension();
  }

  async checkTrialExpiry() {
    const expired = await this.prisma.tenant.findMany({
      where: {
        billingStatus: 'trial',
        trialEndsAt: { lt: new Date() },
      },
      select: { id: true },
    });

    if (expired.length === 0) return;

    await this.prisma.tenant.updateMany({
      where: { id: { in: expired.map((t) => t.id) } },
      data: { billingStatus: 'overdue', overdueAt: new Date() },
    });

    this.logger.log(`Trial → overdue: ${expired.length} tenants`);
  }

  async checkSubscriptionExpiry() {
    const now = new Date();

    // Active tenants whose paidUntil has passed → overdue
    const expired = await (this.prisma as any).tenant.findMany({
      where: {
        billingStatus: 'active',
        paidUntil: { lt: now },
      },
      select: { id: true, name: true },
    });

    if (expired.length > 0) {
      await this.prisma.tenant.updateMany({
        where: { id: { in: expired.map((t) => t.id) } },
        data: { billingStatus: 'overdue', overdueAt: now },
      });

      await (this.prisma as any).billingEvent.createMany({
        data: expired.map((t) => ({
          tenantId: t.id,
          type: 'subscription_expired',
          amount: '0',
          description: "Abonnement expiré — en attente de renouvellement",
          status: 'completed',
        })),
      });

      this.logger.log(`Subscription expired → overdue: ${expired.length} tenants`);
    }
  }

  async checkOverdueSuspension() {
    const graceDays = parseInt(process.env.BILLING_GRACE_DAYS ?? '14', 10);
    const cutoff = new Date(Date.now() - graceDays * 24 * 60 * 60 * 1000);

    const overdue = await this.prisma.tenant.findMany({
      where: {
        billingStatus: 'overdue',
        overdueAt: { lt: cutoff },
      },
      select: { id: true },
    });

    if (overdue.length === 0) return;

    await this.prisma.tenant.updateMany({
      where: { id: { in: overdue.map((t) => t.id) } },
      data: { billingStatus: 'suspended' },
    });

    await (this.prisma as any).billingEvent.createMany({
      data: overdue.map((t) => ({
        tenantId: t.id,
        type: 'payment',
        amount: '0',
        status: 'overdue',
        description: `Suspension automatique — impayé > ${graceDays}j`,
      })),
    });

    this.logger.log(`Overdue → suspended: ${overdue.length} tenants`);
  }
}
