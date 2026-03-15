import { DynamicModule, Module } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { InventoryController } from './inventory.controller';

@Module({})
export class InventoryModule {
  static register(): DynamicModule {
    return {
      module: InventoryModule,
      controllers: [InventoryController],
      providers: [InventoryService],
      exports: [InventoryService],
    };
  }
}
