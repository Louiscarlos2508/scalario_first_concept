import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class ExpenseService {
  constructor(private readonly prisma: PrismaService) {}

  async createExpense(data: {
    tenantId: string;
    userId: string;
    label: string;
    amount: number;
    category: string;
    date: string; // ISO date string (YYYY-MM-DD)
    notes?: string;
  }) {
    return this.prisma.expense.create({
      data: {
        tenantId: data.tenantId,
        userId: data.userId,
        label: data.label,
        amount: new Prisma.Decimal(data.amount),
        category: data.category,
        date: new Date(data.date),
        notes: data.notes ?? null,
      },
    });
  }

  async getExpenses(params: {
    tenantId: string;
    from?: string;
    to?: string;
  }) {
    const { tenantId, from, to } = params;
    const dateFilter = this.buildDateFilter(from, to);

    return this.prisma.expense.findMany({
      where: {
        tenantId,
        isDeleted: false,
        ...(dateFilter ? { date: dateFilter } : {}),
      },
      orderBy: { date: 'desc' },
    });
  }

  async deleteExpense(id: string, tenantId: string) {
    const expense = await this.prisma.expense.findFirst({
      where: { id, tenantId, isDeleted: false },
    });

    if (!expense) {
      throw new NotFoundException(`Expense ${id} not found.`);
    }

    return this.prisma.expense.update({
      where: { id },
      data: { isDeleted: true },
    });
  }

  async getTotalExpenses(params: {
    tenantId: string;
    from?: string;
    to?: string;
  }): Promise<number> {
    const expenses = await this.getExpenses(params);
    return expenses.reduce((sum, e) => sum + Number(e.amount), 0);
  }

  private buildDateFilter(
    from?: string,
    to?: string,
  ): { gte?: Date; lte?: Date } | undefined {
    if (!from && !to) return undefined;
    const filter: { gte?: Date; lte?: Date } = {};
    if (from) filter.gte = new Date(from);
    if (to) {
      const toDate = new Date(to);
      toDate.setUTCHours(23, 59, 59, 999);
      filter.lte = toDate;
    }
    return filter;
  }
}
