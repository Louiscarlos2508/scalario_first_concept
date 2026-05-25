import { Injectable, Logger } from '@nestjs/common';
import { readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { z } from 'zod';

/**
 * STORY-V14-006 — Stub loader pour `catalog/capabilities/<category>/*.json`.
 *
 * À implémenter pleinement dans V14-024 (Scalario Sense Flutter).
 * Pour l'instant : énumère + parse + validation Zod minimale.
 */

const CapabilityZod = z.object({
  schema_version: z.literal('1.0.0'),
  capability_id: z.string(),
  category: z.enum(['input', 'output', 'location', 'auth', 'integration', 'payment']),
  platform_support: z.object({
    ios: z.boolean(),
    android: z.boolean(),
    web: z.boolean().optional(),
    desktop: z.boolean().optional(),
  }),
  permissions_required: z.array(z.string()).optional(),
  fallback_strategy: z.enum(['disable', 'manual_input', 'skip', 'error']).optional(),
  config_schema: z.record(z.unknown()).optional(),
  examples: z.array(z.record(z.unknown())).optional(),
});

export type Capability = z.infer<typeof CapabilityZod>;

@Injectable()
export class CapabilityLoader {
  private readonly logger = new Logger(CapabilityLoader.name);
  private readonly baseDir: string;
  private capabilities = new Map<string, Capability>();

  constructor() {
    const root = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
    this.baseDir = resolve(root, 'capabilities');
  }

  loadAll(): Map<string, Capability> {
    this.capabilities.clear();
    let categories: string[];
    try {
      categories = readdirSync(this.baseDir, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name);
    } catch {
      this.logger.warn(`capabilities dir not found: ${this.baseDir}`);
      return this.capabilities;
    }

    for (const category of categories) {
      const dir = join(this.baseDir, category);
      const files = readdirSync(dir).filter((f) => f.endsWith('.json'));
      for (const file of files) {
        try {
          const raw = readFileSync(join(dir, file), 'utf8');
          const parsed = CapabilityZod.parse(JSON.parse(raw));
          this.capabilities.set(parsed.capability_id, parsed);
        } catch (err) {
          this.logger.error(
            `Failed to load capability ${category}/${file}: ${(err as Error).message}`,
          );
        }
      }
    }
    this.logger.log(`capabilities loaded: ${this.capabilities.size}`);
    return this.capabilities;
  }

  get(capabilityId: string): Capability | undefined {
    return this.capabilities.get(capabilityId);
  }
}
