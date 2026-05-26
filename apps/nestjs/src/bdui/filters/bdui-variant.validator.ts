import { Injectable, Logger } from '@nestjs/common';
import { UxProfileLoader } from '../../catalog-loader/loaders/ux-profile-loader';
import { UxProfileValidator } from '../../catalog-loader/validators/ux-profile.validator';
import type { ScreenConfig } from '../interfaces';

@Injectable()
export class BduiVariantValidator {
  private readonly logger = new Logger(BduiVariantValidator.name);

  constructor(
    private readonly loader: UxProfileLoader,
    private readonly validator: UxProfileValidator,
  ) {}

  validateScreenVariants(
    sector: string,
    screenConfig: ScreenConfig,
  ): void {
    for (const zoneKey of ['kpis', 'main', 'aside', 'actions'] as const) {
      const zone = screenConfig.zones?.[zoneKey];
      if (!Array.isArray(zone)) continue;
      for (const component of zone) {
        this.validateComponent(sector, component as Record<string, unknown>);
      }
    }
  }

  private validateComponent(
    sector: string,
    component: Record<string, unknown>,
  ): void {
    const type = component.type as string | undefined;
    const variant = component.variant as string | undefined;
    if (!type) return;
    if (!variant || variant === 'auto') return;

    this.validator.assertVariantAllowed(sector, type, variant);

    const children = component.children as Record<string, unknown>[] | undefined;
    if (Array.isArray(children)) {
      for (const child of children) {
        this.validateComponent(sector, child);
      }
    }
  }
}
