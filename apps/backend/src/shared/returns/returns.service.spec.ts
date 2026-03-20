import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { Decimal } from '@prisma/client/runtime/library';
import { ReturnsService } from './returns.service';
import { PrismaService } from '../../prisma/prisma.service';
import { InventoryService } from '../inventory/inventory.service';

const TENANT_ID = 'tenant-uuid-001';
const USER_ID = 'user-uuid-001';
const TX_ID = 'tx-uuid-001';
const ITEM_ID = 'item-uuid-001';
const RETURN_ID = 'return-uuid-001';
const CUSTOMER_ID = 'customer-uuid-001';

const makeDto = (overrides = {}) => ({
  originalTxId: TX_ID,
  catalogItemId: ITEM_ID,
  quantity: 2,
  unitPrice: 5000,
  resolution: 'cash_refund' as const,
  reason: 'produit défectueux',
  ...overrides,
});

describe('ReturnsService', () => {
  let service: ReturnsService;
  let prisma: jest.Mocked<PrismaService>;
  let inventoryService: jest.Mocked<InventoryService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReturnsService,
        {
          provide: PrismaService,
          useValue: {
            tenant: {
              findUnique: jest.fn().mockResolvedValue({
                returnPolicyDays: 30,
                returnRequiresReason: true,
              }),
            },
            transaction: {
              findFirst: jest.fn().mockResolvedValue({
                id: TX_ID,
                tenantId: TENANT_ID,
                customerId: CUSTOMER_ID,
                createdAt: new Date(),
              }),
            },
            returnRecord: {
              create: jest.fn().mockResolvedValue({
                id: RETURN_ID,
                catalogItemId: ITEM_ID,
                quantity: new Decimal(2),
                unitPrice: new Decimal(5000),
                resolution: 'cash_refund',
                tenantId: TENANT_ID,
              }),
              findMany: jest.fn().mockResolvedValue([]),
              count: jest.fn().mockResolvedValue(0),
            },
            contact: {
              update: jest.fn().mockResolvedValue({}),
            },
          },
        },
        {
          provide: InventoryService,
          useValue: {
            createMovement: jest.fn().mockResolvedValue({ id: 'mov-001' }),
          },
        },
      ],
    }).compile();

    service = module.get<ReturnsService>(ReturnsService);
    prisma = module.get(PrismaService);
    inventoryService = module.get(InventoryService);
  });

  describe('createReturn', () => {
    it('creates return record and reinstates stock', async () => {
      const result = await service.createReturn(TENANT_ID, USER_ID, makeDto());

      expect(prisma.returnRecord.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            catalogItemId: ITEM_ID,
            resolution: 'cash_refund',
            reason: 'produit défectueux',
          }),
        }),
      );
      expect(inventoryService.createMovement).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'RETURN', quantity: 2, catalogItemId: ITEM_ID }),
      );
      expect(result.id).toBe(RETURN_ID);
    });

    it('throws NotFoundException when originalTxId not found', async () => {
      (prisma.transaction.findFirst as jest.Mock).mockResolvedValueOnce(null);

      await expect(
        service.createReturn(TENANT_ID, USER_ID, makeDto()),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws BadRequestException when return window exceeded', async () => {
      const oldDate = new Date();
      oldDate.setDate(oldDate.getDate() - 45);
      (prisma.transaction.findFirst as jest.Mock).mockResolvedValueOnce({
        id: TX_ID,
        tenantId: TENANT_ID,
        customerId: CUSTOMER_ID,
        createdAt: oldDate,
      });

      await expect(
        service.createReturn(TENANT_ID, USER_ID, makeDto()),
      ).rejects.toThrow(BadRequestException);
    });

    it('throws BadRequestException when reason required but missing', async () => {
      await expect(
        service.createReturn(TENANT_ID, USER_ID, makeDto({ reason: '' })),
      ).rejects.toThrow(BadRequestException);
    });

    it('increments contact balance for credit_note resolution', async () => {
      await service.createReturn(TENANT_ID, USER_ID, makeDto({ resolution: 'credit_note' }));

      expect(prisma.contact.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: CUSTOMER_ID },
          data: expect.objectContaining({ balance: expect.anything() }),
        }),
      );
    });

    it('does not increment balance for cash_refund resolution', async () => {
      await service.createReturn(TENANT_ID, USER_ID, makeDto({ resolution: 'cash_refund' }));

      expect(prisma.contact.update).not.toHaveBeenCalled();
    });
  });

  describe('getReturnsSummaryForSession', () => {
    it('returns zero summary when no returns in session window', async () => {
      const openedAt = new Date('2026-03-19T08:00:00Z');
      const closedAt = new Date('2026-03-19T18:00:00Z');

      const result = await service.getReturnsSummaryForSession(TENANT_ID, openedAt, closedAt);

      expect(result.count).toBe(0);
      expect(result.amount.toNumber()).toBe(0);
      expect(result.cashRefundAmount.toNumber()).toBe(0);
    });

    it('sums amounts and cash refunds correctly', async () => {
      (prisma.returnRecord.findMany as jest.Mock).mockResolvedValueOnce([
        { quantity: new Decimal(2), unitPrice: new Decimal(5000), resolution: 'cash_refund' },
        { quantity: new Decimal(1), unitPrice: new Decimal(3000), resolution: 'credit_note' },
      ]);

      const result = await service.getReturnsSummaryForSession(
        TENANT_ID,
        new Date('2026-03-19T08:00:00Z'),
        new Date('2026-03-19T18:00:00Z'),
      );

      expect(result.count).toBe(2);
      expect(result.amount.toNumber()).toBe(13000); // 10000 + 3000
      expect(result.cashRefundAmount.toNumber()).toBe(10000); // only cash_refund
    });
  });
});
