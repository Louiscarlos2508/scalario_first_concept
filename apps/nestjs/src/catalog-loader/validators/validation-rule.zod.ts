import { z } from 'zod';

export const ValidationRuleZod = z
  .object({
    kind: z.enum(['required', 'min', 'max', 'pattern', 'min_length', 'max_length']),
    value: z.unknown().optional(),
    message_i18n_key: z.string().optional(),
  })
  .strict();

export type ValidationRule = z.infer<typeof ValidationRuleZod>;
