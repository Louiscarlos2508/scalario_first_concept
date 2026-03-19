import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  Query,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ExpenseService } from './expense.service';
import { RequiresModule } from '../kernel/modules/module.decorator';
import { Roles } from '../kernel/rbac/roles.decorator';

@Controller('retail/expenses')
@RequiresModule('expenses')
export class RetailExpenseController {
  constructor(private readonly expenseService: ExpenseService) {}

  // POST /retail/expenses
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @Roles('owner', 'manager')
  async createExpense(
    @Body()
    body: {
      tenantId: string;
      label: string;
      amount: number;
      category: string;
      date: string;
      notes?: string;
    },
    @Req() req: any,
  ) {
    const userId = req.user?.sub ?? req.user?.id ?? 'system';
    return this.expenseService.createExpense({ ...body, userId });
  }

  // GET /retail/expenses?tenantId=&from=&to=
  @Get()
  @Roles('owner', 'manager')
  async getExpenses(
    @Query('tenantId') tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.expenseService.getExpenses({ tenantId, from, to });
  }

  // DELETE /retail/expenses/:id
  @Delete(':id')
  @Roles('owner', 'manager')
  async deleteExpense(
    @Param('id') id: string,
    @Query('tenantId') tenantId: string,
  ) {
    return this.expenseService.deleteExpense(id, tenantId);
  }
}
