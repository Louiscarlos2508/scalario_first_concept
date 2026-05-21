import { z } from 'zod';

export const StartWorkflowActionSchema = z.object({
  action_type: z.literal('start_workflow'),
  workflow_id: z.string().min(1),
  entity_id: z.string().uuid().optional(),
  initial_context: z.record(z.unknown()).optional().default({}),
  client_mutation_id: z.string().uuid(),
});

export type StartWorkflowAction = z.infer<typeof StartWorkflowActionSchema>;
