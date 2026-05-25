import { SetMetadata } from '@nestjs/common';

/**
 * STORY-019 — `@AbacAction(action, subject)`.
 *
 * Reads as : "AbacGuard must check that the authenticated user's ability
 * permits this action on this subject before invoking the handler". Use
 * for any controller route that consumes a tenant-scoped resource type.
 *
 * Pair with `RbacGuard` (`@Roles`) : RBAC gates ROLES, ABAC gates
 * ATTRIBUTES. A route can carry both decorators.
 */
export const ABAC_ACTION_KEY = 'abac:action';

export interface AbacActionMetadata {
  action: string;
  subject: string;
}

export const AbacAction = (action: string, subject: string): MethodDecorator & ClassDecorator =>
  SetMetadata<string, AbacActionMetadata>(ABAC_ACTION_KEY, { action, subject });
