import { z } from 'zod';

const HANDLE_REGEX = /^[a-z0-9-]{3,32}$/;

export const UpdateTenantHandleSchema = z.object({
  handle: z.string().regex(HANDLE_REGEX, 'handle must match ^[a-z0-9-]{3,32}$').max(32),
});

export type UpdateTenantHandleDto = z.infer<typeof UpdateTenantHandleSchema>;
