import { Test, TestingModule } from '@nestjs/testing';
import { ReportingService } from './reporting.service';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

const TENANT_ID = 'tenant-uuid-001';

const mockPrisma = {
  transaction: { findMany: jest.fn() },
  inventoryMovement: { findMany: jest.fn() },
  posSession: { findMany: jest.fn() },
  retailProduct: { findMany: jest.fn() },
  expense: { findMany: jest.fn() },
};

describe('ReportingService', () => {
  let service: ReportingService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReportingService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<ReportingService>(ReportingService);
  });

  // ── getSalesReport ────────────────────────────────────────────────────────

  describe('getSalesReport', () => {
    it('aggregates totalRevenue, saleCount, and breakdownByPaymentMethod (AC1)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([
        { totalAmount: new Prisma.Decimal(50000), paymentMethod: 'CASH' },
        { totalAmount: new Prisma.Decimal(30000), paymentMethod: 'CASH' },
        { totalAmount: new Prisma.Decimal(20000), paymentMethod: 'MOBILE_MONEY' },
      ]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);

      const result = await service.getSalesReport({ tenantId: TENANT_ID });

      expect(result.totalRevenue).toBe(100000);
      expect(result.saleCount).toBe(3);
      expect(result.breakdownByPaymentMethod).toEqual({
        CASH: 80000,
        MOBILE_MONEY: 20000,
      });
    });

    it('calculates totalLosses from LOSS movements (AC1)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([
        { type: 'LOSS', quantity: new Prisma.Decimal(5) },
        { type: 'LOSS', quantity: new Prisma.Decimal(3) },
        { type: 'TRANSFER_IN', quantity: new Prisma.Decimal(10) },
      ]);

      const result = await service.getSalesReport({ tenantId: TENANT_ID });

      expect(result.totalLosses).toBe(8);
      expect(result.totalTransferVariances).toBe(1); // only TRANSFER_IN counted
    });

    it('passes date range filter to queries (AC1)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);

      await service.getSalesReport({
        tenantId: TENANT_ID,
        from: '2026-03-01',
        to: '2026-03-15',
      });

      const expectedTo = new Date('2026-03-15');
      expectedTo.setUTCHours(23, 59, 59, 999);
      expect(mockPrisma.transaction.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            tenantId: TENANT_ID,
            createdAt: { gte: new Date('2026-03-01'), lte: expectedTo },
          }),
        }),
      );
    });

    it('returns null from/to when no date filter provided (AC1)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);

      const result = await service.getSalesReport({ tenantId: TENANT_ID });

      expect(result.from).toBeNull();
      expect(result.to).toBeNull();
    });
  });

  // ── getSessionReport ──────────────────────────────────────────────────────

  describe('getSessionReport', () => {
    it('returns CLOSED sessions with totalVariance (AC2)', async () => {
      const sessions = [
        {
          id: 'sess-1',
          status: 'CLOSED',
          variance: new Prisma.Decimal(-500),
          varianceExplanation: 'Short change',
        },
        {
          id: 'sess-2',
          status: 'CLOSED',
          variance: new Prisma.Decimal(200),
          varianceExplanation: null,
        },
      ];
      mockPrisma.posSession.findMany.mockResolvedValue(sessions);

      const result = await service.getSessionReport({ tenantId: TENANT_ID });

      expect(mockPrisma.posSession.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ tenantId: TENANT_ID, status: 'CLOSED' }),
        }),
      );
      expect(result.sessions).toHaveLength(2);
      expect(result.totalVariance).toBe(-300); // -500 + 200
    });

    it('applies closedAt date filter when provided (AC2)', async () => {
      mockPrisma.posSession.findMany.mockResolvedValue([]);

      await service.getSessionReport({
        tenantId: TENANT_ID,
        from: '2026-03-01',
        to: '2026-03-15',
      });

      const expectedTo = new Date('2026-03-15');
      expectedTo.setUTCHours(23, 59, 59, 999);
      expect(mockPrisma.posSession.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            closedAt: { gte: new Date('2026-03-01'), lte: expectedTo },
          }),
        }),
      );
    });
  });

  // ── getInventoryReport ────────────────────────────────────────────────────

  describe('getInventoryReport', () => {
    it('groups movements by type correctly (AC3)', async () => {
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([
        { type: 'DELIVERY', quantity: new Prisma.Decimal(100) },
        { type: 'DELIVERY', quantity: new Prisma.Decimal(50) },
        { type: 'TRANSFER_IN', quantity: new Prisma.Decimal(30) },
        { type: 'TRANSFER_OUT', quantity: new Prisma.Decimal(30) },
        { type: 'LOSS', quantity: new Prisma.Decimal(5), reason: 'Expired' },
        { type: 'ADJUSTMENT', quantity: new Prisma.Decimal(2) },
      ]);

      const result = await service.getInventoryReport({ tenantId: TENANT_ID });

      expect(result.deliveries).toHaveLength(2);
      expect(result.transfersIn).toHaveLength(1);
      expect(result.transfersOut).toHaveLength(1);
      expect(result.losses).toHaveLength(1);
      expect(result.losses[0].reason).toBe('Expired');
      expect(result.adjustments).toHaveLength(1);
    });

    it('returns empty arrays when no movements in range (AC3)', async () => {
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);

      const result = await service.getInventoryReport({ tenantId: TENANT_ID });

      expect(result.deliveries).toHaveLength(0);
      expect(result.losses).toHaveLength(0);
    });
  });

  // ── getSalesStats ─────────────────────────────────────────────────────────

  describe('getSalesStats', () => {
    it('returns totalRevenue, saleCount, avgTransactionValue, totalLosses, totalCashVariance (AC1 7.2)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([
        { totalAmount: new Prisma.Decimal(60000), paymentMethod: 'CASH', itemsJson: [], createdAt: new Date('2026-03-20') },
        { totalAmount: new Prisma.Decimal(40000), paymentMethod: 'MOBILE_MONEY', itemsJson: [], createdAt: new Date('2026-03-20') },
      ]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([
        { type: 'LOSS', quantity: new Prisma.Decimal(3) },
      ]);
      mockPrisma.posSession.findMany.mockResolvedValue([
        { variance: new Prisma.Decimal(-500) },
        { variance: new Prisma.Decimal(200) },
      ]);
      mockPrisma.expense.findMany.mockResolvedValue([]);

      const result = await service.getSalesStats({ tenantId: TENANT_ID });

      expect(result.totalRevenue).toBe(100000);
      expect(result.saleCount).toBe(2);
      expect(result.avgTransactionValue).toBe(50000);
      expect(result.totalLosses).toBe(3);
      expect(result.totalCashVariance).toBe(-300);
    });

    it('computes top 3 products by quantity from itemsJson (AC1 7.2)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([
        {
          totalAmount: new Prisma.Decimal(10000),
          paymentMethod: 'CASH',
          createdAt: new Date('2026-03-20'),
          itemsJson: [
            { name: 'Milk', quantity: 10, price: 500 },
            { name: 'Bread', quantity: 5, price: 300 },
          ],
        },
        {
          totalAmount: new Prisma.Decimal(5000),
          paymentMethod: 'CASH',
          createdAt: new Date('2026-03-20'),
          itemsJson: [
            { name: 'Milk', quantity: 8, price: 500 },
            { name: 'Sugar', quantity: 20, price: 1000 },
            { name: 'Rice', quantity: 3, price: 800 },
          ],
        },
      ]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);
      mockPrisma.posSession.findMany.mockResolvedValue([]);
      mockPrisma.expense.findMany.mockResolvedValue([]);

      const result = await service.getSalesStats({ tenantId: TENANT_ID });

      // Sugar=20, Milk=18, Bread=5, Rice=3 — top 3: Sugar, Milk, Bread
      expect(result.top3Products).toHaveLength(3);
      expect(result.top3Products[0].name).toBe('Sugar');
      expect(result.top3Products[0].quantity).toBe(20);
      expect(result.top3Products[1].name).toBe('Milk');
      expect(result.top3Products[1].quantity).toBe(18);
    });

    it('returns avgTransactionValue=0 when no transactions (AC1 7.2)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);
      mockPrisma.posSession.findMany.mockResolvedValue([]);
      mockPrisma.expense.findMany.mockResolvedValue([]);

      const result = await service.getSalesStats({ tenantId: TENANT_ID });

      expect(result.avgTransactionValue).toBe(0);
      expect(result.top3Products).toHaveLength(0);
    });

    it('counts distinct customers with a purchase in the period (AC1 7.2)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([
        { totalAmount: new Prisma.Decimal(10000), paymentMethod: 'CASH', itemsJson: [], createdAt: new Date('2026-03-20'), customerId: 'cust-A' },
        { totalAmount: new Prisma.Decimal(5000), paymentMethod: 'CASH', itemsJson: [], createdAt: new Date('2026-03-20'), customerId: 'cust-A' },
        { totalAmount: new Prisma.Decimal(8000), paymentMethod: 'CASH', itemsJson: [], createdAt: new Date('2026-03-20'), customerId: 'cust-B' },
        { totalAmount: new Prisma.Decimal(3000), paymentMethod: 'CASH', itemsJson: [], createdAt: new Date('2026-03-20'), customerId: null },
      ]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);
      mockPrisma.posSession.findMany.mockResolvedValue([]);
      mockPrisma.expense.findMany.mockResolvedValue([]);

      const result = await service.getSalesStats({ tenantId: TENANT_ID });

      // 2 distinct customers (cust-A and cust-B); null customerId excluded
      expect(result.activeCustomerCount).toBe(2);
    });

    it('returns activeCustomerCount=0 when no transactions (AC1 7.2)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);
      mockPrisma.posSession.findMany.mockResolvedValue([]);
      mockPrisma.expense.findMany.mockResolvedValue([]);

      const result = await service.getSalesStats({ tenantId: TENANT_ID });

      expect(result.activeCustomerCount).toBe(0);
    });

    it('returns totalExpenses and netProfit in getSalesStats (AC5)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([
        { totalAmount: new Prisma.Decimal(100000), paymentMethod: 'CASH', itemsJson: [], createdAt: new Date('2026-03-20') },
      ]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);
      mockPrisma.posSession.findMany.mockResolvedValue([]);
      mockPrisma.expense.findMany.mockResolvedValue([
        { amount: new Prisma.Decimal(30000) },
        { amount: new Prisma.Decimal(20000) },
      ]);

      const result = await service.getSalesStats({ tenantId: TENANT_ID });

      expect(result.totalExpenses).toBe(50000);
      expect(result.netProfit).toBe(50000); // 100000 - 50000
    });

    it('returns dailyStats grouped by day for the line chart (AC1 7.2)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([
        { totalAmount: new Prisma.Decimal(20000), paymentMethod: 'CASH', itemsJson: [], createdAt: new Date('2026-03-18T10:00:00Z') },
        { totalAmount: new Prisma.Decimal(15000), paymentMethod: 'CASH', itemsJson: [], createdAt: new Date('2026-03-18T14:00:00Z') },
        { totalAmount: new Prisma.Decimal(30000), paymentMethod: 'CASH', itemsJson: [], createdAt: new Date('2026-03-20T09:00:00Z') },
      ]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);
      mockPrisma.posSession.findMany.mockResolvedValue([]);
      mockPrisma.expense.findMany.mockResolvedValue([]);

      const result = await service.getSalesStats({ tenantId: TENANT_ID });

      // 2 transactions on the 18th, 1 on the 20th (19th has none — not in array)
      expect(result.dailyStats).toHaveLength(2);
      expect(result.dailyStats[0]).toEqual({ day: '2026-03-18', revenue: 35000, orderCount: 2 });
      expect(result.dailyStats[1]).toEqual({ day: '2026-03-20', revenue: 30000, orderCount: 1 });
    });

    it('returns empty dailyStats when no transactions (AC1 7.2)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);
      mockPrisma.posSession.findMany.mockResolvedValue([]);
      mockPrisma.expense.findMany.mockResolvedValue([]);

      const result = await service.getSalesStats({ tenantId: TENANT_ID });

      expect(result.dailyStats).toHaveLength(0);
    });

    it('returns netProfit=0 when no sales and no expenses (AC5)', async () => {
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      mockPrisma.inventoryMovement.findMany.mockResolvedValue([]);
      mockPrisma.posSession.findMany.mockResolvedValue([]);
      mockPrisma.expense.findMany.mockResolvedValue([]);

      const result = await service.getSalesStats({ tenantId: TENANT_ID });

      expect(result.totalExpenses).toBe(0);
      expect(result.netProfit).toBe(0);
    });
  });

  // ── getCriticalStock ──────────────────────────────────────────────────────

  describe('getCriticalStock', () => {
    it('flags items below minStockLevel as critical (AC2 7.2)', async () => {
      mockPrisma.retailProduct.findMany.mockResolvedValue([
        {
          id: 'prod-1',
          stockQuantity: new Prisma.Decimal(2),
          minStockLevel: new Prisma.Decimal(5),
          catalogItem: { name: 'Milk', barcode: '1234' },
        },
        {
          id: 'prod-2',
          stockQuantity: new Prisma.Decimal(10),
          minStockLevel: new Prisma.Decimal(3),
          catalogItem: { name: 'Bread', barcode: '5678' },
        },
        {
          id: 'prod-3',
          stockQuantity: new Prisma.Decimal(0),
          minStockLevel: null,
          catalogItem: { name: 'Rice', barcode: null },
        },
      ]);

      const result = await service.getCriticalStock(TENANT_ID);

      // Only prod-1 is critical (2 <= 5); prod-2 has 10 > 3; prod-3 has no threshold
      expect(result.criticalItems).toHaveLength(1);
      expect(result.criticalItems[0].name).toBe('Milk');
      expect(result.criticalItems[0].stockQuantity).toBe(2);
      expect(result.allItems).toHaveLength(3);
      const milkItem = result.allItems.find((i) => i.name === 'Milk');
      expect(milkItem?.isCritical).toBe(true);
      const breadItem = result.allItems.find((i) => i.name === 'Bread');
      expect(breadItem?.isCritical).toBe(false);
    });

    it('returns empty criticalItems when all stock is sufficient (AC2 7.2)', async () => {
      mockPrisma.retailProduct.findMany.mockResolvedValue([
        {
          id: 'prod-1',
          stockQuantity: new Prisma.Decimal(100),
          minStockLevel: new Prisma.Decimal(5),
          catalogItem: { name: 'Flour', barcode: null },
        },
      ]);

      const result = await service.getCriticalStock(TENANT_ID);

      expect(result.criticalItems).toHaveLength(0);
      expect(result.allItems).toHaveLength(1);
    });
  });
});
