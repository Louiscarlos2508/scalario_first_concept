import { DynamicModule, Module } from '@nestjs/common';
import { ReturnsService } from './returns.service';
import { ReturnsController } from './returns.controller';
import { InventoryModule } from '../inventory/inventory.module';

@Module({})
export class ReturnsModule {
  static register(): DynamicModule {
    return {
      module: ReturnsModule,
      imports: [InventoryModule.register()],
      providers: [ReturnsService],
      controllers: [ReturnsController],
      exports: [ReturnsService],
    };
  }
}
