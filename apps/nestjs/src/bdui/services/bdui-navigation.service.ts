import { Injectable, Logger } from '@nestjs/common';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

@Injectable()
export class BduiNavigationService {
  private readonly logger = new Logger(BduiNavigationService.name);
  private readonly baseDir: string;

  constructor() {
    this.baseDir = process.env.CATALOG_DIR ?? resolve(process.cwd(), '..', '..', 'catalog');
  }

  getNavigation(tenantSlug: string, userRoles?: string[]): Record<string, unknown> {
    const nav = this.loadNavigationConfig(tenantSlug);
    if (!nav) {
      return { modules: [], sidebar: { groups: [] }, top_actions: [] };
    }

    const navMap = nav as Record<string, unknown>;
    const sidebar = navMap.sidebar as Record<string, unknown> | undefined;
    if (sidebar && typeof sidebar.groups === 'object' && sidebar.groups != null) {
      const filtered = (sidebar.groups as Record<string, unknown>[]).map((g) => {
        const screens = (g.screens as Record<string, unknown>[] | undefined) ?? [];
        const filteredScreens = userRoles != null
          ? screens.filter((s) => {
              const screenRoles = s.roles as string[] | undefined;
              if (screenRoles == null || screenRoles.length === 0) return true;
              return screenRoles.some((r: string) => userRoles.includes(r));
            })
          : screens;
        return { ...g, screens: filteredScreens };
      }).filter((g) => {
        const screens = g.screens as unknown[] | undefined;
        return screens && screens.length > 0;
      });
      sidebar.groups = filtered;
    }

    return navMap;
  }

  private loadNavigationConfig(tenantSlug: string): Record<string, unknown> | null {
    const base = resolve(this.baseDir, 'tenants', tenantSlug);
    const paths = [
      resolve(base, 'navigation.json'),
      resolve(this.baseDir, '..', '..', 'catalog', 'tenants', tenantSlug, 'navigation.json'),
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
