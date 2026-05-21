import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import { resolve, sep } from 'node:path';
import type { WorkflowFsmDef } from './workflow-fsm.types';

const SLUG_RE = /^[\w-]+$/;

@Injectable()
export class WorkflowDefinitionResolver {
  private readonly logger = new Logger(WorkflowDefinitionResolver.name);
  private readonly baseDir: string;
  private readonly cache = new Map<string, WorkflowFsmDef | null>();

  constructor() {
    this.baseDir = resolve(process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog'));
  }

  resolveWorkflowId(moduleId: string): string {
    return `workflow_${moduleId}`;
  }

  loadFsmDef(tenantSlug: string, workflowId: string): WorkflowFsmDef | null {
    if (!SLUG_RE.test(tenantSlug) || !SLUG_RE.test(workflowId)) {
      throw new BadRequestException({
        error: 'INVALID_IDENTIFIER',
        message: 'tenantSlug and workflowId must contain only word characters and hyphens.',
      });
    }

    const cacheKey = `${tenantSlug}:${workflowId}`;
    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey) ?? null;
    }

    const workflowsDir = resolve(this.baseDir, 'workflows');
    const domainsDir = resolve(this.baseDir, 'domains');
    const candidates = [
      resolve(workflowsDir, `${tenantSlug}__${workflowId}.json`),
      resolve(domainsDir, `${tenantSlug}.json`),
    ];

    for (const p of candidates) {
      if (!p.startsWith(this.baseDir + sep)) {
        continue;
      }
      try {
        const raw = readFileSync(p, 'utf8');

        if (p.startsWith(workflowsDir)) {
          const def = JSON.parse(raw) as WorkflowFsmDef;
          this.cache.set(cacheKey, def);
          return def;
        }

        const parsed = JSON.parse(raw) as { workflows?: Record<string, WorkflowFsmDef> };
        if (parsed.workflows?.[workflowId]) {
          const def = parsed.workflows[workflowId];
          this.cache.set(cacheKey, def);
          return def;
        }
      } catch {
        /* try next */
      }
    }

    this.cache.set(cacheKey, null);
    return null;
  }
}
