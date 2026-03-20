import { Test, TestingModule } from '@nestjs/testing';
import { CatalogController } from './catalog.controller';
import { CatalogService } from './catalog.service';
import { PriceHistoryService } from './price-history/price-history.service';

const mockCatalogService = {
  getCategories: jest.fn(),
  createCategory: jest.fn(),
  deleteCategory: jest.fn(),
  getItems: jest.fn(),
  createItem: jest.fn(),
  deleteItem: jest.fn(),
  syncItems: jest.fn(),
};

describe('CatalogController', () => {
  let controller: CatalogController;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CatalogController],
      providers: [
        { provide: CatalogService, useValue: mockCatalogService },
        { provide: PriceHistoryService, useValue: {} },
      ],
    }).compile();

    controller = module.get<CatalogController>(CatalogController);
  });

  describe('getCategories', () => {
    it('calls catalogService.getCategories with tenantId', async () => {
      const cats = [{ id: 'c1', name: 'Boissons' }];
      mockCatalogService.getCategories.mockResolvedValue(cats);

      const result = await controller.getCategories('tid-1');

      expect(mockCatalogService.getCategories).toHaveBeenCalledWith('tid-1');
      expect(result).toEqual(cats);
    });
  });

  describe('createCategory', () => {
    it('calls catalogService.createCategory with name and tenantId from body', async () => {
      const created = { id: 'c2', name: 'Épicerie', tenantId: 'tid-1' };
      mockCatalogService.createCategory.mockResolvedValue(created);

      const result = await controller.createCategory({ name: 'Épicerie', tenantId: 'tid-1' });

      expect(mockCatalogService.createCategory).toHaveBeenCalledWith({
        name: 'Épicerie',
        tenantId: 'tid-1',
      });
      expect(result).toEqual(created);
    });
  });

  describe('deleteCategory', () => {
    it('calls catalogService.deleteCategory with id', async () => {
      mockCatalogService.deleteCategory.mockResolvedValue({ id: 'c1' });

      const result = await controller.deleteCategory('c1');

      expect(mockCatalogService.deleteCategory).toHaveBeenCalledWith('c1');
      expect(result).toEqual({ id: 'c1' });
    });
  });

  describe('getItems', () => {
    it('calls catalogService.getItems with parsed pagination params', async () => {
      const response = { items: [], meta: { total: 0, page: 1, limit: 100, hasMore: false, serverTime: '' } };
      mockCatalogService.getItems.mockResolvedValue(response);

      const result = await controller.getItems('tid-1', undefined, '1', '100', undefined);

      expect(mockCatalogService.getItems).toHaveBeenCalledWith({
        tenantId: 'tid-1',
        query: undefined,
        page: 1,
        limit: 100,
        since: undefined,
      });
      expect(result).toEqual(response);
    });

    it('passes since param to catalogService.getItems', async () => {
      const since = '2026-03-01T00:00:00.000Z';
      const response = { items: [], meta: { total: 0, page: 1, limit: 100, hasMore: false, serverTime: '' } };
      mockCatalogService.getItems.mockResolvedValue(response);

      await controller.getItems(undefined, undefined, '1', '100', since);

      expect(mockCatalogService.getItems).toHaveBeenCalledWith(
        expect.objectContaining({ since }),
      );
    });
  });

  describe('syncItems', () => {
    it('calls catalogService.syncItems with items from body', async () => {
      const items = [{ id: 'item-1', name: 'Bière', price: 500, tenantId: 'tid' }];
      mockCatalogService.syncItems.mockResolvedValue(items);

      const result = await controller.syncItems({ items });

      expect(mockCatalogService.syncItems).toHaveBeenCalledWith(items);
      expect(result).toEqual(items);
    });
  });

  describe('createItem', () => {
    it('extracts userId from req.user.sub and calls catalogService.createItem', async () => {
      const body = { name: 'Bière', price: 500, tenantId: 'tid-1' };
      const req = { user: { sub: 'user-abc' } };
      const created = { id: 'item-1', ...body };
      mockCatalogService.createItem.mockResolvedValue(created);

      const result = await controller.createItem(body, req);

      expect(mockCatalogService.createItem).toHaveBeenCalledWith(body, 'user-abc');
      expect(result).toEqual(created);
    });

    it('passes null userId when req.user is absent', async () => {
      const body = { name: 'Test', price: 100, tenantId: 'tid-1' };
      const req = {};
      mockCatalogService.createItem.mockResolvedValue({ id: 'item-2', ...body });

      await controller.createItem(body, req);

      expect(mockCatalogService.createItem).toHaveBeenCalledWith(body, null);
    });
  });

  describe('deleteItem', () => {
    it('extracts userId from req.user.sub and calls catalogService.deleteItem', async () => {
      const req = { user: { sub: 'user-xyz' } };
      mockCatalogService.deleteItem.mockResolvedValue({ id: 'item-1', isDeleted: true });

      const result = await controller.deleteItem('item-1', 'tid-1', req);

      expect(mockCatalogService.deleteItem).toHaveBeenCalledWith('item-1', 'user-xyz', 'tid-1');
      expect(result).toEqual({ id: 'item-1', isDeleted: true });
    });
  });
});
