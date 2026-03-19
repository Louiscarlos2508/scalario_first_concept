import { DynamicModule, Module } from '@nestjs/common';
import { PurchaseOrdersService } from './purchase-orders.service';
import { PurchaseOrdersController } from './purchase-orders.controller';

@Module({})
export class PurchaseOrdersModule {
  static register(): DynamicModule {
    return {
      module: PurchaseOrdersModule,
      controllers: [PurchaseOrdersController],
      providers: [PurchaseOrdersService],
      exports: [PurchaseOrdersService],
    };
  }
}
