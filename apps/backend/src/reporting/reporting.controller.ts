import { Controller, Get, Query } from '@nestjs/common';
import { ReportingService } from './reporting.service';
import { Roles } from '../kernel/rbac/roles.decorator';
import { RequiresModule } from '../kernel/modules/module.decorator';

@Controller('reports')
@RequiresModule('reports')
@Roles('owner', 'manager')
export class ReportingController {
  constructor(private readonly reportingService: ReportingService) {}

  // AC1 (7.2) — GET /reports/sales/stats?tenantId=&from=&to=
  @Get('sales/stats')
  async getSalesStats(
    @Query('tenantId') tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.reportingService.getSalesStats({ tenantId, from, to });
  }

  // AC1 (7.1) — GET /reports/sales?tenantId=&from=&to=&groupBy=day
  @Get('sales')
  async getSalesReport(
    @Query('tenantId') tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('groupBy') groupBy?: string,
  ) {
    return this.reportingService.getSalesReport({ tenantId, from, to, groupBy });
  }

  // AC2 — GET /reports/sessions?tenantId=&from=&to=
  @Get('sessions')
  async getSessionReport(
    @Query('tenantId') tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.reportingService.getSessionReport({ tenantId, from, to });
  }

  // AC3 (7.1) / AC2 (7.2) — GET /reports/inventory?tenantId=&from=&to=
  // No date filter → critical stock (AC2 7.2); with dates → movement report (AC3 7.1)
  @Get('inventory')
  async getInventoryReport(
    @Query('tenantId') tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    if (!from && !to) {
      return this.reportingService.getCriticalStock(tenantId);
    }
    return this.reportingService.getInventoryReport({ tenantId, from, to });
  }
}
