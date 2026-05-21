import { z } from 'zod';

export const TransitionWorkflowActionSchema = z.object({
  action_type: z.literal('transition_workflow'),
  run_id: z.string().uuid(),
  event: z.string().min(1),
  params: z.record(z.unknown()).optional().default({}),
  client_mutation_id: z.string().uuid(),
});

export type TransitionWorkflowAction = z.infer<typeof TransitionWorkflowActionSchema>;
