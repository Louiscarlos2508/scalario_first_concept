import { AsyncLocalStorage } from 'node:async_hooks';

export interface TenantStore {
  tenant_id: string;
  user_id?: string;
  roles?: string[];
}

const storage = new AsyncLocalStorage<TenantStore>();

export class TenantContextMissingError extends Error {
  constructor() {
    super('No tenant context set — this code path skipped TenantMiddleware.');
    this.name = 'TenantContextMissingError';
  }
}

export const tenantContext = {
  run<T>(value: TenantStore, fn: () => T): T {
    return storage.run(value, fn);
  },

  get(): TenantStore | undefined {
    return storage.getStore();
  },

  getOrThrow(): TenantStore {
    const store = storage.getStore();
    if (!store) throw new TenantContextMissingError();
    return store;
  },
};
