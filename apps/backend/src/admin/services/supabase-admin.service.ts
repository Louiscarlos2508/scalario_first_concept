import { Injectable, OnModuleInit } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseAdminService implements OnModuleInit {
  private client: SupabaseClient;

  onModuleInit() {
    this.client = createClient(
      process.env.SUPABASE_URL ?? 'http://127.0.0.1:54321',
      process.env.SUPABASE_KEY ?? '',
    );
  }

  /**
   * Creates a new user in Supabase Auth using admin API.
   * Returns the created user's id.
   * Throws if email is already taken or any other Supabase error.
   */
  async createUser(email: string, password: string, fullName?: string): Promise<string> {
    const { data, error } = await this.client.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: fullName ? { full_name: fullName } : undefined,
    });

    if (error || !data.user) {
      throw new Error(error?.message ?? 'Failed to create Supabase user');
    }

    return data.user.id;
  }

  /**
   * Deletes a user from Supabase Auth (used for rollback/compensation).
   */
  async deleteUser(userId: string): Promise<void> {
    await this.client.auth.admin.deleteUser(userId);
  }

  /**
   * Fetches a user from Supabase Auth by id.
   */
  async getUserById(userId: string): Promise<{ email: string; fullName: string | null; lastSignInAt: string | null } | null> {
    const { data, error } = await this.client.auth.admin.getUserById(userId);
    if (error || !data.user) return null;
    return {
      email: data.user.email ?? '',
      fullName: (data.user.user_metadata?.full_name as string | undefined) ?? null,
      lastSignInAt: data.user.last_sign_in_at ?? null,
    };
  }

  /**
   * Bans a user by setting banned_until to far future (soft-disable).
   */
  async banUser(userId: string): Promise<void> {
    await this.client.auth.admin.updateUserById(userId, {
      ban_duration: '876000h', // ~100 years
    });
  }
}
