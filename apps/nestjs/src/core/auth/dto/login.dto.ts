import { z } from 'zod';

export const LoginSchema = z.object({
  email: z
    .string()
    .email()
    .transform((v) => v.toLowerCase()),
  password: z.string().min(1),
  tenant_slug: z
    .string()
    .regex(/^[a-z0-9-]{3,63}$/, 'tenant_slug must be lowercase alphanumeric with dashes'),
});

export type LoginDto = z.infer<typeof LoginSchema>;
