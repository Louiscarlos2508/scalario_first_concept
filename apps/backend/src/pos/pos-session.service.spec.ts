import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { PosSessionService } from './pos-session.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventBusService } from '../kernel/events/event-bus.service';
import { ReturnsService } from '../shared/returns/returns.service';
import { Prisma } from '@prisma/client';

const TENANT_ID = 'tenant-uuid-001';
const USER_ID = 'user-uuid-001';
const SESSION_ID = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

const mockPrisma = {
  posSession: {
    findFirst: jest.fn(),
    create: jest.fn(),
    findUnique: jest.fn(),
    update: jest.fn(),
    findMany: jest.fn(),
    upsert: jest.fn(),
  },
  transaction: {
    findMany: jest.fn(),
  },
};

const mockEventBus = {
  publish: jest.fn(),
};

const makeSession = (overrides: Record<string, any> = {}) => ({
  id: SESSION_ID,
  userId: USER_ID,
  tenantId: TENANT_ID,
  openingBalance: new Prisma.Decimal(15000),
  closingBalance: null,
  theoreticalBalance: null,
  variance: null,
  varianceExplanation: null,
  status: 'OPEN',
  openedAt: new Date(),
  closedAt: null,
  ...overrides,
});

describe('PosSessionService', () => {
  let service: PosSessionService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PosSessionService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: EventBusService, useValue: mockEventBus },
        { provide: ReturnsService, useValue: { getReturnsSummaryForSession: jest.fn().mockResolvedValue({ count: 0, amount: 0, cashRefundAmount: 0 }) } },
      ],
    }).compile();

    service = module.get<PosSessionService>(PosSessionService);
  });

  // ── openSession ──────────────────────────────────────────────────────────

  describe('openSession', () => {
    it('creates OPEN session when no existing session (AC2)', async () => {
      mockPrisma.posSession.findFirst.mockResolvedValue(null);
      const created = makeSession();
      mockPrisma.posSession.create.mockResolvedValue(created);

      const result = await service.openSession({ userId: USER_ID, tenantId: TENANT_ID, openingBalance: 15000 });

      expect(mockPrisma.posSession.findFirst).toHaveBeenCalledWith({
        where: { userId: USER_ID, tenantId: TENANT_ID, status: 'OPEN' },
      });
      expect(mockPrisma.posSession.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ userId: USER_ID, tenantId: TENANT_ID, status: 'OPEN' }),
      });
      expect(result.status).toBe('OPEN');
    });

    it('throws BadRequestException if user already has OPEN session (AC2)', async () => {
      mockPrisma.posSession.findFirst.mockResolvedValue(makeSession());

      await expect(
        service.openSession({ userId: USER_ID, tenantId: TENANT_ID, openingBalance: 15000 }),
      ).rejects.toThrow(BadRequestException);

      expect(mockPrisma.posSession.create).not.toHaveBeenCalled();
    });
  });

  // ── closeSession ─────────────────────────────────────────────────────────

  describe('closeSession', () => {
    it('calculates theoretical_balance and variance correctly (AC3)', async () => {
      const session = makeSession();
      mockPrisma.posSession.findUnique.mockResolvedValue(session);
      // getSessionSummary inner mocks
      mockPrisma.transaction.findMany.mockResolvedValue([
        { totalAmount: new Prisma.Decimal(50000), paymentMethod: 'CASH' },
        { totalAmount: new Prisma.Decimal(20000), paymentMethod: 'MOBILE_MONEY' },
      ]);
      mockPrisma.posSession.update.mockResolvedValue({
        ...session,
        status: 'CLOSED',
        closingBalance: new Prisma.Decimal(64500),
        theoreticalBalance: new Prisma.Decimal(65000),
        variance: new Prisma.Decimal(-500),
        varianceExplanation: 'Short change error',
        closedAt: new Date(),
      });

      const result = await service.closeSession(SESSION_ID, 64500, 'Short change error');

      // theoretical = 15000 (opening) + 50000 (CASH) = 65000; variance = 64500 - 65000 = -500
      expect(mockPrisma.posSession.update).toHaveBeenCalledWith({
        where: { id: SESSION_ID },
        data: expect.objectContaining({
          closingBalance: expect.any(Prisma.Decimal),
          theoreticalBalance: expect.any(Prisma.Decimal),
          variance: expect.any(Prisma.Decimal),
          varianceExplanation: 'Short change error',
          status: 'CLOSED',
        }),
      });
      expect(result.status).toBe('CLOSED');
    });

    it('rejects closure when variance != 0 and no explanation provided (AC3)', async () => {
      mockPrisma.posSession.findUnique.mockResolvedValue(makeSession());
      mockPrisma.transaction.findMany.mockResolvedValue([
        { totalAmount: new Prisma.Decimal(50000), paymentMethod: 'CASH' },
      ]);

      // Variance = 64500 - 65000 = -500 (non-zero, no explanation)
      await expect(service.closeSession(SESSION_ID, 64500)).rejects.toThrow(
        BadRequestException,
      );
      expect(mockPrisma.posSession.update).not.toHaveBeenCalled();
    });

    it('closes session when variance = 0 without explanation (AC3)', async () => {
      mockPrisma.posSession.findUnique.mockResolvedValue(makeSession());
      mockPrisma.transaction.findMany.mockResolvedValue([
        { totalAmount: new Prisma.Decimal(50000), paymentMethod: 'CASH' },
      ]);
      const closedSession = { ...makeSession(), status: 'CLOSED', closedAt: new Date() };
      mockPrisma.posSession.update.mockResolvedValue(closedSession);

      // 15000 + 50000 = 65000; closingBalance = 65000 → variance = 0
      const result = await service.closeSession(SESSION_ID, 65000);

      expect(result.status).toBe('CLOSED');
      expect(mockPrisma.posSession.update).toHaveBeenCalled();
    });

    it('emits session.closed event after successful closure (AC3)', async () => {
      const session = makeSession();
      mockPrisma.posSession.findUnique.mockResolvedValue(session);
      mockPrisma.transaction.findMany.mockResolvedValue([]);
      const closedSession = { ...session, status: 'CLOSED', closedAt: new Date('2026-03-15T10:00:00Z') };
      mockPrisma.posSession.update.mockResolvedValue(closedSession);

      // variance = 15000 - 15000 = 0 (no CASH sales, closingBalance = openingBalance)
      await service.closeSession(SESSION_ID, 15000);

      expect(mockEventBus.publish).toHaveBeenCalledWith('session.closed', {
        sessionId: SESSION_ID,
        tenantId: TENANT_ID,
        userId: USER_ID,
        variance: 0,
        closedAt: expect.any(String),
      });
    });

    it('throws if session not found or already closed (AC3)', async () => {
      mockPrisma.posSession.findUnique.mockResolvedValue(null);

      await expect(service.closeSession(SESSION_ID, 15000)).rejects.toThrow(BadRequestException);
    });
  });

  // ── getSessionSummary ────────────────────────────────────────────────────

  describe('getSessionSummary', () => {
    it('uses transaction.findMany (not order.findMany) and returns correct shape (AC4, AC6)', async () => {
      mockPrisma.posSession.findUnique.mockResolvedValue(makeSession());
      mockPrisma.transaction.findMany.mockResolvedValue([
        { totalAmount: new Prisma.Decimal(30000), paymentMethod: 'CASH' },
        { totalAmount: new Prisma.Decimal(10000), paymentMethod: 'CASH' },
        { totalAmount: new Prisma.Decimal(20000), paymentMethod: 'MOBILE_MONEY' },
      ]);

      const result = await service.getSessionSummary(SESSION_ID);

      expect(mockPrisma.transaction.findMany).toHaveBeenCalledWith({ where: { sessionId: SESSION_ID } });
      expect(result.totalSales).toBe(60000);
      expect(result.totalsByMethod).toEqual({ CASH: 40000, MOBILE_MONEY: 20000 });
      // theoreticalCash = 15000 (opening) + 40000 (CASH) = 55000
      expect(result.theoreticalCash).toBe(55000);
      expect(result.openingBalance).toBe(15000);
    });

    it('returns varianceExplanation from session (AC4)', async () => {
      const session = makeSession({ varianceExplanation: 'Counted again', status: 'CLOSED' });
      mockPrisma.posSession.findUnique.mockResolvedValue(session);
      mockPrisma.transaction.findMany.mockResolvedValue([]);

      const result = await service.getSessionSummary(SESSION_ID);

      expect(result.varianceExplanation).toBe('Counted again');
    });

    it('throws BadRequestException for invalid UUID format (AC4)', async () => {
      await expect(service.getSessionSummary('not-a-uuid')).rejects.toThrow(BadRequestException);
      expect(mockPrisma.posSession.findUnique).not.toHaveBeenCalled();
    });

    it('throws BadRequestException when session not found (AC4)', async () => {
      mockPrisma.posSession.findUnique.mockResolvedValue(null);

      await expect(service.getSessionSummary(SESSION_ID)).rejects.toThrow(BadRequestException);
    });
  });

  // ── getSessionReports ────────────────────────────────────────────────────

  describe('getSessionReports', () => {
    it('returns CLOSED sessions ordered by closedAt desc (AC5)', async () => {
      const sessions = [makeSession({ status: 'CLOSED' })];
      mockPrisma.posSession.findMany.mockResolvedValue(sessions);

      const result = await service.getSessionReports(TENANT_ID);

      expect(mockPrisma.posSession.findMany).toHaveBeenCalledWith({
        where: { tenantId: TENANT_ID, status: 'CLOSED' },
        orderBy: { closedAt: 'desc' },
      });
      expect(result).toEqual(sessions);
    });
  });
});
