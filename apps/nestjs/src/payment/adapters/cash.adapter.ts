import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type {
  PaymentAdapter,
  PaymentInitiateInput,
  PaymentMethod,
  PaymentResult,
  PaymentSession,
} from '../payment.types';

/**
 * STORY-042 AC-14 — Cash payments. No external API; the act of recording
 * the sale is the payment. `initiate` completes immediately; `verify`
 * confirms the session always exists (logged on initiate).
 */
@Injectable()
export class CashAdapter implements PaymentAdapter {
  private readonly logger = new Logger(CashAdapter.name);
  readonly id = 'cash';
  readonly supportedMethods: readonly PaymentMethod[] = ['cash'];

  private readonly sessions = new Map<string, { amount: number; currency: string }>();

  async initiate(input: PaymentInitiateInput): Promise<PaymentSession> {
    const sessionId = randomUUID();
    this.sessions.set(sessionId, { amount: input.amount, currency: input.currency });
    this.logger.log(
      `cash.initiate tenant=${input.tenantId} session=${sessionId} amount=${input.amount} ${input.currency}`,
    );
    return {
      session_id: sessionId,
      status: 'completed',
      provider: 'internal_cash',
      message: 'Cash payment completed instantly.',
    };
  }

  async verify(sessionId: string): Promise<PaymentResult> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return {
        session_id: sessionId,
        status: 'failed',
        message: 'Cash session not found (may have been cleared).',
      };
    }
    return {
      session_id: sessionId,
      status: 'completed',
      amount: session.amount,
      currency: session.currency,
    };
  }
}
