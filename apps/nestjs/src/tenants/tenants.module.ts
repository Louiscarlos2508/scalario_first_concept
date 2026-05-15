import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { Tenant } from '../auth/entities/tenant.entity';
import { User } from '../auth/entities/user.entity';
import { TenantsProvisionController } from './tenants-provision.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Tenant, User]), AuthModule],
  controllers: [TenantsProvisionController],
})
export class TenantsModule {}
