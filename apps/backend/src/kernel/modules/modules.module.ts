import { Module } from '@nestjs/common';
import { ModuleRegistryService } from './module-registry.service';
import { ModuleGuard } from './module.guard';

@Module({
  providers: [ModuleRegistryService, ModuleGuard],
  exports: [ModuleRegistryService, ModuleGuard],
})
export class ModulesModule {}
