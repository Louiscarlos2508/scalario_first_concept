import { Test, TestingModule } from '@nestjs/testing';
import { CatalogService } from './catalog.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';

const mockPrisma = {
  category: {
    findMany: jest.fn(),
    create: jest.fn(),
    delete: jest.fn(),
  },
  catalogItem: {
    findMany: jest.fn(),
    count: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    upsert: jest.fn(),
  },
};

const mockAuditLog = {
  log: jest.fn(),
};

describe('CatalogService', () => {
  let service: CatalogService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CatalogService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditLogService, useValue: mockAuditLog },
      ],
    }).compile();

    service = module.get<CatalogService>(CatalogService);
  });

  // ── Categories ───────────────────────────────────────────────────────────

  describe('getCategories', () => {
    it('returns categories for tenant ordered by name', async () => {
      const cats = [{ id: 'cat-1', name: 'Boissons', tenantId: 'tid' }];
      mockPrisma.category.findMany.mockResolvedValue(cats);

      const result = await service.getCategories('tid');

      expect(mockPrisma.category.findMany).toHaveBeenCalledWith({
        where: { tenantId: 'tid' },
        orderBy: { name: 'asc' },
      });
      expect(result).toEqual(cats);
    });
  });

  describe('createCategory', () => {
    it('creates a category with name and tenantId', async () => {
      const newCat = { id: 'cat-2', name: 'Épicerie', tenantId: 'tid' };
      mockPrisma.category.create.mockResolvedValue(newCat);

      const result = await service.createCategory({ name: 'Épicerie', tenantId: 'tid' });

      expect(mockPrisma.category.create).toHaveBeenCalledWith({
        data: { name: 'Épicerie', tenantId: 'tid' },
      });
      expect(result).toEqual(newCat);
    });
  });

  describe('deleteCategory', () => {
    it('deletes a category by id', async () => {
      const deleted = { id: 'cat-1', name: 'Old', tenantId: 'tid' };
      mockPrisma.category.delete.mockResolvedValue(deleted);

      const result = await service.deleteCategory('cat-1');

      expect(mockPrisma.category.delete).toHaveBeenCalledWith({
        where: { id: 'cat-1' },
      });
      expect(result).toEqual(deleted);
    });
  });

  // ── Items ─────────────────────────────────────────────────────────────────

  describe('getItems', () => {
    it('returns paginated items with meta, excluding soft-deleted when no since', async () => {
      const items = [{ id: 'item-1', name: 'Bière', isDeleted: false, retailProduct: null }];
      mockPrisma.catalogItem.findMany.mockResolvedValue(items);
      mockPrisma.catalogItem.count.mockResolvedValue(1);

      const result = await service.getItems({ tenantId: 'tid', page: 1, limit: 100 });

      expect(mockPrisma.catalogItem.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ isDeleted: false, tenantId: 'tid' }),
          orderBy: { updatedAt: 'asc' },
          skip: 0,
          take: 100,
          include: { retailProduct: true },
        }),
      );
      expect(result.items).toEqual([
        { id: 'item-1', name: 'Bière', isDeleted: false, stockQuantity: null, weightUnit: null, minStockLevel: null },
      ]);
      expect(result.meta).toEqual(
        expect.objectContaining({ total: 1, page: 1, limit: 100, hasMore: false }),
      );
      expect(result.meta.serverTime).toBeDefined();
    });

    it('flattens RetailProduct fields into catalog item response (AC3)', async () => {
      const retailProduct = { id: 'rp-1', catalogItemId: 'item-2', stockQuantity: 42.5, weightUnit: null, minStockLevel: 10 };
      const items = [{ id: 'item-2', name: 'Coca-Cola 50cl', isDeleted: false, retailProduct }];
      mockPrisma.catalogItem.findMany.mockResolvedValue(items);
      mockPrisma.catalogItem.count.mockResolvedValue(1);

      const result = await service.getItems({ tenantId: 'tid' });

      expect(result.items[0]).toMatchObject({
        id: 'item-2',
        name: 'Coca-Cola 50cl',
        stockQuantity: 42.5,
        weightUnit: null,
        minStockLevel: 10,
      });
      expect((result.items[0] as any).retailProduct).toBeUndefined();
    });

    it('returns null retail fields when CatalogItem has no RetailProduct', async () => {
      const items = [{ id: 'item-3', name: 'Service', isDeleted: false, retailProduct: null }];
      mockPrisma.catalogItem.findMany.mockResolvedValue(items);
      mockPrisma.catalogItem.count.mockResolvedValue(1);

      const result = await service.getItems({ tenantId: 'tid' });

      expect(result.items[0]).toMatchObject({
        id: 'item-3',
        stockQuantity: null,
        weightUnit: null,
        minStockLevel: null,
      });
    });

    it('uses updatedAt filter and includes soft-deleted when since is provided', async () => {
      mockPrisma.catalogItem.findMany.mockResolvedValue([]);
      mockPrisma.catalogItem.count.mockResolvedValue(0);

      const since = '2026-03-01T00:00:00.000Z';
      await service.getItems({ tenantId: 'tid', since });

      expect(mockPrisma.catalogItem.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            updatedAt: { gt: new Date(since) },
            tenantId: 'tid',
          }),
        }),
      );
    });

    it('applies query filter on name and barcode', async () => {
      mockPrisma.catalogItem.findMany.mockResolvedValue([]);
      mockPrisma.catalogItem.count.mockResolvedValue(0);

      await service.getItems({ tenantId: 'tid', query: 'beer' });

      expect(mockPrisma.catalogItem.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            OR: [
              { name: { contains: 'beer', mode: 'insensitive' } },
              { barcode: { contains: 'beer', mode: 'insensitive' } },
            ],
          }),
        }),
      );
    });

    it('calculates hasMore correctly', async () => {
      mockPrisma.catalogItem.findMany.mockResolvedValue(new Array(100).fill({}));
      mockPrisma.catalogItem.count.mockResolvedValue(105);

      const result = await service.getItems({ limit: 100 });

      expect(result.meta.hasMore).toBe(true);
    });
  });

  describe('syncItems', () => {
    it('upserts each item and returns results', async () => {
      const items = [
        { id: 'item-1', name: 'Bière', price: 500, tenantId: 'tid' },
        { id: 'item-2', name: 'Eau', price: 200, tenantId: 'tid' },
      ];
      mockPrisma.catalogItem.upsert
        .mockResolvedValueOnce(items[0])
        .mockResolvedValueOnce(items[1]);

      const result = await service.syncItems(items);

      expect(mockPrisma.catalogItem.upsert).toHaveBeenCalledTimes(2);
      expect(mockPrisma.catalogItem.upsert).toHaveBeenCalledWith({
        where: { id: 'item-1' },
        update: items[0],
        create: items[0],
      });
      expect(result).toEqual(items);
    });

    it('returns empty array when no items provided', async () => {
      const result = await service.syncItems([]);
      expect(mockPrisma.catalogItem.upsert).not.toHaveBeenCalled();
      expect(result).toEqual([]);
    });
  });

  describe('createItem', () => {
    it('creates a catalog item with default itemType=physical', async () => {
      const newItem = {
        id: 'item-1',
        name: 'Bière Castel',
        price: '500',
        itemType: 'physical',
        tenantId: 'tid',
      };
      mockPrisma.catalogItem.create.mockResolvedValue(newItem);
      mockAuditLog.log.mockResolvedValue(undefined);

      const result = await service.createItem(
        { name: 'Bière Castel', price: 500, tenantId: 'tid' },
        'user-123',
      );

      expect(mockPrisma.catalogItem.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          name: 'Bière Castel',
          price: 500,
          tenantId: 'tid',
          itemType: 'physical',
        }),
      });
      expect(result).toEqual(newItem);
    });

    it('records AuditLog with action=CREATE on item creation', async () => {
      const newItem = { id: 'item-2', name: 'Test', price: '100', itemType: 'physical', tenantId: 'tid' };
      mockPrisma.catalogItem.create.mockResolvedValue(newItem);
      mockAuditLog.log.mockResolvedValue(undefined);

      await service.createItem({ name: 'Test', price: 100, tenantId: 'tid' }, 'user-abc');

      expect(mockAuditLog.log).toHaveBeenCalledWith(
        expect.objectContaining({
          tenantId: 'tid',
          userId: 'user-abc',
          action: 'CREATE',
          entity: 'CatalogItem',
          entityId: 'item-2',
        }),
      );
    });

    it('accepts explicit itemType', async () => {
      const newItem = { id: 'item-3', itemType: 'service', tenantId: 'tid', name: 'Réparation', price: '1000' };
      mockPrisma.catalogItem.create.mockResolvedValue(newItem);
      mockAuditLog.log.mockResolvedValue(undefined);

      await service.createItem(
        { name: 'Réparation', price: 1000, tenantId: 'tid', itemType: 'service' },
        null,
      );

      expect(mockPrisma.catalogItem.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ itemType: 'service' }),
      });
    });
  });

  // ── Epic 20 — unitType + conversionRate ──────────────────────────────────

  describe('createItem — unitType (AC2, AC5)', () => {
    it('persists unitType=weight when provided', async () => {
      const newItem = { id: 'item-w', name: 'Tomates', price: '1500', unitType: 'weight', tenantId: 'tid', itemType: 'physical', pricePerUnit: null, conversionRate: null };
      mockPrisma.catalogItem.create.mockResolvedValue(newItem);
      mockAuditLog.log.mockResolvedValue(undefined);

      const result = await service.createItem(
        { name: 'Tomates', price: 1500, tenantId: 'tid', unitType: 'weight' },
        null,
      );

      expect(mockPrisma.catalogItem.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ unitType: 'weight' }),
      });
      expect(result.unitType).toBe('weight');
    });

    it('throws BadRequestException for invalid unitType', async () => {
      await expect(
        service.createItem(
          { name: 'X', price: 100, tenantId: 'tid', unitType: 'invalid' as any },
          null,
        ),
      ).rejects.toThrow('Invalid unitType');
      expect(mockPrisma.catalogItem.create).not.toHaveBeenCalled();
    });

    it('defaults unitType to piece when not provided', async () => {
      const newItem = { id: 'item-p', name: 'Bière', price: '500', unitType: 'piece', tenantId: 'tid', itemType: 'physical', pricePerUnit: null, conversionRate: null };
      mockPrisma.catalogItem.create.mockResolvedValue(newItem);
      mockAuditLog.log.mockResolvedValue(undefined);

      await service.createItem({ name: 'Bière', price: 500, tenantId: 'tid' }, null);

      expect(mockPrisma.catalogItem.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ unitType: 'piece' }),
      });
    });
  });

  describe('applyConversionRate (AC4, AC5)', () => {
    it('returns quantity × conversionRate when conversionRate is set', () => {
      expect(service.applyConversionRate(3, 0.5)).toBe(1.5);
    });

    it('returns quantity unchanged when conversionRate is null', () => {
      expect(service.applyConversionRate(3, null)).toBe(3);
    });

    it('returns quantity unchanged when conversionRate is undefined', () => {
      expect(service.applyConversionRate(3, undefined)).toBe(3);
    });
  });

  describe('updateItem (AC2, PATCH endpoint)', () => {
    it('updates unitType on an existing item', async () => {
      const updated = { id: 'item-1', unitType: 'weight', name: 'Tomates', tenantId: 'tid' };
      mockPrisma.catalogItem.update.mockResolvedValue(updated);
      mockAuditLog.log.mockResolvedValue(undefined);

      const result = await service.updateItem('item-1', { unitType: 'weight' }, null, 'tid');

      expect(mockPrisma.catalogItem.update).toHaveBeenCalledWith({
        where: { id: 'item-1' },
        data: expect.objectContaining({ unitType: 'weight' }),
        include: { retailProduct: true },
      });
      expect(result.unitType).toBe('weight');
    });

    it('throws BadRequestException for invalid unitType on update', async () => {
      await expect(
        service.updateItem('item-1', { unitType: 'bad' as any }, null, 'tid'),
      ).rejects.toThrow('Invalid unitType');
    });
  });

  describe('deleteItem', () => {
    it('soft-deletes item (is_deleted = true)', async () => {
      const updated = { id: 'item-1', isDeleted: true };
      mockPrisma.catalogItem.update.mockResolvedValue(updated);
      mockAuditLog.log.mockResolvedValue(undefined);

      const result = await service.deleteItem('item-1', 'user-x', 'tid');

      expect(mockPrisma.catalogItem.update).toHaveBeenCalledWith({
        where: { id: 'item-1' },
        data: { isDeleted: true },
      });
      expect(result).toEqual(updated);
    });

    it('records AuditLog with action=DELETE on soft-delete', async () => {
      mockPrisma.catalogItem.update.mockResolvedValue({ id: 'item-1', isDeleted: true });
      mockAuditLog.log.mockResolvedValue(undefined);

      await service.deleteItem('item-1', 'user-x', 'tid');

      expect(mockAuditLog.log).toHaveBeenCalledWith(
        expect.objectContaining({
          tenantId: 'tid',
          userId: 'user-x',
          action: 'DELETE',
          entity: 'CatalogItem',
          entityId: 'item-1',
          before: { isDeleted: false },
          after: { isDeleted: true },
        }),
      );
    });
  });
});
