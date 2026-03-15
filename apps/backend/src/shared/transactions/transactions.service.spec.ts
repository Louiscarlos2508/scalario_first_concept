import { Test, TestingModule } from '@nestjs/testing';
import { TransactionsService } from './transactions.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { EventBusService } from '../../kernel/events/event-bus.service';
import { ContactsService } from '../contacts/contacts.service';
import { PaymentsService } from '../payments/payments.service';

const TENANT_ID = 'tenant-uuid-001';
const TX_ID = 'tx-uuid-001';
const CUSTOMER_ID = 'customer-uuid-001';

const makeData = (overrides: any = {}) => ({
  id: TX_ID,
  totalAmount: 1247,
  itemsJson: [{ name: 'Item A', qty: 1, price: 1247 }],
  paymentMethod: 'CASH',
  tenantId: TENANT_ID,
  ...overrides,
});

describe('TransactionsService', () => {
  let service: TransactionsService;
  let prisma: jest.Mocked<PrismaService>;
  let auditLog: jest.Mocked<AuditLogService>;
  let eventBus: jest.Mocked<EventBusService>;
  let contactsService: jest.Mocked<ContactsService>;
  let paymentsService: jest.Mocked<PaymentsService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TransactionsService,
        {
          provide: PrismaService,
          useValue: {
            transaction: {
              findUnique: jest.fn(),
              create: jest.fn(),
              findMany: jest.fn(),
              count: jest.fn(),
            },
          },
        },
        {
          provide: AuditLogService,
          useValue: { log: jest.fn() },
        },
        {
          provide: EventBusService,
          useValue: { publish: jest.fn() },
        },
        {
          provide: ContactsService,
          useValue: { updateBalance: jest.fn() },
        },
        {
          provide: PaymentsService,
          useValue: { roundTotal: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<TransactionsService>(TransactionsService);
    prisma = module.get(PrismaService);
    auditLog = module.get(AuditLogService);
    eventBus = module.get(EventBusService);
    contactsService = module.get(ContactsService);
    paymentsService = module.get(PaymentsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ── createTransaction ─────────────────────────────────────────────────────

  describe('createTransaction', () => {
    it('creates a new transaction, logs audit, and emits event (AC1, AC5)', async () => {
      const data = makeData();
      const createdTx = { ...data, id: TX_ID, totalAmount: 1245, createdAt: new Date() };

      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(null);
      (paymentsService.roundTotal as jest.Mock).mockReturnValue(1245);
      (prisma.transaction.create as jest.Mock).mockResolvedValue(createdTx);
      (auditLog.log as jest.Mock).mockResolvedValue(undefined);

      const result = await service.createTransaction(data, 'user-001');

      expect(prisma.transaction.findUnique).toHaveBeenCalledWith({ where: { id: TX_ID } });
      expect(paymentsService.roundTotal).toHaveBeenCalledWith(1247);
      expect(prisma.transaction.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ totalAmount: 1245 }) }),
      );
      expect(auditLog.log).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'CREATE', entity: 'Transaction', entityId: TX_ID }),
      );
      expect(eventBus.publish).toHaveBeenCalledWith('transaction.created', {
        transactionId: TX_ID,
        tenantId: TENANT_ID,
      });
      expect(result).toEqual(createdTx);
    });

    it('returns existing record without side effects when UUID already exists (AC1 — idempotent)', async () => {
      const existingTx = { id: TX_ID, totalAmount: 1245, tenantId: TENANT_ID };
      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(existingTx);

      const result = await service.createTransaction(makeData(), 'user-001');

      expect(result).toEqual(existingTx);
      expect(prisma.transaction.create).not.toHaveBeenCalled();
      expect(auditLog.log).not.toHaveBeenCalled();
      expect(eventBus.publish).not.toHaveBeenCalled();
      expect(contactsService.updateBalance).not.toHaveBeenCalled();
    });

    it('calls updateBalance with full amount for CREDIT payment (AC2)', async () => {
      const data = makeData({ paymentMethod: 'CREDIT', customerId: CUSTOMER_ID });
      const createdTx = { ...data, id: TX_ID, totalAmount: 1245 };

      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(null);
      (paymentsService.roundTotal as jest.Mock).mockReturnValue(1245);
      (prisma.transaction.create as jest.Mock).mockResolvedValue(createdTx);
      (contactsService.updateBalance as jest.Mock).mockResolvedValue(undefined);
      (auditLog.log as jest.Mock).mockResolvedValue(undefined);

      await service.createTransaction(data, null);

      expect(contactsService.updateBalance).toHaveBeenCalledWith(CUSTOMER_ID, 1245);
    });

    it('calls updateBalance with CREDIT portion only for SPLIT payment (AC3)', async () => {
      const splits = { CASH: 500, CREDIT: 745 };
      const data = makeData({ paymentMethod: 'SPLIT', paymentSplits: splits, customerId: CUSTOMER_ID });
      const createdTx = { ...data, id: TX_ID, totalAmount: 1245 };

      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(null);
      (paymentsService.roundTotal as jest.Mock).mockReturnValue(1245);
      (prisma.transaction.create as jest.Mock).mockResolvedValue(createdTx);
      (contactsService.updateBalance as jest.Mock).mockResolvedValue(undefined);
      (auditLog.log as jest.Mock).mockResolvedValue(undefined);

      await service.createTransaction(data, null);

      expect(contactsService.updateBalance).toHaveBeenCalledWith(CUSTOMER_ID, 745);
    });

    it('does not call updateBalance for CASH payment', async () => {
      const data = makeData({ paymentMethod: 'CASH', customerId: CUSTOMER_ID });
      const createdTx = { ...data, id: TX_ID, totalAmount: 1245 };

      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(null);
      (paymentsService.roundTotal as jest.Mock).mockReturnValue(1245);
      (prisma.transaction.create as jest.Mock).mockResolvedValue(createdTx);
      (auditLog.log as jest.Mock).mockResolvedValue(undefined);

      await service.createTransaction(data, null);

      expect(contactsService.updateBalance).not.toHaveBeenCalled();
    });
  });

  // ── getTransactions ───────────────────────────────────────────────────────

  describe('getTransactions', () => {
    const mockItems = [{ id: TX_ID, tenantId: TENANT_ID }];

    it('returns all transactions without since filter (AC4)', async () => {
      (prisma.transaction.findMany as jest.Mock).mockResolvedValue(mockItems);
      (prisma.transaction.count as jest.Mock).mockResolvedValue(1);

      const result = await service.getTransactions({ tenantId: TENANT_ID });

      expect(prisma.transaction.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { tenantId: TENANT_ID } }),
      );
      expect(result.items).toEqual(mockItems);
      expect(result.meta).toMatchObject({ total: 1, hasMore: false });
      expect(result.meta.serverTime).toBeDefined();
    });

    it('filters by createdAt gt since when provided (AC4)', async () => {
      const since = '2026-01-01T00:00:00.000Z';
      (prisma.transaction.findMany as jest.Mock).mockResolvedValue([]);
      (prisma.transaction.count as jest.Mock).mockResolvedValue(0);

      await service.getTransactions({ tenantId: TENANT_ID, since });

      expect(prisma.transaction.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { tenantId: TENANT_ID, createdAt: { gt: new Date(since) } },
        }),
      );
    });

    it('sets hasMore true when more records exist beyond current page', async () => {
      (prisma.transaction.findMany as jest.Mock).mockResolvedValue(mockItems);
      (prisma.transaction.count as jest.Mock).mockResolvedValue(10);

      const result = await service.getTransactions({ tenantId: TENANT_ID, page: 1, limit: 1 });

      expect(result.meta.hasMore).toBe(true);
    });
  });
});
