import { BadRequestException, UnprocessableEntityException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { AdminTenantsService } from './admin-tenants.service';
import { PrismaService } from '../../prisma/prisma.service';
import { SupabaseAdminService } from '../services/supabase-admin.service';
import { ModuleRegistryService } from '../../kernel/modules/module-registry.service';
import { BusinessTypeService } from '../business-type/business-type.service';

describe('AdminTenantsService', () => {
  let service: AdminTenantsService;

  const mockTenantId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';
  const mockUserId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  const mockRoleId = 'role-owner-uuid';

  const mockPrismaService = {
    tenant: {
      create: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
    role: {
      findUnique: jest.fn(),
    },
    organizationMember: {
      create: jest.fn(),
    },
    businessTypeDefinition: {
      findUnique: jest.fn(),
    },
  };

  const mockSupabaseAdminService = {
    createUser: jest.fn(),
    deleteUser: jest.fn(),
  };

  const mockModuleRegistryService = {
    activateDefaultModulesForTenant: jest.fn(),
  };

  const mockBusinessTypeService = {
    seedCategories: jest.fn().mockResolvedValue(undefined),
  };

  beforeEach(async () => {
    jest.resetAllMocks();
    mockBusinessTypeService.seedCategories.mockResolvedValue(undefined);
    // Default: 'generaliste' is a valid retail type
    mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue({
      code: 'generaliste',
      isActive: true,
      vertical: 'retail',
    });

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminTenantsService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: SupabaseAdminService, useValue: mockSupabaseAdminService },
        { provide: ModuleRegistryService, useValue: mockModuleRegistryService },
        { provide: BusinessTypeService, useValue: mockBusinessTypeService },
      ],
    }).compile();

    service = module.get<AdminTenantsService>(AdminTenantsService);
  });

  describe('createTenant', () => {
    const createDto = {
      name: 'Boutique Koné',
      ownerEmail: 'owner@boutique.com',
      ownerPassword: 'password123',
    };

    it('should create tenant, orgMember, and activate modules on success', async () => {
      mockSupabaseAdminService.createUser.mockResolvedValue(mockUserId);
      mockPrismaService.tenant.create.mockResolvedValue({
        id: mockTenantId,
        name: 'Boutique Koné',
        currency: 'XOF',
        timezone: 'Africa/Ouagadougou',
        status: 'active',
        businessType: 'generaliste',
      });
      mockPrismaService.role.findUnique.mockResolvedValue({
        id: mockRoleId,
        name: 'owner',
        vertical: 'retail',
      });
      mockPrismaService.organizationMember.create.mockResolvedValue({ id: 'member-uuid' });
      mockModuleRegistryService.activateDefaultModulesForTenant.mockResolvedValue(undefined);

      const result = await service.createTenant(createDto);

      expect(mockSupabaseAdminService.createUser).toHaveBeenCalledWith(
        createDto.ownerEmail,
        createDto.ownerPassword,
      );
      expect(mockPrismaService.tenant.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          name: createDto.name,
          currency: 'XOF',
          timezone: 'Africa/Ouagadougou',
          status: 'active',
          plan: 'standard',
          billingStatus: 'trial',
        }),
      });
      expect(mockPrismaService.role.findUnique).toHaveBeenCalledWith({
        where: { name_vertical: { name: 'owner', vertical: 'retail' } },
      });
      expect(mockPrismaService.organizationMember.create).toHaveBeenCalledWith({
        data: {
          organizationId: mockTenantId,
          userId: mockUserId,
          roleId: mockRoleId,
        },
      });
      expect(mockModuleRegistryService.activateDefaultModulesForTenant).toHaveBeenCalledWith(mockTenantId, 'standard');
      expect(result.tenantId).toBe(mockTenantId);
      expect(result.userId).toBe(mockUserId);
      expect(result.name).toBe('Boutique Koné');
    });

    it('should use provided currency and timezone', async () => {
      mockSupabaseAdminService.createUser.mockResolvedValue(mockUserId);
      mockPrismaService.tenant.create.mockResolvedValue({
        id: mockTenantId,
        name: 'Test',
        currency: 'EUR',
        timezone: 'Europe/Paris',
        status: 'active',
        businessType: 'generaliste',
      });
      mockPrismaService.role.findUnique.mockResolvedValue({ id: mockRoleId });
      mockPrismaService.organizationMember.create.mockResolvedValue({ id: 'member-uuid' });
      mockModuleRegistryService.activateDefaultModulesForTenant.mockResolvedValue(undefined);

      await service.createTenant({
        name: 'Test',
        ownerEmail: 'test@test.com',
        ownerPassword: 'password123',
        currency: 'EUR',
        timezone: 'Europe/Paris',
      });

      expect(mockPrismaService.tenant.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          name: 'Test',
          currency: 'EUR',
          timezone: 'Europe/Paris',
          status: 'active',
          plan: 'standard',
        }),
      });
    });

    it('should throw UnprocessableEntityException when Supabase user creation fails', async () => {
      mockSupabaseAdminService.createUser.mockRejectedValue(
        new Error('Email address already registered'),
      );

      await expect(service.createTenant(createDto)).rejects.toThrow(UnprocessableEntityException);
      expect(mockPrismaService.tenant.create).not.toHaveBeenCalled();
    });

    it('should rollback Supabase user if tenant creation fails', async () => {
      mockSupabaseAdminService.createUser.mockResolvedValue(mockUserId);
      mockPrismaService.tenant.create.mockRejectedValue(new Error('DB error'));
      mockSupabaseAdminService.deleteUser.mockResolvedValue(undefined);

      await expect(service.createTenant(createDto)).rejects.toThrow();
      expect(mockSupabaseAdminService.deleteUser).toHaveBeenCalledWith(mockUserId);
    });

    it('should throw if name is missing', async () => {
      await expect(
        service.createTenant({ name: '', ownerEmail: 'a@b.com', ownerPassword: 'pass12345' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw if ownerPassword is too short', async () => {
      await expect(
        service.createTenant({ name: 'Test', ownerEmail: 'a@b.com', ownerPassword: 'short' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException when businessType does not belong to vertical', async () => {
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue(null);

      await expect(
        service.createTenant({
          name: 'Test',
          ownerEmail: 'a@b.com',
          ownerPassword: 'password123',
          businessType: 'artisan_boulangerie',
          vertical: 'retail',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should store vertical on the tenant and return it', async () => {
      mockSupabaseAdminService.createUser.mockResolvedValue(mockUserId);
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue({
        code: 'epicerie',
        isActive: true,
        vertical: 'retail',
      });
      mockPrismaService.tenant.create.mockResolvedValue({
        id: mockTenantId,
        name: 'Epicerie',
        currency: 'XOF',
        timezone: 'Africa/Ouagadougou',
        status: 'active',
        businessType: 'epicerie',
        vertical: 'retail',
      });
      mockPrismaService.role.findUnique.mockResolvedValue({ id: mockRoleId });
      mockPrismaService.organizationMember.create.mockResolvedValue({ id: 'member-uuid' });
      mockModuleRegistryService.activateDefaultModulesForTenant.mockResolvedValue(undefined);

      const result = await service.createTenant({
        name: 'Epicerie',
        ownerEmail: 'owner@epicerie.com',
        ownerPassword: 'password123',
        businessType: 'epicerie',
        vertical: 'retail',
      });

      expect(mockPrismaService.tenant.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ businessType: 'epicerie', vertical: 'retail' }),
      });
      expect(result.businessType).toBe('epicerie');
    });
  });

  describe('listTenants', () => {
    it('should return tenants with membersCount and activeModules', async () => {
      mockPrismaService.tenant.findMany.mockResolvedValue([
        {
          id: mockTenantId,
          name: 'Boutique Koné',
          status: 'active',
          currency: 'XOF',
          timezone: 'Africa/Ouagadougou',
          createdAt: new Date('2026-01-01'),
          _count: { members: 3 },
          tenantModules: [
            { module: { code: 'catalog' }, status: 'active' },
            { module: { code: 'retail' }, status: 'active' },
            { module: { code: 'inventory' }, status: 'inactive' },
          ],
        },
      ]);

      const result = await service.listTenants();

      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        id: mockTenantId,
        name: 'Boutique Koné',
        status: 'active',
        membersCount: 3,
        activeModules: ['catalog', 'retail'],
      });
    });
  });

  describe('updateTenant', () => {
    it('should update tenant with provided fields', async () => {
      mockPrismaService.tenant.update.mockResolvedValue({
        id: mockTenantId,
        name: 'New Name',
        currency: 'XOF',
        timezone: 'Africa/Ouagadougou',
        status: 'active',
        createdAt: new Date(),
      });

      const result = await service.updateTenant(mockTenantId, { name: 'New Name' });

      expect(mockPrismaService.tenant.update).toHaveBeenCalledWith({
        where: { id: mockTenantId },
        data: { name: 'New Name' },
      });
      expect(result.name).toBe('New Name');
    });

    it('should throw BadRequestException for invalid status', async () => {
      await expect(
        service.updateTenant(mockTenantId, { status: 'invalid_status' }),
      ).rejects.toThrow(BadRequestException);

      expect(mockPrismaService.tenant.update).not.toHaveBeenCalled();
    });

    it('should accept valid status values', async () => {
      for (const status of ['active', 'suspended', 'archived']) {
        mockPrismaService.tenant.update.mockResolvedValue({
          id: mockTenantId,
          name: 'Test',
          status,
          currency: 'XOF',
          timezone: 'Africa/Ouagadougou',
          createdAt: new Date(),
        });

        await expect(
          service.updateTenant(mockTenantId, { status }),
        ).resolves.not.toThrow();
      }
    });
  });
});
