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

  getNavigation(tenantSlug: string): Record<string, unknown> {
    const nav = this.loadNavigationConfig(tenantSlug);
    if (!nav) {
      return { modules: [], sidebar: { groups: [] }, top_actions: [] };
    }

    const sidebar = (nav as Record<string, unknown>).sidebar as Record<string, unknown> | undefined;
    if (sidebar && typeof sidebar.groups === 'object' && sidebar.groups != null) {
      sidebar.groups = (sidebar.groups as unknown[]).filter(
        (g) => {
          const group = g as Record<string, unknown>;
          const screens = group.screens as unknown[] | undefined;
          return screens && screens.length > 0;
        },
      );
    }

    return nav as Record<string, unknown>;
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
