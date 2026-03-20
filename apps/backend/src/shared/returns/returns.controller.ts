import { Controller, Post, Get, Body, Query } from '@nestjs/common';
import { ReturnsService } from './returns.service';
import { CreateReturnDto } from './dto/create-return.dto';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('returns')
export class ReturnsController {
  constructor(private readonly returnsService: ReturnsService) {}

  @Post()
  async createReturn(
    @Query('tenantId') tenantId: string,
    @Query('userId') userId: string,
    @Body() dto: CreateReturnDto,
  ) {
    return this.returnsService.createReturn(tenantId, userId, dto);
  }

  @Get()
  @Roles('owner', 'manager')
  async listReturns(
    @Query('tenantId') tenantId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('originalTxId') originalTxId?: string,
  ) {
    return this.returnsService.listReturns(tenantId, {
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 20,
      originalTxId,
    });
  }
}
