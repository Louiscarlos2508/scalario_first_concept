import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { InternalRequestsService } from './internal-requests.service';
import { PrismaService } from '../../prisma/prisma.service';
import { InventoryService } from '../inventory/inventory.service';

const TENANT_ID = 'tenant-uuid-001';
const ITEM_ID = 'item-uuid-001';
const USER_ID = 'user-uuid-001';
const REQ_ID = 'req-uuid-001';

const mockRequest = {
  id: REQ_ID,
  tenantId: TENANT_ID,
  catalogItemId: ITEM_ID,
  quantity: 10,
  status: 'pending',
  urgency: 'normal',
  requestedBy: USER_ID,
  preparedBy: null,
  approvedBy: null,
  reason: null,
  catalogItem: { name: 'Produit Test' },
  createdAt: new Date(),
  updatedAt: new Date(),
};

describe('InternalRequestsService', () => {
  let service: InternalRequestsService;
  let prisma: jest.Mocked<PrismaService>;
  let inventoryService: jest.Mocked<InventoryService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InternalRequestsService,
        {
          provide: PrismaService,
          useValue: {
            internalRequest: {
              create: jest.fn(),
              update: jest.fn(),
              findFirst: jest.fn(),
              findMany: jest.fn(),
            },
            tenant: {
              findUnique: jest.fn(),
            },
            role: {
              findMany: jest.fn().mockResolvedValue([]),
            },
            organizationMember: {
              findMany: jest.fn().mockResolvedValue([]),
            },
            notification: {
              create: jest.fn().mockResolvedValue({}),
              createMany: jest.fn().mockResolvedValue({ count: 0 }),
            },
          },
        },
        {
          provide: InventoryService,
          useValue: {
            createMovement: jest.fn().mockResolvedValue({}),
          },
        },
      ],
    }).compile();

    service = module.get<InternalRequestsService>(InternalRequestsService);
    prisma = module.get(PrismaService);
    inventoryService = module.get(InventoryService);
  });

  // ── 1. create() → status = pending ─────────────────────────────────────────
  it('create() crée une demande avec status pending', async () => {
    (prisma.internalRequest.create as jest.Mock).mockResolvedValue({
      ...mockRequest,
      status: 'pending',
    });

    const result = await service.create({
      catalogItemId: ITEM_ID,
      quantity: 10,
      urgency: 'normal',
      tenantId: TENANT_ID,
      requestedBy: USER_ID,
    });

    expect(prisma.internalRequest.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ status: 'pending' }) }),
    );
    expect(result.status).toBe('pending');
  });

  // ── 2. prepare() + skipManagerApproval = false → status = prepared ──────────
  it('prepare() avec skipManagerApproval=false → status=prepared', async () => {
    (prisma.internalRequest.findFirst as jest.Mock).mockResolvedValue(mockRequest);
    (prisma.tenant.findUnique as jest.Mock).mockResolvedValue({ skipManagerApproval: false });
    (prisma.internalRequest.update as jest.Mock).mockResolvedValue({
      ...mockRequest,
      status: 'prepared',
      preparedBy: USER_ID,
    });

    const result = await service.prepare(REQ_ID, TENANT_ID, USER_ID);

    expect(prisma.internalRequest.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: 'prepared', preparedBy: USER_ID }),
      }),
    );
    expect(result.status).toBe('prepared');
  });

  // ── 3. prepare() + skipManagerApproval = true → status = approved ────────────
  it('prepare() avec skipManagerApproval=true → status=approved (saute manager)', async () => {
    (prisma.internalRequest.findFirst as jest.Mock).mockResolvedValue(mockRequest);
    (prisma.tenant.findUnique as jest.Mock).mockResolvedValue({ skipManagerApproval: true });
    (prisma.internalRequest.update as jest.Mock).mockResolvedValue({
      ...mockRequest,
      status: 'approved',
      preparedBy: USER_ID,
    });

    const result = await service.prepare(REQ_ID, TENANT_ID, USER_ID);

    expect(prisma.internalRequest.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: 'approved' }),
      }),
    );
    expect(result.status).toBe('approved');
  });

  // ── 4. approve() → status = fulfilled + TRANSFER_OUT créé ──────────────────
  it('approve() → status=fulfilled et TRANSFER_OUT généré', async () => {
    const preparedRequest = { ...mockRequest, status: 'prepared' };
    (prisma.internalRequest.findFirst as jest.Mock).mockResolvedValue(preparedRequest);
    (prisma.internalRequest.update as jest.Mock).mockResolvedValue({
      ...preparedRequest,
      status: 'fulfilled',
      approvedBy: USER_ID,
    });

    const result = await service.approve(REQ_ID, TENANT_ID, USER_ID);

    expect(result.status).toBe('fulfilled');
    expect(inventoryService.createMovement).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'TRANSFER_OUT', tenantId: TENANT_ID }),
    );
  });

  // ── 5. approve() avec quantity modifiée → quantité mise à jour avant TRANSFER_OUT
  it('approve() avec quantity modifiée → quantité mise à jour', async () => {
    const preparedRequest = { ...mockRequest, status: 'prepared', quantity: 5 };
    (prisma.internalRequest.findFirst as jest.Mock).mockResolvedValue(preparedRequest);
    (prisma.internalRequest.update as jest.Mock).mockResolvedValue({
      ...preparedRequest,
      status: 'fulfilled',
      quantity: 20,
    });

    await service.approve(REQ_ID, TENANT_ID, USER_ID, 20);

    expect(prisma.internalRequest.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ quantity: 20 }),
      }),
    );
    expect(inventoryService.createMovement).toHaveBeenCalledWith(
      expect.objectContaining({ quantity: 20 }),
    );
  });

  // ── 6. reject() → status = rejected + reason enregistré ────────────────────
  it('reject() → status=rejected avec reason', async () => {
    (prisma.internalRequest.findFirst as jest.Mock).mockResolvedValue(mockRequest);
    (prisma.internalRequest.update as jest.Mock).mockResolvedValue({
      ...mockRequest,
      status: 'rejected',
      reason: 'Stock insuffisant',
    });

    const result = await service.reject(REQ_ID, TENANT_ID, 'Stock insuffisant');

    expect(prisma.internalRequest.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: 'rejected', reason: 'Stock insuffisant' }),
      }),
    );
    expect(result.status).toBe('rejected');
  });

  // ── 7. list() filtré par status=pending → retourne uniquement les pending ───
  it('list() filtré par status=pending', async () => {
    const pendingItems = [mockRequest, { ...mockRequest, id: 'req-uuid-002' }];
    (prisma.internalRequest.findMany as jest.Mock).mockResolvedValue(pendingItems);

    const result = await service.list({ tenantId: TENANT_ID, status: 'pending' });

    expect(prisma.internalRequest.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ tenantId: TENANT_ID, status: 'pending' }),
      }),
    );
    expect(result).toHaveLength(2);
  });

  // ── prepare() → lève NotFoundException si demande inexistante ───────────────
  it('prepare() lève NotFoundException si demande inexistante', async () => {
    (prisma.internalRequest.findFirst as jest.Mock).mockResolvedValue(null);

    await expect(service.prepare(REQ_ID, TENANT_ID, USER_ID)).rejects.toThrow(NotFoundException);
  });

  // ── approve() → lève NotFoundException si demande inexistante ───────────────
  it('approve() lève NotFoundException si demande inexistante', async () => {
    (prisma.internalRequest.findFirst as jest.Mock).mockResolvedValue(null);

    await expect(service.approve(REQ_ID, TENANT_ID, USER_ID)).rejects.toThrow(NotFoundException);
  });

  // ── reject() → lève BadRequestException si déjà fulfilled ──────────────────
  it('reject() lève BadRequestException si déjà fulfilled', async () => {
    (prisma.internalRequest.findFirst as jest.Mock).mockResolvedValue({
      ...mockRequest,
      status: 'fulfilled',
    });

    await expect(service.reject(REQ_ID, TENANT_ID, 'raison')).rejects.toThrow(BadRequestException);
  });
});
