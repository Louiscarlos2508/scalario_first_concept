import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../../common/decorators/roles.decorator';
import { IS_PUBLIC_KEY } from '../../common/decorators/public.decorator';
import { SUPER_ADMIN } from '../constants';
import { RolesService } from '../services/roles.service';

/**
 * Layer 2 RBAC guard — STORY-015.
 *
 * Reads `@Roles(...)` metadata via Reflector, then computes
 * `req.user.roles ∩ tenants.config.roles ∩ required`. The triple-
 * intersection is defense-in-depth: even a JWT with a stale or invented
 * role string is rejected if the role is no longer in the tenant config.
 *
 * `SUPER_ADMIN` bypasses both validations — it is a cross-tenant system
 * role posted by ops, never via the PATCH /tenants/:slug/roles endpoint.
 */
@Injectable()
export class RbacGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly rolesService: RolesService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (isPublic) return true;

    const required = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (!required || required.length === 0) return true;

    const req = ctx.switchToHttp().getRequest<{
      user?: { roles?: unknown; tenant_id?: unknown };
    }>();
    const user = req.user;
    if (!user || !Array.isArray(user.roles) || user.roles.length === 0) {
      throw new ForbiddenException('No roles in token');
    }

    const userRoles = (user.roles as unknown[]).filter((r): r is string => typeof r === 'string');

    if (userRoles.includes(SUPER_ADMIN)) return true;

    if (typeof user.tenant_id !== 'string') {
      throw new ForbiddenException('Tenant context missing');
    }

    const tenantRoles = await this.rolesService.getRolesForTenant(user.tenant_id);
    const validUserRoles = userRoles.filter((r) => tenantRoles.includes(r));

    const intersection = validUserRoles.filter((r) => required.includes(r));
    if (intersection.length === 0) {
      throw new ForbiddenException(`Required role(s): ${required.join(', ')}`);
    }
    return true;
  }
}
