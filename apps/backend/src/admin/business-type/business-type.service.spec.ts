import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { BusinessTypeService } from './business-type.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('BusinessTypeService', () => {
  let service: BusinessTypeService;

  const mockBusinessType = {
    id: 'uuid-1',
    code: 'telephonie',
    name: 'Téléphonie & Accessoires',
    description: null,
    defaultFlags: { hasVariants: true, trackSerialNumbers: true, warrantyMonths: 12 },
    visibleSections: ['variants', 'serial', 'warranty'],
    suggestedCategories: ['Smartphones', 'Accessoires', 'Cartes SIM', 'Recharge', 'Réparation'],
    icon: null,
    isActive: true,
    // Epic 30 — FR111, FR109: new fields
    roleLabels: { commercial: 'Vendeur', manager: 'Responsable boutique', cashier: 'Caissier' },
    documentType: 'receipt',
    createdAt: new Date(),
  };

  const mockDistributionType = {
    id: 'uuid-14',
    code: 'distribution',
    name: 'Commerce de distribution',
    description: 'Vente en gros, livraison clients, bons de livraison',
    defaultFlags: { hasVariants: true },
    visibleSections: ['variants'],
    suggestedCategories: ['Alimentaire', 'Boissons', 'Hygiène', 'Nettoyage', 'Épicerie fine'],
    icon: 'local_shipping',
    isActive: true,
    roleLabels: { commercial: 'Commercial terrain', manager: 'Directeur dépôt', cashier: 'Opérateur' },
    documentType: 'delivery_note',
    createdAt: new Date(),
  };

  const mockPrismaService = {
    businessTypeDefinition: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
    tenant: {
      update: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.resetAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BusinessTypeService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<BusinessTypeService>(BusinessTypeService);
  });

  // ─── AC4 ───────────────────────────────────────────────────────────────────
  describe('listActive()', () => {
    it('returns only active types ordered by name', async () => {
      const types = [mockBusinessType, { ...mockBusinessType, code: 'textile', name: 'Textile' }];
      mockPrismaService.businessTypeDefinition.findMany.mockResolvedValue(types);

      const result = await service.listActive();

      expect(mockPrismaService.businessTypeDefinition.findMany).toHaveBeenCalledWith({
        where: { isActive: true },
        orderBy: { name: 'asc' },
      });
      expect(result).toHaveLength(2);
    });
  });

  // ─── AC5 ───────────────────────────────────────────────────────────────────
  describe('getDefinition()', () => {
    it('returns full BusinessTypeDefinition when code exists and is active', async () => {
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue(mockBusinessType);

      const result = await service.getDefinition('telephonie');

      expect(result).toEqual(mockBusinessType);
      expect(mockPrismaService.businessTypeDefinition.findUnique).toHaveBeenCalledWith({
        where: { code: 'telephonie' },
      });
    });

    it('throws NotFoundException when code does not exist', async () => {
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue(null);

      await expect(service.getDefinition('unknown')).rejects.toThrow(NotFoundException);
      await expect(service.getDefinition('unknown')).rejects.toThrow(
        'Type de business introuvable : unknown',
      );
    });

    it('throws NotFoundException when type exists but is inactive', async () => {
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue({
        ...mockBusinessType,
        isActive: false,
      });

      await expect(service.getDefinition('telephonie')).rejects.toThrow(NotFoundException);
    });
  });

  // ─── AC6 ───────────────────────────────────────────────────────────────────
  describe('assignToTenant()', () => {
    const tenantId = 'tenant-uuid';

    it('updates tenant.businessType when code is valid and active', async () => {
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue(mockBusinessType);
      mockPrismaService.tenant.update.mockResolvedValue({ id: tenantId, businessType: 'telephonie' });

      const result = await service.assignToTenant(tenantId, 'telephonie');

      expect(mockPrismaService.businessTypeDefinition.findUnique).toHaveBeenCalledWith({
        where: { code: 'telephonie' },
      });
      expect(mockPrismaService.tenant.update).toHaveBeenCalledWith({
        where: { id: tenantId },
        data: { businessType: 'telephonie' },
      });
      expect(result.businessType).toBe('telephonie');
    });

    it('throws NotFoundException when code does not exist, tenant NOT modified', async () => {
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue(null);

      await expect(service.assignToTenant(tenantId, 'unknown')).rejects.toThrow(NotFoundException);
      await expect(service.assignToTenant(tenantId, 'unknown')).rejects.toThrow(
        'Type de business inconnu : unknown',
      );
      expect(mockPrismaService.tenant.update).not.toHaveBeenCalled();
    });

    it('throws NotFoundException when type is inactive, tenant NOT modified', async () => {
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue({
        ...mockBusinessType,
        isActive: false,
      });

      await expect(service.assignToTenant(tenantId, 'telephonie')).rejects.toThrow(NotFoundException);
      expect(mockPrismaService.tenant.update).not.toHaveBeenCalled();
    });
  });

  // ─── AC3: seedCategories stub ──────────────────────────────────────────────
  describe('seedCategories()', () => {
    it('resolves without throwing for any input', async () => {
      await expect(service.seedCategories('tenant-uuid', 'telephonie')).resolves.not.toThrow();
    });
  });

  // ─── Epic 30 AC5: new fields roleLabels + documentType returned by endpoints ─
  describe('getDefinition() — roleLabels + documentType (FR109, FR111)', () => {
    it('returns roleLabels in telephonie definition', async () => {
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue(mockBusinessType);

      const result = await service.getDefinition('telephonie');

      expect(result.roleLabels).toEqual({
        commercial: 'Vendeur',
        manager: 'Responsable boutique',
        cashier: 'Caissier',
      });
      expect(result.documentType).toBe('receipt');
    });

    it('returns distribution type with documentType=delivery_note and roleLabels for terrain roles', async () => {
      mockPrismaService.businessTypeDefinition.findUnique.mockResolvedValue(mockDistributionType);

      const result = await service.getDefinition('distribution');

      expect(result.code).toBe('distribution');
      expect(result.documentType).toBe('delivery_note');
      expect(result.roleLabels).toEqual({
        commercial: 'Commercial terrain',
        manager: 'Directeur dépôt',
        cashier: 'Opérateur',
      });
      expect(result.suggestedCategories).toContain('Alimentaire');
      expect(result.icon).toBe('local_shipping');
    });
  });
});
