import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { PromotionsService } from './promotions.service';
import { PrismaService } from '../../prisma/prisma.service';

const mockPrisma = {
  promotion: {
    create: jest.fn(),
    findMany: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
  },
};

describe('PromotionsService', () => {
  let service: PromotionsService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PromotionsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();
    service = module.get<PromotionsService>(PromotionsService);
  });

  describe('createPromotion', () => {
    it('creates a promotion with status=active', async () => {
      const created = { id: 'promo-1', status: 'active', type: 'PERCENT' };
      mockPrisma.promotion.create.mockResolvedValue(created);

      const result = await service.createPromotion('tid', {
        type: 'PERCENT',
        scope: 'ITEM',
        scopeId: 'item-1',
        value: { percent: 10 },
        startDate: '2026-01-01',
        endDate: '2026-12-31',
      });

      expect(result).toEqual(created);
      expect(mockPrisma.promotion.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'active' }) }),
      );
    });
  });

  describe('listPromotions', () => {
    it('returns promotions filtered by status', async () => {
      const promos = [{ id: 'p1', status: 'active' }];
      mockPrisma.promotion.findMany.mockResolvedValue(promos);

      const result = await service.listPromotions('tid', { status: 'active' });

      expect(result).toEqual(promos);
      expect(mockPrisma.promotion.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: expect.objectContaining({ status: 'active' }) }),
      );
    });
  });

  describe('deletePromotion', () => {
    it('soft-deletes (status=inactive)', async () => {
      mockPrisma.promotion.findFirst.mockResolvedValue({ id: 'p1' });
      mockPrisma.promotion.update.mockResolvedValue({ id: 'p1', status: 'inactive' });

      await service.deletePromotion('p1', 'tid');

      expect(mockPrisma.promotion.update).toHaveBeenCalledWith({
        where: { id: 'p1' },
        data: { status: 'inactive' },
      });
    });

    it('throws NotFoundException when not found', async () => {
      mockPrisma.promotion.findFirst.mockResolvedValue(null);
      await expect(service.deletePromotion('bad', 'tid')).rejects.toThrow(NotFoundException);
    });
  });

  describe('getActivePromotionsForItem', () => {
    it('returns promotions matching ITEM scope', async () => {
      const now = new Date();
      const promos = [
        { id: 'p1', scope: 'ITEM', scopeId: 'item-1', startDate: new Date(now.getTime() - 1000), endDate: new Date(now.getTime() + 1000) },
        { id: 'p2', scope: 'ITEM', scopeId: 'item-2', startDate: new Date(now.getTime() - 1000), endDate: new Date(now.getTime() + 1000) },
      ];
      mockPrisma.promotion.findMany.mockResolvedValue(promos);

      const result = await service.getActivePromotionsForItem('tid', 'item-1', null);

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('p1');
    });

    it('returns promotions matching CATEGORY scope', async () => {
      const now = new Date();
      const promos = [
        { id: 'p3', scope: 'CATEGORY', scopeId: 'cat-1', startDate: new Date(now.getTime() - 1000), endDate: new Date(now.getTime() + 1000) },
      ];
      mockPrisma.promotion.findMany.mockResolvedValue(promos);

      const result = await service.getActivePromotionsForItem('tid', 'item-x', 'cat-1');

      expect(result).toHaveLength(1);
    });
  });
});
