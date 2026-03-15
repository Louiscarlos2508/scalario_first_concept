import { Module } from '@nestjs/common';
import { PermissionService } from './permission.service';
import { RolesGuard } from './roles.guard';

@Module({
  providers: [PermissionService, RolesGuard],
  exports: [PermissionService, RolesGuard],
})
export class RbacModule {}
