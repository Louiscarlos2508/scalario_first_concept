import { Column, Index } from 'typeorm';

/**
 * Convention base for any business entity that is scoped to a single tenant.
 * Every `@Entity()` that holds tenant-owned rows MUST extend this class so
 * the `tenant_id` column + composite index pattern is uniform across the
 * schema. Layer 4 RLS (STORY-017) consumes `tenant_id` via
 * `current_setting('app.current_tenant_id')`.
 *
 * Whitelist exceptions (entities with their own tenant_id column declared
 * directly): `Tenant`, `User`, `RefreshToken`, `AuditLog`.
 */
export abstract class TenantScopedEntity {
  @Column({ type: 'uuid' })
  @Index()
  tenant_id!: string;
}
