import { Controller, Get, Param, Patch, Query } from '@nestjs/common';
import { BatchesService } from './batches.service';
import { RequiresModule } from '../../kernel/modules/module.decorator';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('batches')
@RequiresModule('inventory')
@Roles('owner', 'manager')
export class BatchesController {
  constructor(private readonly batchesService: BatchesService) {}

  @Get('expiring')
  async getExpiring(
    @Query('tenantId') tenantId: string,
    @Query('days') days = '7',
  ) {
    return this.batchesService.getBatchesExpiring(tenantId, parseInt(days, 10));
  }

  @Get('expiring/count')
  async getExpiringCount(@Query('tenantId') tenantId: string) {
    return this.batchesService.getExpiringCount(tenantId);
  }

  @Patch(':id/deplete')
  async depleteBatch(
    @Param('id') batchId: string,
    @Query('tenantId') tenantId: string,
  ) {
    return this.batchesService.depleteBatch(batchId, tenantId);
  }
}
