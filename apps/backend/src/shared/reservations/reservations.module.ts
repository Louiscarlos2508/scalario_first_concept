import { DynamicModule, Module } from '@nestjs/common';
import { ReservationsService } from './reservations.service';
import { ReservationsController } from './reservations.controller';
import { InventoryModule } from '../inventory/inventory.module';

@Module({})
export class ReservationsModule {
  static register(): DynamicModule {
    return {
      module: ReservationsModule,
      imports: [InventoryModule.register()],
      providers: [ReservationsService],
      controllers: [ReservationsController],
      exports: [ReservationsService],
    };
  }
}
