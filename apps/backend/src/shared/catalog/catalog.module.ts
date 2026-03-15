import { DynamicModule, Module } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { CatalogController } from './catalog.controller';

@Module({})
export class CatalogModule {
  static register(): DynamicModule {
    return {
      module: CatalogModule,
      providers: [CatalogService],
      controllers: [CatalogController],
      exports: [CatalogService],
    };
  }
}
