import { Test, TestingModule } from '@nestjs/testing';
import { ModuleRegistryService } from './module-registry.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('ModuleRegistryService', () => {
  let service: ModuleRegistryService;

  const mockPrismaService = {
    tenantModule: {
      findFirst: jest.fn(),
      upsert: jest.fn(),
    },
    module: {
      findMany: jest.fn(),
    },
  };

  const validTenantId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ModuleRegistryService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<ModuleRegistryService>(ModuleRegistryService);
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('isModuleActive', () => {
    it('should return true when module is active for tenant', async () => {
      mockPrismaService.tenantModule.findFirst.mockResolvedValue({
        id: 'tm-1',
        tenantId: validTenantId,
        moduleId: 'mod-pos',
        status: 'active',
      });

      const result = await service.isModuleActive(validTenantId, 'pos');

      expect(result).toBe(true);
      expect(mockPrismaService.tenantModule.findFirst).toHaveBeenCalledWith({
        where: {
          tenantId: validTenantId,
          status: 'active',
          module: { code: 'pos' },
        },
      });
    });

    it('should return false when no tenant_module row exists', async () => {
      mockPrismaService.tenantModule.findFirst.mockResolvedValue(null);

      const result = await service.isModuleActive(validTenantId, 'pos');

      expect(result).toBe(false);
    });

    it('should return false for Phase 3 module with available_phase3 status (no active row)', async () => {
      // findFirst with status='active' filter returns null even if available_phase3 row exists
      mockPrismaService.tenantModule.findFirst.mockResolvedValue(null);

      const result = await service.isModuleActive(validTenantId, 'connect');

      expect(result).toBe(false);
    });

    it('should pass moduleCode to nested module filter', async () => {
      mockPrismaService.tenantModule.findFirst.mockResolvedValue(null);

      await service.isModuleActive(validTenantId, 'catalog');

      expect(mockPrismaService.tenantModule.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            module: { code: 'catalog' },
          }),
        }),
      );
    });

    it('should filter by status active in the query', async () => {
      mockPrismaService.tenantModule.findFirst.mockResolvedValue(null);

      await service.isModuleActive(validTenantId, 'pos');

      expect(mockPrismaService.tenantModule.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            status: 'active',
          }),
        }),
      );
    });
  });

  describe('activateDefaultModulesForTenant', () => {
    const mockModules = [
      { id: 'mod-catalog', code: 'catalog', type: 'shared' },
      { id: 'mod-retail', code: 'retail', type: 'vertical' },
    ];

    it('should query shared and retail modules then upsert TenantModule for each', async () => {
      mockPrismaService.module.findMany.mockResolvedValue(mockModules);
      mockPrismaService.tenantModule.upsert.mockResolvedValue({});

      await service.activateDefaultModulesForTenant(validTenantId);

      expect(mockPrismaService.module.findMany).toHaveBeenCalledWith({
        where: {
          OR: [{ type: 'shared' }, { code: 'retail' }],
        },
      });
      expect(mockPrismaService.tenantModule.upsert).toHaveBeenCalledTimes(2);
    });

    it('should upsert each module with status active and correct composite key', async () => {
      mockPrismaService.module.findMany.mockResolvedValue([
        { id: 'mod-catalog', code: 'catalog', type: 'shared' },
      ]);
      mockPrismaService.tenantModule.upsert.mockResolvedValue({});

      await service.activateDefaultModulesForTenant(validTenantId);

      expect(mockPrismaService.tenantModule.upsert).toHaveBeenCalledWith({
        where: { tenantId_moduleId: { tenantId: validTenantId, moduleId: 'mod-catalog' } },
        create: { tenantId: validTenantId, moduleId: 'mod-catalog', status: 'active' },
        update: { status: 'active' },
      });
    });

    it('should do nothing when no default modules exist', async () => {
      mockPrismaService.module.findMany.mockResolvedValue([]);

      await service.activateDefaultModulesForTenant(validTenantId);

      expect(mockPrismaService.tenantModule.upsert).not.toHaveBeenCalled();
    });
  });
});
