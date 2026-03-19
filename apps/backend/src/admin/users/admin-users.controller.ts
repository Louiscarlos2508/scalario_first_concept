import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { SuperAdminGuard } from '../guards/super-admin.guard';
import { AdminUsersService, CreateTenantUserDto, UpdateTenantUserRoleDto } from './admin-users.service';

@Controller('admin/tenants/:tenantId/users')
@UseGuards(SuperAdminGuard)
export class AdminUsersController {
  constructor(private readonly adminUsersService: AdminUsersService) {}

  @Post()
  @HttpCode(201)
  createUser(
    @Param('tenantId') tenantId: string,
    @Body() body: CreateTenantUserDto,
  ) {
    return this.adminUsersService.createUser(tenantId, body);
  }

  @Get()
  listUsers(@Param('tenantId') tenantId: string) {
    return this.adminUsersService.listUsers(tenantId);
  }

  @Patch(':userId')
  updateUserRole(
    @Param('tenantId') tenantId: string,
    @Param('userId') userId: string,
    @Body() body: UpdateTenantUserRoleDto,
  ) {
    return this.adminUsersService.updateUserRole(tenantId, userId, body.role);
  }

  @Delete(':userId')
  @HttpCode(204)
  removeUser(
    @Param('tenantId') tenantId: string,
    @Param('userId') userId: string,
  ) {
    return this.adminUsersService.removeUser(tenantId, userId);
  }
}
