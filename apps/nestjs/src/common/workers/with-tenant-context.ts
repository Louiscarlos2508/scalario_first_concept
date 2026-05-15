import { tenantContext, TenantStore } from '../context/tenant-context';

/**
 * Helper for async jobs / cron workers that don't run inside an HTTP
 * request. Wrap the job body so all downstream DB calls see the right
 * `tenant_id` via `tenantContext.get()`.
 *
 * @example
 *   await withTenantContext(tenant.id, () => statsService.computeDaily());
 */
export function withTenantContext<T>(
  tenant_id: string,
  fn: () => Promise<T>,
  extra: Omit<TenantStore, 'tenant_id'> = {},
): Promise<T> {
  return tenantContext.run({ tenant_id, ...extra }, fn);
}
