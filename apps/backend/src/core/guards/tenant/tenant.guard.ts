import { CanActivate, ExecutionContext, Injectable, BadRequestException } from '@nestjs/common';
import { Observable } from 'rxjs';

@Injectable()
export class TenantGuard implements CanActivate {
  canActivate(
    context: ExecutionContext,
  ): boolean | Promise<boolean> | Observable<boolean> {
    const request = context.switchToHttp().getRequest();
    const tenantId = request.headers['x-tenant-id'];

    if (!tenantId) {
      // Ideally, for some routes (create org), we don't need this.
      // But global tenant guard enforces it.
      // We might need a decorator to bypass it.
      throw new BadRequestException('Missing x-tenant-id header');
    }

    // valid UUID check could go here
    request.tenantId = tenantId;
    return true;
  }
}
