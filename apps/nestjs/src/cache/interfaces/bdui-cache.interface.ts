export interface IBdUiCache {
  get<T>(tenant_id: string, screen_id: string, role: string): Promise<T | null>;
  set<T>(tenant_id: string, screen_id: string, role: string, value: T): Promise<void>;
  /** Invalidates locally + remotely (pub/sub broadcast to all nodes). */
  invalidate(tenant_id: string, screen_id?: string): Promise<void>;
}
