import { Injectable, Logger } from '@nestjs/common';
import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

export interface ModuleCatalogEntry {
  id: string;
  schema_version: string;
  name?: string;
  icon?: string;
  entities?: Array<Record<string, unknown>>;
  actions?: Record<string, unknown>;
  screens?: string[];
  workflows?: string[];
  rbac_roles?: string[];
  [key: string]: unknown;
}

export interface TenantCatalogEntry {
  id: string;
  schema_version: string;
  name?: string;
  tenant_handle?: string;
  sector?: string;
  currency?: string;
  locale?: string;
  timezone?: string;
  modules?: string[];
  entities?: string[];
  screens?: string[];
  [key: string]: unknown;
}

export interface ResolvedScreen {
  screenConfig: Record<string, unknown>;
  source: 'tenant_file' | 'module_file' | 'generated';
}

@Injectable()
export class ModuleCatalogV2Loader {
  private readonly logger = new Logger(ModuleCatalogV2Loader.name);
  private readonly baseDir: string;

  constructor() {
    this.baseDir = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
  }

  loadModuleConfig(moduleId: string): ModuleCatalogEntry | null {
    const paths = [
      resolve(this.baseDir, 'modules', moduleId, 'module.json'),
      resolve(this.baseDir, 'modules', `${moduleId}.json`),
    ];
    for (const p of paths) {
      try {
        if (existsSync(p)) {
          const raw = readFileSync(p, 'utf8');
          const parsed = JSON.parse(raw) as ModuleCatalogEntry;
          if (parsed.id === moduleId) return parsed;
        }
      } catch { /* try next */ }
    }
    return null;
  }

  loadTenantConfig(tenantSlug: string): TenantCatalogEntry | null {
    const paths = [
      resolve(this.baseDir, 'tenants', tenantSlug, 'module.json'),
      resolve(this.baseDir, 'domains', `${tenantSlug}.json`),
    ];
    for (const p of paths) {
      try {
        if (existsSync(p)) {
          const raw = readFileSync(p, 'utf8');
          return JSON.parse(raw) as TenantCatalogEntry;
        }
      } catch { /* try next */ }
    }
    return null;
  }

  resolveScreenConfig(tenantSlug: string, screenId: string): Record<string, unknown> | null {
    const tenantPaths = [
      resolve(this.baseDir, 'tenants', tenantSlug, 'screens', `${screenId}.json`),
      resolve(this.baseDir, 'tenants', tenantSlug, `${screenId}.json`),
    ];
    for (const p of tenantPaths) {
      try {
        if (existsSync(p)) {
          const raw = readFileSync(p, 'utf8');
          return JSON.parse(raw) as Record<string, unknown>;
        }
      } catch { /* try next */ }
    }

    const tenantCfg = this.loadTenantConfig(tenantSlug);
    if (tenantCfg?.screens) {
      for (const screenRef of tenantCfg.screens) {
        if (screenRef.endsWith(`${screenId}.json`)) {
          const absPath = resolve(this.baseDir, 'tenants', tenantSlug, screenRef);
          try {
            if (existsSync(absPath)) {
              return JSON.parse(readFileSync(absPath, 'utf8')) as Record<string, unknown>;
            }
          } catch { /* continue */ }
        }
      }
    }

    const moduleDirs = this.findModuleDirs();
    for (const modDir of moduleDirs) {
      const moduleCfg = this.loadModuleConfig(modDir);
      if (!moduleCfg?.screens) continue;
      for (const screenRef of moduleCfg.screens) {
        if (screenRef.endsWith(`${screenId}.json`)) {
          const absPath = resolve(this.baseDir, 'modules', modDir, screenRef);
          try {
            if (existsSync(absPath)) {
              return JSON.parse(readFileSync(absPath, 'utf8')) as Record<string, unknown>;
            }
          } catch { /* continue */ }
        }
      }
    }

    return null;
  }

  private findModuleDirs(): string[] {
    const modulesDir = resolve(this.baseDir, 'modules');
    if (!existsSync(modulesDir)) return [];
    try {
      const { readdirSync } = require('node:fs');
      return readdirSync(modulesDir, { withFileTypes: true })
        .filter((e: { isDirectory: () => boolean }) => e.isDirectory())
        .map((e: { name: string }) => e.name);
    } catch {
      return [];
    }
  }
}
