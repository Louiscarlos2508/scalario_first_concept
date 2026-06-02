import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { BduiLayoutCacheService } from '../cache/bdui-layout-cache.service';
import { ScreenConfigRepository } from '../repositories/screen-config.repository';
import { CatalogueLoaderService } from './catalogue-loader.service';
import { RbacComponentFilter } from '../filters/rbac-component-filter';
import { A2uiToScreenConfigService } from './a2ui-to-screen-config.service';
import type { ScreenConfig } from '../interfaces';

@Injectable()
export class BduiService {
  private readonly logger = new Logger(BduiService.name);

  constructor(
    private readonly cache: BduiLayoutCacheService,
    private readonly screenConfigRepo: ScreenConfigRepository,
    private readonly catalogueLoader: CatalogueLoaderService,
    private readonly filter: RbacComponentFilter,
    private readonly a2uiBridge: A2uiToScreenConfigService,
  ) {}

  async getLayout(
    tenantId: string,
    screenId: string,
    roles: string[],
    tenantSlug?: string,
  ): Promise<ScreenConfig> {
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
      this.catalogueLoader.loadScreenConfig(tenantSlug ?? tenantId, screenId);

    if (!raw) {
      const generated = await this.a2uiBridge.generateScreenConfig(tenantId, screenId);
      if (generated) {
        this.logger.log(
          `bdui.layout.generated tenant_id=${tenantId} screen_id=${screenId} source=mind_engine`,
        );
        const filtered = this.filter.apply(generated, roles);
        await this.cache.set(tenantId, screenId, roles, filtered);
        return filtered;
      }

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
    tenantSlug?: string,
  ): Promise<Record<string, ScreenConfig>> {
    const result: Record<string, ScreenConfig> = {};
    for (const screenId of screenIds) {
      result[screenId] = await this.getLayout(tenantId, screenId, roles, tenantSlug);
    }
    return result;
  }

  private normalizeScreenConfig(raw: Record<string, unknown>, screenId: string): ScreenConfig {
    const zones = raw.zones as Record<string, unknown> | undefined;

    const normalizedZones: Record<string, unknown> = {};
    if (zones) {
      for (const [key, val] of Object.entries(zones)) {
        if (Array.isArray(val)) {
          normalizedZones[key] = val;
        } else if (typeof val === 'object' && val !== null) {
          const zoneObj = val as Record<string, unknown>;
          if (Array.isArray(zoneObj.components)) {
            normalizedZones[key] = zoneObj.components;
          } else {
            normalizedZones[key] = [];
          }
        } else {
          normalizedZones[key] = [];
        }
      }
    }

    return {
      schema_version: (raw.schema_version as string) ?? '2.0.0',
      screen: (raw.screen as string) ?? screenId,
      layout: (raw.layout as Record<string, unknown>) ?? {},
      zones: normalizedZones,
      data: raw.data as Record<string, unknown> | undefined,
      rules: raw.rules as unknown[] | undefined,
      states: raw.states as Record<string, unknown> | undefined,
      i18n: raw.i18n as Record<string, unknown> | undefined,
    } as ScreenConfig;
  }

  private countComponents(config: ScreenConfig): number {
    let count = 0;
    if (!config.zones) return 0;
    for (const val of Object.values(config.zones)) {
      if (Array.isArray(val)) {
        count += this.countInComponents(val);
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
