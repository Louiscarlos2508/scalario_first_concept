import { Inject, Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenant, type TenantConfig } from '../../auth/entities/tenant.entity';
import { RedisService } from '../../cache/services/redis.service';
import { CaslAbacEngine } from './engines/casl.engine';
import { ABAC_ENGINE, type ABACEngine } from './engines/abac-engine.interface';
import type { AbacAbility, AbacUser } from './types';

const KEY_PREFIX = 'ability:';
const TTL_SECONDS = 300;

/**
 * STORY-019 — Builds and caches per-user CASL abilities.
 *
 * Cache key : `ability:<tenant_id>:<user_id>:<config_version>`.
 * `tenants.config.version` is bumped by the PATCH config flow
 * (Sprint 3+) ; any change to `roles` or `abac_rules` invalidates
 * every active ability in O(1).
 *
 * Fail-open : if Redis is unavailable or its payload is corrupt, we
 * rebuild from the raw rules. Outage of Redis must not lock anyone out.
 */
@Injectable()
export class AbilityFactory {
  private readonly logger = new Logger(AbilityFactory.name);

  constructor(
    @Inject(ABAC_ENGINE) private readonly engine: ABACEngine,
    @InjectRepository(Tenant) private readonly tenantRepo: Repository<Tenant>,
    private readonly redis: RedisService,
  ) {}

  async createForUser(user: AbacUser, tenant: Tenant): Promise<AbacAbility> {
    const version = readConfigVersion(tenant.config);
    const cacheKey = `${KEY_PREFIX}${tenant.id}:${user.user_id}:${version}`;

    if (this.redis.isAvailable()) {
      try {
        const raw = await this.redis.getClient().get(cacheKey);
        if (raw) {
          const rules = JSON.parse(raw) as unknown[];
          return this.castEngine().fromRules(rules);
        }
      } catch (err) {
        this.logger.warn(`ability cache get failed (fail-open): ${(err as Error).message}`);
      }
    }

    const ability = this.engine.buildAbility(user, tenant.config);

    if (this.redis.isAvailable()) {
      try {
        const rules = this.castEngine().rules(ability);
        await this.redis.getClient().set(cacheKey, JSON.stringify(rules), 'EX', TTL_SECONDS);
      } catch (err) {
        this.logger.warn(`ability cache set failed: ${(err as Error).message}`);
      }
    }

    return ability;
  }

  /**
   * Convenience used by tests / workers that already have user + raw
   * tenant config (no DB lookup).
   */
  build(user: AbacUser, tenantConfig: TenantConfig): AbacAbility {
    return this.engine.buildAbility(user, tenantConfig);
  }

  async findTenant(tenant_id: string): Promise<Tenant | null> {
    return this.tenantRepo.findOne({ where: { id: tenant_id } });
  }

  /**
   * The cache (de)serialization roundtrip needs the concrete CASL engine
   * methods (`rules`, `fromRules`) ; the interface only exposes
   * build/evaluate. Phase 3 Rete will need its own serialization story.
   */
  private castEngine(): CaslAbacEngine {
    if (this.engine instanceof CaslAbacEngine) return this.engine;
    throw new Error('ability cache is only supported with CaslAbacEngine (Phase 1)');
  }
}

function readConfigVersion(config: TenantConfig | undefined): number {
  const v = (config as { version?: unknown } | undefined)?.version;
  return typeof v === 'number' && Number.isFinite(v) ? v : 0;
}
