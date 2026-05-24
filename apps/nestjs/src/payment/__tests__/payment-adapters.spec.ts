import { CashAdapter } from '../adapters/cash.adapter';
import { CreditAdapter } from '../adapters/credit.adapter';
import { MobileMoneyAdapter } from '../adapters/mobile-money.adapter';
import { PaymentAdapterRegistry } from '../payment-adapter.registry';
import { PaymentAdapterNotFoundError } from '../payment.types';

describe('STORY-042 — Payment adapters + registry', () => {
  describe('AC-14 — CashAdapter', () => {
    it('initiate returns completed status immediately', async () => {
      const cash = new CashAdapter();
      const session = await cash.initiate({
        tenantId: 't1',
        amount: 1000,
        currency: 'XOF',
        method: 'cash',
      });
      expect(session.status).toBe('completed');
      expect(session.session_id).toBeTruthy();
      expect(session.provider).toBe('internal_cash');
    });

    it('verify returns the recorded amount + currency', async () => {
      const cash = new CashAdapter();
      const session = await cash.initiate({
        tenantId: 't1',
        amount: 2500,
        currency: 'EUR',
        method: 'cash',
      });
      const result = await cash.verify(session.session_id);
      expect(result.status).toBe('completed');
      expect(result.amount).toBe(2500);
      expect(result.currency).toBe('EUR');
    });

    it('verify on unknown session returns failed', async () => {
      const cash = new CashAdapter();
      const result = await cash.verify('non-existent');
      expect(result.status).toBe('failed');
    });
  });

  describe('AC-15 — MobileMoneyAdapter (Phase 1 stub)', () => {
    it('supports the 5 declared providers', () => {
      const mm = new MobileMoneyAdapter();
      expect(mm.supportedProviders).toEqual([
        'wave',
        'orange_money',
        'orange_money_ci',
        'mtn_momo',
        'moov_money',
      ]);
    });

    it('initiate returns phase_2_stub with stub_ prefix', async () => {
      const mm = new MobileMoneyAdapter();
      const session = await mm.initiate({
        tenantId: 't1',
        amount: 5000,
        currency: 'XOF',
        method: 'mobile_money',
        provider: 'wave',
      });
      expect(session.status).toBe('phase_2_stub');
      expect(session.session_id).toMatch(/^stub_/);
      expect(session.provider).toBe('wave');
    });

    it('initiate with unknown provider returns failed (not throw)', async () => {
      const mm = new MobileMoneyAdapter();
      const session = await mm.initiate({
        tenantId: 't1',
        amount: 100,
        currency: 'XOF',
        method: 'mobile_money',
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        provider: 'paypal' as any,
      });
      expect(session.status).toBe('failed');
    });

    it('verify returns completed_simulated', async () => {
      const mm = new MobileMoneyAdapter();
      const session = await mm.initiate({
        tenantId: 't1',
        amount: 8000,
        currency: 'XOF',
        method: 'mobile_money',
        provider: 'orange_money_ci',
      });
      const result = await mm.verify(session.session_id);
      expect(result.status).toBe('completed_simulated');
      expect(result.amount).toBe(8000);
    });
  });

  describe('AC-16 — CreditAdapter', () => {
    it('initiate accumulates the per-user balance', async () => {
      const credit = new CreditAdapter();
      const s1 = await credit.initiate({
        tenantId: 't1',
        amount: 1000,
        currency: 'XOF',
        method: 'credit',
        meta: { user_id: 'u1' },
      });
      const s2 = await credit.initiate({
        tenantId: 't1',
        amount: 500,
        currency: 'XOF',
        method: 'credit',
        meta: { user_id: 'u1' },
      });
      expect(s1.status).toBe('completed');
      expect(s2.status).toBe('completed');
      const r = await credit.verify(s2.session_id);
      expect(r.remaining_balance).toBe(1500);
    });

    it('balances are user-scoped within a tenant', async () => {
      const credit = new CreditAdapter();
      await credit.initiate({
        tenantId: 't1',
        amount: 1000,
        currency: 'XOF',
        method: 'credit',
        meta: { user_id: 'u1' },
      });
      const sU2 = await credit.initiate({
        tenantId: 't1',
        amount: 200,
        currency: 'XOF',
        method: 'credit',
        meta: { user_id: 'u2' },
      });
      const r = await credit.verify(sU2.session_id);
      expect(r.remaining_balance).toBe(200);
    });
  });

  describe('AC-17 — PaymentAdapterRegistry', () => {
    let registry: PaymentAdapterRegistry;
    beforeEach(() => {
      registry = new PaymentAdapterRegistry(
        new CashAdapter(),
        new MobileMoneyAdapter(),
        new CreditAdapter(),
      );
    });

    it('resolves cash → CashAdapter', () => {
      const adapter = registry.getAdapter('t1', 'cash');
      expect(adapter.id).toBe('cash');
    });

    it('resolves mobile_money + wave → MobileMoneyAdapter', () => {
      const adapter = registry.getAdapter('t1', 'mobile_money', 'wave');
      expect(adapter.id).toBe('mobile_money');
    });

    it('resolves credit → CreditAdapter', () => {
      const adapter = registry.getAdapter('t1', 'credit');
      expect(adapter.id).toBe('credit');
    });

    it('throws PaymentAdapterNotFoundError for unknown provider', () => {
      expect(() =>
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        registry.getAdapter('t1', 'mobile_money', 'paypal' as any),
      ).toThrow(PaymentAdapterNotFoundError);
    });

    it('list() returns the 3 adapters', () => {
      expect(registry.list()).toHaveLength(3);
    });
  });
});
