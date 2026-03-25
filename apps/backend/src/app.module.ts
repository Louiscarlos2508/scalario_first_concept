import { Module } from '@nestjs/common';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ScheduleModule } from '@nestjs/schedule';
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
import { SduiModule } from './kernel/sdui/sdui.module';
import { AdminModule } from './admin/admin.module';
import { PurchaseOrdersModule } from './shared/purchase-orders/purchase-orders.module';
import { StockAlertsModule } from './shared/stock-alerts/stock-alerts.module';
import { NotificationsModule } from './shared/notifications/notifications.module';
import { BatchesModule } from './shared/batches/batches.module';
import { PromotionsModule } from './shared/promotions/promotions.module';
import { ReturnsModule } from './shared/returns/returns.module';
import { ReservationsModule } from './shared/reservations/reservations.module';
import { ClientOrdersModule } from './shared/client-orders/client-orders.module';
import { TenantModule } from './tenant/tenant.module';
import { InternalRequestsModule } from './shared/internal-requests/internal-requests.module';

@Module({
  imports: [
    EventEmitterModule.forRoot({
      wildcard: true,
      delimiter: '.',
      global: true,
    }),
    ScheduleModule.forRoot(),
    KernelModule,
    OrganizationModule,
    CatalogModule.register(),
    ContactsModule.register(),
    TransactionsModule.register(),
    InventoryModule.register(),
    PosModule,
    RetailModule.register(),
    ReportingModule.register(),
    SduiModule,
    PrismaModule,
    AdminModule,
    PurchaseOrdersModule.register(),
    StockAlertsModule.register(),
    NotificationsModule.register(),
    BatchesModule.register(),
    PromotionsModule.register(),
    ReturnsModule.register(),
    ReservationsModule.register(),
    ClientOrdersModule.register(),
    InternalRequestsModule.register(),
    TenantModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
