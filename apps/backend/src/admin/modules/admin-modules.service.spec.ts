import { NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { AdminModulesService } from './admin-modules.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('AdminModulesService', () => {
  let service: AdminModulesService;

  const mockTenantId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';

  const catalogModule = {
    id: 'mod-catalog-uuid',
    code: 'catalog',
    name: 'Catalogue',
    type: 'shared',
    dependencies: [],
    createdAt: new Date(),
  };

  const inventoryModule = {
    id: 'mod-inventory-uuid',
    code: 'inventory',
    name: 'Inventaire',
    type: 'shared',
    dependencies: ['catalog'],
    createdAt: new Date(),
  };

  const retailModule = {
    id: 'mod-retail-uuid',
    code: 'retail',
    name: 'Retail POS',
    type: 'vertical',
    dependencies: ['catalog', 'inventory', 'transactions'],
    createdAt: new Date(),
  };

  const mockPrismaService = {
    module: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    tenantModule: {
      findMany: jest.fn(),
      upsert: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.resetAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminModulesService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<AdminModulesService>(AdminModulesService);
  });

  // ─── listModules ────────────────────────────────────────────────────────────

  describe('listModules', () => {
    it('should return all modules from the registry', async () => {
      const modules = [catalogModule, inventoryModule, retailModule];
      mockPrismaService.module.findMany.mockResolvedValue(modules);

      const result = await service.listModules();

      expect(mockPrismaService.module.findMany).toHaveBeenCalledWith({
        orderBy: { name: 'asc' },
      });
      expect(result).toHaveLength(3);
      expect(result[0]).toMatchObject({
        id: catalogModule.id,
        code: 'catalog',
        name: 'Catalogue',
        type: 'shared',
        dependencies: [],
      });
    });
  });

  // ─── listTenantModules ───────────────────────────────────────────────────────

  describe('listTenantModules', () => {
    it('should LEFT JOIN all modules with tenant activation status', async () => {
      mockPrismaService.module.findMany.mockResolvedValue([
        catalogModule,
        inventoryModule,
        retailModule,
      ]);
      mockPrismaService.tenantModule.findMany.mockResolvedValue([
        {
          moduleId: 'mod-catalog-uuid',
          status: 'active',
          activatedAt: new Date('2026-01-01'),
          module: { code: 'catalog' },
        },
        {
          moduleId: 'mod-inventory-uuid',
          status: 'active',
          activatedAt: new Date('2026-01-02'),
          module: { code: 'inventory' },
        },
      ]);

      const result = await service.listTenantModules(mockTenantId);

      expect(result).toHaveLength(3);

      const catalog = result.find((m) => m.moduleCode === 'catalog');
      expect(catalog?.status).toBe('active');
      expect(catalog?.activatedAt).toBeTruthy();

      const retail = result.find((m) => m.moduleCode === 'retail');
      expect(retail?.status).toBe('inactive');
      expect(retail?.activatedAt).toBeNull();
    });

    it('should return all modules as inactive when tenant has no TenantModules', async () => {
      mockPrismaService.module.findMany.mockResolvedValue([catalogModule]);
      mockPrismaService.tenantModule.findMany.mockResolvedValue([]);

      const result = await service.listTenantModules(mockTenantId);

      expect(result[0]).toMatchObject({
        moduleCode: 'catalog',
        status: 'inactive',
        activatedAt: null,
      });
    });
  });

  // ─── activateModule ──────────────────────────────────────────────────────────

  describe('activateModule', () => {
    it('should throw NotFoundException when module code does not exist', async () => {
      mockPrismaService.module.findUnique.mockResolvedValue(null);

      await expect(
        service.activateModule(mockTenantId, 'nonexistent'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should activate a module with no dependencies directly', async () => {
      mockPrismaService.module.findUnique.mockResolvedValue(catalogModule);
      mockPrismaService.tenantModule.findMany.mockResolvedValue([]); // no active modules
      const activatedAt = new Date();
      mockPrismaService.tenantModule.upsert.mockResolvedValue({
        moduleId: catalogModule.id,
        status: 'active',
        activatedAt,
        module: { code: 'catalog' },
      });

      const result = await service.activateModule(mockTenantId, 'catalog');

      expect(mockPrismaService.tenantModule.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { tenantId_moduleId: { tenantId: mockTenantId, moduleId: catalogModule.id } },
          create: expect.objectContaining({ status: 'active' }),
          update: expect.objectContaining({ status: 'active' }),
        }),
      );
      expect(result).toMatchObject({ moduleCode: 'catalog', status: 'active' });
    });

    it('should throw 422 MISSING_DEPENDENCY when dependencies not active', async () => {
      // inventory depends on catalog
      mockPrismaService.module.findUnique.mockResolvedValue(inventoryModule);
      // catalog is NOT active for this tenant
      mockPrismaService.tenantModule.findMany.mockResolvedValue([]);

      await expect(
        service.activateModule(mockTenantId, 'inventory'),
      ).rejects.toThrow(UnprocessableEntityException);

      try {
        await service.activateModule(mockTenantId, 'inventory');
      } catch (e: any) {
        expect(e.response).toMatchObject({
          error: 'MISSING_DEPENDENCY',
          missing: ['catalog'],
        });
      }
    });

    it('should activate module when all dependencies are active', async () => {
      mockPrismaService.module.findUnique.mockResolvedValue(inventoryModule);
      // catalog IS active
      mockPrismaService.tenantModule.findMany.mockResolvedValue([
        { moduleId: 'mod-catalog-uuid', status: 'active', module: { code: 'catalog' } },
      ]);
      const activatedAt = new Date();
      mockPrismaService.tenantModule.upsert.mockResolvedValue({
        moduleId: inventoryModule.id,
        status: 'active',
        activatedAt,
        module: { code: 'inventory' },
      });

      const result = await service.activateModule(mockTenantId, 'inventory');

      expect(result).toMatchObject({ moduleCode: 'inventory', status: 'active' });
      expect(mockPrismaService.tenantModule.upsert).toHaveBeenCalled();
    });
  });

  // ─── deactivateModule ────────────────────────────────────────────────────────

  describe('deactivateModule', () => {
    it('should throw NotFoundException when module code does not exist', async () => {
      mockPrismaService.module.findUnique.mockResolvedValue(null);

      await expect(
        service.deactivateModule(mockTenantId, 'nonexistent'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw 422 HAS_DEPENDENTS when another active module depends on this one', async () => {
      // Deactivating 'catalog' — retail depends on it and is active
      mockPrismaService.module.findUnique.mockResolvedValue(catalogModule);
      // Active TenantModules that have dependencies on 'catalog'
      mockPrismaService.tenantModule.findMany.mockResolvedValue([
        {
          moduleId: 'mod-retail-uuid',
          status: 'active',
          module: { code: 'retail', dependencies: ['catalog', 'inventory', 'transactions'] },
        },
      ]);

      await expect(
        service.deactivateModule(mockTenantId, 'catalog'),
      ).rejects.toThrow(UnprocessableEntityException);

      try {
        await service.deactivateModule(mockTenantId, 'catalog');
      } catch (e: any) {
        expect(e.response).toMatchObject({
          error: 'HAS_DEPENDENTS',
          dependents: ['retail'],
        });
      }
    });

    it('should deactivate module when no active dependents exist', async () => {
      mockPrismaService.module.findUnique.mockResolvedValue(catalogModule);
      // No active TenantModules depend on catalog
      mockPrismaService.tenantModule.findMany.mockResolvedValue([]);

      mockPrismaService.tenantModule.upsert.mockResolvedValue({
        moduleId: catalogModule.id,
        status: 'inactive',
        activatedAt: null,
        module: { code: 'catalog' },
      });

      const result = await service.deactivateModule(mockTenantId, 'catalog');

      expect(mockPrismaService.tenantModule.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { tenantId_moduleId: { tenantId: mockTenantId, moduleId: catalogModule.id } },
          update: expect.objectContaining({ status: 'inactive', activatedAt: null }),
        }),
      );
      expect(result).toMatchObject({ moduleCode: 'catalog', status: 'inactive' });
    });

    it('should deactivate when only inactive dependents exist', async () => {
      // The DB query already filters WHERE status='active', so inactive dependents
      // are never returned — mock simulates the real DB response.
      mockPrismaService.module.findUnique.mockResolvedValue(catalogModule);
      mockPrismaService.tenantModule.findMany.mockResolvedValue([]); // DB returns nothing for status='active'
      mockPrismaService.tenantModule.upsert.mockResolvedValue({
        moduleId: catalogModule.id,
        status: 'inactive',
        activatedAt: null,
        module: { code: 'catalog' },
      });

      await expect(
        service.deactivateModule(mockTenantId, 'catalog'),
      ).resolves.not.toThrow();
    });
  });
});
