import { z } from 'zod';

const HANDLE_REGEX = /^[a-z0-9-]{3,32}$/;

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
  template: z
    .string()
    .regex(/^[a-z][a-z0-9_]*$/, 'template id must match ^[a-z][a-z0-9_]*$')
    .max(64)
    .optional(),
  /** STORY-V14-013 — optional @handle-style identifier for Phase 4 network. */
  handle: z
    .string()
    .regex(HANDLE_REGEX, 'handle must match ^[a-z0-9-]{3,32}$')
    .max(32)
    .optional(),
});

export type ProvisionTenantDto = z.infer<typeof ProvisionTenantSchema>;
