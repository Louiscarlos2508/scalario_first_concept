import { z } from 'zod';

export const DataSourceZod = z
  .object({
    type: z.enum(['module_data', 'kpi', 'static', 'computed']),
    module_id: z.string().optional(),
    query: z.record(z.unknown()).optional(),
  })
  .strict();

export type DataSource = z.infer<typeof DataSourceZod>;
