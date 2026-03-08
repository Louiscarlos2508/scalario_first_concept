import { Module } from '@nestjs/common';
import { AuthGuard } from './auth.guard';
import { SupabaseService } from './supabase.service';

@Module({
  providers: [SupabaseService, AuthGuard],
  exports: [SupabaseService, AuthGuard],
})
export class AuthModule {}
