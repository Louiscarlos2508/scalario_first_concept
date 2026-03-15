import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../auth/auth.decorator';
import { ROLES_KEY } from './roles.decorator';
import { PermissionService } from './permission.service';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly permissionService: PermissionService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // 1. @Public() bypasses all guards including RolesGuard
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    // 2. If no @Roles() decorator — no role restriction, pass through
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles || requiredRoles.length === 0) return true;

    // 3. Get user + tenant context (set by AuthGuard and TenantGuard)
    const request = context.switchToHttp().getRequest();
    const userId: string | undefined = request.user?.id;
    const tenantId: string | undefined = request.tenantId;

    if (!userId || !tenantId) {
      throw new ForbiddenException('Missing user or tenant context');
    }

    // 4. Resolve user role in this tenant
    const roleName = await this.permissionService.getUserRoleName(userId, tenantId);
    if (!roleName) {
      throw new ForbiddenException('User has no role in this tenant');
    }

    // 5. Check role against required roles
    if (!requiredRoles.includes(roleName)) {
      throw new ForbiddenException('Insufficient role for this action');
    }

    return true;
  }
}
