import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { PriceLevelsService } from './price-levels.service';
import { PrismaService } from '../../../prisma/prisma.service';

const mockPrisma = {
  catalogItem: { findUnique: jest.fn() },
  priceLevel: {
    create: jest.fn(),
    findMany: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
  },
  contact: { findUnique: jest.fn() },
};

describe('PriceLevelsService', () => {
  let service: PriceLevelsService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PriceLevelsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();
    service = module.get<PriceLevelsService>(PriceLevelsService);
  });

  // ── createPriceLevel ──────────────────────────────────────────────────────

  describe('createPriceLevel', () => {
    it('creates a price level for the tenant item', async () => {
      const item = { id: 'item-1', tenantId: 'tid' };
      const created = { id: 'pl-1', levelCode: 'GROS', price: 4500 };
      mockPrisma.catalogItem.findUnique.mockResolvedValue(item);
      mockPrisma.priceLevel.create.mockResolvedValue(created);

      const result = await service.createPriceLevel('item-1', 'tid', {
        levelCode: 'GROS',
        label: 'Prix gros',
        price: 4500,
        minQty: 10,
      });

      expect(result).toEqual(created);
    });

    it('throws NotFoundException when item not found', async () => {
      mockPrisma.catalogItem.findUnique.mockResolvedValue(null);
      await expect(
        service.createPriceLevel('item-bad', 'tid', { levelCode: 'GROS', label: 'Gros', price: 4500 }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ── resolvePriceLevel ─────────────────────────────────────────────────────

  describe('resolvePriceLevel', () => {
    it('returns cheapest eligible level when minQty met', async () => {
      mockPrisma.priceLevel.findMany.mockResolvedValue([
        { levelCode: 'GROS', label: 'Prix gros', price: 4500, minQty: 10, customerTypes: [] },
        { levelCode: 'DEMI', label: 'Demi-gros', price: 4800, minQty: 5, customerTypes: [] },
      ]);
      mockPrisma.contact.findUnique.mockResolvedValue(null);

      const result = await service.resolvePriceLevel('item-1', 12, null, 'tid');

      expect(result).toEqual({ levelCode: 'GROS', label: 'Prix gros', price: 4500 });
    });

    it('excludes level when minQty not met', async () => {
      mockPrisma.priceLevel.findMany.mockResolvedValue([
        { levelCode: 'GROS', label: 'Prix gros', price: 4500, minQty: 10, customerTypes: [] },
      ]);

      const result = await service.resolvePriceLevel('item-1', 5, null, 'tid');

      expect(result).toBeNull();
    });

    it('applies level based on contactType match', async () => {
      mockPrisma.priceLevel.findMany.mockResolvedValue([
        { levelCode: 'LOYALTY', label: 'Fidélité', price: 4600, minQty: null, customerTypes: ['loyal'] },
      ]);
      mockPrisma.contact.findUnique.mockResolvedValue({ contactType: 'loyal' });

      const result = await service.resolvePriceLevel('item-1', 1, 'contact-1', 'tid');

      expect(result?.levelCode).toBe('LOYALTY');
    });

    it('excludes level when contactType does not match', async () => {
      mockPrisma.priceLevel.findMany.mockResolvedValue([
        { levelCode: 'LOYALTY', label: 'Fidélité', price: 4600, minQty: null, customerTypes: ['loyal'] },
      ]);
      mockPrisma.contact.findUnique.mockResolvedValue({ contactType: 'customer' });

      const result = await service.resolvePriceLevel('item-1', 1, 'contact-1', 'tid');

      expect(result).toBeNull();
    });

    it('returns null when no levels configured', async () => {
      mockPrisma.priceLevel.findMany.mockResolvedValue([]);

      const result = await service.resolvePriceLevel('item-1', 5, null, 'tid');

      expect(result).toBeNull();
    });
  });

  // ── deletePriceLevel ──────────────────────────────────────────────────────

  describe('deletePriceLevel', () => {
    it('soft-deletes (isActive=false)', async () => {
      mockPrisma.priceLevel.findFirst.mockResolvedValue({ id: 'pl-1' });
      mockPrisma.priceLevel.update.mockResolvedValue({ id: 'pl-1', isActive: false });

      await service.deletePriceLevel('item-1', 'pl-1', 'tid');

      expect(mockPrisma.priceLevel.update).toHaveBeenCalledWith({
        where: { id: 'pl-1' },
        data: { isActive: false },
      });
    });

    it('throws NotFoundException when price level not found', async () => {
      mockPrisma.priceLevel.findFirst.mockResolvedValue(null);
      await expect(service.deletePriceLevel('item-1', 'pl-bad', 'tid')).rejects.toThrow(NotFoundException);
    });
  });
});
