import { SetMetadata } from '@nestjs/common';

/**
 * `@Roles(...roles)` — STORY-015 Layer 2 RBAC.
 *
 * Each string passed must either be a SYSTEM_ROLE (e.g. `SUPER_ADMIN`) or a
 * business role known to a tenant template (validated by the CI lint script
 * `tools/check-roles-decorator.ts` — see DoD). The decorator itself does NOT
 * validate the value — it only attaches metadata; the RbacGuard enforces it.
 */
export const ROLES_KEY = 'roles';

export const Roles = (...roles: string[]): MethodDecorator & ClassDecorator =>
  SetMetadata(ROLES_KEY, roles);
