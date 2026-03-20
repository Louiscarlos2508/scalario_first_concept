import { DynamicModule, Module } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { CatalogController } from './catalog.controller';
import { VariantsService } from './variants/variants.service';
import { VariantsController } from './variants/variants.controller';
import { PriceLevelsService } from './price-levels/price-levels.service';
import { PriceLevelsController } from './price-levels/price-levels.controller';
import { SerialsService } from './serials/serials.service';
import { SerialsController } from './serials/serials.controller';
import { PriceHistoryService } from './price-history/price-history.service';

@Module({})
export class CatalogModule {
  static register(): DynamicModule {
    return {
      module: CatalogModule,
      providers: [CatalogService, VariantsService, PriceLevelsService, SerialsService, PriceHistoryService],
      controllers: [CatalogController, VariantsController, PriceLevelsController, SerialsController],
      exports: [CatalogService, VariantsService, PriceLevelsService, SerialsService, PriceHistoryService],
    };
  }
}
