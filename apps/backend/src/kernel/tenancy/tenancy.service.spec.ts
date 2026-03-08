import { Test, TestingModule } from '@nestjs/testing';
import { TenancyService } from './tenancy.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('TenancyService', () => {
  let service: TenancyService;

  const mockPrismaService = {
    organizationMember: {
      findUnique: jest.fn(),
    },
    tenant: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TenancyService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<TenancyService>(TenancyService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  const validTenantId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  const validUserId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';

  describe('validateTenantAccess', () => {
    it('should return true when user is a member', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue({
        id: 'member-1',
        organizationId: validTenantId,
        userId: validUserId,
        role: 'owner',
      });

      const result = await service.validateTenantAccess(validTenantId, validUserId);
      expect(result).toBe(true);
    });

    it('should return false when user is not a member', async () => {
      mockPrismaService.organizationMember.findUnique.mockResolvedValue(null);

      const result = await service.validateTenantAccess(validTenantId, validUserId);
      expect(result).toBe(false);
    });

    it('should return false for invalid UUID format', async () => {
      const result = await service.validateTenantAccess('not-a-uuid', validUserId);
      expect(result).toBe(false);
      expect(mockPrismaService.organizationMember.findUnique).not.toHaveBeenCalled();
    });
  });

  describe('getTenantConfig', () => {
    it('should return tenant config when tenant exists', async () => {
      const mockTenant = {
        id: validTenantId,
        name: 'Test Org',
        currency: 'XOF',
        timezone: 'Africa/Abidjan',
        fiscalJurisdiction: null,
        status: 'active',
        sessionTimeoutMinutes: 480,
      };
      mockPrismaService.tenant.findUnique.mockResolvedValue(mockTenant);

      const result = await service.getTenantConfig(validTenantId);
      expect(result).toEqual({
        id: validTenantId,
        name: 'Test Org',
        currency: 'XOF',
        timezone: 'Africa/Abidjan',
        fiscalJurisdiction: null,
        status: 'active',
        sessionTimeoutMinutes: 480,
      });
    });

    it('should return null when tenant does not exist', async () => {
      mockPrismaService.tenant.findUnique.mockResolvedValue(null);

      const result = await service.getTenantConfig(validTenantId);
      expect(result).toBeNull();
    });
  });

  describe('createTenant', () => {
    it('should create tenant with defaults', async () => {
      const mockCreated = {
        id: validTenantId,
        name: 'New Org',
        currency: 'XOF',
        timezone: 'Africa/Abidjan',
        status: 'active',
      };
      mockPrismaService.tenant.create.mockResolvedValue(mockCreated);

      const result = await service.createTenant({ name: 'New Org' });
      expect(result).toEqual(mockCreated);
      expect(mockPrismaService.tenant.create).toHaveBeenCalledWith({
        data: {
          name: 'New Org',
          currency: 'XOF',
          timezone: 'Africa/Abidjan',
          fiscalJurisdiction: undefined,
        },
      });
    });

    it('should create tenant with custom currency and timezone', async () => {
      mockPrismaService.tenant.create.mockResolvedValue({});

      await service.createTenant({
        name: 'Custom Org',
        currency: 'EUR',
        timezone: 'Europe/Paris',
        fiscalJurisdiction: 'FR',
      });

      expect(mockPrismaService.tenant.create).toHaveBeenCalledWith({
        data: {
          name: 'Custom Org',
          currency: 'EUR',
          timezone: 'Europe/Paris',
          fiscalJurisdiction: 'FR',
        },
      });
    });
  });

  describe('updateTenantConfig', () => {
    it('should update tenant configuration', async () => {
      mockPrismaService.tenant.update.mockResolvedValue({});

      await service.updateTenantConfig(validTenantId, {
        name: 'Updated Org',
        sessionTimeoutMinutes: 240,
      });

      expect(mockPrismaService.tenant.update).toHaveBeenCalledWith({
        where: { id: validTenantId },
        data: { name: 'Updated Org', sessionTimeoutMinutes: 240 },
      });
    });
  });
});
