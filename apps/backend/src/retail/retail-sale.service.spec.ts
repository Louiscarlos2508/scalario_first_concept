import { Test, TestingModule } from '@nestjs/testing';
import { RetailSaleService } from './retail-sale.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventBusService } from '../kernel/events/event-bus.service';

const TENANT_ID = 'tenant-uuid-001';
const TX_ID = 'tx-uuid-001';
const SESSION_ID = 'session-uuid-001';
const CASHIER_ID = 'cashier-uuid-001';

const mockPrisma = {
  $transaction: jest.fn(),
  retailSale: {
    create: jest.fn(),
  },
};

const mockEventBus = {
  publish: jest.fn(),
};

describe('RetailSaleService', () => {
  let service: RetailSaleService;

  beforeEach(async () => {
    jest.clearAllMocks();

    // Default: $transaction delegates to the passed async function with the mock prisma client
    mockPrisma.$transaction.mockImplementation((fn: (tx: any) => Promise<any>) => fn(mockPrisma));

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RetailSaleService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: EventBusService, useValue: mockEventBus },
      ],
    }).compile();

    service = module.get<RetailSaleService>(RetailSaleService);
  });

  // ── createRetailSale ─────────────────────────────────────────────────────

  describe('createRetailSale', () => {
    it('wraps RetailSale creation in prisma.$transaction (AC3 — atomic)', async () => {
      const retailSale = { id: 'rs-001', transactionId: TX_ID, sessionId: SESSION_ID, receiptNumber: 'REC-001', cashierId: CASHIER_ID };
      mockPrisma.retailSale.create.mockResolvedValue(retailSale);

      await service.createRetailSale({
        transactionId: TX_ID,
        sessionId: SESSION_ID,
        receiptNumber: 'REC-001',
        cashierId: CASHIER_ID,
        tenantId: TENANT_ID,
      });

      expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
      expect(mockPrisma.retailSale.create).toHaveBeenCalledWith({
        data: {
          transactionId: TX_ID,
          sessionId: SESSION_ID,
          receiptNumber: 'REC-001',
          cashierId: CASHIER_ID,
        },
      });
    });

    it('links RetailSale to active session via sessionId (AC3 — session scoping)', async () => {
      const retailSale = { id: 'rs-002', transactionId: TX_ID, sessionId: SESSION_ID, receiptNumber: 'REC-002', cashierId: CASHIER_ID };
      mockPrisma.retailSale.create.mockResolvedValue(retailSale);

      const result = await service.createRetailSale({
        transactionId: TX_ID,
        sessionId: SESSION_ID,
        receiptNumber: 'REC-002',
        cashierId: CASHIER_ID,
        tenantId: TENANT_ID,
      });

      expect(mockPrisma.retailSale.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ sessionId: SESSION_ID }),
        }),
      );
      expect(result.sessionId).toBe(SESSION_ID);
    });

    it('sets sessionId to null when not provided (AC3 — session optional)', async () => {
      const retailSale = { id: 'rs-003', transactionId: TX_ID, sessionId: null, receiptNumber: 'REC-003', cashierId: CASHIER_ID };
      mockPrisma.retailSale.create.mockResolvedValue(retailSale);

      await service.createRetailSale({
        transactionId: TX_ID,
        receiptNumber: 'REC-003',
        cashierId: CASHIER_ID,
        tenantId: TENANT_ID,
      });

      expect(mockPrisma.retailSale.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ sessionId: null }),
        }),
      );
    });

    it('publishes retail.sale.created event after creation (AC3)', async () => {
      const retailSale = { id: 'rs-004', transactionId: TX_ID, sessionId: SESSION_ID, receiptNumber: 'REC-004', cashierId: CASHIER_ID };
      mockPrisma.retailSale.create.mockResolvedValue(retailSale);

      await service.createRetailSale({
        transactionId: TX_ID,
        sessionId: SESSION_ID,
        receiptNumber: 'REC-004',
        cashierId: CASHIER_ID,
        tenantId: TENANT_ID,
      });

      expect(mockEventBus.publish).toHaveBeenCalledWith('retail.sale.created', {
        retailSaleId: 'rs-004',
        transactionId: TX_ID,
        sessionId: SESSION_ID,
        tenantId: TENANT_ID,
      });
    });

    it('returns the created RetailSale', async () => {
      const retailSale = { id: 'rs-005', transactionId: TX_ID, sessionId: null, receiptNumber: 'REC-005', cashierId: CASHIER_ID };
      mockPrisma.retailSale.create.mockResolvedValue(retailSale);

      const result = await service.createRetailSale({
        transactionId: TX_ID,
        receiptNumber: 'REC-005',
        cashierId: CASHIER_ID,
        tenantId: TENANT_ID,
      });

      expect(result).toEqual(retailSale);
    });
  });
});
