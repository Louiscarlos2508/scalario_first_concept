import { Controller, Get, Query } from '@nestjs/common';
import { StockAlertsService } from './stock-alerts.service';
import { Roles } from '../../kernel/rbac/roles.decorator';

@Controller('stock-alerts')
export class StockAlertsController {
  constructor(private readonly service: StockAlertsService) {}

  // GET /stock-alerts/count?tenantId=
  @Get('count')
  @Roles('owner', 'manager')
  async getCount(@Query('tenantId') tenantId: string) {
    const criticalCount = await this.service.getAlertsCount(tenantId);
    return { criticalCount };
  }

  // GET /stock-alerts?tenantId=&limit=&offset=
  @Get()
  @Roles('owner', 'manager')
  async getAlerts(
    @Query('tenantId') tenantId: string,
    @Query('limit') limit: string = '50',
    @Query('offset') offset: string = '0',
  ) {
    return this.service.getAlerts(tenantId, {
      limit: parseInt(limit),
      offset: parseInt(offset),
    });
  }
}
