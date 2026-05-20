import { z } from 'zod';

export const GetLayoutParamsSchema = z.object({
  tenant: z.string().min(1),
  screenId: z.string().min(1),
});

export type GetLayoutParams = z.infer<typeof GetLayoutParamsSchema>;
