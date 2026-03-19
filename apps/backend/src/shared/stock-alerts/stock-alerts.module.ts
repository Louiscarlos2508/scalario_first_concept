import { DynamicModule, Module } from '@nestjs/common';
import { StockAlertsService } from './stock-alerts.service';
import { StockAlertsController } from './stock-alerts.controller';

@Module({})
export class StockAlertsModule {
  static register(): DynamicModule {
    return {
      module: StockAlertsModule,
      controllers: [StockAlertsController],
      providers: [StockAlertsService],
      exports: [StockAlertsService],
    };
  }
}
