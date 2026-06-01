import { Module } from '@nestjs/common';
import { CatalogueController } from './catalogue.controller';
import { CatalogueValidatorService } from './services/catalogue-validator.service';
import { CatalogueLoaderService } from './services/catalogue-loader.service';
import { ModuleCatalogV2Loader } from './loaders/module-catalog-v2.loader';
import { WorkflowModule } from '../engines/workflow/workflow.module';

@Module({
  imports: [WorkflowModule],
  controllers: [CatalogueController],
  providers: [CatalogueValidatorService, CatalogueLoaderService, ModuleCatalogV2Loader],
  exports: [CatalogueValidatorService, CatalogueLoaderService, ModuleCatalogV2Loader]
})
export class CatalogueModule {}
