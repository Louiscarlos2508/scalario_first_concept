import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { BduiLayoutCacheService } from '../cache/bdui-layout-cache.service';
import { ScreenConfigRepository } from '../repositories/screen-config.repository';
import { CatalogueLoaderService } from './catalogue-loader.service';
import { RbacComponentFilter } from '../filters/rbac-component-filter';
import type { ScreenConfig } from '../interfaces';

@Injectable()
export class BduiService {
  private readonly logger = new Logger(BduiService.name);

  constructor(
    private readonly cache: BduiLayoutCacheService,
    private readonly screenConfigRepo: ScreenConfigRepository,
    private readonly catalogueLoader: CatalogueLoaderService,
    private readonly filter: RbacComponentFilter,
  ) {}

  async getLayout(tenantId: string, screenId: string, roles: string[]): Promise<ScreenConfig> {
    const start = Date.now();

    const cached = await this.cache.get(tenantId, screenId, roles);
    if (cached) {
      const ms = Date.now() - start;
      this.logger.log(
        `bdui.layout.served tenant_id=${tenantId} screen_id=${screenId} role_count=${roles.length} cache=hit duration_ms=${ms}`,
      );
      return cached;
    }

    const raw =
      (await this.screenConfigRepo.findByTenantAndScreen(tenantId, screenId)) ??
      this.catalogueLoader.loadScreenConfig(tenantId, screenId);

    if (!raw) {
      throw new NotFoundException(`Screen "${screenId}" not found for tenant "${tenantId}"`);
    }

    const screenConfig = this.normalizeScreenConfig(raw, screenId);
    const filtered = this.filter.apply(screenConfig, roles);
    const componentCountBefore = this.countComponents(screenConfig);
    const componentCountAfter = this.countComponents(filtered);

    await this.cache.set(tenantId, screenId, roles, filtered);

    const ms = Date.now() - start;
    this.logger.log(
      `bdui.layout.served tenant_id=${tenantId} screen_id=${screenId} role_count=${roles.length} cache=miss duration_ms=${ms} components_before=${componentCountBefore} components_filtered_out=${componentCountBefore - componentCountAfter}`,
    );

    return filtered;
  }

  async getBulkLayouts(
    tenantId: string,
    screenIds: string[],
    roles: string[],
  ): Promise<Record<string, ScreenConfig>> {
    const result: Record<string, ScreenConfig> = {};
    for (const screenId of screenIds) {
      result[screenId] = await this.getLayout(tenantId, screenId, roles);
    }
    return result;
  }

  private normalizeScreenConfig(raw: Record<string, unknown>, screenId: string): ScreenConfig {
    return {
      schema_version: (raw.schema_version as string) ?? '1.0.0',
      screen: (raw.screen as string) ?? screenId,
      zones: (raw.zones as ScreenConfig['zones']) ?? {
        kpis: [],
        main: [],
        aside: [],
        actions: [],
      },
    } as ScreenConfig;
  }

  private countComponents(config: ScreenConfig): number {
    let count = 0;
    const zoneKeys = ['kpis', 'main', 'aside', 'actions'] as const;
    for (const key of zoneKeys) {
      const zone = config.zones?.[key];
      if (Array.isArray(zone)) {
        count += this.countInComponents(zone);
      }
    }
    return count;
  }

  private countInComponents(components: unknown[]): number {
    let count = 0;
    for (const c of components) {
      count++;
      const props = (c as Record<string, unknown>)?.props;
      const children =
        props && typeof props === 'object'
          ? (props as Record<string, unknown>).children
          : undefined;
      if (Array.isArray(children)) {
        count += this.countInComponents(children);
      }
    }
    return count;
  }
}
