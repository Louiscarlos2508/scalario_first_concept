import { Body, Controller, Param, Patch, UseGuards } from '@nestjs/common';
import { SuperAdminGuard } from '../guards/super-admin.guard';
import { TenantPlanService } from './tenant-plan.service';
import { AssignPlanDto } from './dto/assign-plan.dto';

@Controller('admin/tenants')
@UseGuards(SuperAdminGuard)
export class TenantPlanController {
  constructor(private readonly tenantPlanService: TenantPlanService) {}

  @Patch(':id/plan')
  assignPlan(@Param('id') id: string, @Body() dto: AssignPlanDto) {
    return this.tenantPlanService.assignPlan(id, dto);
  }
}
