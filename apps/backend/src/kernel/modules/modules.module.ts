import { Module } from '@nestjs/common';
import { ModuleRegistryService } from './module-registry.service';
import { ModuleGuard } from './module.guard';
import { TenantModulesController } from './tenant-modules.controller';

@Module({
  controllers: [TenantModulesController],
  providers: [ModuleRegistryService, ModuleGuard],
  exports: [ModuleRegistryService, ModuleGuard],
})
export class ModulesModule {}
