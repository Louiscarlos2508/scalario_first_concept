import { Module, Global } from '@nestjs/common';
import { SupabaseService } from './services/supabase/supabase.service';
import { AuthGuard } from './guards/auth/auth.guard';
import { TenantGuard } from './guards/tenant/tenant.guard';

@Global()
@Module({
  providers: [SupabaseService, AuthGuard, TenantGuard],
  exports: [SupabaseService, AuthGuard, TenantGuard],
})
export class CoreModule { }
