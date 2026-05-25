import { z } from 'zod';
import { RuleZod } from './rule.zod';
import { DataSourceZod } from './data-source.zod';
import { ValidationRuleZod } from './validation-rule.zod';

export const ComponentConfigZod = z
  .object({
    schema_version: z.literal('1.0.0'),
    type: z.string().min(1),
    id: z.string().optional(),
    props: z.record(z.unknown()).default({}),
    visible_if: z.union([z.null(), RuleZod]).optional(),
    source: z.union([z.null(), DataSourceZod]).optional(),
    validation: z.array(ValidationRuleZod).default([]),
    i18n_key: z.string().optional(),
  })
  .strict();

export type ComponentConfig = z.infer<typeof ComponentConfigZod>;
