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
  // Optional template id from `catalog/domains/*.json` — populates
  // `tenants.config.roles` at provision time (STORY-015 AC-20).
  template: z
    .string()
    .regex(/^[a-z][a-z0-9_]*$/, 'template id must match ^[a-z][a-z0-9_]*$')
    .max(64)
    .optional(),
});

export type ProvisionTenantDto = z.infer<typeof ProvisionTenantSchema>;
