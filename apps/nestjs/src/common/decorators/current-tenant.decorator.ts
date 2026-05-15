import { createParamDecorator } from '@nestjs/common';
import { tenantContext } from '../context/tenant-context';

/**
 * Injects the current tenant_id read from AsyncLocalStorage. Throws
 * `TenantContextMissingError` if called outside a tenant context (public
 * route, detached async task) — fail loud rather than silently leak.
 */
export const CurrentTenant = createParamDecorator((): string => {
  return tenantContext.getOrThrow().tenant_id;
});
