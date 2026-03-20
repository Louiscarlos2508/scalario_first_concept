import { Module } from '@nestjs/common';
import { PosController } from './pos.controller';
import { PosService } from './pos.service';

import { PosSessionService } from './pos-session.service';
import { PosSessionController } from './pos-session.controller';
import { CustomerService } from './customer.service';
import { CustomerController } from './customer.controller';
import { CatalogModule } from '../shared/catalog/catalog.module';
import { ContactsModule } from '../shared/contacts/contacts.module';
import { TransactionsModule } from '../shared/transactions/transactions.module';
import { InventoryModule } from '../shared/inventory/inventory.module';
import { ReturnsModule } from '../shared/returns/returns.module';

@Module({
    imports: [CatalogModule.register(), ContactsModule.register(), TransactionsModule.register(), InventoryModule.register(), ReturnsModule.register()],
    providers: [PosService, PosSessionService, CustomerService],
    controllers: [PosController, PosSessionController, CustomerController],
})
export class PosModule { }
