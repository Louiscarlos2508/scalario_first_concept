import { z } from 'zod';
import { ScreenConfigZod } from './screen-config.zod';
import { WorkflowDefinitionZod } from './workflow.zod';
import { abacRuleSchema } from '../../core/security/abac/rule.schema';

export const ActionDefinitionZod = z
  .object({
    handler: z
      .string()
      .regex(
        /^[a-z]+\.[a-z_]+$/,
        "Le champ 'handler' doit suivre le pattern 'domaine.action' (ex: 'crud.create')",
      ),
    entity_type: z.string().optional(),
    label: z.string().optional(),
    i18n_key: z.string().optional(),
    merge: z.record(z.unknown()).optional(),
  })
  .passthrough();

export type ActionDefinition = z.infer<typeof ActionDefinitionZod>;

export const ModuleConfigZod = z
  .object({
    id: z
      .string()
      .regex(
        /^[a-z][a-z0-9_]*$/,
        "L'id doit être en snake_case, préfixe alphabétique (ex: 'retail_fresh_produce')",
      ),
    schema_version: z.literal('1.0.0'),
    name: z.string(),
    i18n_key: z.string().optional(),
    icon: z.string().optional(),
    entities: z.array(
      z
        .object({
          name: z
            .string()
            .regex(
              /^[A-Z][A-Za-z0-9]*$/,
              "Le nom d'entité doit être en PascalCase (ex: 'Product')",
            ),
          display_name: z.string().optional(),
          i18n_key: z.string().optional(),
          fields: z
            .array(
              z
                .object({
                  name: z.string(),
                  type: z.string(),
                  required: z.boolean().optional().default(false),
                  i18n_key: z.string().optional(),
                })
                .passthrough(),
            )
            .optional(),
        })
        .passthrough(),
    ),
    screens: z.array(ScreenConfigZod).optional(),
    actions: z.record(ActionDefinitionZod).optional(),
    workflows: z.record(WorkflowDefinitionZod).optional(),
    rbac_roles: z.array(z.string()).default([]),
    abac_rules: z.array(abacRuleSchema).default([]),
    conflict_strategy: z.enum(['server_wins', 'client_wins', 'manual']).default('server_wins'),
  })
  .strict();

export type ModuleConfig = z.infer<typeof ModuleConfigZod>;
