import { DynamicModule, Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';

@Module({})
export class PaymentsModule {
  static register(): DynamicModule {
    return {
      module: PaymentsModule,
      providers: [PaymentsService],
      exports: [PaymentsService],
    };
  }
}
