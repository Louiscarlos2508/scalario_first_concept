import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { VariantsService } from './variants.service';
import { PrismaService } from '../../../prisma/prisma.service';

const mockPrisma = {
  catalogItem: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  productVariant: {
    create: jest.fn(),
    findMany: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
    count: jest.fn(),
  },
};

describe('VariantsService', () => {
  let service: VariantsService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VariantsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();
    service = module.get<VariantsService>(VariantsService);
  });

  // ── createVariant ─────────────────────────────────────────────────────────

  describe('createVariant', () => {
    it('creates variant and sets hasVariants=true on parent', async () => {
      const item = { id: 'item-1', tenantId: 'tid' };
      const created = { id: 'var-1', catalogItemId: 'item-1', price: 500, attributes: {} };

      mockPrisma.catalogItem.findUnique.mockResolvedValue(item);
      mockPrisma.productVariant.create.mockResolvedValue(created);
      mockPrisma.catalogItem.update.mockResolvedValue({});

      const result = await service.createVariant('item-1', 'tid', {
        price: 500,
        attributes: { taille: 'M' },
      });

      expect(result).toEqual(created);
      expect(mockPrisma.catalogItem.update).toHaveBeenCalledWith({
        where: { id: 'item-1' },
        data: { hasVariants: true },
      });
    });

    it('throws NotFoundException when item does not belong to tenant', async () => {
      mockPrisma.catalogItem.findUnique.mockResolvedValue(null);

      await expect(
        service.createVariant('item-1', 'tid', { price: 500 }),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws NotFoundException when item belongs to different tenant', async () => {
      mockPrisma.catalogItem.findUnique.mockResolvedValue({ id: 'item-1', tenantId: 'other' });

      await expect(
        service.createVariant('item-1', 'tid', { price: 500 }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ── getVariants ───────────────────────────────────────────────────────────

  describe('getVariants', () => {
    it('returns active variants for catalog item', async () => {
      const variants = [{ id: 'v1' }, { id: 'v2' }];
      mockPrisma.productVariant.findMany.mockResolvedValue(variants);

      const result = await service.getVariants('item-1', 'tid');

      expect(result).toEqual(variants);
      expect(mockPrisma.productVariant.findMany).toHaveBeenCalledWith({
        where: { catalogItemId: 'item-1', tenantId: 'tid', isActive: true },
        orderBy: { createdAt: 'asc' },
      });
    });
  });

  // ── updateVariant ─────────────────────────────────────────────────────────

  describe('updateVariant', () => {
    it('updates variant price and attributes', async () => {
      const variant = { id: 'v1', catalogItemId: 'item-1', tenantId: 'tid' };
      const updated = { ...variant, price: 600 };
      mockPrisma.productVariant.findFirst.mockResolvedValue(variant);
      mockPrisma.productVariant.update.mockResolvedValue(updated);

      const result = await service.updateVariant('item-1', 'v1', 'tid', { price: 600 });

      expect(result).toEqual(updated);
    });

    it('throws NotFoundException when variant not found', async () => {
      mockPrisma.productVariant.findFirst.mockResolvedValue(null);

      await expect(
        service.updateVariant('item-1', 'v-bad', 'tid', { price: 600 }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ── deleteVariant ─────────────────────────────────────────────────────────

  describe('deleteVariant', () => {
    it('soft-deletes variant (isActive=false)', async () => {
      const variant = { id: 'v1', catalogItemId: 'item-1', tenantId: 'tid' };
      mockPrisma.productVariant.findFirst.mockResolvedValue(variant);
      mockPrisma.productVariant.update.mockResolvedValue({ ...variant, isActive: false });
      mockPrisma.productVariant.count.mockResolvedValue(1); // still has others

      await service.deleteVariant('item-1', 'v1', 'tid');

      expect(mockPrisma.productVariant.update).toHaveBeenCalledWith({
        where: { id: 'v1' },
        data: { isActive: false },
      });
      // hasVariants should NOT be reset when remaining > 0
      expect(mockPrisma.catalogItem.update).not.toHaveBeenCalled();
    });

    it('resets hasVariants on parent when last variant is deleted', async () => {
      const variant = { id: 'v1', catalogItemId: 'item-1', tenantId: 'tid' };
      mockPrisma.productVariant.findFirst.mockResolvedValue(variant);
      mockPrisma.productVariant.update.mockResolvedValue({ ...variant, isActive: false });
      mockPrisma.productVariant.count.mockResolvedValue(0);
      mockPrisma.catalogItem.update.mockResolvedValue({});

      await service.deleteVariant('item-1', 'v1', 'tid');

      expect(mockPrisma.catalogItem.update).toHaveBeenCalledWith({
        where: { id: 'item-1' },
        data: { hasVariants: false },
      });
    });

    it('throws NotFoundException when variant not found', async () => {
      mockPrisma.productVariant.findFirst.mockResolvedValue(null);

      await expect(
        service.deleteVariant('item-1', 'v-bad', 'tid'),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
