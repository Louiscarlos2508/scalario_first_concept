import { Test, TestingModule } from '@nestjs/testing';
import { RetailSessionController } from './retail-session.controller';
import { PosSessionService } from '../pos/pos-session.service';

const SESSION_ID = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const TENANT_ID = 'tenant-uuid-001';
const USER_ID = 'user-uuid-001';

const mockPosSessionService = {
  openSession: jest.fn(),
  closeSession: jest.fn(),
  getSessionSummary: jest.fn(),
  getSessionReports: jest.fn(),
};

describe('RetailSessionController', () => {
  let controller: RetailSessionController;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [RetailSessionController],
      providers: [{ provide: PosSessionService, useValue: mockPosSessionService }],
    }).compile();

    controller = module.get<RetailSessionController>(RetailSessionController);
  });

  // ── POST /retail/sessions/open ────────────────────────────────────────────

  describe('openSession (POST /retail/sessions/open)', () => {
    it('delegates to openSession with userId from req.user.sub (AC2)', async () => {
      const session = { id: SESSION_ID, status: 'OPEN' };
      mockPosSessionService.openSession.mockResolvedValue(session);
      const req = { user: { sub: USER_ID } };

      await controller.openSession({ tenantId: TENANT_ID, openingBalance: 15000 }, req);

      expect(mockPosSessionService.openSession).toHaveBeenCalledWith({
        userId: USER_ID,
        tenantId: TENANT_ID,
        openingBalance: 15000,
      });
    });

    it('uses body.userId when req.user is absent (AC2)', async () => {
      mockPosSessionService.openSession.mockResolvedValue({});

      await controller.openSession({ userId: USER_ID, tenantId: TENANT_ID, openingBalance: 5000 }, {});

      expect(mockPosSessionService.openSession).toHaveBeenCalledWith({
        userId: USER_ID,
        tenantId: TENANT_ID,
        openingBalance: 5000,
      });
    });
  });

  // ── POST /retail/sessions/close/:id ──────────────────────────────────────

  describe('closeSession (POST /retail/sessions/close/:id)', () => {
    it('delegates to closeSession with varianceExplanation (AC3)', async () => {
      const closed = { id: SESSION_ID, status: 'CLOSED' };
      mockPosSessionService.closeSession.mockResolvedValue(closed);

      const result = await controller.closeSession(SESSION_ID, {
        closingBalance: 64500,
        varianceExplanation: 'Short change error',
      });

      expect(mockPosSessionService.closeSession).toHaveBeenCalledWith(
        SESSION_ID,
        64500,
        'Short change error',
      );
      expect(result.status).toBe('CLOSED');
    });

    it('delegates without varianceExplanation when not provided (AC3)', async () => {
      mockPosSessionService.closeSession.mockResolvedValue({});

      await controller.closeSession(SESSION_ID, { closingBalance: 65000 });

      expect(mockPosSessionService.closeSession).toHaveBeenCalledWith(SESSION_ID, 65000, undefined);
    });
  });

  // ── GET /retail/sessions/summary/:id ─────────────────────────────────────

  describe('getSessionSummary (GET /retail/sessions/summary/:id)', () => {
    it('delegates to getSessionSummary (AC4)', async () => {
      const summary = { session: { id: SESSION_ID }, totalSales: 60000 };
      mockPosSessionService.getSessionSummary.mockResolvedValue(summary);

      const result = await controller.getSessionSummary(SESSION_ID);

      expect(mockPosSessionService.getSessionSummary).toHaveBeenCalledWith(SESSION_ID);
      expect(result).toEqual(summary);
    });
  });

  // ── GET /retail/sessions/reports ─────────────────────────────────────────

  describe('getSessionReports (GET /retail/sessions/reports)', () => {
    it('delegates to getSessionReports with tenantId (AC5)', async () => {
      const reports = [{ id: SESSION_ID, status: 'CLOSED' }];
      mockPosSessionService.getSessionReports.mockResolvedValue(reports);

      const result = await controller.getSessionReports(TENANT_ID);

      expect(mockPosSessionService.getSessionReports).toHaveBeenCalledWith(TENANT_ID);
      expect(result).toEqual(reports);
    });
  });
});
