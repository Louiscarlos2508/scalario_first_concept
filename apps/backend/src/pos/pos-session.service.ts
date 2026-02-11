import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PosSessionService {
    constructor(private prisma: PrismaService) { }

    async openSession(data: { userId: string; tenantId: string; openingBalance: number }) {
        // Check if there is already an open session for this user/tenant
        const existingSession = await this.prisma.posSession.findFirst({
            where: {
                userId: data.userId,
                tenantId: data.tenantId,
                status: 'OPEN',
            },
        });

        if (existingSession) {
            throw new BadRequestException('An active session already exists for this user.');
        }

        return this.prisma.posSession.create({
            data: {
                userId: data.userId,
                tenantId: data.tenantId,
                openingBalance: new Prisma.Decimal(data.openingBalance),
                status: 'OPEN',
            },
        });
    }

    async closeSession(sessionId: string, closingBalance: number) {
        const session = await this.prisma.posSession.findUnique({
            where: { id: sessionId },
        });

        if (!session || session.status !== 'OPEN') {
            throw new BadRequestException('Session not found or already closed.');
        }

        const summary = await this.getSessionSummary(sessionId);
        const theoreticalBalance = summary.theoreticalCash;
        const variance = closingBalance - theoreticalBalance;

        return this.prisma.posSession.update({
            where: { id: sessionId },
            data: {
                closingBalance: new Prisma.Decimal(closingBalance),
                theoreticalBalance: new Prisma.Decimal(theoreticalBalance),
                variance: new Prisma.Decimal(variance),
                status: 'CLOSED',
                closedAt: new Date(),
            },
        });
    }

    async getActiveSession(userId: string, tenantId: string) {
        return this.prisma.posSession.findFirst({
            where: {
                userId,
                tenantId,
                status: 'OPEN',
            },
        });
    }

    async getSessionSummary(sessionId: string) {
        if (!this.isValidUuid(sessionId)) {
            throw new BadRequestException('Invalid session ID format.');
        }

        const session = await this.prisma.posSession.findUnique({
            where: { id: sessionId },
        });

        if (!session) {
            throw new BadRequestException('Session not found.');
        }

        const orders = await this.prisma.order.findMany({
            where: { sessionId },
        });

        // Group by payment method
        const totalsByMethod: Record<string, number> = {};
        let totalSales = 0;

        orders.forEach((order) => {
            const method = order.paymentMethod || 'UNKNOWN';
            const amount = order.totalAmount instanceof Prisma.Decimal
                ? order.totalAmount.toNumber()
                : Number(order.totalAmount);

            totalsByMethod[method] = (totalsByMethod[method] || 0) + (amount || 0);
            totalSales += (amount || 0);
        });

        const openingBalance = session.openingBalance instanceof Prisma.Decimal
            ? session.openingBalance.toNumber()
            : Number(session.openingBalance);

        return {
            session,
            totalsByMethod,
            totalSales,
            theoreticalCash: openingBalance + (totalsByMethod['CASH'] || 0),
        };
    }

    async syncSession(data: any) {
        const remoteId = data.remoteId || data.id;

        // If we have a remoteId and it's a valid UUID, we try to upsert
        if (remoteId && this.isValidUuid(remoteId)) {
            return this.prisma.posSession.upsert({
                where: { id: remoteId },
                update: {
                    openingBalance: data.openingBalance != null ? new Prisma.Decimal(data.openingBalance) : undefined,
                    closingBalance: data.closingBalance != null ? new Prisma.Decimal(data.closingBalance) : undefined,
                    status: data.status,
                    closedAt: data.closedAt ? new Date(data.closedAt) : null,
                },
                create: {
                    id: remoteId,
                    userId: data.userId,
                    tenantId: data.tenantId,
                    openingBalance: new Prisma.Decimal(data.openingBalance || 0),
                    closingBalance: data.closingBalance != null ? new Prisma.Decimal(data.closingBalance) : null,
                    status: data.status || 'OPEN',
                    openedAt: data.openedAt ? new Date(data.openedAt) : new Date(),
                    closedAt: data.closedAt ? new Date(data.closedAt) : null,
                },
            });
        }

        // Otherwise, we create a new session
        return this.prisma.posSession.create({
            data: {
                userId: data.userId,
                tenantId: data.tenantId,
                openingBalance: new Prisma.Decimal(data.openingBalance || 0),
                closingBalance: data.closingBalance != null ? new Prisma.Decimal(data.closingBalance) : null,
                status: data.status || 'OPEN',
                openedAt: data.openedAt ? new Date(data.openedAt) : new Date(),
                closedAt: data.closedAt ? new Date(data.closedAt) : null,
            },
        });
    }

    private isValidUuid(id: string): boolean {
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        return uuidRegex.test(id);
    }
}
