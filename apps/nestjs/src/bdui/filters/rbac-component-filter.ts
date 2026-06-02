import { Injectable } from '@nestjs/common';
import type { ScreenConfig, ComponentConfig } from '../interfaces';

@Injectable()
export class RbacComponentFilter {
  apply(config: ScreenConfig, roles: string[]): ScreenConfig {
    if (!config.zones) return config;

    const filteredZones: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(config.zones)) {
      if (Array.isArray(val)) {
        filteredZones[key] = this.filterZone(val as ComponentConfig[], roles);
      } else {
        filteredZones[key] = val;
      }
    }

    return { ...config, zones: filteredZones };
  }

  private filterZone(
    components: ComponentConfig[] | undefined,
    roles: string[],
  ): ComponentConfig[] {
    if (!components) return [];
    return components
      .filter((c) => this.isVisibleForRoles(c, roles))
      .map((c) => this.recurseChildren(c, roles));
  }

  private isVisibleForRoles(c: ComponentConfig, roles: string[]): boolean {
    if (!c.visible_if) return true;
    if (c.visible_if.operator === 'role') {
      const allowed = c.visible_if.value as string[] | undefined;
      if (!Array.isArray(allowed)) return false;
      return roles.some((r) => allowed.includes(r));
    }
    return true;
  }

  private recurseChildren(c: ComponentConfig, roles: string[]): ComponentConfig {
    const children = (c.props?.children as ComponentConfig[] | undefined) ?? undefined;
    if (!children) return c;
    const filtered = this.filterZone(children, roles);
    return { ...c, props: { ...c.props, children: filtered } };
  }
}