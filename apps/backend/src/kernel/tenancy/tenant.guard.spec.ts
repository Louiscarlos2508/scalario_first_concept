import { Test, TestingModule } from '@nestjs/testing';
import {
  ExecutionContext,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { TenantGuard } from './tenant.guard';
import { TenancyService } from './tenancy.service';

describe('TenantGuard', () => {
  let guard: TenantGuard;

  const mockTenancyService = {
    validateTenantAccess: jest.fn(),
  };

  const mockReflector = {
    getAllAndOverride: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TenantGuard,
        { provide: TenancyService, useValue: mockTenancyService },
        { provide: Reflector, useValue: mockReflector },
      ],
    }).compile();

    guard = module.get<TenantGuard>(TenantGuard);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  function createMockContext(
    headers: Record<string, string> = {},
    user?: any,
  ): ExecutionContext {
    const request = { headers, user, tenantId: null };
    return {
      switchToHttp: () => ({
        getRequest: () => request,
      }),
      getHandler: () => jest.fn(),
      getClass: () => jest.fn(),
    } as unknown as ExecutionContext;
  }

  const validTenantId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  const validUserId = 'f1e2d3c4-b5a6-7890-abcd-ef1234567890';

  it('should allow request with valid tenant and user membership', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    mockTenancyService.validateTenantAccess.mockResolvedValue(true);

    const ctx = createMockContext(
      { 'x-tenant-id': validTenantId },
      { id: validUserId },
    );
    const result = await guard.canActivate(ctx);

    expect(result).toBe(true);
    const request = ctx.switchToHttp().getRequest();
    expect(request.tenantId).toBe(validTenantId);
  });

  it('should throw BadRequestException when x-tenant-id is missing', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    const ctx = createMockContext({});

    await expect(guard.canActivate(ctx)).rejects.toThrow(BadRequestException);
    await expect(guard.canActivate(ctx)).rejects.toThrow(
      'Missing x-tenant-id header',
    );
  });

  it('should throw BadRequestException when x-tenant-id is invalid UUID', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    const ctx = createMockContext({ 'x-tenant-id': 'not-a-uuid' });

    await expect(guard.canActivate(ctx)).rejects.toThrow(BadRequestException);
    await expect(guard.canActivate(ctx)).rejects.toThrow(
      'Invalid x-tenant-id format',
    );
  });

  it('should throw ForbiddenException when user is not a member of tenant', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    mockTenancyService.validateTenantAccess.mockResolvedValue(false);

    const ctx = createMockContext(
      { 'x-tenant-id': validTenantId },
      { id: validUserId },
    );

    await expect(guard.canActivate(ctx)).rejects.toThrow(ForbiddenException);
    await expect(guard.canActivate(ctx)).rejects.toThrow(
      'You are not a member of this organization',
    );
  });

  it('should bypass tenant check when @Public() decorator is present', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(true);
    const ctx = createMockContext({});

    const result = await guard.canActivate(ctx);
    expect(result).toBe(true);
    expect(mockTenancyService.validateTenantAccess).not.toHaveBeenCalled();
  });

  it('should allow request when no user context (pre-auth)', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);

    const ctx = createMockContext({ 'x-tenant-id': validTenantId });
    const result = await guard.canActivate(ctx);

    expect(result).toBe(true);
    expect(mockTenancyService.validateTenantAccess).not.toHaveBeenCalled();
  });
});
