import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { RetailExpenseController } from './retail-expense.controller';
import { ExpenseService } from './expense.service';

const TENANT_ID = 'tenant-uuid-001';

const mockExpenseService = {
  createExpense: jest.fn(),
  getExpenses: jest.fn(),
  deleteExpense: jest.fn(),
};

const mockReq = { user: { sub: 'user-uuid-001' } };

describe('RetailExpenseController', () => {
  let controller: RetailExpenseController;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [RetailExpenseController],
      providers: [{ provide: ExpenseService, useValue: mockExpenseService }],
    }).compile();

    controller = module.get<RetailExpenseController>(RetailExpenseController);
  });

  // ── POST /retail/expenses ─────────────────────────────────────────────────

  describe('createExpense (POST /retail/expenses)', () => {
    it('delegates to expenseService.createExpense with userId from JWT (AC2)', async () => {
      const expense = { id: 'e1', label: 'Loyer', amount: 150000 };
      mockExpenseService.createExpense.mockResolvedValue(expense);

      const body = {
        tenantId: TENANT_ID,
        label: 'Loyer',
        amount: 150000,
        category: 'LOYER',
        date: '2026-03-01',
      };
      const result = await controller.createExpense(body, mockReq);

      expect(mockExpenseService.createExpense).toHaveBeenCalledWith({
        ...body,
        userId: 'user-uuid-001',
      });
      expect(result).toEqual(expense);
    });
  });

  // ── GET /retail/expenses ──────────────────────────────────────────────────

  describe('getExpenses (GET /retail/expenses)', () => {
    it('delegates to expenseService.getExpenses with query params (AC3)', async () => {
      const expenses = [{ id: 'e1' }];
      mockExpenseService.getExpenses.mockResolvedValue(expenses);

      const result = await controller.getExpenses(TENANT_ID, '2026-03-01', '2026-03-15');

      expect(mockExpenseService.getExpenses).toHaveBeenCalledWith({
        tenantId: TENANT_ID,
        from: '2026-03-01',
        to: '2026-03-15',
      });
      expect(result).toEqual(expenses);
    });
  });

  // ── DELETE /retail/expenses/:id ───────────────────────────────────────────

  describe('deleteExpense (DELETE /retail/expenses/:id)', () => {
    it('delegates to expenseService.deleteExpense (AC4)', async () => {
      const deleted = { id: 'e1', isDeleted: true };
      mockExpenseService.deleteExpense.mockResolvedValue(deleted);

      const result = await controller.deleteExpense('e1', TENANT_ID);

      expect(mockExpenseService.deleteExpense).toHaveBeenCalledWith('e1', TENANT_ID);
      expect(result).toEqual(deleted);
    });

    it('propagates NotFoundException when expense not found (AC4)', async () => {
      mockExpenseService.deleteExpense.mockRejectedValue(new NotFoundException());

      await expect(controller.deleteExpense('nonexistent', TENANT_ID)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
