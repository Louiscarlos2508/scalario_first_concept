import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { ClientOrdersService } from './client-orders.service';
import { PrismaService } from '../../prisma/prisma.service';
import { InventoryService } from '../inventory/inventory.service';

const ORDER_STUB = {
  id: 'order-1',
  orderNumber: 'CO-0001',
  tenantId: 'tid',
  customerId: 'cid',
  status: 'draft',
  lines: [
    { id: 'line-1', clientOrderId: 'order-1', catalogItemId: 'item-1', variantId: null, quantity: 5, unitPrice: 1000, deliveredQty: 0 },
  ],
};

const mockPrisma = {
  clientOrder: {
    create: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
  },
  clientOrderLine: {},
  inventoryMovement: {
    create: jest.fn(),
    aggregate: jest.fn(),
  },
  contact: {
    findFirst: jest.fn(),
  },
};

const mockInventory = {
  getCurrentStock: jest.fn(),
};

describe('ClientOrdersService', () => {
  let service: ClientOrdersService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ClientOrdersService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: InventoryService, useValue: mockInventory },
      ],
    }).compile();

    service = module.get<ClientOrdersService>(ClientOrdersService);
  });

  // AC1 — createOrder: generates CO-0001 for first order of tenant
  describe('createOrder', () => {
    it('creates order with CO-0001 for a new tenant', async () => {
      mockPrisma.contact.findFirst.mockResolvedValue({ id: 'cid', name: 'Client A' });
      mockPrisma.clientOrder.findFirst.mockResolvedValue(null); // no prior orders
      mockPrisma.clientOrder.create.mockResolvedValue(ORDER_STUB);

      const dto = {
        tenantId: 'tid',
        customerId: 'cid',
        lines: [{ catalogItemId: 'item-1', quantity: 5, unitPrice: 1000 }],
      };

      const result = await service.createOrder('tid', 'user-1', dto as any);

      expect(mockPrisma.clientOrder.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            orderNumber: 'CO-0001',
            status: 'draft',
          }),
        }),
      );
      expect(result.orderNumber).toBe('CO-0001');
    });

    it('increments orderNumber for subsequent orders (CO-0002 after CO-0001)', async () => {
      mockPrisma.contact.findFirst.mockResolvedValue({ id: 'cid' });
      mockPrisma.clientOrder.findFirst.mockResolvedValue({ orderNumber: 'CO-0001' }); // prior order
      mockPrisma.clientOrder.create.mockResolvedValue({ ...ORDER_STUB, orderNumber: 'CO-0002' });

      const dto = { tenantId: 'tid', customerId: 'cid', lines: [{ catalogItemId: 'item-1', quantity: 1, unitPrice: 500 }] };
      await service.createOrder('tid', 'user-1', dto as any);

      expect(mockPrisma.clientOrder.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ orderNumber: 'CO-0002' }),
        }),
      );
    });

    it('throws NotFoundException when customer not found', async () => {
      mockPrisma.contact.findFirst.mockResolvedValue(null);

      const dto = { tenantId: 'tid', customerId: 'unknown', lines: [{ catalogItemId: 'item-1', quantity: 1, unitPrice: 500 }] };
      await expect(service.createOrder('tid', 'user-1', dto as any)).rejects.toThrow(NotFoundException);
    });

    it('throws 422 when lines array is empty', async () => {
      mockPrisma.contact.findFirst.mockResolvedValue({ id: 'cid' });

      const dto = { tenantId: 'tid', customerId: 'cid', lines: [] };
      await expect(service.createOrder('tid', 'user-1', dto as any)).rejects.toThrow(
        UnprocessableEntityException,
      );
    });
  });

  // AC2 — confirmOrder: validates stock, creates RESERVATION movements
  describe('confirmOrder', () => {
    it('confirms order and creates RESERVATION movement per line when stock is sufficient', async () => {
      mockPrisma.clientOrder.findFirst.mockResolvedValue({ ...ORDER_STUB, status: 'draft' });
      mockInventory.getCurrentStock.mockResolvedValue(10);
      mockPrisma.inventoryMovement.aggregate.mockResolvedValue({ _sum: { quantity: 0 } });
      mockPrisma.inventoryMovement.create.mockResolvedValue({});
      mockPrisma.clientOrder.update.mockResolvedValue({ ...ORDER_STUB, status: 'confirmed' });

      const result = await service.confirmOrder('order-1', 'tid', 'user-1');

      expect(mockPrisma.inventoryMovement.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            type: 'RESERVATION',
            catalogItemId: 'item-1',
            referenceId: 'order-1',
          }),
        }),
      );
      expect(result.status).toBe('confirmed');
    });

    it('throws 422 when available stock < required quantity', async () => {
      mockPrisma.clientOrder.findFirst.mockResolvedValue({ ...ORDER_STUB, status: 'draft' });
      mockInventory.getCurrentStock.mockResolvedValue(3); // only 3 available
      mockPrisma.inventoryMovement.aggregate.mockResolvedValue({ _sum: { quantity: 0 } });

      await expect(service.confirmOrder('order-1', 'tid', 'user-1')).rejects.toThrow(
        UnprocessableEntityException,
      );
    });

    it('accounts for existing reservations when checking available stock', async () => {
      mockPrisma.clientOrder.findFirst.mockResolvedValue({ ...ORDER_STUB, status: 'draft' });
      mockInventory.getCurrentStock.mockResolvedValue(7);
      // 3 already reserved, 0 released → available = 7 - 3 = 4 < 5 → should fail
      mockPrisma.inventoryMovement.aggregate
        .mockResolvedValueOnce({ _sum: { quantity: 3 } }) // RESERVATION
        .mockResolvedValueOnce({ _sum: { quantity: 0 } }); // RESERVATION_RELEASE

      await expect(service.confirmOrder('order-1', 'tid', 'user-1')).rejects.toThrow(
        UnprocessableEntityException,
      );
    });

    it('throws 422 for invalid transition (not draft)', async () => {
      mockPrisma.clientOrder.findFirst.mockResolvedValue({ ...ORDER_STUB, status: 'confirmed' });

      await expect(service.confirmOrder('order-1', 'tid', 'user-1')).rejects.toThrow(
        UnprocessableEntityException,
      );
    });
  });

  // AC3 — cancelOrder: creates RESERVATION_RELEASE for confirmed orders
  describe('cancelOrder', () => {
    it('cancels a draft order without creating RESERVATION_RELEASE', async () => {
      mockPrisma.clientOrder.findFirst.mockResolvedValue({ ...ORDER_STUB, status: 'draft' });
      mockPrisma.clientOrder.update.mockResolvedValue({ ...ORDER_STUB, status: 'cancelled' });

      const result = await service.cancelOrder('order-1', 'tid', 'user-1');

      expect(mockPrisma.inventoryMovement.create).not.toHaveBeenCalled();
      expect(result.status).toBe('cancelled');
    });

    it('cancels a confirmed order and creates RESERVATION_RELEASE per line', async () => {
      mockPrisma.clientOrder.findFirst.mockResolvedValue({ ...ORDER_STUB, status: 'confirmed' });
      mockPrisma.inventoryMovement.create.mockResolvedValue({});
      mockPrisma.clientOrder.update.mockResolvedValue({ ...ORDER_STUB, status: 'cancelled' });

      const result = await service.cancelOrder('order-1', 'tid', 'user-1');

      expect(mockPrisma.inventoryMovement.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            type: 'RESERVATION_RELEASE',
            catalogItemId: 'item-1',
            referenceId: 'order-1',
          }),
        }),
      );
      expect(result.status).toBe('cancelled');
    });

    it('throws 422 when trying to cancel a delivered order', async () => {
      mockPrisma.clientOrder.findFirst.mockResolvedValue({ ...ORDER_STUB, status: 'delivered' });

      await expect(service.cancelOrder('order-1', 'tid', 'user-1')).rejects.toThrow(
        UnprocessableEntityException,
      );
    });
  });

  // AC4 — getKpis: returns inProgressCount and pendingRevenue for active statuses
  describe('getKpis', () => {
    it('returns inProgressCount and pendingRevenue from active orders', async () => {
      const activeOrders = [
        {
          lines: [
            { quantity: 2, unitPrice: 500 },
            { quantity: 1, unitPrice: 1000 },
          ],
        },
        {
          lines: [{ quantity: 3, unitPrice: 200 }],
        },
      ];
      mockPrisma.clientOrder.findMany.mockResolvedValue(activeOrders);

      const result = await service.getKpis('tid');

      // revenue = (2*500 + 1*1000) + (3*200) = 2000 + 600 = 2600
      expect(result.inProgressCount).toBe(2);
      expect(result.pendingRevenue).toBe(2600);
    });

    it('returns zeros when no active orders', async () => {
      mockPrisma.clientOrder.findMany.mockResolvedValue([]);

      const result = await service.getKpis('tid');

      expect(result.inProgressCount).toBe(0);
      expect(result.pendingRevenue).toBe(0);
    });
  });
});
