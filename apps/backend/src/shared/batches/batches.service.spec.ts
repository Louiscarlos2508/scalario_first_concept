import { Test, TestingModule } from '@nestjs/testing';
import { BatchesService } from './batches.service';
import { PrismaService } from '../../prisma/prisma.service';

const TENANT_ID = 'tenant-uuid';

const BATCH_ID = 'batch-uuid-1';

const makeBatch = (overrides: Partial<any> = {}) => ({
  id: 'batch-1',
  catalogItemId: 'item-1',
  tenantId: TENANT_ID,
  receivedAt: new Date(),
  expiresAt: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), // 5 days from now
  initialQty: 100,
  remainingQty: 80,
  batchRef: null,
  isDepleted: false,
  createdAt: new Date(),
  catalogItem: { name: 'Tomates', expiryDays: 10 },
  ...overrides,
});

describe('BatchesService', () => {
  let service: BatchesService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      productBatch: {
        findMany: jest.fn(),
        update: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BatchesService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = module.get<BatchesService>(BatchesService);
  });

  describe('getBatchesExpiring', () => {
    it('returns batches expiring within the given days window', async () => {
      const batch = makeBatch();
      (prisma.productBatch.findMany as jest.Mock).mockResolvedValue([batch]);

      const result = await service.getBatchesExpiring(TENANT_ID, 7);

      expect(prisma.productBatch.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ tenantId: TENANT_ID, isDepleted: false }),
          orderBy: { expiresAt: 'asc' },
        }),
      );
      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        batchId: 'batch-1',
        catalogItemId: 'item-1',
        itemName: 'Tomates',
        remainingQty: 80,
      });
    });

    it('computes freshnessPercent correctly (5 of 10 days remaining = 50%)', async () => {
      const expiresAt = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000);
      const batch = makeBatch({ expiresAt, catalogItem: { name: 'Tomates', expiryDays: 10 } });
      (prisma.productBatch.findMany as jest.Mock).mockResolvedValue([batch]);

      const result = await service.getBatchesExpiring(TENANT_ID, 7);

      expect(result[0].freshnessPercent).toBe(50);
    });

    it('caps freshnessPercent at 100', async () => {
      const expiresAt = new Date(Date.now() + 20 * 24 * 60 * 60 * 1000); // 20 days but expiryDays=10
      const batch = makeBatch({ expiresAt, catalogItem: { name: 'A', expiryDays: 10 } });
      (prisma.productBatch.findMany as jest.Mock).mockResolvedValue([batch]);

      const result = await service.getBatchesExpiring(TENANT_ID, 30);

      expect(result[0].freshnessPercent).toBe(100);
    });

    it('returns empty list when no batches match', async () => {
      (prisma.productBatch.findMany as jest.Mock).mockResolvedValue([]);
      const result = await service.getBatchesExpiring(TENANT_ID, 7);
      expect(result).toHaveLength(0);
    });
  });

  describe('getExpiringCount', () => {
    it('returns urgentCount of batches with freshnessPercent < 50', async () => {
      // Batch 1: expiresAt = 3 days, expiryDays = 10 → 30% → urgent
      const b1 = makeBatch({
        id: 'b1',
        expiresAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        catalogItem: { name: 'A', expiryDays: 10 },
      });
      // Batch 2: expiresAt = 7 days, expiryDays = 10 → 70% → not urgent
      const b2 = makeBatch({
        id: 'b2',
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        catalogItem: { name: 'B', expiryDays: 10 },
      });
      (prisma.productBatch.findMany as jest.Mock).mockResolvedValue([b1, b2]);

      const result = await service.getExpiringCount(TENANT_ID);

      expect(result.urgentCount).toBe(1);
    });

    it('returns urgentCount = 0 when no urgent batches', async () => {
      (prisma.productBatch.findMany as jest.Mock).mockResolvedValue([]);
      const result = await service.getExpiringCount(TENANT_ID);
      expect(result.urgentCount).toBe(0);
    });
  });

  describe('depleteBatch', () => {
    it('marks batch isDepleted=true and remainingQty=0', async () => {
      const updated = { id: BATCH_ID, isDepleted: true, remainingQty: 0 };
      (prisma.productBatch.update as jest.Mock).mockResolvedValue(updated);

      const result = await service.depleteBatch(BATCH_ID, TENANT_ID);

      expect(prisma.productBatch.update).toHaveBeenCalledWith({
        where: { id: BATCH_ID, tenantId: TENANT_ID },
        data: { isDepleted: true, remainingQty: 0 },
      });
      expect(result).toEqual(updated);
    });
  });
});
