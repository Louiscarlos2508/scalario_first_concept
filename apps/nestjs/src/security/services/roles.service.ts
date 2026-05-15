import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenant } from '../../auth/entities/tenant.entity';

/**
 * RolesService — caches per-tenant role lists (TTL 5 min) and exposes
 * mutation helpers. STORY-018 will swap the in-memory Map for Redis with
 * cross-node invalidation; the public API (`getRolesForTenant`,
 * `invalidateCache`) is intentionally Redis-shaped.
 */
@Injectable()
export class RolesService {
  private readonly logger = new Logger(RolesService.name);
  private readonly cache = new Map<string, { roles: string[]; expires_at: number }>();
  private readonly TTL_MS = 5 * 60 * 1000;

  constructor(@InjectRepository(Tenant) private readonly tenantRepo: Repository<Tenant>) {}

  async getRolesForTenant(tenant_id: string): Promise<string[]> {
    const cached = this.cache.get(tenant_id);
    if (cached && cached.expires_at > Date.now()) return cached.roles;

    const tenant = await this.tenantRepo.findOne({ where: { id: tenant_id } });
    if (!tenant) throw new NotFoundException(`Tenant ${tenant_id} not found`);

    const roles = Array.isArray(tenant.config?.roles) ? tenant.config.roles : [];
    this.cache.set(tenant_id, { roles, expires_at: Date.now() + this.TTL_MS });
    return roles;
  }

  async getRolesForTenantSlug(slug: string): Promise<{ tenant: Tenant; roles: string[] }> {
    const tenant = await this.tenantRepo.findOne({ where: { slug } });
    if (!tenant) throw new NotFoundException(`Tenant ${slug} not found`);
    const roles = await this.getRolesForTenant(tenant.id);
    return { tenant, roles };
  }

  /**
   * Persists a new role list for the tenant and invalidates the cache. The
   * caller is responsible for Zod validation of `roles` (uniqueness, regex,
   * length). Returns the persisted list.
   */
  async setRolesForTenant(tenant_id: string, roles: string[]): Promise<string[]> {
    const tenant = await this.tenantRepo.findOne({ where: { id: tenant_id } });
    if (!tenant) throw new NotFoundException(`Tenant ${tenant_id} not found`);

    const config = { ...(tenant.config ?? {}), roles };
    await this.tenantRepo.update({ id: tenant_id }, { config });
    this.invalidateCache(tenant_id);
    return roles;
  }

  invalidateCache(tenant_id: string): void {
    this.cache.delete(tenant_id);
    // STORY-018 — publish invalidation event on Redis pub/sub channel here.
    this.logger.debug(`role-cache invalidated tenant_id=${tenant_id}`);
  }

  /**
   * Test-only / boot-only — wipes the entire cache. Used by E2E fixtures
   * that mutate tenant config directly via the DB.
   */
  clear(): void {
    this.cache.clear();
  }
}
