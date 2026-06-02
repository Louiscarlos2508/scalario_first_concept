import { Injectable, Logger } from '@nestjs/common';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

export interface NavigationScreen {
  id: string;
  title: string;
}

export interface NavigationModule {
  id: string;
  name: string;
  icon: string;
  screens: NavigationScreen[];
}

export interface NavigationResponse {
  modules: NavigationModule[];
}

@Injectable()
export class BduiNavigationService {
  private readonly logger = new Logger(BduiNavigationService.name);
  private readonly baseDir: string;

  constructor() {
    this.baseDir = process.env.CATALOG_DIR ?? resolve(process.cwd(), '..', '..', 'catalog');
  }

  getNavigation(tenantSlug: string): NavigationResponse {
    const tenantConfig = this.loadTenantConfig(tenantSlug);
    if (!tenantConfig) return { modules: [] };

    const modules = (tenantConfig.modules ?? []) as Array<{ id: string; name?: string; icon?: string }>;
    const screensDef = (tenantConfig.screens ?? {}) as Record<string, { module: string | null; title: string; layout: string; roles: string[]; order: number }>;

    const moduleScreens: Record<string, NavigationScreen[]> = {};

    const ordered = Object.entries(screensDef)
      .sort((a, b) => (a[1].module ?? '')?.localeCompare(b[1].module ?? '') || a[1].order - b[1].order);

    for (const [id, def] of ordered) {
      const modId = def.module ?? '_orphan';
      if (!moduleScreens[modId]) moduleScreens[modId] = [];
      moduleScreens[modId].push({ id, title: def.title ?? id });
    }

    const result: NavigationModule[] = [];

    for (const mod of modules) {
      const screens = moduleScreens[mod.id];
      if (!screens || screens.length === 0) continue;
      result.push({
        id: mod.id,
        name: mod.name ?? mod.id,
        icon: mod.icon ?? 'apps',
        screens,
      });
      delete moduleScreens[mod.id];
    }

    const orphanKeys = Object.keys(moduleScreens);
    if (orphanKeys.length > 0 && orphanKeys[0] !== '_orphan') {
      for (const key of orphanKeys) {
        const screens = moduleScreens[key];
        if (screens && screens.length > 0) {
          result.push({
            id: key,
            name: key,
            icon: 'apps',
            screens,
          });
        }
      }
    }

    return { modules: result };
  }

  private loadTenantConfig(tenantSlug: string): Record<string, unknown> | null {
    const paths = [
      resolve(this.baseDir, 'tenants', tenantSlug, 'module.json'),
      resolve(this.baseDir, '..', '..', 'catalog', 'tenants', tenantSlug, 'module.json'),
    ];

    for (const p of paths) {
      try {
        if (existsSync(p)) {
          return JSON.parse(readFileSync(p, 'utf8')) as Record<string, unknown>;
        }
      } catch {
        /* try next */
      }
    }
    return null;
  }
}