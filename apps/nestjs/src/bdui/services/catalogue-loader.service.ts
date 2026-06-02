import { Injectable, Logger } from '@nestjs/common';
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';

export interface ScreenConfig {
  screen: string;
  schema_version: string;
  layout: Record<string, unknown>;
  zones: Record<string, unknown>;
  data?: Record<string, unknown>;
  rules?: unknown[];
  states?: Record<string, unknown>;
  i18n?: Record<string, unknown>;
  [key: string]: unknown;
}

@Injectable()
export class CatalogueLoaderService {
  private readonly logger = new Logger(CatalogueLoaderService.name);
  private readonly baseDir: string;

  constructor() {
    this.baseDir = process.env.CATALOG_DIR ?? resolve(process.cwd(), '..', '..', 'catalog');
  }

  loadScreenConfig(tenantSlug: string, screenId: string): ScreenConfig | null {
    const screenDir = resolve(this.baseDir, 'tenants', tenantSlug, 'screens', screenId);
    const screenJsonPath = resolve(screenDir, 'screen.json');

    if (!existsSync(screenJsonPath)) {
      // Fallback: try old flat format (backward compat)
      const flatPath = resolve(this.baseDir, 'tenants', tenantSlug, 'screens', `${screenId}.json`);
      if (existsSync(flatPath)) {
        return JSON.parse(readFileSync(flatPath, 'utf8')) as ScreenConfig;
      }
      return null;
    }

    try {
      const raw = JSON.parse(readFileSync(screenJsonPath, 'utf8')) as Record<string, unknown>;
      this.logger.debug(`screen folder hit: tenant=${tenantSlug} screen=${screenId}`);
      return this.resolveRefs(raw, screenDir) as ScreenConfig;
    } catch (err) {
      this.logger.warn(`Failed to load screen ${screenId}: ${(err as Error).message}`);
      return null;
    }
  }

  private resolveRefs(value: unknown, baseDir: string): unknown {
    if (Array.isArray(value)) {
      return value.map((v) => this.resolveRefs(v, baseDir));
    }

    if (value !== null && typeof value === 'object') {
      const obj = value as Record<string, unknown>;

      if (typeof obj['$ref'] === 'string') {
        return this.resolveRef(obj['$ref'] as string, baseDir);
      }

      const resolved: Record<string, unknown> = {};
      for (const [key, val] of Object.entries(obj)) {
        resolved[key] = this.resolveRefs(val, baseDir);
      }
      return resolved;
    }

    return value;
  }

  private resolveRef(ref: string, baseDir: string): unknown {
    const [filePath, jsonPointer] = ref.split('#');
    const absPath = resolve(baseDir, filePath);

    if (!existsSync(absPath)) {
      this.logger.warn(`$ref target not found: ${absPath}`);
      return null;
    }

    try {
      const content = JSON.parse(readFileSync(absPath, 'utf8'));

      if (!jsonPointer) {
        return this.resolveRefs(content, dirname(absPath));
      }

      const parts = jsonPointer.replace(/^\//, '').split('/');
      let current = content;
      for (const part of parts) {
        if (current === null || typeof current !== 'object') return null;
        current = (current as Record<string, unknown>)[part];
        if (current === undefined) return null;
      }
      return this.resolveRefs(current, dirname(absPath));
    } catch (err) {
      this.logger.warn(`Failed to resolve $ref ${ref}: ${(err as Error).message}`);
      return null;
    }
  }
}