import { InternalServerErrorException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { OrganizationService } from './organization.service';
import { SupabaseService } from '../kernel/auth/supabase.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditLogService } from '../kernel/audit/audit-log.service';
import { ModuleRegistryService } from '../kernel/modules/module-registry.service';

describe('OrganizationService', () => {
  let service: OrganizationService;

  const mockTenantId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';
  const mockUserId  = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  const mockRoleId  = 'role-owner-uuid';

  const mockSupabaseClient = {
    from: jest.fn(),
    insert: jest.fn(),
    select: jest.fn(),
    single: jest.fn(),
  };

  const mockSupabaseService = {
    getClient: jest.fn(),
  };

  const mockPrismaService = {
    role: {
      findUnique: jest.fn(),
    },
    organizationMember: {
      create: jest.fn(),
    },
  };

  const mockAuditLogService = {
    log: jest.fn(),
  };

  const mockModuleRegistryService = {
    activateDefaultModulesForTenant: jest.fn(),
  };

  beforeEach(async () => {
    // Restore Supabase fluent chain before each test (resetAllMocks clears mockReturnThis)
    mockSupabaseClient.from.mockReturnThis();
    mockSupabaseClient.insert.mockReturnThis();
    mockSupabaseClient.select.mockReturnThis();
    mockSupabaseService.getClient.mockReturnValue(mockSupabaseClient);
    mockAuditLogService.log.mockResolvedValue(undefined);
    mockModuleRegistryService.activateDefaultModulesForTenant.mockResolvedValue(undefined);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrganizationService,
        { provide: SupabaseService, useValue: mockSupabaseService },
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: AuditLogService, useValue: mockAuditLogService },
        { provide: ModuleRegistryService, useValue: mockModuleRegistryService },
      ],
    }).compile();

    service = module.get<OrganizationService>(OrganizationService);
  });

  afterEach(() => {
    // resetAllMocks flushes mockReturnValueOnce queue — prevents bleed between tests
    jest.resetAllMocks();
  });

  describe('createOrganization', () => {
    it('should create a tenant and link the user as owner', async () => {
      const mockTenant = { id: mockTenantId, name: 'Test Org' };
      mockSupabaseClient.single.mockResolvedValue({ data: mockTenant, error: null });
      mockPrismaService.role.findUnique.mockResolvedValue({ id: mockRoleId, name: 'owner', vertical: 'retail' });
      mockPrismaService.organizationMember.create.mockResolvedValue({});

      const result = await service.createOrganization('Test Org', mockUserId);

      expect(result).toEqual(mockTenant);
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
    });

    it('should call auditLogService.log with CREATE action after creating organization', async () => {
      const mockTenant = { id: mockTenantId, name: 'Test Org' };
      mockSupabaseClient.single.mockResolvedValue({ data: mockTenant, error: null });
      mockPrismaService.role.findUnique.mockResolvedValue({ id: mockRoleId, name: 'owner', vertical: 'retail' });
      mockPrismaService.organizationMember.create.mockResolvedValue({});

      await service.createOrganization('Test Org', mockUserId);

      expect(mockAuditLogService.log).toHaveBeenCalledWith({
        tenantId: mockTenantId,
        userId: mockUserId,
        action: 'CREATE',
        entity: 'Tenant',
        entityId: mockTenantId,
        before: null,
        after: { id: mockTenantId, name: 'Test Org' },
      });
    });

    it('should call activateDefaultModulesForTenant with the new tenant id', async () => {
      const mockTenant = { id: mockTenantId, name: 'Test Org' };
      mockSupabaseClient.single.mockResolvedValue({ data: mockTenant, error: null });
      mockPrismaService.role.findUnique.mockResolvedValue({ id: mockRoleId, name: 'owner', vertical: 'retail' });
      mockPrismaService.organizationMember.create.mockResolvedValue({});

      await service.createOrganization('Test Org', mockUserId);

      expect(mockModuleRegistryService.activateDefaultModulesForTenant).toHaveBeenCalledWith(
        mockTenantId,
      );
    });

    it('should throw InternalServerErrorException when Supabase tenant creation fails', async () => {
      mockSupabaseClient.single.mockResolvedValue({
        data: null,
        error: { message: 'DB error' },
      });

      await expect(service.createOrganization('Bad Org', mockUserId)).rejects.toThrow(
        InternalServerErrorException,
      );
      expect(mockPrismaService.role.findUnique).not.toHaveBeenCalled();
      expect(mockAuditLogService.log).not.toHaveBeenCalled();
      expect(mockModuleRegistryService.activateDefaultModulesForTenant).not.toHaveBeenCalled();
    });

    it('should throw InternalServerErrorException when owner role is not seeded', async () => {
      const mockTenant = { id: mockTenantId, name: 'Test Org' };
      mockSupabaseClient.single.mockResolvedValue({ data: mockTenant, error: null });
      mockPrismaService.role.findUnique.mockResolvedValue(null); // role not found

      await expect(service.createOrganization('Test Org', mockUserId)).rejects.toThrow(
        InternalServerErrorException,
      );
      expect(mockPrismaService.organizationMember.create).not.toHaveBeenCalled();
      expect(mockAuditLogService.log).not.toHaveBeenCalled();
      expect(mockModuleRegistryService.activateDefaultModulesForTenant).not.toHaveBeenCalled();
    });
  });

  describe('addMember', () => {
    it('should add a manager to a tenant', async () => {
      const mockRole = { id: 'role-manager-uuid', name: 'manager', vertical: 'retail' };
      const mockMember = { id: 'member-uuid', organizationId: mockTenantId, userId: mockUserId, roleId: mockRole.id };
      mockPrismaService.role.findUnique.mockResolvedValue(mockRole);
      mockPrismaService.organizationMember.create.mockResolvedValue(mockMember);

      const result = await service.addMember(mockTenantId, mockUserId, 'manager');

      expect(result).toEqual(mockMember);
      expect(mockPrismaService.role.findUnique).toHaveBeenCalledWith({
        where: { name_vertical: { name: 'manager', vertical: 'retail' } },
      });
      expect(mockPrismaService.organizationMember.create).toHaveBeenCalledWith({
        data: {
          organizationId: mockTenantId,
          userId: mockUserId,
          roleId: mockRole.id,
        },
      });
    });

    it('should call auditLogService.log with CREATE action after adding member', async () => {
      const mockRole = { id: 'role-manager-uuid', name: 'manager', vertical: 'retail' };
      const mockMember = { id: 'member-uuid', organizationId: mockTenantId, userId: mockUserId, roleId: mockRole.id };
      mockPrismaService.role.findUnique.mockResolvedValue(mockRole);
      mockPrismaService.organizationMember.create.mockResolvedValue(mockMember);

      await service.addMember(mockTenantId, mockUserId, 'manager');

      expect(mockAuditLogService.log).toHaveBeenCalledWith({
        tenantId: mockTenantId,
        userId: mockUserId,
        action: 'CREATE',
        entity: 'OrganizationMember',
        entityId: mockMember.id,
        before: null,
        after: { id: mockMember.id, userId: mockUserId, roleId: mockRole.id },
      });
    });

    it('should add a commercial to a tenant', async () => {
      const mockRole = { id: 'role-commercial-uuid', name: 'commercial', vertical: 'retail' };
      mockPrismaService.role.findUnique.mockResolvedValue(mockRole);
      mockPrismaService.organizationMember.create.mockResolvedValue({ id: 'member-2' });

      await service.addMember(mockTenantId, mockUserId, 'commercial');

      expect(mockPrismaService.role.findUnique).toHaveBeenCalledWith({
        where: { name_vertical: { name: 'commercial', vertical: 'retail' } },
      });
    });

    it('should throw InternalServerErrorException when role is not found', async () => {
      mockPrismaService.role.findUnique.mockResolvedValue(null);

      await expect(service.addMember(mockTenantId, mockUserId, 'manager')).rejects.toThrow(
        InternalServerErrorException,
      );
      expect(mockPrismaService.organizationMember.create).not.toHaveBeenCalled();
      expect(mockAuditLogService.log).not.toHaveBeenCalled();
    });
  });
});
