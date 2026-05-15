import { z } from 'zod';

export const RefreshSchema = z.object({
  refresh_token: z.string().min(32),
});

export type RefreshDto = z.infer<typeof RefreshSchema>;
