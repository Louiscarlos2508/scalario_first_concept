import { Test, TestingModule } from '@nestjs/testing';
import { ReportingController } from './reporting.controller';
import { ReportingService } from './reporting.service';

const TENANT_ID = 'tenant-uuid-001';

const mockReportingService = {
  getSalesReport: jest.fn(),
  getSessionReport: jest.fn(),
  getInventoryReport: jest.fn(),
  getSalesStats: jest.fn(),
  getCriticalStock: jest.fn(),
};

describe('ReportingController', () => {
  let controller: ReportingController;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [ReportingController],
      providers: [{ provide: ReportingService, useValue: mockReportingService }],
    }).compile();

    controller = module.get<ReportingController>(ReportingController);
  });

  // ── GET /reports/sales ────────────────────────────────────────────────────

  describe('getSalesReport (GET /reports/sales)', () => {
    it('delegates to getSalesReport with query params (AC1)', async () => {
      const report = { totalRevenue: 100000, saleCount: 3 };
      mockReportingService.getSalesReport.mockResolvedValue(report);

      const result = await controller.getSalesReport(TENANT_ID, '2026-03-01', '2026-03-15', 'day');

      expect(mockReportingService.getSalesReport).toHaveBeenCalledWith({
        tenantId: TENANT_ID,
        from: '2026-03-01',
        to: '2026-03-15',
        groupBy: 'day',
      });
      expect(result).toEqual(report);
    });
  });

  // ── GET /reports/sessions ─────────────────────────────────────────────────

  describe('getSessionReport (GET /reports/sessions)', () => {
    it('delegates to getSessionReport with query params (AC2)', async () => {
      const report = { sessions: [], totalVariance: 0 };
      mockReportingService.getSessionReport.mockResolvedValue(report);

      const result = await controller.getSessionReport(TENANT_ID, '2026-03-01', '2026-03-15');

      expect(mockReportingService.getSessionReport).toHaveBeenCalledWith({
        tenantId: TENANT_ID,
        from: '2026-03-01',
        to: '2026-03-15',
      });
      expect(result).toEqual(report);
    });
  });

  // ── GET /reports/inventory ────────────────────────────────────────────────

  describe('getInventoryReport (GET /reports/inventory)', () => {
    it('delegates to getInventoryReport when dates provided (AC3 7.1)', async () => {
      const report = { deliveries: [], transfersIn: [], transfersOut: [], losses: [], adjustments: [] };
      mockReportingService.getInventoryReport.mockResolvedValue(report);

      const result = await controller.getInventoryReport(TENANT_ID, '2026-03-01', '2026-03-15');

      expect(mockReportingService.getInventoryReport).toHaveBeenCalledWith({
        tenantId: TENANT_ID,
        from: '2026-03-01',
        to: '2026-03-15',
      });
      expect(result).toEqual(report);
    });

    it('delegates to getCriticalStock when no dates provided (AC2 7.2)', async () => {
      const stock = { criticalItems: [], allItems: [] };
      mockReportingService.getCriticalStock.mockResolvedValue(stock);

      const result = await controller.getInventoryReport(TENANT_ID, undefined, undefined);

      expect(mockReportingService.getCriticalStock).toHaveBeenCalledWith(TENANT_ID);
      expect(mockReportingService.getInventoryReport).not.toHaveBeenCalled();
      expect(result).toEqual(stock);
    });
  });

  // ── GET /reports/sales/stats ──────────────────────────────────────────────

  describe('getSalesStats (GET /reports/sales/stats)', () => {
    it('delegates to getSalesStats with query params (AC1 7.2)', async () => {
      const stats = { totalRevenue: 100000, saleCount: 5, avgTransactionValue: 20000 };
      mockReportingService.getSalesStats.mockResolvedValue(stats);

      const result = await controller.getSalesStats(TENANT_ID, '2026-03-01', '2026-03-15');

      expect(mockReportingService.getSalesStats).toHaveBeenCalledWith({
        tenantId: TENANT_ID,
        from: '2026-03-01',
        to: '2026-03-15',
      });
      expect(result).toEqual(stats);
    });
  });
});
