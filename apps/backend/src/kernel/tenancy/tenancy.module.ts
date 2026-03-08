import { Module } from '@nestjs/common';
import { TenantGuard } from './tenant.guard';
import { TenancyService } from './tenancy.service';

@Module({
  providers: [TenancyService, TenantGuard],
  exports: [TenancyService, TenantGuard],
})
export class TenancyModule {}
