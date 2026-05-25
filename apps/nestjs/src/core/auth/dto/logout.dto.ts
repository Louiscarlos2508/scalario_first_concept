import { z } from 'zod';

export const LogoutSchema = z.object({
  refresh_token: z.string().min(32),
});

export type LogoutDto = z.infer<typeof LogoutSchema>;
