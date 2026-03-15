import { Test, TestingModule } from '@nestjs/testing';
import { RetailOrchestrationService } from './retail-orchestration.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventBusService } from '../kernel/events/event-bus.service';

const TENANT_ID = 'tenant-uuid-001';
const USER_ID = 'user-uuid-001';
const TX_ID = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const SALE_ID = 'b1ffcd00-0d1c-5fg9-cc7e-7cc0ce491b22';

const mockTx = {
  transaction: { create: jest.fn() },
  retailSale: { create: jest.fn() },
};

const mockPrisma = {
  $transaction: jest.fn(),
};

const mockEventBus = {
  publish: jest.fn(),
};

describe('RetailOrchestrationService', () => {
  let service: RetailOrchestrationService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RetailOrchestrationService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: EventBusService, useValue: mockEventBus },
      ],
    }).compile();

    service = module.get<RetailOrchestrationService>(RetailOrchestrationService);
  });

  // ── createSale ────────────────────────────────────────────────────────────

  describe('createSale', () => {
    it('creates Transaction + RetailSale atomically in a single $transaction (AC2)', async () => {
      const createdTransaction = { id: TX_ID, totalAmount: 50000, tenantId: TENANT_ID };
      const createdSale = { id: SALE_ID, transactionId: TX_ID };

      mockTx.transaction.create.mockResolvedValue(createdTransaction);
      mockTx.retailSale.create.mockResolvedValue(createdSale);
      mockPrisma.$transaction.mockImplementation((fn: (tx: typeof mockTx) => Promise<any>) => fn(mockTx));

      const result = await service.createSale({
        totalAmount: 50000,
        items: [{ name: 'Item A', quantity: 2, price: 25000 }],
        paymentMethod: 'CASH',
        sessionId: null,
        tenantId: TENANT_ID,
        userId: USER_ID,
      });

      expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
      expect(mockTx.transaction.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            totalAmount: 50000,
            tenantId: TENANT_ID,
          }),
        }),
      );
      expect(mockTx.retailSale.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            transactionId: TX_ID,
          }),
        }),
      );
      expect(result.transaction).toEqual(createdTransaction);
      expect(result.retailSale).toEqual(createdSale);
    });

    it('emits transaction.created event after commit (AC2)', async () => {
      const createdTransaction = { id: TX_ID, totalAmount: 50000, tenantId: TENANT_ID };
      const createdSale = { id: SALE_ID, transactionId: TX_ID };

      mockTx.transaction.create.mockResolvedValue(createdTransaction);
      mockTx.retailSale.create.mockResolvedValue(createdSale);
      mockPrisma.$transaction.mockImplementation((fn: (tx: typeof mockTx) => Promise<any>) => fn(mockTx));

      await service.createSale({
        totalAmount: 50000,
        paymentMethod: 'CASH',
        tenantId: TENANT_ID,
        userId: USER_ID,
      });

      expect(mockEventBus.publish).toHaveBeenCalledWith('transaction.created', {
        transactionId: TX_ID,
        tenantId: TENANT_ID,
      });
    });

    it('emits credit.applied event when paymentMethod is CREDIT and customerId provided (AC2)', async () => {
      const CUSTOMER_ID = 'cust-uuid-001';
      const createdTransaction = { id: TX_ID, totalAmount: 30000, tenantId: TENANT_ID };
      const createdSale = { id: SALE_ID, transactionId: TX_ID };

      mockTx.transaction.create.mockResolvedValue(createdTransaction);
      mockTx.retailSale.create.mockResolvedValue(createdSale);
      mockPrisma.$transaction.mockImplementation((fn: (tx: typeof mockTx) => Promise<any>) => fn(mockTx));

      await service.createSale({
        totalAmount: 30000,
        paymentMethod: 'CREDIT',
        customerId: CUSTOMER_ID,
        tenantId: TENANT_ID,
        userId: USER_ID,
      });

      expect(mockEventBus.publish).toHaveBeenCalledWith('credit.applied', {
        customerId: CUSTOMER_ID,
        amount: 30000,
        transactionId: TX_ID,
        tenantId: TENANT_ID,
      });
    });

    it('does NOT emit credit.applied when paymentMethod is CASH (AC2)', async () => {
      const createdTransaction = { id: TX_ID, totalAmount: 50000, tenantId: TENANT_ID };
      const createdSale = { id: SALE_ID, transactionId: TX_ID };

      mockTx.transaction.create.mockResolvedValue(createdTransaction);
      mockTx.retailSale.create.mockResolvedValue(createdSale);
      mockPrisma.$transaction.mockImplementation((fn: (tx: typeof mockTx) => Promise<any>) => fn(mockTx));

      await service.createSale({
        totalAmount: 50000,
        paymentMethod: 'CASH',
        tenantId: TENANT_ID,
        userId: USER_ID,
      });

      const creditCalls = mockEventBus.publish.mock.calls.filter(([event]) => event === 'credit.applied');
      expect(creditCalls).toHaveLength(0);
    });

    it('uses provided transactionId (idempotency support) (AC2)', async () => {
      const createdTransaction = { id: TX_ID, totalAmount: 20000, tenantId: TENANT_ID };
      const createdSale = { id: SALE_ID, transactionId: TX_ID };

      mockTx.transaction.create.mockResolvedValue(createdTransaction);
      mockTx.retailSale.create.mockResolvedValue(createdSale);
      mockPrisma.$transaction.mockImplementation((fn: (tx: typeof mockTx) => Promise<any>) => fn(mockTx));

      await service.createSale({
        transactionId: TX_ID,
        totalAmount: 20000,
        paymentMethod: 'CASH',
        tenantId: TENANT_ID,
        userId: USER_ID,
      });

      expect(mockTx.transaction.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ id: TX_ID }),
        }),
      );
    });
  });
});
