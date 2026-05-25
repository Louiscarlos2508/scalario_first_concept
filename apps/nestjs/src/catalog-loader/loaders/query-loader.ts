import { Injectable, Logger } from '@nestjs/common';
import { readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

/**
 * STORY-V14-006 — Stub loader pour `catalog/queries/<sector>/*.sql`.
 *
 * **RÈGLE CRITIQUE (PRD v14 §22.5) :** le SQL brut n'est **JAMAIS** exposé à
 * l'IA. Le LLM référence une query par son ID (`pharmacie.rapport_ventes_medicaments`),
 * jamais par son contenu. Le SQL reste validé humain dans `catalog/queries/`.
 *
 * À implémenter pleinement dans V14-028 (Scalario Vault niveau 3).
 * Pour l'instant : énumère + parse les metadata `-- @params { ... }` + `-- @access [ ... ]`.
 */

export interface NamedQuery {
  query_id: string; // e.g., "pharmacie.rapport_ventes_medicaments"
  sector: string; // e.g., "pharmacie"
  name: string; // e.g., "rapport_ventes_medicaments"
  sql: string; // raw SQL (NEVER exposed to LLM)
  params_schema?: unknown; // parsed from `-- @params { ... }` header
  access_roles?: string[]; // parsed from `-- @access [ ... ]` header
}

@Injectable()
export class QueryLoader {
  private readonly logger = new Logger(QueryLoader.name);
  private readonly baseDir: string;
  private queries = new Map<string, NamedQuery>();

  constructor() {
    const root = process.env.CATALOG_DIR ?? resolve(process.cwd(), 'catalog');
    this.baseDir = resolve(root, 'queries');
  }

  loadAll(): Map<string, NamedQuery> {
    this.queries.clear();
    let sectors: string[];
    try {
      sectors = readdirSync(this.baseDir, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name);
    } catch {
      this.logger.warn(`queries dir not found: ${this.baseDir}`);
      return this.queries;
    }

    for (const sector of sectors) {
      const dir = join(this.baseDir, sector);
      const files = readdirSync(dir).filter((f) => f.endsWith('.sql'));
      for (const file of files) {
        const name = file.replace(/\.sql$/, '');
        const query_id = `${sector}.${name}`;
        try {
          const sql = readFileSync(join(dir, file), 'utf8');
          const params_schema = this.extractMetadata(sql, '@params');
          const access_roles = this.extractAccessRoles(sql);
          this.queries.set(query_id, { query_id, sector, name, sql, params_schema, access_roles });
        } catch (err) {
          this.logger.error(`Failed to load query ${query_id}: ${(err as Error).message}`);
        }
      }
    }
    this.logger.log(`queries loaded: ${this.queries.size}`);
    return this.queries;
  }

  get(queryId: string): NamedQuery | undefined {
    return this.queries.get(queryId);
  }

  private extractMetadata(sql: string, tag: string): unknown {
    const match = sql.match(new RegExp(`^--\\s*${tag}\\s*(\\{.*\\})$`, 'm'));
    if (!match) return undefined;
    try {
      return JSON.parse(match[1]);
    } catch {
      return undefined;
    }
  }

  private extractAccessRoles(sql: string): string[] | undefined {
    const match = sql.match(/^--\s*@access\s*(\[.*\])$/m);
    if (!match) return undefined;
    try {
      return JSON.parse(match[1].replace(/'/g, '"'));
    } catch {
      return undefined;
    }
  }
}
