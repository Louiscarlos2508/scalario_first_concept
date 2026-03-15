import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test, TestingModule } from '@nestjs/testing';
import { RolesGuard } from './roles.guard';
import { PermissionService } from './permission.service';
import { IS_PUBLIC_KEY } from '../auth/auth.decorator';
import { ROLES_KEY } from './roles.decorator';

describe('RolesGuard', () => {
  let guard: RolesGuard;

  const mockPermissionService = {
    getUserRoleName: jest.fn(),
  };

  const mockReflector = {
    getAllAndOverride: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RolesGuard,
        { provide: Reflector, useValue: mockReflector },
        { provide: PermissionService, useValue: mockPermissionService },
      ],
    }).compile();

    guard = module.get<RolesGuard>(RolesGuard);
  });

  afterEach(() => {
    // resetAllMocks clears the mockReturnValueOnce queue — critical to avoid
    // stale values bleeding between tests when guard returns early
    jest.resetAllMocks();
  });

  const buildContext = (userId?: string, tenantId?: string): ExecutionContext =>
    ({
      getHandler: () => ({}),
      getClass: () => ({}),
      switchToHttp: () => ({
        getRequest: () => ({
          user: userId ? { id: userId } : undefined,
          tenantId,
        }),
      }),
    }) as unknown as ExecutionContext;

  /**
   * Helper: set up reflector to return isPublic + requiredRoles.
   * The reflector's getAllAndOverride is called twice (IS_PUBLIC_KEY then ROLES_KEY).
   */
  const setupReflector = (isPublic: boolean, requiredRoles: string[] | null) => {
    mockReflector.getAllAndOverride
      .mockReturnValueOnce(isPublic)
      .mockReturnValueOnce(requiredRoles);
  };

  describe('when @Public() is set', () => {
    it('should return true regardless of role', async () => {
      // Only set up IS_PUBLIC_KEY mock — guard returns before reading ROLES_KEY
      mockReflector.getAllAndOverride.mockReturnValueOnce(true);

      const context = buildContext('user-1', 'tenant-1');
      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockPermissionService.getUserRoleName).not.toHaveBeenCalled();
    });
  });

  describe('when no @Roles() decorator is set', () => {
    it('should return true (opt-in guard)', async () => {
      setupReflector(false, null);

      const context = buildContext('user-1', 'tenant-1');
      const result = await guard.canActivate(context);

      expect(result).toBe(true);
      expect(mockPermissionService.getUserRoleName).not.toHaveBeenCalled();
    });

    it('should return true for empty roles array', async () => {
      setupReflector(false, []);

      const context = buildContext('user-1', 'tenant-1');
      const result = await guard.canActivate(context);

      expect(result).toBe(true);
    });
  });

  describe('when @Roles() is set', () => {
    it('should allow access when user role matches required role', async () => {
      setupReflector(false, ['owner']);
      mockPermissionService.getUserRoleName.mockResolvedValue('owner');

      const context = buildContext('user-1', 'tenant-1');
      const result = await guard.canActivate(context);

      expect(result).toBe(true);
    });

    it('should allow access when user role is one of multiple required roles', async () => {
      setupReflector(false, ['owner', 'manager']);
      mockPermissionService.getUserRoleName.mockResolvedValue('manager');

      const context = buildContext('user-1', 'tenant-1');
      const result = await guard.canActivate(context);

      expect(result).toBe(true);
    });

    it('should throw ForbiddenException when commercial tries owner-only endpoint', async () => {
      setupReflector(false, ['owner']);
      mockPermissionService.getUserRoleName.mockResolvedValue('commercial');

      const context = buildContext('user-1', 'tenant-1');

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
    });

    it('should throw ForbiddenException when manager tries owner-only endpoint', async () => {
      setupReflector(false, ['owner']);
      mockPermissionService.getUserRoleName.mockResolvedValue('manager');

      const context = buildContext('user-1', 'tenant-1');

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
    });

    it('should throw ForbiddenException when user has no role in tenant', async () => {
      setupReflector(false, ['owner']);
      mockPermissionService.getUserRoleName.mockResolvedValue(null);

      const context = buildContext('user-1', 'tenant-1');

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
    });

    it('should throw ForbiddenException when tenantId is missing', async () => {
      setupReflector(false, ['owner']);

      const context = buildContext('user-1', undefined);

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
      expect(mockPermissionService.getUserRoleName).not.toHaveBeenCalled();
    });

    it('should throw ForbiddenException when userId is missing', async () => {
      setupReflector(false, ['owner']);

      const context = buildContext(undefined, 'tenant-1');

      await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
    });
  });

  describe('reflector key usage', () => {
    it('should check IS_PUBLIC_KEY before ROLES_KEY', async () => {
      // Guard returns early when public — only IS_PUBLIC_KEY is consumed
      mockReflector.getAllAndOverride.mockReturnValueOnce(true);

      const context = buildContext('user-1', 'tenant-1');
      await guard.canActivate(context);

      expect(mockReflector.getAllAndOverride).toHaveBeenCalledWith(
        IS_PUBLIC_KEY,
        expect.any(Array),
      );
      expect(mockPermissionService.getUserRoleName).not.toHaveBeenCalled();
    });

    it('should check ROLES_KEY when not public', async () => {
      setupReflector(false, null);

      const context = buildContext('user-1', 'tenant-1');
      await guard.canActivate(context);

      expect(mockReflector.getAllAndOverride).toHaveBeenNthCalledWith(
        1,
        IS_PUBLIC_KEY,
        expect.any(Array),
      );
      expect(mockReflector.getAllAndOverride).toHaveBeenNthCalledWith(
        2,
        ROLES_KEY,
        expect.any(Array),
      );
    });
  });
});
