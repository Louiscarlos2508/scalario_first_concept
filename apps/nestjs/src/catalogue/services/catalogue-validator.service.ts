import { Injectable, Logger } from '@nestjs/common';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, extname } from 'node:path';
import { ModuleConfigZod } from '../validators/module-config.zod';
import { ScreenConfigZod } from '../validators/screen-config.zod';
import { WorkflowDefinitionZod } from '../validators/workflow.zod';
import {
  ValidationErrorFormatter,
  type ValidationErrorList,
} from '../errors/validation-error.formatter';
import type { ZodTypeAny } from 'zod';

export type CatalogueType = 'domain' | 'module' | 'fusion' | 'screen' | 'workflow';

export interface CatalogueValidationResult {
  valid: boolean;
  file: string;
  type: CatalogueType;
  errors?: ValidationErrorList;
  parseError?: string;
}

@Injectable()
export class CatalogueValidatorService {
  private readonly logger = new Logger(CatalogueValidatorService.name);
  private readonly formatter = new ValidationErrorFormatter();

  private readonly typeSchemaMap: Record<string, ZodTypeAny> = {
    domain: ModuleConfigZod,
    module: ModuleConfigZod,
    fusion: ModuleConfigZod,
    screen: ScreenConfigZod,
    workflow: WorkflowDefinitionZod,
  };

  validateContent(content: unknown, type: CatalogueType): CatalogueValidationResult {
    const schema = this.typeSchemaMap[type];
    if (!schema) {
      return {
        valid: false,
        file: '',
        type,
        errors: [
          {
            path: '',
            message: `Type inconnu : '${type}'. Types valides : domain, module, fusion, screen, workflow`,
            code: 'custom',
            received: type,
          },
        ],
      };
    }

    const result = schema.safeParse(content);
    if (result.success) {
      return { valid: true, file: '', type };
    }

    return {
      valid: false,
      file: '',
      type,
      errors: this.formatter.format(result.error),
    };
  }

  validateFile(filePath: string, type: CatalogueType): CatalogueValidationResult {
    let raw: string;
    try {
      raw = readFileSync(filePath, 'utf8');
    } catch (err) {
      return {
        valid: false,
        file: filePath,
        type,
        parseError: `Impossible de lire le fichier : ${(err as Error).message}`,
      };
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch (err) {
      const match = (err as Error).message.match(/position\s+(\d+)|line\s+(\d+)/i);
      const posInfo = match ? ` à ${match[0]}` : '';
      return {
        valid: false,
        file: filePath,
        type,
        parseError: `JSON syntaxe invalide${posInfo}. Détail : ${(err as Error).message}`,
      };
    }

    const result = this.validateContent(parsed, type);
    return { ...result, file: filePath };
  }

  inferTypeFromPath(filePath: string): CatalogueType | null {
    const normalized = filePath.replace(/\\/g, '/');
    if (normalized.includes('/domains/') || normalized.includes('/domain/')) return 'domain';
    if (normalized.includes('/modules/') || normalized.includes('/module/')) return 'module';
    if (normalized.includes('/fusions/') || normalized.includes('/fusion/')) return 'fusion';
    if (normalized.includes('/screens/') || normalized.includes('/screen/')) return 'screen';
    if (normalized.includes('/workflows/') || normalized.includes('/workflow/')) return 'workflow';
    return null;
  }

  validateDirectory(rootDir: string): CatalogueValidationResult[] {
    const results: CatalogueValidationResult[] = [];
    const dirs: [CatalogueType, string][] = [
      ['domain', join(rootDir, 'domains')],
      ['module', join(rootDir, 'modules')],
      ['fusion', join(rootDir, 'fusions')],
    ];

    for (const [type, dir] of dirs) {
      if (!existsSync(dir)) continue;
      const files = this.listJsonFiles(dir);
      for (const file of files) {
        results.push(this.validateFile(file, type));
      }
    }

    return results;
  }

  private listJsonFiles(dir: string): string[] {
    const results: string[] = [];
    if (!existsSync(dir)) return results;

    const entries = readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = join(dir, entry.name);
      if (entry.isDirectory()) {
        results.push(...this.listJsonFiles(fullPath));
      } else if (extname(entry.name) === '.json') {
        results.push(fullPath);
      }
    }
    return results;
  }
}
