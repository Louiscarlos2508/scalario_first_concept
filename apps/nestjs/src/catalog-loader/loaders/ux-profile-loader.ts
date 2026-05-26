import { Injectable, Logger } from '@nestjs/common';
import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { z } from 'zod';

const VariantConfigZod = z.object({
  default_variant: z.string().optional(),
  mobile_variant: z.string().optional(),
  desktop_variant: z.string().optional(),
  allowed_variants: z.array(z.string()),
  _comment: z.string().optional(),
});

const ComponentsJsonZod = z.object({
  $schema_version: z.string(),
  $inherits: z.string().optional(),
  sector: z.string().optional(),
  components: z.record(VariantConfigZod),
});

type VariantConfig = z.infer<typeof VariantConfigZod>;
type ComponentsJson = z.infer<typeof ComponentsJsonZod>;

@Injectable()
export class UxProfileLoader {
  private readonly logger = new Logger(UxProfileLoader.name);
  private readonly baseDir: string;
  private cache = new Map<string, ComponentsJson>();

  constructor() {
    let root = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
    if (!existsSync(root)) {
      root = resolve(process.cwd(), '../../catalog');
    }
    this.baseDir = resolve(root, 'ux_profiles');
  }

  load(sector: string): ComponentsJson {
    const cacheKey = sector;
    if (this.cache.has(cacheKey)) return this.cache.get(cacheKey)!;

    const base = this.loadFile('_base/components.json');
    if (sector === '_base') {
      this.cache.set(cacheKey, base);
      return base;
    }

    const sectorData = this.tryLoadFile(`${sector}/components.json`);
    const merged = this.mergeProfiles(base, sectorData);
    this.cache.set(cacheKey, merged);
    return merged;
  }

  getVariantConfig(sector: string, componentType: string): VariantConfig | undefined {
    const profile = this.load(sector);
    return profile.components[componentType];
  }

  clearCache(): void {
    this.cache.clear();
  }

  private loadFile(relativePath: string): ComponentsJson {
    const filePath = resolve(this.baseDir, relativePath);
    const raw = readFileSync(filePath, 'utf8');
    return ComponentsJsonZod.parse(JSON.parse(raw));
  }

  private tryLoadFile(relativePath: string): ComponentsJson | null {
    try {
      return this.loadFile(relativePath);
    } catch {
      this.logger.warn(`UX profile not found: ${relativePath}, using _base fallback`);
      return null;
    }
  }

  private mergeProfiles(base: ComponentsJson, sector: ComponentsJson | null): ComponentsJson {
    if (!sector) return base;
    const mergedComponents = { ...base.components };
    for (const [key, value] of Object.entries(sector.components)) {
      mergedComponents[key] = value;
    }
    return {
      $schema_version: sector.$schema_version,
      $inherits: sector.$inherits,
      sector: sector.sector,
      components: mergedComponents,
    };
  }
}
