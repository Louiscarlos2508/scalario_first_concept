import { Test, TestingModule } from '@nestjs/testing';
import { AdminMonitoringService } from './admin-monitoring.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('AdminMonitoringService', () => {
  let service: AdminMonitoringService;

  const mockTenant = (overrides: Partial<{
    id: string;
    name: string;
    status: string;
    createdAt: Date;
    _count: { members: number };
    auditLogs: { createdAt: Date }[];
  }> = {}) => ({
    id: 'tenant-uuid-1',
    name: 'Boutique Test',
    status: 'active',
    createdAt: new Date('2026-01-01'),
    _count: { members: 3 },
    auditLogs: [{ createdAt: new Date('2026-03-15') }],
    ...overrides,
  });

  const mockPrismaService = {
    tenant: {
      findMany: jest.fn(),
    },
    organizationMember: {
      findMany: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.resetAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminMonitoringService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<AdminMonitoringService>(AdminMonitoringService);
  });

  describe('getHealth()', () => {
    it('returns activeTenants count (only status=active)', async () => {
      mockPrismaService.tenant.findMany.mockResolvedValue([
        mockTenant({ id: 't-1', status: 'active' }),
        mockTenant({ id: 't-2', status: 'active' }),
        mockTenant({ id: 't-3', status: 'suspended' }),
      ]);
      mockPrismaService.organizationMember.findMany.mockResolvedValue([
        { userId: 'u-1' },
        { userId: 'u-2' },
      ]);

      const result = await service.getHealth();
      expect(result.activeTenants).toBe(2);
    });

    it('returns totalUsers as distinct user count', async () => {
      mockPrismaService.tenant.findMany.mockResolvedValue([]);
      mockPrismaService.organizationMember.findMany.mockResolvedValue([
        { userId: 'u-1' },
        { userId: 'u-2' },
        { userId: 'u-3' },
      ]);

      const result = await service.getHealth();
      expect(result.totalUsers).toBe(3);
    });

    it('maps tenant fields correctly', async () => {
      const createdAt = new Date('2026-01-10');
      const lastActivity = new Date('2026-03-15');
      mockPrismaService.tenant.findMany.mockResolvedValue([
        mockTenant({
          id: 'tenant-abc',
          name: 'Boutique Koné',
          status: 'active',
          createdAt,
          _count: { members: 5 },
          auditLogs: [{ createdAt: lastActivity }],
        }),
      ]);
      mockPrismaService.organizationMember.findMany.mockResolvedValue([{ userId: 'u-1' }]);

      const result = await service.getHealth();
      const tenant = result.tenants[0];
      expect(tenant.id).toBe('tenant-abc');
      expect(tenant.name).toBe('Boutique Koné');
      expect(tenant.status).toBe('active');
      expect(tenant.createdAt).toBe(createdAt);
      expect(tenant.membersCount).toBe(5);
      expect(tenant.lastActivityAt).toBe(lastActivity);
    });

    it('sets lastActivityAt to null when no audit logs', async () => {
      mockPrismaService.tenant.findMany.mockResolvedValue([
        mockTenant({ auditLogs: [] }),
      ]);
      mockPrismaService.organizationMember.findMany.mockResolvedValue([]);

      const result = await service.getHealth();
      expect(result.tenants[0].lastActivityAt).toBeNull();
    });

    it('always returns failedMutationsCount = 0 (MVP placeholder)', async () => {
      mockPrismaService.tenant.findMany.mockResolvedValue([
        mockTenant(),
        mockTenant({ id: 't-2', name: 'Shop 2' }),
      ]);
      mockPrismaService.organizationMember.findMany.mockResolvedValue([]);

      const result = await service.getHealth();
      result.tenants.forEach((t) => {
        expect(t.failedMutationsCount).toBe(0);
      });
    });

    it('returns empty tenants list when no tenants', async () => {
      mockPrismaService.tenant.findMany.mockResolvedValue([]);
      mockPrismaService.organizationMember.findMany.mockResolvedValue([]);

      const result = await service.getHealth();
      expect(result.activeTenants).toBe(0);
      expect(result.totalUsers).toBe(0);
      expect(result.tenants).toHaveLength(0);
    });
  });
});
