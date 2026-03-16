import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { ExpenseService } from './expense.service';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

const TENANT_ID = 'tenant-uuid-001';
const USER_ID = 'user-uuid-001';

const mockPrisma = {
  expense: {
    create: jest.fn(),
    findMany: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
  },
};

describe('ExpenseService', () => {
  let service: ExpenseService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ExpenseService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<ExpenseService>(ExpenseService);
  });

  // ── createExpense ──────────────────────────────────────────────────────────

  describe('createExpense', () => {
    it('creates expense and returns it (AC2 — POST /retail/expenses)', async () => {
      const created = {
        id: 'expense-uuid-001',
        tenantId: TENANT_ID,
        userId: USER_ID,
        label: 'Loyer mars',
        amount: new Prisma.Decimal(150000),
        category: 'LOYER',
        date: new Date('2026-03-01'),
        notes: null,
        isDeleted: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      mockPrisma.expense.create.mockResolvedValue(created);

      const result = await service.createExpense({
        tenantId: TENANT_ID,
        userId: USER_ID,
        label: 'Loyer mars',
        amount: 150000,
        category: 'LOYER',
        date: '2026-03-01',
      });

      expect(mockPrisma.expense.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          tenantId: TENANT_ID,
          userId: USER_ID,
          label: 'Loyer mars',
          category: 'LOYER',
        }),
      });
      expect(result).toEqual(created);
    });

    it('stores notes when provided', async () => {
      mockPrisma.expense.create.mockResolvedValue({});

      await service.createExpense({
        tenantId: TENANT_ID,
        userId: USER_ID,
        label: 'Électricité',
        amount: 25000,
        category: 'ELECTRICITE',
        date: '2026-03-15',
        notes: 'Facture CIE',
      });

      expect(mockPrisma.expense.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ notes: 'Facture CIE' }),
      });
    });
  });

  // ── getExpenses ────────────────────────────────────────────────────────────

  describe('getExpenses', () => {
    it('returns only non-deleted expenses for tenant (AC3 — GET /retail/expenses)', async () => {
      const expenses = [
        { id: 'e1', label: 'Loyer', amount: new Prisma.Decimal(150000), isDeleted: false },
      ];
      mockPrisma.expense.findMany.mockResolvedValue(expenses);

      const result = await service.getExpenses({ tenantId: TENANT_ID });

      expect(mockPrisma.expense.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ tenantId: TENANT_ID, isDeleted: false }),
        }),
      );
      expect(result).toEqual(expenses);
    });

    it('applies date range filter when from/to provided (AC3)', async () => {
      mockPrisma.expense.findMany.mockResolvedValue([]);

      await service.getExpenses({
        tenantId: TENANT_ID,
        from: '2026-03-01',
        to: '2026-03-15',
      });

      expect(mockPrisma.expense.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            tenantId: TENANT_ID,
            isDeleted: false,
            date: expect.objectContaining({ gte: new Date('2026-03-01') }),
          }),
        }),
      );
    });

    it('returns all non-deleted expenses when no date filter provided', async () => {
      mockPrisma.expense.findMany.mockResolvedValue([]);

      await service.getExpenses({ tenantId: TENANT_ID });

      const call = mockPrisma.expense.findMany.mock.calls[0][0];
      expect(call.where.date).toBeUndefined();
    });
  });

  // ── deleteExpense ──────────────────────────────────────────────────────────

  describe('deleteExpense', () => {
    it('soft-deletes expense by setting isDeleted=true (AC4 — DELETE /retail/expenses/:id)', async () => {
      const existing = { id: 'e1', tenantId: TENANT_ID, isDeleted: false };
      mockPrisma.expense.findFirst.mockResolvedValue(existing);
      mockPrisma.expense.update.mockResolvedValue({ ...existing, isDeleted: true });

      const result = await service.deleteExpense('e1', TENANT_ID);

      expect(mockPrisma.expense.update).toHaveBeenCalledWith({
        where: { id: 'e1' },
        data: { isDeleted: true },
      });
      expect(result.isDeleted).toBe(true);
    });

    it('throws NotFoundException when expense not found or wrong tenant (AC4)', async () => {
      mockPrisma.expense.findFirst.mockResolvedValue(null);

      await expect(service.deleteExpense('nonexistent', TENANT_ID)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ── getTotalExpenses ───────────────────────────────────────────────────────

  describe('getTotalExpenses', () => {
    it('sums all expense amounts for the period', async () => {
      mockPrisma.expense.findMany.mockResolvedValue([
        { amount: new Prisma.Decimal(150000) },
        { amount: new Prisma.Decimal(25000) },
        { amount: new Prisma.Decimal(50000) },
      ]);

      const result = await service.getTotalExpenses({ tenantId: TENANT_ID });

      expect(result).toBe(225000);
    });

    it('returns 0 when no expenses', async () => {
      mockPrisma.expense.findMany.mockResolvedValue([]);

      const result = await service.getTotalExpenses({ tenantId: TENANT_ID });

      expect(result).toBe(0);
    });
  });
});
