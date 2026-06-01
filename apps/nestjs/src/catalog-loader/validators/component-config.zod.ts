import { z } from 'zod';
import { RuleZod } from './rule.zod';
import { DataSourceZod } from './data-source.zod';
import { ValidationRuleZod } from './validation-rule.zod';

export const ActionStepZod = z.object({
  registry: z.enum(['canvas', 'form', 'calc', 'sense', 'vault', 'live']),
  fn: z.string().min(1),
  inputs: z.record(z.unknown()).optional(),
  output: z.string().optional(),
  on_error: z
    .object({
      network: z.enum(['skip', 'retry', 'notify', 'fail']).optional(),
      timeout: z.enum(['skip', 'retry', 'notify', 'fail']).optional(),
      validation: z.enum(['skip', 'retry', 'notify', 'fail']).optional(),
      permission: z.enum(['skip', 'retry', 'notify', 'fail']).optional(),
    })
    .optional(),
}).strict();

export type ActionStep = z.infer<typeof ActionStepZod>;

const MAX_CHILDREN_DEPTH = 5;

export const ComponentConfigZod: z.ZodType<any, z.ZodTypeDef, any> = z
  .object({
    schema_version: z.enum(['1.0.0', '1.1.0']).optional(),
    type: z.string().min(1),
    variant: z.string().min(1).default('default'),
    id: z.string().optional(),
    props: z.record(z.unknown()).default({}),
    visible_if: z.union([z.null(), RuleZod]).optional(),
    source: z.union([z.null(), DataSourceZod]).optional(),
    validation: z.array(ValidationRuleZod).default([]),
    actions: z.array(ActionStepZod).optional(),
    children: z.lazy(() => z.array(ComponentConfigZod)).optional(),
    i18n_key: z.string().optional(),
  })
  .strict()
  .superRefine((data, ctx) => {
    if (data.children) {
      checkChildrenDepth(data, 1, ctx);
    }
  });

function checkChildrenDepth(
  config: any,
  currentDepth: number,
  ctx: z.RefinementCtx,
): void {
  if (currentDepth > MAX_CHILDREN_DEPTH) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: `Children depth exceeds max ${MAX_CHILDREN_DEPTH}`,
      path: ['children'],
    });
    return;
  }
  if (Array.isArray(config.children)) {
    for (const child of config.children) {
      checkChildrenDepth(child, currentDepth + 1, ctx);
    }
  }
}

export type ComponentConfig = z.infer<typeof ComponentConfigZod>;
