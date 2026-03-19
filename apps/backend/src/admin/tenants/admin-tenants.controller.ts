import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { SuperAdminGuard } from '../guards/super-admin.guard';
import { AdminTenantsService, CreateTenantDto, UpdateTenantDto } from './admin-tenants.service';

@Controller('admin/tenants')
@UseGuards(SuperAdminGuard)
export class AdminTenantsController {
  constructor(private readonly adminTenantsService: AdminTenantsService) {}

  @Post()
  async createTenant(@Body() body: CreateTenantDto) {
    return this.adminTenantsService.createTenant(body);
  }

  @Get()
  async listTenants() {
    return this.adminTenantsService.listTenants();
  }

  @Patch(':id')
  async updateTenant(@Param('id') id: string, @Body() body: UpdateTenantDto) {
    return this.adminTenantsService.updateTenant(id, body);
  }
}
