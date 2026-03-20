import { DynamicModule, Module } from '@nestjs/common';
import { PromotionsService } from './promotions.service';
import { PromotionsController } from './promotions.controller';
import { PromotionEngineService } from './promotion-engine.service';

@Module({})
export class PromotionsModule {
  static register(): DynamicModule {
    return {
      module: PromotionsModule,
      providers: [PromotionsService, PromotionEngineService],
      controllers: [PromotionsController],
      exports: [PromotionsService, PromotionEngineService],
    };
  }
}
