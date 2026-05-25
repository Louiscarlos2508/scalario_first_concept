import { z } from 'zod';
import { ComponentConfigZod } from './component-config.zod';

export const ScreenConfigZod = z
  .object({
    screen: z.string().min(1),
    schema_version: z.literal('1.0.0'),
    layout: z.enum(['dashboard', 'list', 'form', 'detail']),
    title: z.string().optional(),
    i18n_key: z.string().optional(),
    zones: z
      .object({
        kpis: z.array(ComponentConfigZod).optional(),
        main: z.array(ComponentConfigZod).optional(),
        aside: z.array(ComponentConfigZod).optional(),
        actions: z.array(ComponentConfigZod).optional(),
      })
      .strict(),
  })
  .strict();

export type ScreenConfig = z.infer<typeof ScreenConfigZod>;
