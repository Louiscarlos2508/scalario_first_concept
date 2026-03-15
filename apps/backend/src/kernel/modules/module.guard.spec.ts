import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test, TestingModule } from '@nestjs/testing';
import { ModuleGuard } from './module.guard';
import { ModuleRegistryService } from './module-registry.service';
import { REQUIRES_MODULE_KEY } from './module.decorator';

describe('ModuleGuard', () => {
  let guard: ModuleGuard;

  const mockModuleRegistryService = {
    isModuleActive: jest.fn(),
  };

  const mockReflector = {
    getAllAndOverride: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ModuleGuard,
        { provide: Reflector, useValue: mockReflector },
        { provide: ModuleRegistryService, useValue: mockModuleRegistryService },
      ],
    }).compile();

    guard = module.get<ModuleGuard>(ModuleGuard);
  });

  afterEach(() => {
    // resetAllMocks flushes mockReturnValueOnce queue — prevents stale values bleeding between tests
    jest.resetAllMocks();
  });

  const buildContext = (tenantId?: string): ExecutionContext =>
    ({
      getHandler: () => ({}),
      getClass: () => ({}),
      switchToHttp: () => ({
        getRequest: () => ({ tenantId }),
      }),
    }) as unknown as ExecutionContext;

  describe('when no @RequiresModule() decorator is set', () => {
    it('should return true (opt-in guard)', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce(undefined);

      const context = buildContext('tenant-1');
      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockModuleRegistryService.isModuleActive).not.toHaveBeenCalled();
    });
  });

  describe('when @RequiresModule() is set', () => {
    it('should allow access when module is active for tenant', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce('pos');
      mockModuleRegistryService.isModuleActive.mockResolvedValue(true);

      const context = buildContext('tenant-1');
      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockModuleRegistryService.isModuleActive).toHaveBeenCalledWith('tenant-1', 'pos');
    });

    it('should throw ForbiddenException when module is not active', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce('pos');
      mockModuleRegistryService.isModuleActive.mockResolvedValue(false);

      const context = buildContext('tenant-1');

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
    });

    it('should throw ForbiddenException when tenantId is missing', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce('pos');

      const context = buildContext(undefined);

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
      expect(mockModuleRegistryService.isModuleActive).not.toHaveBeenCalled();
    });

    it('should use the module code from the decorator when calling isModuleActive', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce('catalog');
      mockModuleRegistryService.isModuleActive.mockResolvedValue(true);

      const context = buildContext('tenant-1');
      await guard.canActivate(context);

      expect(mockModuleRegistryService.isModuleActive).toHaveBeenCalledWith('tenant-1', 'catalog');
    });

    it('should throw ForbiddenException for Phase 3 module not yet activated', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce('connect');
      mockModuleRegistryService.isModuleActive.mockResolvedValue(false);

      const context = buildContext('tenant-1');

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
    });
  });

  describe('reflector key usage', () => {
    it('should check REQUIRES_MODULE_KEY', async () => {
      mockReflector.getAllAndOverride.mockReturnValueOnce(undefined);

      const context = buildContext('tenant-1');
      await guard.canActivate(context);

      expect(mockReflector.getAllAndOverride).toHaveBeenCalledWith(
        REQUIRES_MODULE_KEY,
        expect.any(Array),
      );
    });
  });
});
