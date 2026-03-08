import { Injectable, OnModuleInit } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
  private supabase: SupabaseClient;

  onModuleInit() {
    this.supabase = createClient(
      process.env.SUPABASE_URL || 'https://xyzcompany.supabase.co',
      process.env.SUPABASE_KEY || 'public-anon-key',
    );
  }

  getClient(): SupabaseClient {
    return this.supabase;
  }
}
