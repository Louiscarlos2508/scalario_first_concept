import { Controller, Get, UseGuards } from '@nestjs/common';
import { SuperAdminGuard } from '../guards/super-admin.guard';
import { AdminMonitoringService } from './admin-monitoring.service';

@Controller('admin/monitoring')
@UseGuards(SuperAdminGuard)
export class AdminMonitoringController {
  constructor(private readonly adminMonitoringService: AdminMonitoringService) {}

  @Get('health')
  async getHealth() {
    return this.adminMonitoringService.getHealth();
  }
}
