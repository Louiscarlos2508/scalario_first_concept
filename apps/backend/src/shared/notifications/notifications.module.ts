import { DynamicModule, Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { DailySummaryJob } from './jobs/daily-summary.job';
import { StockAlertsModule } from '../stock-alerts/stock-alerts.module';

@Module({})
export class NotificationsModule {
  static register(): DynamicModule {
    return {
      module: NotificationsModule,
      imports: [StockAlertsModule.register()],
      controllers: [NotificationsController],
      providers: [NotificationsService, DailySummaryJob],
      exports: [NotificationsService],
    };
  }
}
