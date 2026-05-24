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
 * STORY-042 AC-16 — Internal credit (tenant-scoped). A "credit_line"
 * entry is logged in memory in Phase 1; Phase 2 will persist it via the
 * ModuleEngine. `verify` returns the running balance per user.
 */
@Injectable()
export class CreditAdapter implements PaymentAdapter {
  private readonly logger = new Logger(CreditAdapter.name);
  readonly id = 'credit';
  readonly supportedMethods: readonly PaymentMethod[] = ['credit'];

  // In-memory per-user balance. Phase 2 swaps for ModuleEngine entity.
  private readonly balances = new Map<string, number>(); // key: tenant:user → balance
  private readonly sessions = new Map<string, { tenantId: string; userId: string; amount: number; currency: string }>();

  private balanceKey(tenantId: string, userId: string): string {
    return `${tenantId}:${userId}`;
  }

  async initiate(input: PaymentInitiateInput): Promise<PaymentSession> {
    const userId = (input.meta?.user_id as string | undefined) ?? 'anonymous';
    const key = this.balanceKey(input.tenantId, userId);
    const current = this.balances.get(key) ?? 0;
    this.balances.set(key, current + input.amount);

    const sessionId = randomUUID();
    this.sessions.set(sessionId, {
      tenantId: input.tenantId,
      userId,
      amount: input.amount,
      currency: input.currency,
    });
    this.logger.log(
      `credit.initiate tenant=${input.tenantId} user=${userId} session=${sessionId} +${input.amount} ${input.currency} (balance=${current + input.amount})`,
    );
    return {
      session_id: sessionId,
      status: 'completed',
      provider: 'internal_credit',
      message: `Credit line debited; ${current + input.amount} ${input.currency} owed.`,
    };
  }

  async verify(sessionId: string): Promise<PaymentResult> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return { session_id: sessionId, status: 'failed', message: 'Credit session not found.' };
    }
    const balance = this.balances.get(this.balanceKey(session.tenantId, session.userId)) ?? 0;
    return {
      session_id: sessionId,
      status: 'completed',
      amount: session.amount,
      currency: session.currency,
      remaining_balance: balance,
    };
  }
}
