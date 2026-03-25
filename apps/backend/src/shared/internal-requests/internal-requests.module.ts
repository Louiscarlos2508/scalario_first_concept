import { DynamicModule, Module } from '@nestjs/common';
import { InternalRequestsService } from './internal-requests.service';
import { InternalRequestsController } from './internal-requests.controller';
import { InventoryModule } from '../inventory/inventory.module';

@Module({})
export class InternalRequestsModule {
  static register(): DynamicModule {
    return {
      module: InternalRequestsModule,
      imports: [InventoryModule.register()],
      controllers: [InternalRequestsController],
      providers: [InternalRequestsService],
      exports: [InternalRequestsService],
    };
  }
}
