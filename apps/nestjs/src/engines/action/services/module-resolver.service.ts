import { Inject, Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { RedisService } from '../../../core/cache/services/redis.service';
import type { ModuleConfig } from '../../../catalog-loader/validators/module-config.zod';
import { ModuleConfigZod } from '../../../catalog-loader/validators/module-config.zod';

interface CacheEntry {
  config: ModuleConfig;
  loadedAt: number;
}

interface DomainFile {
  id: string;
  name?: string;
  modules?: Array<{ id: string } & Record<string, unknown>>;
  screens?: Record<string, unknown>;
  actions?: Record<string, unknown>;
  entities?: Array<{ name: string } & Record<string, unknown>>;
  rbac_roles?: string[];
  abac_rules?: Array<Record<string, unknown>>;
  [key: string]: unknown;
}

@Injectable()
export class ModuleResolverService implements OnApplicationBootstrap {
  private readonly logger = new Logger(ModuleResolverService.name);
  private readonly baseDir: string;
  private readonly cache = new Map<string, CacheEntry>();
  private readonly CACHE_TTL_MS = 60_000;
  private domainCache: DomainFile[] | null = null;

  constructor(@Inject(RedisService) private readonly redis?: RedisService) {
    this.baseDir = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
  }

  async onApplicationBootstrap(): Promise<void> {
    this.logger.log('ModuleResolverService initialized');
  }

  async resolve(tenantSlug: string, moduleId: string): Promise<ModuleConfig> {
    const cacheKey = `${tenantSlug}:${moduleId}`;
    const cached = this.cache.get(cacheKey);
    if (cached && Date.now() - cached.loadedAt < this.CACHE_TTL_MS) {
      return cached.config;
    }

    const config = await this.loadFromSource(tenantSlug, moduleId);
    this.cache.set(cacheKey, { config, loadedAt: Date.now() });
    return config;
  }

  invalidate(tenantSlug: string, moduleId?: string): void {
    if (moduleId) {
      this.cache.delete(`${tenantSlug}:${moduleId}`);
    } else {
      for (const key of this.cache.keys()) {
        if (key.startsWith(`${tenantSlug}:`)) {
          this.cache.delete(key);
        }
      }
    }
    this.logger.log(`Cache invalidated for tenant=${tenantSlug} module=${moduleId ?? '*'}`);
  }

  private async loadFromSource(tenantSlug: string, moduleId: string): Promise<ModuleConfig> {
    const domainConfig = this.loadDomainFile(tenantSlug);
    if (!domainConfig) {
      throw new ModuleNotFoundError(moduleId);
    }

    if (domainConfig.id === moduleId) {
      const zodResult = ModuleConfigZod.safeParse(domainConfig);
      if (!zodResult.success) {
        throw new Error(
          `Module "${moduleId}" config validation failed: ${zodResult.error.message}`,
        );
      }
      return zodResult.data as ModuleConfig;
    }

    const moduleEntry = domainConfig.modules?.find((m) => m.id === moduleId);
    if (moduleEntry) {
      const merged: ModuleConfig = {
        schema_version: '1.0.0',
        id: moduleEntry.id,
        name: (moduleEntry.name as string) ?? moduleEntry.id,
        entities:
          ((moduleEntry as Record<string, unknown>).entities as ModuleConfig['entities']) ?? [],
        rbac_roles: (domainConfig.rbac_roles as string[]) ?? [],
        abac_rules: (domainConfig.abac_rules as ModuleConfig['abac_rules']) ?? [],
        conflict_strategy: 'server_wins',
        screens: (moduleEntry as Record<string, unknown>).screens as ModuleConfig['screens'],
        actions: (moduleEntry as Record<string, unknown>).actions as ModuleConfig['actions'],
        workflows: (moduleEntry as Record<string, unknown>).workflows as ModuleConfig['workflows'],
      };
      return merged;
    }

    const standaloneConfig = this.loadModuleFile(moduleId);
    if (standaloneConfig) {
      const zodResult = ModuleConfigZod.safeParse(standaloneConfig);
      if (!zodResult.success) {
        throw new Error(
          `Module "${moduleId}" config validation failed: ${zodResult.error.message}`,
        );
      }
      return zodResult.data;
    }

    throw new ModuleNotFoundError(moduleId);
  }

  private loadDomainFile(slug: string): DomainFile | null {
    const paths = [
      resolve(this.baseDir, 'domains', `${slug}.json`),
      resolve(this.baseDir, '..', 'catalog', 'domains', `${slug}.json`),
    ];
    for (const p of paths) {
      try {
        if (existsSync(p)) {
          const raw = readFileSync(p, 'utf8');
          return JSON.parse(raw) as DomainFile;
        }
      } catch {
        /* try next */
      }
    }
    return null;
  }

  private loadModuleFile(moduleId: string): DomainFile | null {
    const paths = [
      resolve(this.baseDir, 'modules', `${moduleId}.json`),
      resolve(this.baseDir, '..', 'catalog', 'modules', `${moduleId}.json`),
    ];
    for (const p of paths) {
      try {
        if (existsSync(p)) {
          const raw = readFileSync(p, 'utf8');
          return JSON.parse(raw) as DomainFile;
        }
      } catch {
        /* try next */
      }
    }
    return null;
  }
}

export class ModuleNotFoundError extends Error {
  constructor(moduleId: string) {
    super(`Module not found: ${moduleId}`);
    this.name = 'ModuleNotFoundError';
  }
}
