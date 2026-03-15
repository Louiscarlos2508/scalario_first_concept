import { Test, TestingModule } from '@nestjs/testing';
import { TransactionsController } from './transactions.controller';
import { TransactionsService } from './transactions.service';

describe('TransactionsController', () => {
  let controller: TransactionsController;
  let service: jest.Mocked<TransactionsService>;

  const mockTx = { id: 'tx-uuid-001', totalAmount: 1245, tenantId: 'tenant-uuid-001' };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TransactionsController],
      providers: [
        {
          provide: TransactionsService,
          useValue: {
            createTransaction: jest.fn(),
            getTransactions: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<TransactionsController>(TransactionsController);
    service = module.get(TransactionsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /transactions', () => {
    it('extracts userId from req.user.sub and passes body to service', async () => {
      (service.createTransaction as jest.Mock).mockResolvedValue(mockTx);

      const body = { id: 'tx-uuid-001', totalAmount: 1247, tenantId: 'tenant-uuid-001' };
      const req = { user: { sub: 'user-sub-001' } };

      const result = await controller.createTransaction(body, req);

      expect(service.createTransaction).toHaveBeenCalledWith(body, 'user-sub-001');
      expect(result).toEqual(mockTx);
    });

    it('passes null userId when req.user is absent', async () => {
      (service.createTransaction as jest.Mock).mockResolvedValue(mockTx);

      const body = { id: 'tx-uuid-001', totalAmount: 1247, tenantId: 'tenant-uuid-001' };
      const req = {};

      await controller.createTransaction(body, req);

      expect(service.createTransaction).toHaveBeenCalledWith(body, null);
    });
  });

  describe('GET /transactions', () => {
    it('passes parsed query params to service', async () => {
      const mockResponse = {
        items: [mockTx],
        meta: { total: 1, page: 1, limit: 50, hasMore: false, serverTime: new Date().toISOString() },
      };
      (service.getTransactions as jest.Mock).mockResolvedValue(mockResponse);

      const result = await controller.getTransactions('tenant-uuid-001', '2026-01-01T00:00:00.000Z', '2', '50');

      expect(service.getTransactions).toHaveBeenCalledWith({
        tenantId: 'tenant-uuid-001',
        since: '2026-01-01T00:00:00.000Z',
        page: 2,
        limit: 50,
      });
      expect(result).toEqual(mockResponse);
    });

    it('uses default page=1 and limit=100 when not provided', async () => {
      (service.getTransactions as jest.Mock).mockResolvedValue({ items: [], meta: {} });

      await controller.getTransactions();

      expect(service.getTransactions).toHaveBeenCalledWith({
        tenantId: undefined,
        since: undefined,
        page: 1,
        limit: 100,
      });
    });
  });
});
