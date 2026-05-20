import { Injectable, Logger } from '@nestjs/common';
import { kahnTopologicalSort } from './kahn';
import type { ValidationResult, WorkflowValidationError } from './workflow-validator.types';
import type { WorkflowStep } from './workflow-validator.types';

export { type ValidationResult, type WorkflowValidationError, type WorkflowStep };

@Injectable()
export class WorkflowValidatorService {
  private readonly logger = new Logger(WorkflowValidatorService.name);

  validateDAG(workflowId: string, steps: WorkflowStep[]): ValidationResult {
    const errors: WorkflowValidationError[] = [];

    if (steps.length === 0) {
      return {
        valid: false,
        errors: [
          {
            code: 'WF_NO_ENTRY_POINT',
            workflowId,
            message: `Workflow '${workflowId}' : aucun workflow ne peut être vide — déclarez au moins une étape.`,
          },
        ],
      };
    }

    const ids = new Set<string>();
    for (const s of steps) {
      if (ids.has(s.id)) {
        errors.push({
          code: 'WF_DUPLICATE_ID',
          stepId: s.id,
          workflowId,
          message: `Workflow '${workflowId}' : étape '${s.id}' déclarée plusieurs fois.`,
        });
      }
      ids.add(s.id);
    }

    if (errors.length > 0) return { valid: false, errors };

    for (const s of steps) {
      for (const dep of s.dependsOn ?? []) {
        if (dep === s.id) {
          errors.push({
            code: 'WF_SELF_LOOP',
            stepId: s.id,
            workflowId,
            message: `Workflow '${workflowId}' : étape '${s.id}' se dépend d'elle-même.`,
          });
        } else if (!ids.has(dep)) {
          errors.push({
            code: 'WF_UNKNOWN_DEPENDENCY',
            stepId: s.id,
            missingDependencyId: dep,
            workflowId,
            message: `Workflow '${workflowId}' : étape '${s.id}' dépend de '${dep}' qui n'existe pas.`,
          });
        }
      }
    }

    if (errors.length > 0) return { valid: false, errors };

    const nodes = steps.map((s) => s.id);
    const edges = steps.flatMap((s) => (s.dependsOn ?? []).map((d) => [d, s.id] as const));

    const kahnResult = kahnTopologicalSort(nodes, edges);

    if (!kahnResult.ok) {
      return {
        valid: false,
        errors: [
          {
            code: 'WF_CYCLE',
            cyclicSteps: kahnResult.remaining,
            workflowId,
            message: `Workflow '${workflowId}' : cycle détecté impliquant [${kahnResult.remaining.join(', ')}].`,
          },
        ],
      };
    }

    const entryPoints = steps.filter((s) => !s.dependsOn?.length).map((s) => s.id);
    if (entryPoints.length === 0) {
      return {
        valid: false,
        errors: [
          {
            code: 'WF_NO_ENTRY_POINT',
            workflowId,
            message: `Workflow '${workflowId}' : aucun point d'entrée (toutes les étapes ont des dépendances).`,
          },
        ],
      };
    }

    const visitedFromEntry = new Set<string>(entryPoints);
    const bfsQueue = [...entryPoints];
    const adjFrom = new Map<string, string[]>(nodes.map((n) => [n, []]));
    for (const [from, to] of edges) {
      adjFrom.get(from)!.push(to);
    }
    while (bfsQueue.length > 0) {
      const current = bfsQueue.shift()!;
      for (const next of adjFrom.get(current) ?? []) {
        if (!visitedFromEntry.has(next)) {
          visitedFromEntry.add(next);
          bfsQueue.push(next);
        }
      }
    }

    const unreachableSteps = nodes.filter(
      (n) => !visitedFromEntry.has(n) && steps.find((s) => s.id === n)?.dependsOn?.length,
    );

    for (const stepId of unreachableSteps) {
      errors.push({
        code: 'WF_UNREACHABLE',
        stepId,
        workflowId,
        message: `Workflow '${workflowId}' : étape '${stepId}' est inaccessible (aucun chemin depuis un point d'entrée).`,
      });
    }

    if (errors.length > 0) return { valid: false, errors };

    const terminalSteps = nodes.filter((n) => !edges.some(([from]) => from === n));

    return {
      valid: true,
      sortedSteps: kahnResult.sorted,
      entryPoints,
      terminalSteps,
    };
  }
}
