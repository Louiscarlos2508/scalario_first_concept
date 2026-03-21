import { Test, TestingModule } from '@nestjs/testing';
import { UnprocessableEntityException } from '@nestjs/common';
import { PurchaseOrdersService } from './purchase-orders.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogService } from '../../kernel/audit/audit-log.service';
import { EventBusService } from '../../kernel/events/event-bus.service';

const mockPrisma = {
  purchaseOrder: {
    create: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
  },
  purchaseOrderLine: {
    update: jest.fn(),
    findMany: jest.fn(),
  },
  inventoryMovement: {
    create: jest.fn(),
  },
  catalogItem: {
    findUnique: jest.fn().mockResolvedValue(null),
  },
  productBatch: {
    create: jest.fn(),
  },
};

const mockAuditLog = { log: jest.fn() };
const mockEventBus = { publish: jest.fn() };

describe('PurchaseOrdersService', () => {
  let service: PurchaseOrdersService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PurchaseOrdersService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditLogService, useValue: mockAuditLog },
        { provide: EventBusService, useValue: mockEventBus },
      ],
    }).compile();

    service = module.get<PurchaseOrdersService>(PurchaseOrdersService);
  });

  // AC5 — Test 1: Create PO with 2 lines → 2 PurchaseOrderLines created with receivedQuantity = null
  describe('createPurchaseOrder', () => {
    it('creates a PO with 2 lines; lines have receivedQuantity = null', async () => {
      const createdPo = {
        id: 'po-1',
        status: 'draft',
        tenantId: 'tid',
        lines: [
          { id: 'line-1', catalogItemId: 'item-1', expectedQuantity: 5, receivedQuantity: null },
          { id: 'line-2', catalogItemId: 'item-2', expectedQuantity: 10, receivedQuantity: null },
        ],
        supplier: null,
      };
      mockPrisma.purchaseOrder.create.mockResolvedValue(createdPo);

      const dto = {
        tenantId: 'tid',
        lines: [
          { catalogItemId: 'item-1', expectedQuantity: 5 },
          { catalogItemId: 'item-2', expectedQuantity: 10 },
        ],
      };

      const result = await service.createPurchaseOrder(dto as any, 'user-1');

      expect(mockPrisma.purchaseOrder.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: 'draft',
            lines: { create: expect.arrayContaining([expect.objectContaining({ catalogItemId: 'item-1' })]) },
          }),
        }),
      );
      expect(result.lines).toHaveLength(2);
      expect(result.lines[0].receivedQuantity).toBeNull();
      expect(result.lines[1].receivedQuantity).toBeNull();
    });
  });

  // AC5 — Test 2: Valid transition draft → confirmed OK; invalid received → draft → 422
  describe('updateStatus', () => {
    it('allows valid transition draft → confirmed', async () => {
      mockPrisma.purchaseOrder.findFirst.mockResolvedValue({ id: 'po-1', status: 'draft', tenantId: 'tid' });
      mockPrisma.purchaseOrder.update.mockResolvedValue({ id: 'po-1', status: 'confirmed', lines: [], supplier: null });

      const result = await service.updateStatus('po-1', 'confirmed', 'tid', 'user-1');

      expect(mockPrisma.purchaseOrder.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: 'confirmed' } }),
      );
      expect(result.status).toBe('confirmed');
    });

    it('throws 422 for invalid transition received → draft', async () => {
      mockPrisma.purchaseOrder.findFirst.mockResolvedValue({ id: 'po-1', status: 'received', tenantId: 'tid' });

      await expect(service.updateStatus('po-1', 'draft', 'tid', 'user-1')).rejects.toThrow(
        UnprocessableEntityException,
      );
    });
  });

  // AC5 — Test 3: Full reception (all lines received) → status = 'received', InventoryMovements created
  describe('receivePurchaseOrder — full reception', () => {
    it('sets status to received and creates InventoryMovement for each line', async () => {
      const po = {
        id: 'po-1',
        status: 'confirmed',
        tenantId: 'tid',
        lines: [
          { id: 'line-1', catalogItemId: 'item-1', expectedQuantity: 5, receivedQuantity: null },
          { id: 'line-2', catalogItemId: 'item-2', expectedQuantity: 3, receivedQuantity: null },
        ],
      };
      mockPrisma.purchaseOrder.findFirst.mockResolvedValue(po);
      mockPrisma.purchaseOrderLine.update.mockResolvedValue({});
      mockPrisma.inventoryMovement.create.mockResolvedValue({});
      // After update both lines have receivedQuantity set
      mockPrisma.purchaseOrderLine.findMany.mockResolvedValue([
        { receivedQuantity: 5 },
        { receivedQuantity: 3 },
      ]);
      mockPrisma.purchaseOrder.update.mockResolvedValue({ id: 'po-1', status: 'received', lines: [] });

      const dto = {
        lines: [
          { purchaseOrderLineId: 'line-1', receivedQuantity: 5 },
          { purchaseOrderLineId: 'line-2', receivedQuantity: 3 },
        ],
      };

      const result = await service.receivePurchaseOrder('po-1', dto as any, 'tid', 'user-1');

      expect(mockPrisma.inventoryMovement.create).toHaveBeenCalledTimes(2);
      expect(mockPrisma.purchaseOrder.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: 'received' } }),
      );
      expect(result.status).toBe('received');
    });
  });

  // AC5 — Test 4: Partial reception → status = 'partially_received'
  describe('receivePurchaseOrder — partial reception', () => {
    it('sets status to partially_received when only some lines received', async () => {
      const po = {
        id: 'po-2',
        status: 'confirmed',
        tenantId: 'tid',
        lines: [
          { id: 'line-1', catalogItemId: 'item-1', expectedQuantity: 10, receivedQuantity: null },
          { id: 'line-2', catalogItemId: 'item-2', expectedQuantity: 8, receivedQuantity: null },
        ],
      };
      mockPrisma.purchaseOrder.findFirst.mockResolvedValue(po);
      mockPrisma.purchaseOrderLine.update.mockResolvedValue({});
      mockPrisma.inventoryMovement.create.mockResolvedValue({});
      // Only first line received
      mockPrisma.purchaseOrderLine.findMany.mockResolvedValue([
        { receivedQuantity: 10 },
        { receivedQuantity: null },
      ]);
      mockPrisma.purchaseOrder.update.mockResolvedValue({ id: 'po-2', status: 'partially_received', lines: [] });

      const dto = {
        lines: [{ purchaseOrderLineId: 'line-1', receivedQuantity: 10 }],
      };

      const result = await service.receivePurchaseOrder('po-2', dto as any, 'tid', 'user-1');

      expect(mockPrisma.purchaseOrder.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { status: 'partially_received' } }),
      );
      expect(result.status).toBe('partially_received');
    });
  });

  // AC5 — Test 5: Variance = received - expected, computed correctly per line
  describe('receivePurchaseOrder — variance calculation', () => {
    it('computes variance = receivedQuantity - expectedQuantity for each line', async () => {
      const po = {
        id: 'po-3',
        status: 'confirmed',
        tenantId: 'tid',
        lines: [{ id: 'line-1', catalogItemId: 'item-1', expectedQuantity: 10, receivedQuantity: null }],
      };
      mockPrisma.purchaseOrder.findFirst.mockResolvedValue(po);
      mockPrisma.purchaseOrderLine.update.mockResolvedValue({});
      mockPrisma.inventoryMovement.create.mockResolvedValue({});
      mockPrisma.purchaseOrderLine.findMany.mockResolvedValue([{ receivedQuantity: 8 }]);
      mockPrisma.purchaseOrder.update.mockResolvedValue({ id: 'po-3', status: 'received', lines: [] });

      const dto = { lines: [{ purchaseOrderLineId: 'line-1', receivedQuantity: 8 }] };

      // We verify via event publish payload which contains receivedLines with variance
      await service.receivePurchaseOrder('po-3', dto as any, 'tid', 'user-1');

      expect(mockEventBus.publish).toHaveBeenCalledWith(
        'delivery.received',
        expect.objectContaining({
          lines: expect.arrayContaining([
            expect.objectContaining({
              expectedQuantity: 10,
              receivedQuantity: 8,
              variance: -2,
            }),
          ]),
        }),
      );
    });
  });
});
