import { BadRequestException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { InventoryService } from './inventory.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { EventBusService } from '../../kernel/events/event-bus.service';

const TENANT_ID = 'tenant-uuid-001';
const TX_ID = 'tx-uuid-001';
const ITEM_ID = 'item-uuid-001';
const MOV_ID = 'mov-uuid-001';
const REF_ID = 'ref-uuid-001';

describe('InventoryService', () => {
  let service: InventoryService;
  let prisma: jest.Mocked<PrismaService>;
  let auditLog: jest.Mocked<AuditLogService>;
  let eventBus: jest.Mocked<EventBusService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InventoryService,
        {
          provide: PrismaService,
          useValue: {
            inventoryMovement: {
              create: jest.fn(),
              findMany: jest.fn(),
              findFirst: jest.fn(),
              count: jest.fn(),
            },
            transaction: {
              findUnique: jest.fn(),
            },
          },
        },
        {
          provide: AuditLogService,
          useValue: { log: jest.fn().mockResolvedValue(undefined) },
        },
        {
          provide: EventBusService,
          useValue: { publish: jest.fn().mockReturnValue(true) },
        },
      ],
    }).compile();

    service = module.get<InventoryService>(InventoryService);
    prisma = module.get(PrismaService);
    auditLog = module.get(AuditLogService);
    eventBus = module.get(EventBusService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ── createMovement ────────────────────────────────────────────────────────

  describe('createMovement', () => {
    it('persists movement with all provided fields', async () => {
      const created = {
        id: MOV_ID,
        catalogItemId: ITEM_ID,
        quantity: 10,
        type: 'DELIVERY',
        reason: 'Stock received',
        tenantId: TENANT_ID,
        userId: 'user-001',
        referenceId: null,
        createdAt: new Date(),
      };
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(created);

      const result = await service.createMovement({
        catalogItemId: ITEM_ID,
        quantity: 10,
        type: 'DELIVERY',
        reason: 'Stock received',
        tenantId: TENANT_ID,
        userId: 'user-001',
      });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          catalogItemId: ITEM_ID,
          quantity: 10,
          type: 'DELIVERY',
          reason: 'Stock received',
          tenantId: TENANT_ID,
          userId: 'user-001',
          referenceId: null,
        }),
      });
      expect(result).toEqual(created);
    });

    it('persists movement with nullable optional fields defaulting to null', async () => {
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue({ id: MOV_ID, tenantId: TENANT_ID });

      await service.createMovement({ quantity: 5, type: 'SALE', tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          catalogItemId: null,
          reason: null,
          userId: null,
          referenceId: null,
        }),
      });
    });

    it('emits stock.adjusted event after persist', async () => {
      const created = { id: MOV_ID, tenantId: TENANT_ID, catalogItemId: ITEM_ID, type: 'DELIVERY' };
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(created);

      await service.createMovement({ catalogItemId: ITEM_ID, quantity: 10, type: 'DELIVERY', tenantId: TENANT_ID });

      expect(eventBus.publish).toHaveBeenCalledWith('stock.adjusted', {
        movementId: MOV_ID,
        catalogItemId: ITEM_ID,
        type: 'DELIVERY',
        tenantId: TENANT_ID,
      });
    });

    it('logs AuditLog entry after persist', async () => {
      const created = { id: MOV_ID, tenantId: TENANT_ID };
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(created);

      await service.createMovement({ catalogItemId: ITEM_ID, quantity: 10, type: 'DELIVERY', tenantId: TENANT_ID, userId: 'user-001' });

      expect(auditLog.log).toHaveBeenCalledWith(
        expect.objectContaining({ tenantId: TENANT_ID, userId: 'user-001', action: 'CREATE', entity: 'InventoryMovement', entityId: MOV_ID }),
      );
    });

    // AC1 — LOSS validation
    it('throws BadRequestException when LOSS movement has no reason (AC1)', async () => {
      await expect(
        service.createMovement({ quantity: 3, type: 'LOSS', tenantId: TENANT_ID }),
      ).rejects.toThrow(BadRequestException);
    });

    it('throws BadRequestException when LOSS movement has empty reason (AC1)', async () => {
      await expect(
        service.createMovement({ quantity: 3, type: 'LOSS', tenantId: TENANT_ID, reason: '   ' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('creates LOSS movement when reason is provided (AC1)', async () => {
      const created = { id: MOV_ID, type: 'LOSS', tenantId: TENANT_ID };
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(created);

      const result = await service.createMovement({
        quantity: 3,
        type: 'LOSS',
        reason: 'Damaged goods',
        tenantId: TENANT_ID,
      });

      expect(result).toEqual(created);
      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ type: 'LOSS', reason: 'Damaged goods' }),
      });
    });
  });

  // ── getCurrentStock ───────────────────────────────────────────────────────

  describe('getCurrentStock', () => {
    it('returns 0 when no movements exist (AC3)', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([]);

      const stock = await service.getCurrentStock(ITEM_ID, TENANT_ID);

      expect(stock).toBe(0);
    });

    it('sums correctly across all movement types (AC3)', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([
        { type: 'DELIVERY', quantity: 100 },
        { type: 'SALE', quantity: 30 },
        { type: 'TRANSFER_IN', quantity: 20 },
        { type: 'TRANSFER_OUT', quantity: 10 },
        { type: 'LOSS', quantity: 5 },
        { type: 'ADJUSTMENT', quantity: -3 }, // negative adjustment
      ]);

      const stock = await service.getCurrentStock(ITEM_ID, TENANT_ID);

      // 100 + 20 - 30 - 10 - 5 + (-3) = 72
      expect(stock).toBe(72);
    });

    it('handles positive ADJUSTMENT (stock increase) (AC3)', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([
        { type: 'DELIVERY', quantity: 50 },
        { type: 'ADJUSTMENT', quantity: 10 },
      ]);

      const stock = await service.getCurrentStock(ITEM_ID, TENANT_ID);
      expect(stock).toBe(60);
    });
  });

  // ── adjustInventory ───────────────────────────────────────────────────────

  describe('adjustInventory', () => {
    it('returns { adjusted: false } when variance is zero (AC2)', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([
        { type: 'DELIVERY', quantity: 50 },
      ]);

      const result = await service.adjustInventory({
        catalogItemId: ITEM_ID,
        countedQuantity: 50,
        tenantId: TENANT_ID,
      });

      expect(result).toEqual({ adjusted: false, catalogItemId: ITEM_ID, tenantId: TENANT_ID });
      expect(prisma.inventoryMovement.create).not.toHaveBeenCalled();
    });

    it('throws BadRequestException when non-zero variance and no reason (AC2)', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([
        { type: 'DELIVERY', quantity: 50 },
      ]);

      await expect(
        service.adjustInventory({ catalogItemId: ITEM_ID, countedQuantity: 45, tenantId: TENANT_ID }),
      ).rejects.toThrow(BadRequestException);
    });

    it('creates positive ADJUSTMENT movement when counted > current stock (AC2)', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([
        { type: 'DELIVERY', quantity: 50 },
      ]);
      const created = { id: MOV_ID, type: 'ADJUSTMENT', quantity: 10, tenantId: TENANT_ID };
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(created);

      const result = await service.adjustInventory({
        catalogItemId: ITEM_ID,
        countedQuantity: 60,
        reason: 'Found extra units',
        tenantId: TENANT_ID,
      });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ type: 'ADJUSTMENT', quantity: 10, reason: 'Found extra units' }),
      });
      expect(result).toMatchObject({ adjusted: true, variance: 10 });
    });

    it('creates negative ADJUSTMENT movement when counted < current stock (AC2)', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([
        { type: 'DELIVERY', quantity: 50 },
      ]);
      const created = { id: MOV_ID, type: 'ADJUSTMENT', quantity: -5, tenantId: TENANT_ID };
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(created);

      const result = await service.adjustInventory({
        catalogItemId: ITEM_ID,
        countedQuantity: 45,
        reason: 'Shrinkage',
        tenantId: TENANT_ID,
      });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ type: 'ADJUSTMENT', quantity: -5, reason: 'Shrinkage' }),
      });
      expect(result).toMatchObject({ adjusted: true, variance: -5 });
    });
  });

  // ── createTransferOut ─────────────────────────────────────────────────────

  describe('createTransferOut', () => {
    it('creates TRANSFER_OUT with auto-generated referenceId and emits transfer.created (AC1)', async () => {
      const created = { id: MOV_ID, type: 'TRANSFER_OUT', tenantId: TENANT_ID, referenceId: REF_ID };
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(created);

      const result = await service.createTransferOut({ catalogItemId: ITEM_ID, quantity: 8, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ type: 'TRANSFER_OUT', quantity: 8, referenceId: expect.any(String) }),
      });
      expect(result).toEqual(created);
    });

    it('emits transfer.created event with pending status', async () => {
      const created = { id: MOV_ID, type: 'TRANSFER_OUT', tenantId: TENANT_ID, referenceId: REF_ID };
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(created);

      await service.createTransferOut({ catalogItemId: ITEM_ID, quantity: 8, tenantId: TENANT_ID });

      expect(eventBus.publish).toHaveBeenCalledWith('transfer.created', {
        referenceId: expect.any(String),
        tenantId: TENANT_ID,
        status: 'pending',
      });
    });

    it('logs AuditLog entry for TRANSFER_OUT', async () => {
      const created = { id: MOV_ID, type: 'TRANSFER_OUT', tenantId: TENANT_ID, referenceId: REF_ID };
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(created);

      await service.createTransferOut({ quantity: 8, tenantId: TENANT_ID, userId: 'user-001' });

      expect(auditLog.log).toHaveBeenCalledWith(
        expect.objectContaining({ tenantId: TENANT_ID, userId: 'user-001', action: 'CREATE', entity: 'InventoryMovement', entityId: MOV_ID }),
      );
    });
  });

  // ── confirmTransferIn ─────────────────────────────────────────────────────

  describe('confirmTransferIn', () => {
    it('creates TRANSFER_IN linked to TRANSFER_OUT via referenceId', async () => {
      const outMovement = { id: 'out-001', type: 'TRANSFER_OUT', quantity: 8, catalogItemId: ITEM_ID, tenantId: TENANT_ID };
      const inMovement = { id: MOV_ID, type: 'TRANSFER_IN', quantity: 7, tenantId: TENANT_ID, referenceId: REF_ID };
      (prisma.inventoryMovement.findFirst as jest.Mock).mockResolvedValue(outMovement);
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue(inMovement);

      const result = await service.confirmTransferIn({ referenceId: REF_ID, quantity: 7, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.findFirst).toHaveBeenCalledWith({ where: { referenceId: REF_ID, type: 'TRANSFER_OUT' } });
      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ type: 'TRANSFER_IN', quantity: 7, referenceId: REF_ID }),
      });
      expect(result).toEqual(inMovement);
    });

    it('calculates variance and stores in reason field', async () => {
      const outMovement = { id: 'out-001', type: 'TRANSFER_OUT', quantity: 8, catalogItemId: ITEM_ID, tenantId: TENANT_ID };
      (prisma.inventoryMovement.findFirst as jest.Mock).mockResolvedValue(outMovement);
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue({ id: MOV_ID, tenantId: TENANT_ID });

      await service.confirmTransferIn({ referenceId: REF_ID, quantity: 7, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ reason: 'Variance: 1' }),
      });
    });

    it('sets reason to null when variance is zero', async () => {
      const outMovement = { id: 'out-001', type: 'TRANSFER_OUT', quantity: 8, catalogItemId: ITEM_ID, tenantId: TENANT_ID };
      (prisma.inventoryMovement.findFirst as jest.Mock).mockResolvedValue(outMovement);
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue({ id: MOV_ID, tenantId: TENANT_ID });

      await service.confirmTransferIn({ referenceId: REF_ID, quantity: 8, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ reason: null }),
      });
    });

    it('emits transfer.confirmed event with sent, received and variance', async () => {
      const outMovement = { id: 'out-001', type: 'TRANSFER_OUT', quantity: 8, catalogItemId: ITEM_ID, tenantId: TENANT_ID };
      (prisma.inventoryMovement.findFirst as jest.Mock).mockResolvedValue(outMovement);
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue({ id: MOV_ID, tenantId: TENANT_ID });

      await service.confirmTransferIn({ referenceId: REF_ID, quantity: 7, tenantId: TENANT_ID });

      expect(eventBus.publish).toHaveBeenCalledWith('transfer.confirmed', {
        referenceId: REF_ID, sent: 8, received: 7, variance: 1, tenantId: TENANT_ID,
      });
    });

    it('throws error when TRANSFER_OUT not found for referenceId', async () => {
      (prisma.inventoryMovement.findFirst as jest.Mock).mockResolvedValue(null);

      await expect(
        service.confirmTransferIn({ referenceId: REF_ID, quantity: 7, tenantId: TENANT_ID }),
      ).rejects.toThrow(`No TRANSFER_OUT found for referenceId: ${REF_ID}`);
    });

    it('falls back to outMovement.catalogItemId when not provided', async () => {
      const outMovement = { id: 'out-001', type: 'TRANSFER_OUT', quantity: 8, catalogItemId: ITEM_ID, tenantId: TENANT_ID };
      (prisma.inventoryMovement.findFirst as jest.Mock).mockResolvedValue(outMovement);
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue({ id: MOV_ID, tenantId: TENANT_ID });

      await service.confirmTransferIn({ referenceId: REF_ID, quantity: 8, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ catalogItemId: ITEM_ID }),
      });
    });
  });

  // ── getMovements ──────────────────────────────────────────────────────────

  describe('getMovements', () => {
    it('returns all movements without since filter', async () => {
      const movements = [{ id: MOV_ID, tenantId: TENANT_ID }];
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue(movements);
      (prisma.inventoryMovement.count as jest.Mock).mockResolvedValue(1);

      const result = await service.getMovements({ tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { tenantId: TENANT_ID }, skip: 0, take: 100 }),
      );
      expect(result.items).toEqual(movements);
      expect(result.meta.total).toBe(1);
      expect(result.meta.hasMore).toBe(false);
    });

    it('filters by createdAt when since is provided (AC4)', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([]);
      (prisma.inventoryMovement.count as jest.Mock).mockResolvedValue(0);

      const since = '2026-03-01T00:00:00.000Z';
      await service.getMovements({ tenantId: TENANT_ID, since });

      expect(prisma.inventoryMovement.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { tenantId: TENANT_ID, createdAt: { gt: new Date(since) } },
        }),
      );
    });

    it('response includes meta.serverTime and meta.hasMore (AC4)', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([]);
      (prisma.inventoryMovement.count as jest.Mock).mockResolvedValue(0);

      const result = await service.getMovements({ tenantId: TENANT_ID });

      expect(result.meta).toMatchObject({
        total: 0,
        page: 1,
        limit: 100,
        hasMore: false,
        serverTime: expect.any(String),
      });
    });

    it('filters by referenceId when provided', async () => {
      (prisma.inventoryMovement.findMany as jest.Mock).mockResolvedValue([]);
      (prisma.inventoryMovement.count as jest.Mock).mockResolvedValue(0);

      await service.getMovements({ tenantId: TENANT_ID, referenceId: REF_ID });

      expect(prisma.inventoryMovement.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { tenantId: TENANT_ID, referenceId: REF_ID } }),
      );
    });
  });

  // ── handleTransactionCreated ──────────────────────────────────────────────

  describe('handleTransactionCreated (@OnEvent)', () => {
    it('creates SALE movement for each item in itemsJson', async () => {
      const tx = {
        id: TX_ID,
        tenantId: TENANT_ID,
        itemsJson: [
          { catalogItemId: 'item-001', quantity: 2 },
          { catalogItemId: 'item-002', quantity: 3 },
        ],
      };
      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(tx);
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue({ id: MOV_ID, tenantId: TENANT_ID });

      await service.handleTransactionCreated({ transactionId: TX_ID, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledTimes(2);
    });

    it('falls back to productId field when catalogItemId is absent', async () => {
      const tx = { id: TX_ID, tenantId: TENANT_ID, itemsJson: [{ productId: 'prod-001', qty: 1 }] };
      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(tx);
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue({ id: MOV_ID, tenantId: TENANT_ID });

      await service.handleTransactionCreated({ transactionId: TX_ID, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ catalogItemId: 'prod-001' }) }),
      );
    });

    it('creates no movements when itemsJson is empty', async () => {
      const tx = { id: TX_ID, tenantId: TENANT_ID, itemsJson: [] };
      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(tx);

      await service.handleTransactionCreated({ transactionId: TX_ID, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).not.toHaveBeenCalled();
    });

    it('returns gracefully when transaction not found', async () => {
      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(null);

      await service.handleTransactionCreated({ transactionId: TX_ID, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).not.toHaveBeenCalled();
    });

    it('skips items with quantity <= 0', async () => {
      const tx = {
        id: TX_ID,
        tenantId: TENANT_ID,
        itemsJson: [
          { catalogItemId: 'item-001', quantity: 0 },
          { catalogItemId: 'item-002', quantity: -1 },
          { catalogItemId: 'item-003', quantity: 2 },
        ],
      };
      (prisma.transaction.findUnique as jest.Mock).mockResolvedValue(tx);
      (prisma.inventoryMovement.create as jest.Mock).mockResolvedValue({ id: MOV_ID, tenantId: TENANT_ID });

      await service.handleTransactionCreated({ transactionId: TX_ID, tenantId: TENANT_ID });

      expect(prisma.inventoryMovement.create).toHaveBeenCalledTimes(1);
    });
  });
});
