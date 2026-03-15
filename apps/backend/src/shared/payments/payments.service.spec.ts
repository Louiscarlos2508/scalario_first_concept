import { Test, TestingModule } from '@nestjs/testing';
import { PaymentsService } from './payments.service';

describe('PaymentsService', () => {
  let service: PaymentsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [PaymentsService],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
  });

  // ── roundTotal ────────────────────────────────────────────────────────────

  describe('roundTotal', () => {
    it('rounds 1247 down to 1245', () => {
      expect(service.roundTotal(1247)).toBe(1245);
    });

    it('rounds 1248 up to 1250', () => {
      expect(service.roundTotal(1248)).toBe(1250);
    });

    it('leaves 1250 unchanged (already rounded)', () => {
      expect(service.roundTotal(1250)).toBe(1250);
    });

    it('rounds 1 down to 0', () => {
      expect(service.roundTotal(1)).toBe(0);
    });

    it('rounds 3 up to 5 (midpoint rounds up)', () => {
      expect(service.roundTotal(3)).toBe(5);
    });

    it('rounds 0 to 0', () => {
      expect(service.roundTotal(0)).toBe(0);
    });

    it('rounds 500 to 500', () => {
      expect(service.roundTotal(500)).toBe(500);
    });
  });

  // ── calculateChange ───────────────────────────────────────────────────────

  describe('calculateChange', () => {
    it('returns 400 for 1000 paid on 600 total', () => {
      expect(service.calculateChange(600, 1000)).toBe(400);
    });

    it('returns 0 when paid equals total', () => {
      expect(service.calculateChange(600, 600)).toBe(0);
    });

    it('returns negative when underpaid', () => {
      expect(service.calculateChange(600, 500)).toBe(-100);
    });
  });

  // ── buildSplits ───────────────────────────────────────────────────────────

  describe('buildSplits', () => {
    it('converts map to array of { method, amount } objects', () => {
      const result = service.buildSplits({ CASH: 500, MOBILE_MONEY: 100 });
      expect(result).toHaveLength(2);
      expect(result).toEqual(
        expect.arrayContaining([
          { method: 'CASH', amount: 500 },
          { method: 'MOBILE_MONEY', amount: 100 },
        ]),
      );
    });

    it('returns empty array for empty splits', () => {
      expect(service.buildSplits({})).toEqual([]);
    });

    it('handles single split', () => {
      expect(service.buildSplits({ CREDIT: 1500 })).toEqual([
        { method: 'CREDIT', amount: 1500 },
      ]);
    });
  });
});
