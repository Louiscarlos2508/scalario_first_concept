import { Injectable, Logger } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import type { ScreenConfig } from '../interfaces';

export interface CatalogueScreenEntry {
  screen: string;
  schema_version: string;
  zones: ScreenConfig['zones'];
  [key: string]: unknown;
}

@Injectable()
export class CatalogueLoaderService {
  private readonly logger = new Logger(CatalogueLoaderService.name);
  private readonly baseDir: string;

  constructor() {
    this.baseDir = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
  }

  loadScreenConfig(tenantSlug: string, screenId: string): ScreenConfig | null {
    const candidates = [
      resolve(this.baseDir, 'domains', `${tenantSlug}.json`),
      resolve(this.baseDir, '..', 'catalog', 'domains', `${tenantSlug}.json`),
    ];

    let raw: string | null = null;
    for (const p of candidates) {
      try {
        raw = readFileSync(p, 'utf8');
        break;
      } catch {
        /* try next */
      }
    }

    if (raw) {
      const parsed = JSON.parse(raw) as {
        screens?: Record<string, CatalogueScreenEntry>;
      };

      const screen = parsed.screens?.[screenId];
      if (screen) {
        this.logger.debug(`catalogue filesystem hit: tenant=${tenantSlug} screen=${screenId}`);
        const { schema_version, screen: screenName, zones, ...rest } = screen;
        return {
          schema_version: schema_version ?? '1.0.0',
          screen: screenName ?? screenId,
          zones: zones ?? { kpis: [], main: [], aside: [], actions: [] },
          ...rest,
        };
      }
    }

    const tenantDir = resolve(this.baseDir, 'tenants', tenantSlug);
    try {
      const tenantScreen = readFileSync(resolve(tenantDir, 'screens', `${screenId}.json`), 'utf8');
      const parsed = JSON.parse(tenantScreen) as Record<string, unknown>;
      this.logger.debug(`tenant v2 filesystem hit: tenant=${tenantSlug} screen=${screenId}`);
      return {
        schema_version: (parsed.schema_version as string) ?? '1.0.0',
        screen: screenId,
        zones: (parsed.zones as ScreenConfig['zones']) ?? {
          kpis: [],
          main: [],
          aside: [],
          actions: [],
        },
      };
    } catch {
      /* screen not in tenant dir */
    }

    return null;
  }
}
