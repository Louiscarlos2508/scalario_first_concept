import { Injectable, Logger } from '@nestjs/common';
import { readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { z } from 'zod';

/**
 * STORY-V14-006 — Stub loader pour `catalog/ux_profiles/<sector>/*.json`.
 *
 * À implémenter pleinement dans V14-004 (Catalogue composants × variantes).
 * Pour l'instant : énumère + parse + validation Zod minimale.
 */

const UxProfileZod = z.object({
  schema_version: z.literal('1.0.0'),
  profile_id: z.string(),
  sector: z.string(),
  inherits: z.array(z.string()).optional(),
  variants_allowed: z.record(z.array(z.string())).optional(),
  layout_rules: z.record(z.unknown()).optional(),
  naming_conventions: z.record(z.string()).optional(),
});

export type UxProfile = z.infer<typeof UxProfileZod>;

@Injectable()
export class UxProfileLoader {
  private readonly logger = new Logger(UxProfileLoader.name);
  private readonly baseDir: string;
  private profiles = new Map<string, UxProfile>();

  constructor() {
    const root = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
    this.baseDir = resolve(root, 'ux_profiles');
  }

  loadAll(): Map<string, UxProfile> {
    this.profiles.clear();
    let sectors: string[];
    try {
      sectors = readdirSync(this.baseDir, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name);
    } catch {
      this.logger.warn(`ux_profiles dir not found: ${this.baseDir}`);
      return this.profiles;
    }

    for (const sector of sectors) {
      const sectorDir = join(this.baseDir, sector);
      const files = readdirSync(sectorDir).filter((f) => f.endsWith('.json'));
      for (const file of files) {
        try {
          const raw = readFileSync(join(sectorDir, file), 'utf8');
          const parsed = UxProfileZod.parse(JSON.parse(raw));
          this.profiles.set(parsed.profile_id, parsed);
        } catch (err) {
          this.logger.error(`Failed to load ux_profile ${sector}/${file}: ${(err as Error).message}`);
        }
      }
    }
    this.logger.log(`ux_profiles loaded: ${this.profiles.size}`);
    return this.profiles;
  }

  get(profileId: string): UxProfile | undefined {
    return this.profiles.get(profileId);
  }
}
