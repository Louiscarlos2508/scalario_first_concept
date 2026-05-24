import { Injectable, Logger } from '@nestjs/common';
import { CashAdapter } from './adapters/cash.adapter';
import { CreditAdapter } from './adapters/credit.adapter';
import { MobileMoneyAdapter } from './adapters/mobile-money.adapter';
import {
  PaymentAdapter,
  PaymentAdapterNotFoundError,
  PaymentMethod,
  PaymentProvider,
} from './payment.types';

/**
 * STORY-042 AC-17 — resolves an adapter for `(tenant_id, payment_method,
 * payment_provider)`. The tenant_id is passed for symmetry but Phase 1
 * uses a single global registry (the adapter set is identical across
 * tenants; what changes per tenant is `payment_methods_enabled` +
 * `payment_providers_default` in tenant_defaults).
 */
@Injectable()
export class PaymentAdapterRegistry {
  private readonly logger = new Logger(PaymentAdapterRegistry.name);
  private readonly byMethod: Map<PaymentMethod, PaymentAdapter>;

  constructor(
    cash: CashAdapter,
    mobileMoney: MobileMoneyAdapter,
    credit: CreditAdapter,
  ) {
    this.byMethod = new Map<PaymentMethod, PaymentAdapter>([
      ['cash', cash],
      ['mobile_money', mobileMoney],
      ['credit', credit],
    ]);
  }

  getAdapter(
    tenantId: string,
    method: PaymentMethod,
    provider?: PaymentProvider,
  ): PaymentAdapter {
    const adapter = this.byMethod.get(method);
    if (!adapter) {
      throw new PaymentAdapterNotFoundError(tenantId, method, provider);
    }
    if (provider && adapter.supportedProviders && !adapter.supportedProviders.includes(provider)) {
      throw new PaymentAdapterNotFoundError(tenantId, method, provider);
    }
    return adapter;
  }

  list(): readonly PaymentAdapter[] {
    return [...this.byMethod.values()];
  }
}
