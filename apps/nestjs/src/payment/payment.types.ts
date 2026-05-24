/**
 * STORY-042 — PaymentAdapter contract.
 *
 * Global-scale-by-default : aucun provider (Wave, Orange Money, MTN MoMo)
 * n'est codé en dur dans le ModuleEngine. Le routage passe par le registry
 * qui résout `(tenant_id, payment_method, payment_provider)` → adapter.
 *
 * Phase 1 = 3 adapters : `CashAdapter`, `MobileMoneyAdapter` (sub-providers
 * en stub), `CreditAdapter`. Phase 2 branchera les intégrations réelles
 * Wave/OM/MoMo + webhooks signés.
 */

export type PaymentMethod = 'cash' | 'mobile_money' | 'credit';

export type PaymentProvider =
  | 'wave'
  | 'orange_money'
  | 'orange_money_ci'
  | 'mtn_momo'
  | 'moov_money'
  | 'internal_cash'
  | 'internal_credit';

export type PaymentStatus =
  | 'completed'
  | 'completed_simulated'
  | 'pending'
  | 'phase_2_stub'
  | 'failed';

export interface PaymentMeta {
  reference?: string;
  customer_phone?: string;
  user_id?: string;
  notes?: string;
  [key: string]: unknown;
}

export interface PaymentSession {
  session_id: string;
  status: PaymentStatus;
  provider: PaymentProvider;
  message?: string;
}

export interface PaymentResult {
  session_id: string;
  status: PaymentStatus;
  amount?: number;
  currency?: string;
  remaining_balance?: number;
  message?: string;
}

export interface PaymentInitiateInput {
  tenantId: string;
  amount: number;
  currency: string;
  method: PaymentMethod;
  provider?: PaymentProvider;
  meta?: PaymentMeta;
}

/**
 * Contract every adapter must implement. The registry treats adapters as
 * opaque — only the controller and `PaymentAdapterRegistry` know about
 * concrete types.
 */
export interface PaymentAdapter {
  readonly id: string;
  readonly supportedMethods: readonly PaymentMethod[];
  readonly supportedProviders?: readonly PaymentProvider[];

  initiate(input: PaymentInitiateInput): Promise<PaymentSession>;
  verify(sessionId: string): Promise<PaymentResult>;
  refund?(sessionId: string, amount: number): Promise<PaymentResult>;
}

export class PaymentAdapterNotFoundError extends Error {
  constructor(
    public readonly tenantId: string,
    public readonly method: PaymentMethod,
    public readonly provider?: PaymentProvider,
  ) {
    super(
      `No payment adapter for tenant '${tenantId}' method='${method}'${provider ? ` provider='${provider}'` : ''}`,
    );
    this.name = 'PaymentAdapterNotFoundError';
  }
}
