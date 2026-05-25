import { SetMetadata } from '@nestjs/common';

export const AUDITED_KEY = 'audit:audited';

export interface AuditedOptions {
  /** Action name persisted in `audit_logs.action` (e.g. `CREATE_INVOICE`). */
  action: string;
  /**
   * Path parameter (or response field) to capture into `entity_id`.
   * Default `'id'` — covers REST style `/:moduleId/:id` and POST returns.
   */
  entityIdParam?: string;
  /**
   * Path parameter to capture into `module_id`. Default `'moduleId'`.
   */
  moduleIdParam?: string;
}

/**
 * STORY-020 — `@Audited('ACTION_NAME')` opts a route into the
 * `AuditInterceptor`. Untagged routes pass through unchanged.
 */
export function Audited(action: string, options?: Omit<AuditedOptions, 'action'>): MethodDecorator {
  return SetMetadata(AUDITED_KEY, { action, ...options });
}
