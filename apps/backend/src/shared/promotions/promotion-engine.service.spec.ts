import { Test, TestingModule } from '@nestjs/testing';
import { PromotionEngineService } from './promotion-engine.service';
import { PromotionsService } from './promotions.service';

const mockPromotionsService = {
  getActivePromotionsForItem: jest.fn(),
};

describe('PromotionEngineService', () => {
  let engine: PromotionEngineService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PromotionEngineService,
        { provide: PromotionsService, useValue: mockPromotionsService },
      ],
    }).compile();
    engine = module.get<PromotionEngineService>(PromotionEngineService);
  });

  it('returns null when no promotions', async () => {
    mockPromotionsService.getActivePromotionsForItem.mockResolvedValue([]);
    const result = await engine.evaluate({ catalogItemId: 'i', quantity: 1, unitPrice: 1000, tenantId: 'tid' });
    expect(result).toBeNull();
  });

  it('PERCENT: calculates discount correctly', async () => {
    mockPromotionsService.getActivePromotionsForItem.mockResolvedValue([
      { id: 'p1', type: 'PERCENT', conflictRule: 'BEST', value: { percent: 20 } },
    ]);

    const result = await engine.evaluate({ catalogItemId: 'i', quantity: 1, unitPrice: 5000, tenantId: 'tid' });

    expect(result?.type).toBe('PERCENT');
    expect(result?.discountAmount).toBe(1000);
    expect(result?.discountedPrice).toBe(4000);
  });

  it('BUY_N_GET_M: applies when quantity >= buyN', async () => {
    mockPromotionsService.getActivePromotionsForItem.mockResolvedValue([
      { id: 'p2', type: 'BUY_N_GET_M', conflictRule: 'BEST', value: { buyN: 3, getM: 1 } },
    ]);

    const result = await engine.evaluate({ catalogItemId: 'i', quantity: 3, unitPrice: 1000, tenantId: 'tid' });

    expect(result?.type).toBe('BUY_N_GET_M');
    expect(result?.freeQty).toBe(1);
  });

  it('BUY_N_GET_M: does not apply when quantity < buyN', async () => {
    mockPromotionsService.getActivePromotionsForItem.mockResolvedValue([
      { id: 'p2', type: 'BUY_N_GET_M', conflictRule: 'BEST', value: { buyN: 3, getM: 1 } },
    ]);

    const result = await engine.evaluate({ catalogItemId: 'i', quantity: 2, unitPrice: 1000, tenantId: 'tid' });

    expect(result).toBeNull();
  });

  it('CROSSED_PRICE: uses newPrice', async () => {
    mockPromotionsService.getActivePromotionsForItem.mockResolvedValue([
      { id: 'p3', type: 'CROSSED_PRICE', conflictRule: 'BEST', value: { newPrice: 3500 } },
    ]);

    const result = await engine.evaluate({ catalogItemId: 'i', quantity: 1, unitPrice: 5000, tenantId: 'tid' });

    expect(result?.type).toBe('CROSSED_PRICE');
    expect(result?.discountedPrice).toBe(3500);
    expect(result?.discountAmount).toBe(1500);
  });

  it('BEST conflict: picks promotion with highest discount', async () => {
    mockPromotionsService.getActivePromotionsForItem.mockResolvedValue([
      { id: 'p1', type: 'PERCENT', conflictRule: 'BEST', value: { percent: 10 } },
      { id: 'p2', type: 'CROSSED_PRICE', conflictRule: 'BEST', value: { newPrice: 3000 } },
    ]);

    const result = await engine.evaluate({ catalogItemId: 'i', quantity: 1, unitPrice: 5000, tenantId: 'tid' });

    // PERCENT gives 500 discount, CROSSED_PRICE gives 2000 — CROSSED_PRICE wins
    expect(result?.id).toBe('p2');
  });
});
