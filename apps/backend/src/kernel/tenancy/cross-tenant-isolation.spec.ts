/**
 * Cross-Tenant Isolation Tests — AC3
 *
 * Validates application-level isolation: a user belonging to Tenant A
 * cannot access resources scoped to Tenant B.
 *
 * Isolation layers:
 *   1. TenancyService.validateTenantAccess() — queries OrganizationMember
 *   2. TenantGuard.canActivate() — throws ForbiddenException when access denied
 *
 * NOTE: Full RLS integration tests (real PostgreSQL SET LOCAL app.current_tenant_id)
 * require a test database fixture and are a post-MVP concern. These unit tests
 * validate the application-level isolation layer that is active for all requests.
 */
import { ForbiddenException, BadRequestException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { TenancyService } from './tenancy.service';
import { TenantGuard } from './tenant.guard';
import { PrismaService } from '../../prisma/prisma.service';
import { ExecutionContext } from '@nestjs/common';

const tenantA = 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa';
const tenantB = 'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb';
const userA   = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
const userB   = 'b2c3d4e5-f6a7-8901-bcde-f12345678901';

function buildContext(request: Record<string, any>): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => ({ name: 'testHandler' }),
    getClass:   () => ({ name: 'TestController' }),
  } as unknown as ExecutionContext;
}

// ─────────────────────────────────────────────────────────────
// TenancyService — application-level isolation
// ─────────────────────────────────────────────────────────────
describe('Cross-Tenant Isolation — TenancyService (AC3)', () => {
  let service: TenancyService;

  const mockPrismaService = {
    organizationMember: {
      findUnique: jest.fn(),
    },
    tenant: { findUnique: jest.fn() },
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

  afterEach(() => jest.resetAllMocks());

  it('should return true when userA accesses tenantA (is a member)', async () => {
    mockPrismaService.organizationMember.findUnique.mockResolvedValue({
      organizationId: tenantA,
      userId: userA,
    });
    const result = await service.validateTenantAccess(tenantA, userA);
    expect(result).toBe(true);
  });

  it('should return false when userA attempts to access tenantB (not a member)', async () => {
    // OrganizationMember row for (tenantB, userA) does not exist
    mockPrismaService.organizationMember.findUnique.mockResolvedValue(null);
    const result = await service.validateTenantAccess(tenantB, userA);
    expect(result).toBe(false);
    expect(mockPrismaService.organizationMember.findUnique).toHaveBeenCalledWith({
      where: {
        organizationId_userId: {
          organizationId: tenantB,
          userId: userA,
        },
      },
    });
  });

  it('should return false when userB attempts to access tenantA (not a member)', async () => {
    mockPrismaService.organizationMember.findUnique.mockResolvedValue(null);
    const result = await service.validateTenantAccess(tenantA, userB);
    expect(result).toBe(false);
  });

  it('should return false when tenantId is not a valid UUID (injection guard)', async () => {
    const result = await service.validateTenantAccess('../../etc/passwd', userA);
    expect(result).toBe(false);
    expect(mockPrismaService.organizationMember.findUnique).not.toHaveBeenCalled();
  });

  it('should return false when userId is not a valid UUID (injection guard)', async () => {
    const result = await service.validateTenantAccess(tenantA, 'not-a-uuid');
    expect(result).toBe(false);
    expect(mockPrismaService.organizationMember.findUnique).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────
// TenantGuard — throws ForbiddenException for cross-tenant access
// ─────────────────────────────────────────────────────────────
describe('Cross-Tenant Isolation — TenantGuard (AC3)', () => {
  let guard: TenantGuard;

  const mockTenancyService = { validateTenantAccess: jest.fn() };

  beforeEach(async () => {
    const reflector = new Reflector();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TenantGuard,
        { provide: TenancyService, useValue: mockTenancyService },
        { provide: Reflector, useValue: reflector },
      ],
    }).compile();
    guard = module.get<TenantGuard>(TenantGuard);
  });

  afterEach(() => jest.resetAllMocks());

  it('should throw ForbiddenException when userA (tenant A member) attempts tenant B context', async () => {
    mockTenancyService.validateTenantAccess.mockResolvedValue(false); // userA not in tenantB
    const ctx = buildContext({
      headers: { 'x-tenant-id': tenantB },
      user: { id: userA },
    });
    await expect(guard.canActivate(ctx)).rejects.toThrow(ForbiddenException);
    expect(mockTenancyService.validateTenantAccess).toHaveBeenCalledWith(tenantB, userA);
  });

  it('should allow access when user is a member of the requested tenant', async () => {
    mockTenancyService.validateTenantAccess.mockResolvedValue(true);
    const request: Record<string, any> = {
      headers: { 'x-tenant-id': tenantA },
      user: { id: userA },
    };
    const ctx = buildContext(request);
    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    expect(request.tenantId).toBe(tenantA);
  });

  it('should throw BadRequestException for malformed tenant ID (prevents injection)', async () => {
    const ctx = buildContext({
      headers: { 'x-tenant-id': 'INVALID-ID' },
      user: { id: userA },
    });
    await expect(guard.canActivate(ctx)).rejects.toThrow(BadRequestException);
    expect(mockTenancyService.validateTenantAccess).not.toHaveBeenCalled();
  });
});
