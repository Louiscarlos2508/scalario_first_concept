import { Module } from '@nestjs/common';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { KernelModule } from './kernel/kernel.module';
import { OrganizationModule } from './organization/organization.module';
import { PosModule } from './pos/pos.module';
import { PrismaModule } from './prisma/prisma.module';
import { CatalogModule } from './shared/catalog/catalog.module';
import { ContactsModule } from './shared/contacts/contacts.module';
import { TransactionsModule } from './shared/transactions/transactions.module';
import { InventoryModule } from './shared/inventory/inventory.module';
import { RetailModule } from './retail/retail.module';
import { ReportingModule } from './reporting/reporting.module';

@Module({
  imports: [
    EventEmitterModule.forRoot({
      wildcard: true,
      delimiter: '.',
      global: true,
    }),
    KernelModule,
    OrganizationModule,
    CatalogModule.register(),
    ContactsModule.register(),
    TransactionsModule.register(),
    InventoryModule.register(),
    PosModule,
    RetailModule.register(),
    ReportingModule.register(),
    PrismaModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
