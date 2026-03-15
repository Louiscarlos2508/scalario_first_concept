import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { REQUIRES_MODULE_KEY } from './module.decorator';
import { ModuleRegistryService } from './module-registry.service';

@Injectable()
export class ModuleGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly moduleRegistryService: ModuleRegistryService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredModule = this.reflector.getAllAndOverride<string | undefined>(
      REQUIRES_MODULE_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredModule) return true;

    const request = context.switchToHttp().getRequest();
    const tenantId: string | undefined = request.tenantId;

    if (!tenantId) {
      throw new ForbiddenException('Missing tenant context for module check');
    }

    const isActive = await this.moduleRegistryService.isModuleActive(tenantId, requiredModule);

    if (!isActive) {
      throw new ForbiddenException('Module not activated for this tenant');
    }

    return true;
  }
}
