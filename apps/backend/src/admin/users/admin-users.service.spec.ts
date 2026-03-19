import {
  BadRequestException,
  InternalServerErrorException,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { AdminUsersService } from './admin-users.service';
import { PrismaService } from '../../prisma/prisma.service';
import { SupabaseAdminService } from '../services/supabase-admin.service';

describe('AdminUsersService', () => {
  let service: AdminUsersService;

  const mockTenantId = 'tenant-uuid-1234';
  const mockUserId = 'user-uuid-5678';

  const ownerRole = { id: 'role-owner-uuid', name: 'owner', vertical: 'retail' };
  const managerRole = { id: 'role-manager-uuid', name: 'manager', vertical: 'retail' };
  const cashierRole = { id: 'role-cashier-uuid', name: 'cashier', vertical: 'retail' };

  const mockMember = {
    id: 'member-uuid',
    organizationId: mockTenantId,
    userId: mockUserId,
    roleId: ownerRole.id,
    createdAt: new Date('2026-01-01'),
    role: ownerRole,
  };

  const mockPrismaService = {
    organizationMember: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      count: jest.fn(),
    },
    role: {
      findUnique: jest.fn(),
    },
  };

  const mockSupabaseAdminService = {
    createUser: jest.fn(),
    getUserById: jest.fn(),
    deleteUser: jest.fn(),
    banUser: jest.fn(),
  };

  beforeEach(async () => {
    jest.resetAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminUsersService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: SupabaseAdminService, useValue: mockSupabaseAdminService },
      ],
    }).compile();

    service = module.get<AdminUsersService>(AdminUsersService);
  });

  // ─── createUser ──────────────────────────────────────────────────────────────

  describe('createUser', () => {
    it('should throw 400 when role is invalid', async () => {
      await expect(
        service.createUser(mockTenantId, { email: 'a@b.com', password: 'pass1234', role: 'superadmin' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw 422 EMAIL_ALREADY_EXISTS when Supabase reports duplicate email', async () => {
      mockSupabaseAdminService.createUser.mockRejectedValue(
        new Error('User already registered'),
      );

      await expect(
        service.createUser(mockTenantId, { email: 'dup@example.com', password: 'pass1234', role: 'owner' }),
      ).rejects.toThrow(UnprocessableEntityException);

      try {
        await service.createUser(mockTenantId, { email: 'dup@example.com', password: 'pass1234', role: 'owner' });
      } catch (e: any) {
        expect(e.response).toMatchObject({ error: 'EMAIL_ALREADY_EXISTS' });
      }
    });

    it('should create user and return 201 payload', async () => {
      mockSupabaseAdminService.createUser.mockResolvedValue(mockUserId);
      mockPrismaService.role.findUnique.mockResolvedValue(managerRole);
      mockPrismaService.organizationMember.create.mockResolvedValue({
        ...mockMember,
        role: managerRole,
      });

      const result = await service.createUser(mockTenantId, {
        email: 'manager@example.com',
        password: 'pass1234',
        role: 'manager',
      });

      expect(mockSupabaseAdminService.createUser).toHaveBeenCalledWith('manager@example.com', 'pass1234');
      expect(mockPrismaService.role.findUnique).toHaveBeenCalledWith({
        where: { name_vertical: { name: 'manager', vertical: 'retail' } },
      });
      expect(mockPrismaService.organizationMember.create).toHaveBeenCalled();
      expect(result).toMatchObject({ userId: mockUserId, email: 'manager@example.com', role: 'manager' });
    });

    it('should rollback Supabase user on Prisma P2002 (duplicate member)', async () => {
      mockSupabaseAdminService.createUser.mockResolvedValue(mockUserId);
      mockPrismaService.role.findUnique.mockResolvedValue(ownerRole);
      const p2002Error: any = new Error('Unique constraint failed');
      p2002Error.code = 'P2002';
      mockPrismaService.organizationMember.create.mockRejectedValue(p2002Error);
      mockSupabaseAdminService.deleteUser.mockResolvedValue(undefined);

      await expect(
        service.createUser(mockTenantId, { email: 'dup@example.com', password: 'pass1234', role: 'owner' }),
      ).rejects.toThrow(UnprocessableEntityException);

      expect(mockSupabaseAdminService.deleteUser).toHaveBeenCalledWith(mockUserId);
    });
  });

  // ─── listUsers ───────────────────────────────────────────────────────────────

  describe('listUsers', () => {
    it('should return members enriched with Supabase email and lastSignInAt', async () => {
      mockPrismaService.organizationMember.findMany.mockResolvedValue([mockMember]);
      mockSupabaseAdminService.getUserById.mockResolvedValue({
        email: 'owner@example.com',
        lastSignInAt: '2026-02-01T10:00:00Z',
      });

      const result = await service.listUsers(mockTenantId);

      expect(mockPrismaService.organizationMember.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { organizationId: mockTenantId } }),
      );
      expect(mockSupabaseAdminService.getUserById).toHaveBeenCalledWith(mockUserId);
      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        userId: mockUserId,
        email: 'owner@example.com',
        role: 'owner',
        lastSignInAt: '2026-02-01T10:00:00Z',
      });
    });
  });

  // ─── updateUserRole ──────────────────────────────────────────────────────────

  describe('updateUserRole', () => {
    it('should throw 404 when member does not exist', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(null);

      await expect(
        service.updateUserRole(mockTenantId, mockUserId, 'manager'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw 400 when role is invalid', async () => {
      await expect(
        service.updateUserRole(mockTenantId, mockUserId, 'superadmin'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should update role and return updated member', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(mockMember);
      mockPrismaService.role.findUnique.mockResolvedValue(cashierRole);
      mockPrismaService.organizationMember.update.mockResolvedValue({
        ...mockMember,
        roleId: cashierRole.id,
        role: cashierRole,
      });
      mockSupabaseAdminService.getUserById.mockResolvedValue({
        email: 'owner@example.com',
        lastSignInAt: null,
      });

      const result = await service.updateUserRole(mockTenantId, mockUserId, 'cashier');

      expect(mockPrismaService.organizationMember.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { organizationId_userId: { organizationId: mockTenantId, userId: mockUserId } },
          data: { roleId: cashierRole.id },
        }),
      );
      expect(result).toMatchObject({ userId: mockUserId, role: 'cashier' });
    });
  });

  // ─── removeUser ──────────────────────────────────────────────────────────────

  describe('removeUser', () => {
    it('should throw 404 when member does not exist', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(null);

      await expect(
        service.removeUser(mockTenantId, mockUserId),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw 422 CANNOT_REMOVE_LAST_OWNER when removing the last owner', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(mockMember); // owner
      mockPrismaService.organizationMember.count.mockResolvedValue(1); // only 1 owner

      await expect(
        service.removeUser(mockTenantId, mockUserId),
      ).rejects.toThrow(UnprocessableEntityException);

      try {
        mockPrismaService.organizationMember.findUnique.mockResolvedValue(mockMember);
        mockPrismaService.organizationMember.count.mockResolvedValue(1);
        await service.removeUser(mockTenantId, mockUserId);
      } catch (e: any) {
        expect(e.response).toMatchObject({ error: 'CANNOT_REMOVE_LAST_OWNER' });
      }
    });

    it('should delete member and ban Supabase user when valid removal', async () => {
      const managerMember = { ...mockMember, role: managerRole };
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(managerMember);
      mockPrismaService.organizationMember.delete.mockResolvedValue(managerMember);
      mockSupabaseAdminService.banUser.mockResolvedValue(undefined);

      await service.removeUser(mockTenantId, mockUserId);

      expect(mockPrismaService.organizationMember.delete).toHaveBeenCalledWith({
        where: { organizationId_userId: { organizationId: mockTenantId, userId: mockUserId } },
      });
      expect(mockSupabaseAdminService.banUser).toHaveBeenCalledWith(mockUserId);
    });

    it('should allow removing one of multiple owners', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(mockMember); // owner
      mockPrismaService.organizationMember.count.mockResolvedValue(2); // 2 owners
      mockPrismaService.organizationMember.delete.mockResolvedValue(mockMember);
      mockSupabaseAdminService.banUser.mockResolvedValue(undefined);

      await expect(service.removeUser(mockTenantId, mockUserId)).resolves.not.toThrow();
      expect(mockPrismaService.organizationMember.delete).toHaveBeenCalled();
      expect(mockSupabaseAdminService.banUser).toHaveBeenCalledWith(mockUserId);
    });
  });
});
