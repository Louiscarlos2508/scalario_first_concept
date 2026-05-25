import { z } from 'zod';
import { RuleZod } from './rule.zod';

export const StateDefinitionZod = z
  .object({
    transitions: z.record(z.string()).optional(),
    final: z.boolean().optional().default(false),
    on_enter: z.array(z.string()).optional(),
    on_exit: z.array(z.string()).optional(),
  })
  .strict();

export type StateDefinition = z.infer<typeof StateDefinitionZod>;

export const ConditionalNextZod = z
  .object({
    rules: z.array(
      z
        .object({
          condition: RuleZod,
          next: z.string(),
        })
        .strict(),
    ),
    default: z.string().optional(),
  })
  .strict();

export type ConditionalNext = z.infer<typeof ConditionalNextZod>;

export const WorkflowStepZod = z
  .object({
    id: z.string().min(1),
    type: z.enum(['action', 'condition', 'notification', 'approval']),
    dependsOn: z.array(z.string()).optional(),
    next: z.union([z.string(), ConditionalNextZod]).optional(),
    action: z.string().optional(),
    params: z.record(z.unknown()).optional(),
    visible_if: RuleZod.optional(),
  })
  .strict();

export type WorkflowStep = z.infer<typeof WorkflowStepZod>;

export const WorkflowDefinitionZod = z
  .object({
    id: z
      .string()
      .regex(
        /^wf_[a-z0-9_]+$/,
        "L'id du workflow doit commencer par 'wf_' et contenir uniquement des minuscules, chiffres et underscores",
      ),
    schema_version: z.literal('1.0.0'),
    initial_state: z.string().min(1),
    states: z.record(StateDefinitionZod).refine((obj) => Object.keys(obj).length >= 1, {
      message: 'Un workflow doit contenir au moins un état',
    }),
    steps: z.record(WorkflowStepZod).optional(),
  })
  .strict();

export type WorkflowDefinition = z.infer<typeof WorkflowDefinitionZod>;
