import { Test, TestingModule } from '@nestjs/testing';
import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from './auth.guard';
import { SupabaseService } from './supabase.service';

describe('AuthGuard', () => {
  let guard: AuthGuard;
  let supabaseService: SupabaseService;
  let reflector: Reflector;

  const mockSupabaseService = {
    getClient: jest.fn(),
  };

  const mockReflector = {
    getAllAndOverride: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthGuard,
        { provide: SupabaseService, useValue: mockSupabaseService },
        { provide: Reflector, useValue: mockReflector },
      ],
    }).compile();

    guard = module.get<AuthGuard>(AuthGuard);
    supabaseService = module.get<SupabaseService>(SupabaseService);
    reflector = module.get<Reflector>(Reflector);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  function createMockContext(headers: Record<string, string> = {}): ExecutionContext {
    const request = { headers, user: null };
    return {
      switchToHttp: () => ({
        getRequest: () => request,
      }),
      getHandler: () => jest.fn(),
      getClass: () => jest.fn(),
    } as unknown as ExecutionContext;
  }

  it('should allow request with valid JWT', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    const mockUser = { id: 'user-123', email: 'test@test.com' };
    mockSupabaseService.getClient.mockReturnValue({
      auth: {
        getUser: jest.fn().mockResolvedValue({
          data: { user: mockUser },
          error: null,
        }),
      },
    });

    const ctx = createMockContext({ authorization: 'Bearer valid-token' });
    const result = await guard.canActivate(ctx);

    expect(result).toBe(true);
    const request = ctx.switchToHttp().getRequest();
    expect(request.user).toEqual(mockUser);
  });

  it('should throw UnauthorizedException when no authorization header', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    const ctx = createMockContext({});

    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
    await expect(guard.canActivate(ctx)).rejects.toThrow('Missing Authorization Header');
  });

  it('should throw UnauthorizedException when no bearer token', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    const ctx = createMockContext({ authorization: 'Bearer ' });

    mockSupabaseService.getClient.mockReturnValue({
      auth: {
        getUser: jest.fn().mockResolvedValue({
          data: { user: null },
          error: { message: 'invalid' },
        }),
      },
    });

    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
  });

  it('should throw UnauthorizedException when token is invalid', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    mockSupabaseService.getClient.mockReturnValue({
      auth: {
        getUser: jest.fn().mockResolvedValue({
          data: { user: null },
          error: { message: 'Token expired' },
        }),
      },
    });

    const ctx = createMockContext({ authorization: 'Bearer invalid-token' });
    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
    await expect(guard.canActivate(ctx)).rejects.toThrow('Invalid Token');
  });

  it('should bypass auth when @Public() decorator is present', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(true);
    const ctx = createMockContext({});

    const result = await guard.canActivate(ctx);
    expect(result).toBe(true);
    expect(mockSupabaseService.getClient).not.toHaveBeenCalled();
  });

  it('should throw when authorization header has no token part', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    const ctx = createMockContext({ authorization: 'Basic' });

    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
    await expect(guard.canActivate(ctx)).rejects.toThrow('Missing Bearer Token');
  });

  it('should throw UnauthorizedException when session has expired', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);

    // iat = 10 hours ago, timeout = 8 hours (480 min)
    const iatTenHoursAgo = Math.floor(Date.now() / 1000) - 10 * 3600;
    // Build a minimal fake JWT: header.payload.sig (base64url encoded)
    const payload = Buffer.from(JSON.stringify({ iat: iatTenHoursAgo, sub: 'user-123' })).toString('base64url');
    const fakeToken = `header.${payload}.sig`;

    const mockUser = { id: 'user-123' };
    mockSupabaseService.getClient.mockReturnValue({
      auth: {
        getUser: jest.fn().mockResolvedValue({
          data: { user: mockUser },
          error: null,
        }),
      },
    });

    const ctx = createMockContext({ authorization: `Bearer ${fakeToken}` });
    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
    await expect(guard.canActivate(ctx)).rejects.toThrow('Session expired. Please re-authenticate.');
  });

  it('should allow request with token within session timeout', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);

    // iat = 1 hour ago, timeout = 8 hours
    const iatOneHourAgo = Math.floor(Date.now() / 1000) - 3600;
    const payload = Buffer.from(JSON.stringify({ iat: iatOneHourAgo, sub: 'user-123' })).toString('base64url');
    const fakeToken = `header.${payload}.sig`;

    const mockUser = { id: 'user-123' };
    mockSupabaseService.getClient.mockReturnValue({
      auth: {
        getUser: jest.fn().mockResolvedValue({
          data: { user: mockUser },
          error: null,
        }),
      },
    });

    const ctx = createMockContext({ authorization: `Bearer ${fakeToken}` });
    const result = await guard.canActivate(ctx);
    expect(result).toBe(true);
  });
});
