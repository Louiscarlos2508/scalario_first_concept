import { Injectable, Logger } from '@nestjs/common';
import { UxProfileLoader } from '../loaders/ux-profile-loader';

@Injectable()
export class UxProfileValidator {
  private readonly logger = new Logger(UxProfileValidator.name);

  constructor(private readonly loader: UxProfileLoader) {}

  assertVariantAllowed(
    sector: string,
    componentType: string,
    variant: string,
  ): void {
    if (variant === 'auto') return;

    const config = this.loader.getVariantConfig(sector, componentType);
    if (!config) {
      this.logger.warn(
        `No UX profile config for component ${componentType} in sector ${sector} — allowing`,
      );
      return;
    }

    if (!config.allowed_variants.includes(variant)) {
      const message =
        `${variant} not allowed for ${componentType} in ${sector} UX profile`;
      this.logger.warn(`VARIANT_NOT_ALLOWED: ${message}`);
      throw new VariantNotAllowedException(componentType, variant, sector, config.allowed_variants);
    }
  }
}

export class VariantNotAllowedException extends Error {
  constructor(
    public readonly componentType: string,
    public readonly variant: string,
    public readonly sector: string,
    public readonly allowedVariants: string[],
  ) {
    super(`${variant} not allowed for ${componentType} in ${sector} UX profile`);
    this.name = 'VARIANT_NOT_ALLOWED_IN_PROFILE';
  }
}
