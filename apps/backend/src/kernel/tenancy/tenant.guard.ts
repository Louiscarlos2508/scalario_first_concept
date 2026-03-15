import {
  CanActivate,
  ExecutionContext,
  Injectable,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../auth/auth.decorator';
import { TenancyService } from './tenancy.service';

@Injectable()
export class TenantGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly tenancyService: TenancyService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const tenantId = request.headers['x-tenant-id'];

    // If no x-tenant-id header provided, pass through (no tenant context set).
    // Endpoints that strictly require tenant context must validate request.tenantId themselves.
    // Bootstrap endpoints (e.g. POST /organizations) legitimately have no tenant yet.
    if (!tenantId) {
      return true;
    }

    // Validate UUID format
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(tenantId)) {
      throw new BadRequestException('Invalid x-tenant-id format');
    }

    // Validate user is a member of the tenant (when authenticated)
    const userId = request.user?.id;
    if (userId) {
      const hasAccess = await this.tenancyService.validateTenantAccess(
        tenantId,
        userId,
      );
      if (!hasAccess) {
        throw new ForbiddenException(
          'You are not a member of this organization',
        );
      }
    }

    request.tenantId = tenantId;
    return true;
  }
}
