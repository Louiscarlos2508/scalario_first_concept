import { Test, TestingModule } from '@nestjs/testing';
import { StockAlertsService } from './stock-alerts.service';
import { PrismaService } from '../../prisma/prisma.service';
import { EventBusService } from '../../kernel/events/event-bus.service';

const mockPrisma = {
  retailProduct: {
    findMany: jest.fn(),
    findUnique: jest.fn(),
  },
};

const mockEventBus = { publish: jest.fn() };

const TENANT = 'tenant-1';

describe('StockAlertsService', () => {
  let service: StockAlertsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StockAlertsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: EventBusService, useValue: mockEventBus },
      ],
    }).compile();
    service = module.get(StockAlertsService);
    jest.clearAllMocks();
  });

  describe('getAlertsCount()', () => {
    it('counts items where stockQuantity <= minStockLevel', async () => {
      mockPrisma.retailProduct.findMany.mockResolvedValue([
        { stockQuantity: 5, minStockLevel: 10 },  // below → counts
        { stockQuantity: 10, minStockLevel: 10 }, // equal → counts
        { stockQuantity: 15, minStockLevel: 10 }, // above → does not count
      ]);
      const count = await service.getAlertsCount(TENANT);
      expect(count).toBe(2);
    });

    it('returns 0 when no items are below threshold', async () => {
      mockPrisma.retailProduct.findMany.mockResolvedValue([
        { stockQuantity: 20, minStockLevel: 5 },
      ]);
      const count = await service.getAlertsCount(TENANT);
      expect(count).toBe(0);
    });
  });

  describe('getAlerts()', () => {
    it('returns alerts sorted by deficit descending', async () => {
      mockPrisma.retailProduct.findMany.mockResolvedValue([
        {
          catalogItemId: 'item-A',
          stockQuantity: 3,
          minStockLevel: 10,
          catalogItem: { name: 'Riz', tenantId: TENANT },
        },
        {
          catalogItemId: 'item-B',
          stockQuantity: 8,
          minStockLevel: 10,
          catalogItem: { name: 'Huile', tenantId: TENANT },
        },
      ]);
      const alerts = await service.getAlerts(TENANT);
      expect(alerts).toHaveLength(2);
      // item-A: deficit = 10-3 = 7, item-B: deficit = 10-8 = 2
      expect(alerts[0].catalogItemId).toBe('item-A');
      expect(alerts[0].deficit).toBe(7);
      expect(alerts[1].deficit).toBe(2);
    });

    it('excludes items above threshold', async () => {
      mockPrisma.retailProduct.findMany.mockResolvedValue([
        {
          catalogItemId: 'item-C',
          stockQuantity: 20,
          minStockLevel: 10,
          catalogItem: { name: 'Sucre', tenantId: TENANT },
        },
      ]);
      const alerts = await service.getAlerts(TENANT);
      expect(alerts).toHaveLength(0);
    });
  });

  describe('evaluateAfterMovement()', () => {
    it('publishes LowStockDetected when stock <= minStockLevel', async () => {
      mockPrisma.retailProduct.findUnique.mockResolvedValue({
        stockQuantity: 3,
        minStockLevel: 5,
        catalogItem: { name: 'Farine' },
      });
      await service.evaluateAfterMovement('item-1', TENANT);
      expect(mockEventBus.publish).toHaveBeenCalledWith('LowStockDetected', {
        tenantId: TENANT,
        catalogItemId: 'item-1',
        itemName: 'Farine',
        stockQuantity: 3,
        minStockLevel: 5,
      });
    });

    it('does NOT publish when stock > minStockLevel', async () => {
      mockPrisma.retailProduct.findUnique.mockResolvedValue({
        stockQuantity: 10,
        minStockLevel: 5,
        catalogItem: { name: 'Sel' },
      });
      await service.evaluateAfterMovement('item-2', TENANT);
      expect(mockEventBus.publish).not.toHaveBeenCalled();
    });

    it('does nothing when RetailProduct has no minStockLevel', async () => {
      mockPrisma.retailProduct.findUnique.mockResolvedValue({
        stockQuantity: 3,
        minStockLevel: null,
        catalogItem: { name: 'Poivre' },
      });
      await service.evaluateAfterMovement('item-3', TENANT);
      expect(mockEventBus.publish).not.toHaveBeenCalled();
    });

    it('does nothing when catalogItemId is empty', async () => {
      await service.evaluateAfterMovement('', TENANT);
      expect(mockPrisma.retailProduct.findUnique).not.toHaveBeenCalled();
    });
  });

  describe('onStockAdjusted()', () => {
    it('calls evaluateAfterMovement for SALE type', async () => {
      mockPrisma.retailProduct.findUnique.mockResolvedValue(null);
      await service.onStockAdjusted({ catalogItemId: 'item-1', type: 'SALE', tenantId: TENANT });
      expect(mockPrisma.retailProduct.findUnique).toHaveBeenCalled();
    });

    it('ignores TRANSFER_IN type', async () => {
      await service.onStockAdjusted({ catalogItemId: 'item-1', type: 'TRANSFER_IN', tenantId: TENANT });
      expect(mockPrisma.retailProduct.findUnique).not.toHaveBeenCalled();
    });
  });
});
