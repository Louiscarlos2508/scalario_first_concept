import { z } from 'zod';

export const ExecuteActionBodySchema = z
  .object({
    action: z.string().optional(),
    payload: z.record(z.unknown()).optional(),
  })
  .passthrough()
  .refine(
    (data) =>
      (data as Record<string, unknown>).action_type === 'start_workflow' ||
      (data as Record<string, unknown>).action_type === 'transition_workflow' ||
      typeof data.action === 'string',
    { message: 'Either action or action_type is required in the body', path: ['body'] },
  );

export type ExecuteActionBody = z.infer<typeof ExecuteActionBodySchema>;
