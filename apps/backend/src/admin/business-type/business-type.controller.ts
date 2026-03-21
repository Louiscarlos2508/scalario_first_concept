import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { SuperAdminGuard } from '../guards/super-admin.guard';
import { CurrentTenant } from '../../kernel/tenancy/tenant.decorator';
import { Roles } from '../../kernel/rbac/roles.decorator';
import { BusinessTypeService } from './business-type.service';
import { AssignBusinessTypeDto } from './dto/assign-business-type.dto';

@Controller()
export class BusinessTypeController {
  constructor(private readonly businessTypeService: BusinessTypeService) {}

  @Get('business-type/config')
  @Roles('owner', 'manager', 'cashier')
  async getMyConfig(@CurrentTenant() tenantId: string) {
    return this.businessTypeService.getMyConfig(tenantId);
  }

  @Get('admin/business-types')
  @UseGuards(SuperAdminGuard)
  async listBusinessTypes() {
    return this.businessTypeService.listActive();
  }

  @Get('admin/business-types/:code')
  @UseGuards(SuperAdminGuard)
  async getBusinessType(@Param('code') code: string) {
    return this.businessTypeService.getDefinition(code);
  }

  @Patch('admin/tenants/:id/business-type')
  @UseGuards(SuperAdminGuard)
  async assignBusinessType(
    @Param('id') id: string,
    @Body() body: AssignBusinessTypeDto,
  ) {
    return this.businessTypeService.assignToTenant(id, body.businessType);
  }
}
