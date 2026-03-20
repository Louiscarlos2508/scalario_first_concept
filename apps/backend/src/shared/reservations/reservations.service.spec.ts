import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { Decimal } from '@prisma/client/runtime/library';
import { ReservationsService } from './reservations.service';
import { PrismaService } from '../../prisma/prisma.service';
import { InventoryService } from '../inventory/inventory.service';

const TENANT_ID = 'tenant-uuid-001';
const USER_ID = 'user-uuid-001';
const CUSTOMER_ID = 'customer-uuid-001';
const RESERVATION_ID = 'reservation-uuid-001';
const TX_ID = 'tx-uuid-001';

const makeCreateDto = (overrides = {}) => ({
  customerId: CUSTOMER_ID,
  items: [{ catalogItemId: 'item-001', quantity: 1, unitPrice: 10000 }],
  totalAmount: 20000,
  depositAmount: 4000, // 20% — valid
  paymentMethod: 'CASH',
  ...overrides,
});

const makePendingReservation = (overrides = {}) => ({
  id: RESERVATION_ID,
  customerId: CUSTOMER_ID,
  itemsJson: [{ catalogItemId: 'item-001', quantity: 1, unitPrice: 10000 }],
  totalAmount: new Decimal(20000),
  depositAmount: new Decimal(4000),
  remainingAmount: new Decimal(16000),
  status: 'pending',
  tenantId: TENANT_ID,
  createdBy: USER_ID,
  createdAt: new Date(),
  completedAt: null,
  depositTransactionId: TX_ID,
  completionTransactionId: null,
  ...overrides,
});

describe('ReservationsService', () => {
  let service: ReservationsService;
  let prisma: jest.Mocked<PrismaService>;
  let inventoryService: jest.Mocked<InventoryService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReservationsService,
        {
          provide: PrismaService,
          useValue: {
            contact: {
              findFirst: jest.fn().mockResolvedValue({ id: CUSTOMER_ID }),
              update: jest.fn().mockResolvedValue({}),
            },
            transaction: {
              create: jest.fn().mockResolvedValue({ id: TX_ID }),
            },
            reservation: {
              create: jest.fn().mockResolvedValue(makePendingReservation()),
              findFirst: jest.fn().mockResolvedValue(makePendingReservation()),
              update: jest.fn().mockImplementation((args) =>
                Promise.resolve({ ...makePendingReservation(), ...args.data }),
              ),
              count: jest.fn().mockResolvedValue(2),
              findMany: jest.fn().mockResolvedValue([makePendingReservation()]),
              aggregate: jest.fn().mockResolvedValue({ _sum: { depositAmount: new Decimal(4000) } }),
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

    service = module.get<ReservationsService>(ReservationsService);
    prisma = module.get(PrismaService);
    inventoryService = module.get(InventoryService);
  });

  describe('createReservation', () => {
    it('creates reservation and deposit transaction for valid deposit', async () => {
      const result = await service.createReservation(TENANT_ID, USER_ID, makeCreateDto());

      expect(prisma.transaction.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ transactionType: 'reservation_deposit' }),
        }),
      );
      expect(prisma.reservation.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ status: 'pending', customerId: CUSTOMER_ID }),
        }),
      );
      expect(result.id).toBe(RESERVATION_ID);
    });

    it('throws NotFoundException when customer not found', async () => {
      (prisma.contact.findFirst as jest.Mock).mockResolvedValueOnce(null);

      await expect(
        service.createReservation(TENANT_ID, USER_ID, makeCreateDto()),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws BadRequestException when deposit < 10%', async () => {
      await expect(
        service.createReservation(TENANT_ID, USER_ID, makeCreateDto({ depositAmount: 1000 })), // 5%
      ).rejects.toThrow(BadRequestException);
    });

    it('throws BadRequestException when deposit > 50%', async () => {
      await expect(
        service.createReservation(TENANT_ID, USER_ID, makeCreateDto({ depositAmount: 12000 })), // 60%
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('completeReservation', () => {
    it('completes reservation, creates completion tx, decrements stock', async () => {
      await service.completeReservation(TENANT_ID, RESERVATION_ID, {
        paymentMethod: 'CASH',
        amount: 16000,
      });

      expect(prisma.transaction.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ transactionType: 'reservation_completion' }),
        }),
      );
      expect(inventoryService.createMovement).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'SALE' }),
      );
      expect(prisma.reservation.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'completed' }) }),
      );
    });

    it('throws BadRequestException when already completed', async () => {
      (prisma.reservation.findFirst as jest.Mock).mockResolvedValueOnce(
        makePendingReservation({ status: 'completed' }),
      );

      await expect(
        service.completeReservation(TENANT_ID, RESERVATION_ID, { paymentMethod: 'CASH', amount: 16000 }),
      ).rejects.toThrow(BadRequestException);
    });

    it('throws BadRequestException when amount insufficient', async () => {
      await expect(
        service.completeReservation(TENANT_ID, RESERVATION_ID, { paymentMethod: 'CASH', amount: 1000 }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('cancelReservation', () => {
    it('increments contact balance for credit_note resolution', async () => {
      await service.cancelReservation(TENANT_ID, USER_ID, RESERVATION_ID, {
        depositResolution: 'credit_note',
      }, 'manager');

      expect(prisma.contact.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ balance: expect.anything() }),
        }),
      );
      expect(prisma.reservation.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'cancelled' }) }),
      );
    });

    it('creates refund transaction for cash_refund resolution', async () => {
      await service.cancelReservation(TENANT_ID, USER_ID, RESERVATION_ID, {
        depositResolution: 'cash_refund',
      }, 'owner');

      expect(prisma.transaction.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ transactionType: 'reservation_refund' }),
        }),
      );
      expect(prisma.contact.update).not.toHaveBeenCalled();
    });

    it('throws ForbiddenException when commercial tries to cancel', async () => {
      await expect(
        service.cancelReservation(TENANT_ID, USER_ID, RESERVATION_ID, {
          depositResolution: 'cash_refund',
        }, 'commercial'),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('getKpi', () => {
    it('returns pendingCount and totalDepositAmount', async () => {
      const result = await service.getKpi(TENANT_ID);

      expect(result.pendingCount).toBe(2);
      expect(result.totalDepositAmount).toBe(4000);
    });
  });
});
