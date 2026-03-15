import { Injectable } from '@nestjs/common';

@Injectable()
export class PaymentsService {
  /**
   * Round a total to the nearest 5 FCFA (XOF currency rounding rule).
   * Examples: 1247 → 1245, 1248 → 1250, 1250 → 1250
   */
  roundTotal(amount: number): number {
    return Math.round(amount / 5) * 5;
  }

  /**
   * Calculate change due for a cash payment.
   * Returns paid - total (positive = change due, negative = underpayment).
   */
  calculateChange(total: number, paid: number): number {
    return paid - total;
  }

  /**
   * Convert a payment_splits map to an array of { method, amount } objects.
   * Example: { CASH: 500, MOBILE_MONEY: 100 } → [{ method: 'CASH', amount: 500 }, ...]
   */
  buildSplits(splits: Record<string, number>): { method: string; amount: number }[] {
    return Object.entries(splits).map(([method, amount]) => ({ method, amount }));
  }
}
