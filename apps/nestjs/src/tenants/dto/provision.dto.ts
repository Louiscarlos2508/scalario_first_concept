import { z } from 'zod';

export const ProvisionTenantSchema = z.object({
  name: z.string().min(2).max(120),
  slug: z.string().regex(/^[a-z0-9-]{3,63}$/, 'slug must be lowercase alphanumeric with dashes'),
  owner_email: z
    .string()
    .email()
    .transform((v) => v.toLowerCase()),
  owner_password: z
    .string()
    .min(8)
    .regex(/[A-Z]/, 'password must contain an uppercase letter')
    .regex(/[0-9]/, 'password must contain a digit'),
});

export type ProvisionTenantDto = z.infer<typeof ProvisionTenantSchema>;
