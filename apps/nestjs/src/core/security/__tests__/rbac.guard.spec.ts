import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../../../common/decorators/roles.decorator';
import { IS_PUBLIC_KEY } from '../../../common/decorators/public.decorator';
import { SUPER_ADMIN } from '../constants';
import { RbacGuard } from '../guards/rbac.guard';
import { RolesService } from '../services/roles.service';

function makeCtx(user: unknown): ExecutionContext {
  const handler = () => undefined;
  const klass = class {};
  return {
    getHandler: () => handler,
    getClass: () => klass,
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as unknown as ExecutionContext;
}

function makeReflector(metadata: Record<string, unknown>): Reflector {
  return {
    getAllAndOverride: <T>(key: string): T | undefined => metadata[key] as T | undefined,
  } as unknown as Reflector;
}

function makeRolesService(tenantRoles: string[]): RolesService {
  return {
    getRolesForTenant: jest.fn(async () => tenantRoles),
  } as unknown as RolesService;
}

describe('RbacGuard', () => {
  it('AC-03 — passes when no @Roles() metadata is present', async () => {
    const guard = new RbacGuard(makeReflector({}), makeRolesService([]));
    await expect(guard.canActivate(makeCtx({ roles: [], tenant_id: 't1' }))).resolves.toBe(true);
  });

  it('passes when route is marked @Public()', async () => {
    const guard = new RbacGuard(
      makeReflector({ [IS_PUBLIC_KEY]: true, [ROLES_KEY]: ['OWNER'] }),
      makeRolesService([]),
    );
    await expect(guard.canActivate(makeCtx(undefined))).resolves.toBe(true);
  });

  it('AC-07 — denies when req.user.roles is empty', async () => {
    const guard = new RbacGuard(
      makeReflector({ [ROLES_KEY]: ['OWNER'] }),
      makeRolesService(['OWNER']),
    );
    await expect(guard.canActivate(makeCtx({ roles: [], tenant_id: 't1' }))).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('AC-04 — denies when user roles do not intersect required', async () => {
    const guard = new RbacGuard(
      makeReflector({ [ROLES_KEY]: ['OWNER'] }),
      makeRolesService(['OWNER', 'MANAGER']),
    );
    await expect(
      guard.canActivate(makeCtx({ roles: ['MANAGER'], tenant_id: 't1' })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('AC-05 — allows when user has ANY of the required roles', async () => {
    const guard = new RbacGuard(
      makeReflector({ [ROLES_KEY]: ['OWNER', 'MANAGER'] }),
      makeRolesService(['OWNER', 'MANAGER']),
    );
    await expect(guard.canActivate(makeCtx({ roles: ['MANAGER'], tenant_id: 't1' }))).resolves.toBe(
      true,
    );
  });

  it('AC-06 — allows when user has the required role plus extras', async () => {
    const guard = new RbacGuard(
      makeReflector({ [ROLES_KEY]: ['OWNER'] }),
      makeRolesService(['OWNER', 'COMMERCIAL']),
    );
    await expect(
      guard.canActivate(makeCtx({ roles: ['OWNER', 'COMMERCIAL'], tenant_id: 't1' })),
    ).resolves.toBe(true);
  });

  it('rejects roles no longer in tenants.config.roles (stale-JWT defense)', async () => {
    const guard = new RbacGuard(
      makeReflector({ [ROLES_KEY]: ['COMMERCIAL'] }),
      makeRolesService(['OWNER', 'MANAGER']), // COMMERCIAL was removed
    );
    await expect(
      guard.canActivate(makeCtx({ roles: ['COMMERCIAL'], tenant_id: 't1' })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('SUPER_ADMIN bypasses tenant config intersection', async () => {
    const guard = new RbacGuard(
      makeReflector({ [ROLES_KEY]: ['OWNER'] }),
      makeRolesService([]), // SUPER_ADMIN is NEVER in tenant config
    );
    await expect(
      guard.canActivate(makeCtx({ roles: [SUPER_ADMIN], tenant_id: 't1' })),
    ).resolves.toBe(true);
  });

  it('rejects when req.user is missing entirely', async () => {
    const guard = new RbacGuard(
      makeReflector({ [ROLES_KEY]: ['OWNER'] }),
      makeRolesService(['OWNER']),
    );
    await expect(guard.canActivate(makeCtx(undefined))).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects when tenant_id is missing on the user', async () => {
    const guard = new RbacGuard(
      makeReflector({ [ROLES_KEY]: ['OWNER'] }),
      makeRolesService(['OWNER']),
    );
    await expect(guard.canActivate(makeCtx({ roles: ['OWNER'] }))).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
