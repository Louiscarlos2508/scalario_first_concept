import { Module } from '@nestjs/common';
import { CashAdapter } from './adapters/cash.adapter';
import { CreditAdapter } from './adapters/credit.adapter';
import { MobileMoneyAdapter } from './adapters/mobile-money.adapter';
import { PaymentAdapterRegistry } from './payment-adapter.registry';
import { PaymentController } from './payment.controller';

/**
 * STORY-042 — PaymentAdapter module. Provides the 3 Phase 1 adapters
 * (cash, mobile_money, credit) + the registry that resolves per
 * (tenant, method, provider) tuple.
 */
@Module({
  controllers: [PaymentController],
  providers: [CashAdapter, MobileMoneyAdapter, CreditAdapter, PaymentAdapterRegistry],
  exports: [PaymentAdapterRegistry],
})
export class PaymentModule {}
