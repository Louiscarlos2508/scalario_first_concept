import { Test, TestingModule } from '@nestjs/testing';
import { PermissionService } from './permission.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('PermissionService', () => {
  let service: PermissionService;

  const mockPrismaService = {
    organizationMember: {
      findUnique: jest.fn(),
    },
  };

  const validUserId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  const validTenantId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';

  const ownerMember = {
    id: 'member-1',
    organizationId: validTenantId,
    userId: validUserId,
    roleId: 'role-owner',
    role: {
      id: 'role-owner',
      name: 'owner',
      vertical: 'retail',
      permissions: [
        { permission: { id: 'perm-1', code: 'catalog.edit', module: 'catalog', description: 'Edit catalog' } },
        { permission: { id: 'perm-2', code: 'catalog.price_modify', module: 'catalog', description: 'Modify prices' } },
        { permission: { id: 'perm-3', code: 'users.manage', module: 'kernel', description: 'Manage users' } },
      ],
    },
  };

  const commercialMember = {
    id: 'member-2',
    organizationId: validTenantId,
    userId: 'commercial-user-id',
    roleId: 'role-commercial',
    role: {
      id: 'role-commercial',
      name: 'commercial',
      vertical: 'retail',
      permissions: [
        { permission: { id: 'perm-4', code: 'session.open', module: 'pos', description: 'Open session' } },
        { permission: { id: 'perm-5', code: 'sales.process', module: 'pos', description: 'Process sales' } },
      ],
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PermissionService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<PermissionService>(PermissionService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getUserRoleName', () => {
    it('should return the role name for a member', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(ownerMember);

      const result = await service.getUserRoleName(validUserId, validTenantId);

      expect(result).toBe('owner');
      expect(mockPrismaService.organizationMember.findUnique).toHaveBeenCalledWith({
        where: {
          organizationId_userId: { organizationId: validTenantId, userId: validUserId },
        },
        include: { role: true },
      });
    });

    it('should return null when user is not a member', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(null);

      const result = await service.getUserRoleName(validUserId, validTenantId);

      expect(result).toBeNull();
    });

    it('should return commercial role name correctly', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(commercialMember);

      const result = await service.getUserRoleName('commercial-user-id', validTenantId);

      expect(result).toBe('commercial');
    });
  });

  describe('hasPermission', () => {
    it('should return true when user has the permission', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(ownerMember);

      const result = await service.hasPermission(validUserId, validTenantId, 'catalog.edit');

      expect(result).toBe(true);
    });

    it('should return false when user does not have the permission', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(ownerMember);

      // Owner doesn't have session.open
      const result = await service.hasPermission(validUserId, validTenantId, 'session.open');

      expect(result).toBe(false);
    });

    it('should return false when user is not a member', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(null);

      const result = await service.hasPermission(validUserId, validTenantId, 'catalog.edit');

      expect(result).toBe(false);
    });

    it('should return true for commercial user with session.open', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(commercialMember);

      const result = await service.hasPermission('commercial-user-id', validTenantId, 'session.open');

      expect(result).toBe(true);
    });

    it('should return false for commercial user attempting catalog.price_modify', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(commercialMember);

      const result = await service.hasPermission('commercial-user-id', validTenantId, 'catalog.price_modify');

      expect(result).toBe(false);
    });

    it('should include role permissions in the Prisma query', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(ownerMember);

      await service.hasPermission(validUserId, validTenantId, 'catalog.edit');

      expect(mockPrismaService.organizationMember.findUnique).toHaveBeenCalledWith({
        where: {
          organizationId_userId: { organizationId: validTenantId, userId: validUserId },
        },
        include: {
          role: {
            include: {
              permissions: {
                include: { permission: true },
              },
            },
          },
        },
      });
    });
  });
});
