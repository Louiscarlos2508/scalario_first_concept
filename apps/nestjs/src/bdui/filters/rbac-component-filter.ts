import { Injectable } from '@nestjs/common';
import type { ScreenConfig, ComponentConfig } from '../interfaces';

@Injectable()
export class RbacComponentFilter {
  apply(config: ScreenConfig, roles: string[]): ScreenConfig {
    return {
      ...config,
      zones: {
        kpis: this.filterZone(config.zones?.kpis, roles),
        main: this.filterZone(config.zones?.main, roles),
        aside: this.filterZone(config.zones?.aside, roles),
        actions: this.filterZone(config.zones?.actions, roles),
      },
    };
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

  /**
   * AC-13: no visible_if → always visible (inclusive default).
   * AC-10: operator "role" with value string[] → role intersection.
   *      Fail-closed: if operator is "role" and value is not string[], the
   *      component is REMOVED (never leak sensitive data).
   * Other operators (AND/OR/>/</==) → visible by default (data-aware, client-side).
   */
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
    return {
      ...c,
      props: { ...c.props, children: filtered },
    };
  }
}
