import { z } from 'zod';

export const ExecuteActionBodySchema = z
  .object({
    action: z.string().min(1).optional(),
    action_type: z.enum(['start_workflow', 'transition_workflow']).optional(),
    payload: z.record(z.unknown()).optional(),
  })
  .passthrough()
  .refine((data) => Boolean(data.action_type) !== Boolean(data.action), {
    message: 'Exactly one of `action` or `action_type` must be provided',
    path: ['body'],
  });

export type ExecuteActionBody = z.infer<typeof ExecuteActionBodySchema>;
