import { z } from 'zod';

export const ExecuteActionBodySchema = z.object({
  action: z.string().min(1),
  payload: z.record(z.unknown()).default({}),
});

export type ExecuteActionBody = z.infer<typeof ExecuteActionBodySchema>;
