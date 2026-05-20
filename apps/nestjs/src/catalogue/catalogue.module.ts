import { Module } from '@nestjs/common';
import { CatalogueController } from './catalogue.controller';
import { CatalogueValidatorService } from './services/catalogue-validator.service';
import { CatalogueLoaderService } from './services/catalogue-loader.service';
import { WorkflowModule } from '../workflow/workflow.module';

@Module({
  imports: [WorkflowModule],
  controllers: [CatalogueController],
  providers: [CatalogueValidatorService, CatalogueLoaderService],
  exports: [CatalogueValidatorService, CatalogueLoaderService],
})
export class CatalogueModule {}
