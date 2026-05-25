import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../core/auth/auth.module';
import { Tenant } from '../core/auth/entities/tenant.entity';
import { User } from '../core/auth/entities/user.entity';
import { SecurityModule } from '../core/security/security.module';
import { TenantMiddleware } from '../core/security/middleware/tenant.middleware';
import { TenantsProvisionController } from './tenants-provision.controller';
import { TenantsRolesController } from './tenants-roles.controller';
import { TenantsService } from './tenants.service';

@Module({
  imports: [TypeOrmModule.forFeature([Tenant, User]), AuthModule, SecurityModule],
  controllers: [TenantsProvisionController, TenantsRolesController],
  providers: [TenantsService, TenantMiddleware],
  exports: [TenantsService, TenantMiddleware],
})
export class TenantsModule {}
