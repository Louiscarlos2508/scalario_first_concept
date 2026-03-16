import { DynamicModule, Module } from '@nestjs/common';
import { CatalogModule } from '../shared/catalog/catalog.module';
import { TransactionsModule } from '../shared/transactions/transactions.module';
import { InventoryModule } from '../shared/inventory/inventory.module';
import { PaymentsModule } from '../shared/payments/payments.module';
import { ContactsModule } from '../shared/contacts/contacts.module';
import { RetailController } from './retail.controller';
import { RetailSessionController } from './retail-session.controller';
import { RetailExpenseController } from './retail-expense.controller';
import { RetailOrchestrationService } from './retail-orchestration.service';
import { RetailSaleService } from './retail-sale.service';
import { PosSessionService } from '../pos/pos-session.service';
import { ExpenseService } from './expense.service';

@Module({})
export class RetailModule {
  static register(): DynamicModule {
    return {
      module: RetailModule,
      imports: [
        CatalogModule.register(),
        TransactionsModule.register(),
        InventoryModule.register(),
        PaymentsModule.register(),
        ContactsModule.register(),
      ],
      controllers: [RetailController, RetailSessionController, RetailExpenseController],
      providers: [RetailOrchestrationService, RetailSaleService, PosSessionService, ExpenseService],
      exports: [RetailOrchestrationService],
    };
  }
}
