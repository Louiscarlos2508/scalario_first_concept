import { permittedFieldsOf } from '@casl/ability/extra';
import type { AbacAbility } from '../types';

/**
 * STORY-019 — AC-11 field-level filtering.
 *
 * Returns a shallow copy of `resource` keeping only fields permitted by
 * the ability's `fields[]` whitelist for `(action, subject)`. If no rule
 * restricts fields, the resource is returned untouched.
 *
 * Callers : services that hand a tenant resource to the response. The
 * decorated request has already passed `AbacGuard`, so the absence of
 * field filtering is the remaining leak path — see story threat model
 * scenario #2 (bug serializer).
 */
export function filterFieldsByAbility<T extends Record<string, unknown>>(
  resource: T,
  ability: AbacAbility,
  action: string,
  subject: string,
): Partial<T> {
  const permitted = permittedFieldsOf(ability, action, subject, {
    fieldsFrom: (rule) => rule.fields ?? [],
  });
  if (permitted.length === 0) return { ...resource };
  const out: Partial<T> = {};
  for (const key of permitted) {
    if (Object.prototype.hasOwnProperty.call(resource, key)) {
      out[key as keyof T] = resource[key] as T[keyof T];
    }
  }
  return out;
}
