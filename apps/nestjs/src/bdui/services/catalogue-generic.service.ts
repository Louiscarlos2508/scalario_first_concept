import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { existsSync, readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';

@Injectable()
export class CatalogueGenericService {
  private readonly logger = new Logger(CatalogueGenericService.name);
  private readonly baseDir: string;

  constructor() {
    this.baseDir = process.env.CATALOG_DIR ?? resolve(process.cwd(), '..', '..', 'catalog');
  }

  loadJson(tenantSlug: string, type: string, id?: string): Record<string, unknown> {
    const tenantDir = resolve(this.baseDir, 'tenants', tenantSlug);

    let filePath: string;
    if (id) {
      filePath = resolve(tenantDir, `${type}s`, id, `${type}.json`);
    } else {
      filePath = resolve(tenantDir, `${type}.json`);
    }

    const candidates = [
      filePath,
      resolve(this.baseDir, '..', '..', 'catalog', 'tenants', tenantSlug, `${type}.json`),
    ];

    if (id) {
      candidates.push(
        resolve(this.baseDir, '..', '..', 'catalog', 'tenants', tenantSlug, `${type}s`, id, `${type}.json`),
      );
      candidates.push(
        resolve(tenantDir, `${type}s`, id, 'dialog.json'),
      );
    }

    for (const p of candidates) {
      try {
        if (existsSync(p)) {
          const raw = JSON.parse(readFileSync(p, 'utf8')) as Record<string, unknown>;
          const resolved = this.resolveRefs(raw, dirname(p));
          return resolved as Record<string, unknown>;
        }
      } catch {
        /* try next */
      }
    }

    const label = id ? `${type}/${id}` : type;
    this.logger.warn(`${label} not found for tenant ${tenantSlug}`);
    throw new NotFoundException(`"${label}" not found for tenant "${tenantSlug}"`);
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
    const [filePath] = ref.split('#');
    const absPath = resolve(baseDir, filePath);

    if (!existsSync(absPath)) {
      this.logger.warn(`$ref target not found: ${absPath}`);
      return null;
    }

    try {
      const content = JSON.parse(readFileSync(absPath, 'utf8'));
      return this.resolveRefs(content, dirname(absPath));
    } catch (err) {
      this.logger.warn(`Failed to resolve $ref ${ref}: ${(err as Error).message}`);
      return null;
    }
  }
}
