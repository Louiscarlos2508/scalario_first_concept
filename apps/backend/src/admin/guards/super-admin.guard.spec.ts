import { ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { SuperAdminGuard } from './super-admin.guard';
import { PrismaService } from '../../prisma/prisma.service';

const createMockExecutionContext = (userId?: string): ExecutionContext => ({
  switchToHttp: () => ({
    getRequest: () => ({
      user: userId ? { id: userId } : undefined,
    }),
  }),
  getHandler: jest.fn(),
  getClass: jest.fn(),
  getArgs: jest.fn(),
  getArgByIndex: jest.fn(),
  switchToRpc: jest.fn(),
  switchToWs: jest.fn(),
  getType: jest.fn(),
} as unknown as ExecutionContext);

describe('SuperAdminGuard', () => {
  let guard: SuperAdminGuard;

  const mockPrismaService = {
    organizationMember: {
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.resetAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SuperAdminGuard,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    guard = module.get<SuperAdminGuard>(SuperAdminGuard);
  });

  it('should be defined', () => {
    expect(guard).toBeDefined();
  });

  it('should return true when user has superadmin role', async () => {
    const userId = 'user-superadmin-uuid';
    mockPrismaService.organizationMember.findFirst.mockResolvedValue({
      id: 'member-uuid',
      userId,
      role: { name: 'superadmin', vertical: 'system' },
    });

    const context = createMockExecutionContext(userId);
    const result = await guard.canActivate(context);

    expect(result).toBe(true);
    expect(mockPrismaService.organizationMember.findFirst).toHaveBeenCalledWith({
      where: {
        userId,
        role: { name: 'superadmin' },
      },
      include: { role: true },
    });
  });

  it('should throw ForbiddenException when user does not have superadmin role', async () => {
    const userId = 'user-regular-uuid';
    mockPrismaService.organizationMember.findFirst.mockResolvedValue(null);

    const context = createMockExecutionContext(userId);

    await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
    await expect(guard.canActivate(context)).rejects.toMatchObject({
      message: 'Superadmin role required',
    });
  });

  it('should throw UnauthorizedException when no user in request', async () => {
    const context = createMockExecutionContext(undefined);

    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });
});
