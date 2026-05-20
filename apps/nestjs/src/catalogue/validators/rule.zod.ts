import { z } from 'zod';

export const RuleZod: z.ZodTypeAny = z.lazy(() =>
  z.union([
    z.object({
      operator: z.enum(['AND', 'OR']),
      children: z.array(RuleZod).min(1, 'children doit contenir au moins 1 règle'),
    }),
    z.object({
      operator: z.literal('role'),
      value: z
        .union([z.string(), z.array(z.string())])
        .transform((v) => (Array.isArray(v) ? v : [v]))
        .pipe(z.array(z.string()).min(1, 'value doit contenir au moins un rôle')),
    }),
    z.object({
      operator: z.enum(['>', '<', '==', '!=', '>=', '<=', 'in', 'not_in']),
      field: z.string().min(1, 'field est requis pour les opérateurs de comparaison'),
      value: z.unknown(),
      negate: z.boolean().optional().default(false),
    }),
  ]),
);

export type Rule = z.infer<typeof RuleZod>;
