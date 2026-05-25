import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenant } from '../core/auth/entities/tenant.entity';

/**
 * TenantsService — caches `is_active` (TTL 5 min) for the hot path used by
 * TenantMiddleware. STORY-018 will move this to Redis with cross-node
 * invalidation; the API is intentionally Redis-shaped.
 */
@Injectable()
export class TenantsService {
  private readonly logger = new Logger(TenantsService.name);
  private readonly cache = new Map<string, { is_active: boolean; expires_at: number }>();
  private readonly TTL_MS = 5 * 60 * 1000;

  constructor(@InjectRepository(Tenant) private readonly tenantRepo: Repository<Tenant>) {}

  /**
   * Returns the tenant_id if the tenant exists and is active. Returns null
   * otherwise. Caller (middleware) maps null → 403.
   */
  async getActive(tenant_id: string): Promise<string | null> {
    const cached = this.cache.get(tenant_id);
    if (cached && cached.expires_at > Date.now()) {
      return cached.is_active ? tenant_id : null;
    }

    const tenant = await this.tenantRepo.findOne({
      where: { id: tenant_id },
      select: ['id', 'is_active'],
    });
    const is_active = tenant?.is_active === true;
    this.cache.set(tenant_id, { is_active, expires_at: Date.now() + this.TTL_MS });
    return is_active ? tenant_id : null;
  }

  invalidate(tenant_id: string): void {
    this.cache.delete(tenant_id);
    this.logger.debug(`tenant-active cache invalidated tenant_id=${tenant_id}`);
  }

  clear(): void {
    this.cache.clear();
  }
}
