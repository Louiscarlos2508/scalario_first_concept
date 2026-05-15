import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { Tenant } from '../auth/entities/tenant.entity';
import { User } from '../auth/entities/user.entity';
import { SecurityModule } from '../security/security.module';
import { TenantMiddleware } from '../security/middleware/tenant.middleware';
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
