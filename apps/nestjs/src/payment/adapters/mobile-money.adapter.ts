import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type {
  PaymentAdapter,
  PaymentInitiateInput,
  PaymentMethod,
  PaymentProvider,
  PaymentResult,
  PaymentSession,
} from '../payment.types';

/**
 * STORY-042 AC-15 — Mobile Money adapter. Strategy-style: dispatches on
 * the `provider` field to the right sub-handler (wave, orange_money,
 * orange_money_ci, mtn_momo, moov_money).
 *
 * Phase 1 = ALL sub-providers are stubs that return
 * `status: 'phase_2_stub'` on initiate and `'completed_simulated'` on
 * verify. Phase 2 will wire real APIs + signed webhooks.
 */
@Injectable()
export class MobileMoneyAdapter implements PaymentAdapter {
  private readonly logger = new Logger(MobileMoneyAdapter.name);
  readonly id = 'mobile_money';
  readonly supportedMethods: readonly PaymentMethod[] = ['mobile_money'];
  readonly supportedProviders: readonly PaymentProvider[] = [
    'wave',
    'orange_money',
    'orange_money_ci',
    'mtn_momo',
    'moov_money',
  ];

  private readonly sessions = new Map<string, { provider: PaymentProvider; amount: number; currency: string }>();

  async initiate(input: PaymentInitiateInput): Promise<PaymentSession> {
    const provider = input.provider ?? 'wave';
    if (!this.supportedProviders.includes(provider)) {
      return {
        session_id: '',
        status: 'failed',
        provider,
        message: `Provider '${provider}' not supported by MobileMoneyAdapter.`,
      };
    }
    const sessionId = `stub_${randomUUID()}`;
    this.sessions.set(sessionId, {
      provider,
      amount: input.amount,
      currency: input.currency,
    });
    this.logger.log(
      `mobile_money.initiate tenant=${input.tenantId} provider=${provider} session=${sessionId} amount=${input.amount} ${input.currency}`,
    );
    return {
      session_id: sessionId,
      status: 'phase_2_stub',
      provider,
      message: 'Phase 2 — real provider integration pending. Returning simulated session.',
    };
  }

  async verify(sessionId: string): Promise<PaymentResult> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return {
        session_id: sessionId,
        status: 'failed',
        message: 'Mobile money session not found.',
      };
    }
    return {
      session_id: sessionId,
      status: 'completed_simulated',
      amount: session.amount,
      currency: session.currency,
      message: `Simulated success for provider '${session.provider}' (Phase 1 stub).`,
    };
  }
}
