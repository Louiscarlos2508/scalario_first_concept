import { Injectable, Logger, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenant } from '../../auth/entities/tenant.entity';
import { CHANNEL, KEY_PREFIX, TTL_SECONDS } from '../../cache/constants';
import { RedisService } from '../../cache/services/redis.service';

/**
 * RolesService — STORY-015 + STORY-018.
 *
 * Two-tier cache for per-tenant role lists:
 * - L1: in-process `Map` for sub-ms hits (TTL 60s mirrors BDUI cache).
 * - L2: Redis `roles:<tenant_id>` with TTL 5 min — shared across nodes.
 *
 * Cross-node invalidation goes through the `roles:invalidate` pub/sub
 * channel. STORY-015 AC-14 (PATCH config → immediate invalidation)
 * now works cluster-wide: when one node mutates config, every node
 * drops its L1 + L2 entry.
 *
 * Redis-down → fail-open: lookups bypass cache and hit the DB
 * directly. Outage degrades latency, not availability.
 */
@Injectable()
export class RolesService implements OnModuleInit {
  private readonly logger = new Logger(RolesService.name);
  private readonly local = new Map<string, { roles: string[]; expires_at: number }>();
  private readonly L1_TTL_MS = 60 * 1000;

  constructor(
    @InjectRepository(Tenant) private readonly tenantRepo: Repository<Tenant>,
    private readonly redis: RedisService,
  ) {}

  async onModuleInit(): Promise<void> {
    if (!this.redis.isAvailable()) return;
    try {
      const sub = this.redis.getSubscriber();
      await sub.subscribe(CHANNEL.ROLES_INVALIDATE);
      sub.on('message', (channel, message) => {
        if (channel !== CHANNEL.ROLES_INVALIDATE) return;
        try {
          const { tenant_id } = JSON.parse(message) as { tenant_id: string };
          this.local.delete(tenant_id);
        } catch (err) {
          this.logger.warn(`roles:invalidate malformed: ${(err as Error).message}`);
        }
      });
    } catch (err) {
      this.logger.error(`roles pub/sub subscribe failed: ${(err as Error).message}`);
    }
  }

  async getRolesForTenant(tenant_id: string): Promise<string[]> {
    const l1 = this.local.get(tenant_id);
    if (l1 && l1.expires_at > Date.now()) return l1.roles;

    if (this.redis.isAvailable()) {
      try {
        const raw = await this.redis.getClient().get(`${KEY_PREFIX.ROLES}${tenant_id}`);
        if (raw) {
          const roles = JSON.parse(raw) as string[];
          this.local.set(tenant_id, { roles, expires_at: Date.now() + this.L1_TTL_MS });
          return roles;
        }
      } catch (err) {
        this.logger.warn(`roles L2 get failed (fail-open): ${(err as Error).message}`);
      }
    }

    const tenant = await this.tenantRepo.findOne({ where: { id: tenant_id } });
    if (!tenant) throw new NotFoundException(`Tenant ${tenant_id} not found`);
    const roles = Array.isArray(tenant.config?.roles) ? tenant.config.roles : [];

    this.local.set(tenant_id, { roles, expires_at: Date.now() + this.L1_TTL_MS });
    if (this.redis.isAvailable()) {
      try {
        await this.redis
          .getClient()
          .set(`${KEY_PREFIX.ROLES}${tenant_id}`, JSON.stringify(roles), 'EX', TTL_SECONDS.ROLES);
      } catch (err) {
        this.logger.warn(`roles L2 set failed: ${(err as Error).message}`);
      }
    }
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
    await this.invalidateCache(tenant_id);
    return roles;
  }

  async invalidateCache(tenant_id: string): Promise<void> {
    this.local.delete(tenant_id);
    if (!this.redis.isAvailable()) return;
    try {
      const client = this.redis.getClient();
      await client.del(`${KEY_PREFIX.ROLES}${tenant_id}`);
      await client.publish(CHANNEL.ROLES_INVALIDATE, JSON.stringify({ tenant_id }));
    } catch (err) {
      this.logger.warn(`roles invalidate failed: ${(err as Error).message}`);
    }
    this.logger.debug(`role-cache invalidated tenant_id=${tenant_id}`);
  }

  /**
   * Test-only / boot-only — wipes the entire L1 cache. Used by E2E fixtures
   * that mutate tenant config directly via the DB.
   */
  clear(): void {
    this.local.clear();
  }
}
