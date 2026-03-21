import { DynamicModule, Module } from '@nestjs/common';
import { ClientOrdersService } from './client-orders.service';
import { ClientOrdersController } from './client-orders.controller';
import { InventoryModule } from '../inventory/inventory.module';

@Module({})
export class ClientOrdersModule {
  static register(): DynamicModule {
    return {
      module: ClientOrdersModule,
      imports: [InventoryModule.register()],
      providers: [ClientOrdersService],
      controllers: [ClientOrdersController],
      exports: [ClientOrdersService],
    };
  }
}
