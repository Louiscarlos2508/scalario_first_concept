import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  Req,
} from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import { RequiresModule } from '../../kernel/modules/module.decorator';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('transactions')
@RequiresModule('transactions')
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Post()
  @Roles('owner', 'commercial')
  async createTransaction(@Body() body: any, @Req() req: any) {
    const userId = req.user?.sub ?? null;
    return this.transactionsService.createTransaction(body, userId);
  }

  @Get()
  async getTransactions(
    @Query('tenantId') tenantId?: string,
    @Query('since') since?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('userId') userId?: string,
    @Query('paymentMethod') paymentMethod?: string,
    @Query('search') search?: string,
    @Query('receiptNumber') receiptNumber?: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '50',
  ) {
    return this.transactionsService.getTransactions({
      tenantId,
      since,
      from,
      to,
      userId,
      paymentMethod,
      search: search ?? receiptNumber,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  }
}
