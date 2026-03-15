import { Test, TestingModule } from '@nestjs/testing';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';

const TENANT_ID = 'tenant-uuid-001';
const ITEM_ID = 'item-uuid-001';
const REF_ID = 'ref-uuid-001';

const mockInventoryService = {
  createMovement: jest.fn(),
  createTransferOut: jest.fn(),
  confirmTransferIn: jest.fn(),
  adjustInventory: jest.fn(),
  getCurrentStock: jest.fn(),
  getMovements: jest.fn(),
};

describe('InventoryController', () => {
  let controller: InventoryController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [InventoryController],
      providers: [{ provide: InventoryService, useValue: mockInventoryService }],
    }).compile();

    controller = module.get<InventoryController>(InventoryController);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // ── POST /inventory/movements ─────────────────────────────────────────────

  describe('createMovement (POST /inventory/movements)', () => {
    it('extracts userId from req.user.sub and delegates to createMovement for DELIVERY', async () => {
      const body = { catalogItemId: ITEM_ID, quantity: 10, type: 'DELIVERY', tenantId: TENANT_ID };
      const req = { user: { sub: 'user-001' } };
      mockInventoryService.createMovement.mockResolvedValue({ id: 'mov-001' });

      await controller.createMovement(body, req);

      expect(mockInventoryService.createMovement).toHaveBeenCalledWith({ ...body, userId: 'user-001' });
    });

    it('delegates to createTransferOut when type is TRANSFER_OUT', async () => {
      const body = { catalogItemId: ITEM_ID, quantity: 8, type: 'TRANSFER_OUT', tenantId: TENANT_ID };
      const req = { user: { sub: 'manager-001' } };
      mockInventoryService.createTransferOut.mockResolvedValue({ id: 'mov-001', referenceId: REF_ID });

      await controller.createMovement(body, req);

      expect(mockInventoryService.createTransferOut).toHaveBeenCalledWith({ ...body, userId: 'manager-001' });
      expect(mockInventoryService.createMovement).not.toHaveBeenCalled();
    });

    it('passes userId as null when req.user is absent', async () => {
      const body = { quantity: 5, type: 'DELIVERY', tenantId: TENANT_ID };
      mockInventoryService.createMovement.mockResolvedValue({});

      await controller.createMovement(body, {});

      expect(mockInventoryService.createMovement).toHaveBeenCalledWith({ ...body, userId: null });
    });
  });

  // ── POST /inventory/movements/confirm ─────────────────────────────────────

  describe('confirmTransferIn (POST /inventory/movements/confirm)', () => {
    it('delegates to confirmTransferIn with userId from req.user.sub', async () => {
      const body = { referenceId: REF_ID, quantity: 7, tenantId: TENANT_ID };
      const req = { user: { sub: 'commercial-001' } };
      mockInventoryService.confirmTransferIn.mockResolvedValue({ id: 'mov-in-001' });

      await controller.confirmTransferIn(body, req);

      expect(mockInventoryService.confirmTransferIn).toHaveBeenCalledWith({ ...body, userId: 'commercial-001' });
    });
  });

  // ── POST /inventory/adjust ────────────────────────────────────────────────

  describe('adjustInventory (POST /inventory/adjust)', () => {
    it('passes countedQuantity + reason + userId to service (AC2)', async () => {
      const body = { catalogItemId: ITEM_ID, countedQuantity: 45, reason: 'Physical count', tenantId: TENANT_ID };
      const req = { user: { sub: 'manager-001' } };
      mockInventoryService.adjustInventory.mockResolvedValue({ adjusted: true, variance: -5 });

      const result = await controller.adjustInventory(body, req);

      expect(mockInventoryService.adjustInventory).toHaveBeenCalledWith({ ...body, userId: 'manager-001' });
      expect(result).toEqual({ adjusted: true, variance: -5 });
    });

    it('passes userId as null when req.user is absent', async () => {
      const body = { catalogItemId: ITEM_ID, countedQuantity: 50, tenantId: TENANT_ID };
      mockInventoryService.adjustInventory.mockResolvedValue({ adjusted: false });

      await controller.adjustInventory(body, {});

      expect(mockInventoryService.adjustInventory).toHaveBeenCalledWith({ ...body, userId: null });
    });
  });

  // ── GET /inventory/stock ──────────────────────────────────────────────────

  describe('getStock (GET /inventory/stock)', () => {
    it('calls getCurrentStock and returns stock response (AC3)', async () => {
      mockInventoryService.getCurrentStock.mockResolvedValue(72);

      const result = await controller.getStock(ITEM_ID, TENANT_ID);

      expect(mockInventoryService.getCurrentStock).toHaveBeenCalledWith(ITEM_ID, TENANT_ID);
      expect(result).toMatchObject({
        catalogItemId: ITEM_ID,
        tenantId: TENANT_ID,
        currentStock: 72,
        computedAt: expect.any(String),
      });
    });
  });

  // ── GET /inventory/movements ──────────────────────────────────────────────

  describe('getMovements (GET /inventory/movements)', () => {
    it('passes parsed params including referenceId to service (AC4)', async () => {
      const movements = { items: [], meta: { total: 0, page: 1, limit: 50, hasMore: false, serverTime: '' } };
      mockInventoryService.getMovements.mockResolvedValue(movements);

      await controller.getMovements(TENANT_ID, '2026-03-01T00:00:00Z', REF_ID, '2', '50');

      expect(mockInventoryService.getMovements).toHaveBeenCalledWith({
        tenantId: TENANT_ID,
        since: '2026-03-01T00:00:00Z',
        referenceId: REF_ID,
        page: 2,
        limit: 50,
      });
    });

    it('uses default page=1 and limit=100 when not provided', async () => {
      mockInventoryService.getMovements.mockResolvedValue({ items: [], meta: {} });

      await controller.getMovements(undefined, undefined, undefined, '1', '100');

      expect(mockInventoryService.getMovements).toHaveBeenCalledWith({
        tenantId: undefined,
        since: undefined,
        referenceId: undefined,
        page: 1,
        limit: 100,
      });
    });
  });
});
