import { z } from 'zod';
import { ROLE_NAME_REGEX, isSystemRole } from '../../security/constants';

const RoleName = z
  .string()
  .min(1)
  .max(32)
  .regex(ROLE_NAME_REGEX, 'role must match ^[A-Z][A-Z0-9_]{0,31}$')
  .refine((r) => !isSystemRole(r), {
    message: 'system roles cannot be assigned via PATCH (e.g. SUPER_ADMIN)',
  });

export const UpdateRolesSchema = z
  .object({
    add: z.array(RoleName).max(64).optional(),
    remove: z.array(RoleName).max(64).optional(),
  })
  .refine((v) => (v.add?.length ?? 0) + (v.remove?.length ?? 0) > 0, {
    message: 'add or remove must contain at least one role',
  });

export type UpdateRolesDto = z.infer<typeof UpdateRolesSchema>;

/**
 * Used at boot/provision time to validate a tenant's full role list (from
 * a template or the existing DB row). The same regex/format applies.
 */
export const RolesListSchema = z
  .array(RoleName)
  .min(1)
  .max(64)
  .refine((arr) => new Set(arr).size === arr.length, { message: 'roles must be unique' });
