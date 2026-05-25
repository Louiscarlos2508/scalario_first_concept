import { Injectable, Logger, Optional } from '@nestjs/common';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, extname } from 'node:path';
import { ModuleConfigZod } from '../validators/module-config.zod';
import { ScreenConfigZod } from '../validators/screen-config.zod';
import { WorkflowDefinitionZod } from '../validators/workflow.zod';
import {
  ValidationErrorFormatter,
  type ValidationErrorList,
} from '../errors/validation-error.formatter';
import { WorkflowValidatorService } from '../../engines/workflow/validator/workflow-validator.service';
import type { ZodTypeAny } from 'zod';

export type CatalogueType = 'domain' | 'module' | 'fusion' | 'screen' | 'workflow';

export interface DagValidationError {
  workflowId: string;
  code: string;
  message: string;
  stepId?: string;
  cyclicSteps?: string[];
  missingDependencyId?: string;
}

export interface CatalogueValidationResult {
  valid: boolean;
  file: string;
  type: CatalogueType;
  errors?: ValidationErrorList;
  parseError?: string;
  dagErrors?: DagValidationError[];
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

  constructor(@Optional() private readonly dagValidator?: WorkflowValidatorService) {}

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
    if (!result.success) {
      return {
        valid: false,
        file: '',
        type,
        errors: this.formatter.format(result.error),
      };
    }

    const dagErrors: DagValidationError[] = [];

    if ((type === 'domain' || type === 'module' || type === 'fusion') && result.success) {
      const parsed = result.data as Record<string, unknown>;
      const workflows = parsed.workflows as
        | Record<
            string,
            {
              id?: string;
              steps?: Record<string, { id: string; type: string; dependsOn?: string[] }>;
            }
          >
        | undefined;

      if (workflows) {
        const validator = this.dagValidator ?? new WorkflowValidatorService();
        for (const [wfKey, wf] of Object.entries(workflows)) {
          const wfId = wf.id ?? wfKey;
          const stepValues = wf.steps ? Object.values(wf.steps) : [];

          if (stepValues.length === 0) continue;

          const dagResult = validator.validateDAG(
            wfId,
            stepValues.map((s) => ({
              id: s.id,
              type: s.type as 'action' | 'condition' | 'notification' | 'approval',
              dependsOn: s.dependsOn,
            })),
          );

          if (!dagResult.valid) {
            for (const err of dagResult.errors) {
              dagErrors.push({
                workflowId: err.workflowId,
                code: err.code,
                message: err.message,
                stepId: err.stepId,
                cyclicSteps: err.cyclicSteps,
                missingDependencyId: err.missingDependencyId,
              });
            }
          }
        }
      }
    }

    if (dagErrors.length > 0) {
      return { valid: false, file: '', type, dagErrors };
    }

    return { valid: true, file: '', type };
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
