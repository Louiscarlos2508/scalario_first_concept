import { z } from 'zod';

export const GetDataQuerySchema = z.object({
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(200).optional().default(50),
  filters: z.string().optional(),
  sort: z.string().optional(),
});

export type GetDataQuery = z.infer<typeof GetDataQuerySchema>;
