import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface TenantHealthDto {
  id: string;
  name: string;
  status: string;
  createdAt: Date;
  membersCount: number;
  lastActivityAt: Date | null;
  failedMutationsCount: number;
}

export interface MonitoringHealthDto {
  activeTenants: number;
  totalUsers: number;
  tenants: TenantHealthDto[];
}

@Injectable()
export class AdminMonitoringService {
  constructor(private readonly prisma: PrismaService) {}

  async getHealth(): Promise<MonitoringHealthDto> {
    const [tenants, distinctMembers] = await Promise.all([
      this.prisma.tenant.findMany({
        include: {
          _count: { select: { members: true } },
          auditLogs: {
            orderBy: { createdAt: 'desc' },
            take: 1,
            select: { createdAt: true },
          },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.organizationMember.findMany({
        select: { userId: true },
        distinct: ['userId'],
      }),
    ]);

    const activeTenants = tenants.filter((t) => t.status === 'active').length;
    const totalUsers = distinctMembers.length;

    return {
      activeTenants,
      totalUsers,
      tenants: tenants.map((t) => ({
        id: t.id,
        name: t.name,
        status: t.status,
        createdAt: t.createdAt,
        membersCount: t._count.members,
        lastActivityAt: t.auditLogs[0]?.createdAt ?? null,
        // TODO: implémenter quand outbox server-side existe
        failedMutationsCount: 0,
      })),
    };
  }
}
