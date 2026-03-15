import { DynamicModule, Module } from '@nestjs/common';
import { CatalogModule } from '../shared/catalog/catalog.module';
import { TransactionsModule } from '../shared/transactions/transactions.module';
import { InventoryModule } from '../shared/inventory/inventory.module';
import { ReportingController } from './reporting.controller';
import { ReportingService } from './reporting.service';

@Module({})
export class ReportingModule {
  static register(): DynamicModule {
    return {
      module: ReportingModule,
      imports: [
        TransactionsModule.register(),
        InventoryModule.register(),
        CatalogModule.register(),
      ],
      controllers: [ReportingController],
      providers: [ReportingService],
      exports: [ReportingService],
    };
  }
}
