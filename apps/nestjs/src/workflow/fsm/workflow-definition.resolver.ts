import { Injectable, Logger } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import type { WorkflowFsmDef } from './workflow-fsm.types';

@Injectable()
export class WorkflowDefinitionResolver {
  private readonly logger = new Logger(WorkflowDefinitionResolver.name);
  private readonly baseDir: string;

  constructor() {
    this.baseDir = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
  }

  resolveWorkflowId(moduleId: string): string {
    return `workflow_${moduleId}`;
  }

  loadFsmDef(tenantSlug: string, workflowId: string): WorkflowFsmDef | null {
    const candidates = [
      resolve(this.baseDir, 'workflows', `${tenantSlug}__${workflowId}.json`),
      resolve(this.baseDir, 'domains', `${tenantSlug}.json`),
      resolve(this.baseDir, '..', 'catalog', 'domains', `${tenantSlug}.json`),
      resolve(this.baseDir, '..', '..', 'catalog', 'domains', `${tenantSlug}.json`),
      resolve(this.baseDir, '..', '..', '..', 'catalog', 'domains', `${tenantSlug}.json`),
    ];

    for (const p of candidates) {
      try {
        const raw = readFileSync(p, 'utf8');

        if (p.includes('workflows')) {
          return JSON.parse(raw) as WorkflowFsmDef;
        }

        const parsed = JSON.parse(raw) as {
          workflows?: Record<string, WorkflowFsmDef>;
        };
        if (parsed.workflows?.[workflowId]) {
          return parsed.workflows[workflowId];
        }
      } catch {
        /* try next */
      }
    }

    return null;
  }
}
