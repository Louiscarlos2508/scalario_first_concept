import { DynamicModule, Module } from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import { TransactionsController } from './transactions.controller';
import { ContactsModule } from '../contacts/contacts.module';
import { PaymentsModule } from '../payments/payments.module';

@Module({})
export class TransactionsModule {
  static register(): DynamicModule {
    return {
      module: TransactionsModule,
      imports: [ContactsModule.register(), PaymentsModule.register()],
      providers: [TransactionsService],
      controllers: [TransactionsController],
      exports: [TransactionsService],
    };
  }
}
