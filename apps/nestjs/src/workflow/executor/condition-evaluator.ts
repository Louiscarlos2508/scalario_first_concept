import type { ExecutionContext, StepCondition } from './workflow-executor.types';
import { WorkflowExecutionError } from './workflow-executor.types';

export class ConditionEvaluator {
  evaluate(condition: StepCondition, ctx: ExecutionContext): boolean {
    const value = this.resolvePath(condition.field, ctx.data);
    switch (condition.op) {
      case '==':
        return value == condition.value;
      case '!=':
        return value != condition.value;
      case '>':
      case '<':
      case '>=':
      case '<=': {
        const numValue = Number(value);
        const numTarget = Number(condition.value);
        if (Number.isNaN(numValue) || Number.isNaN(numTarget)) {
          throw new WorkflowExecutionError('INVALID_CONDITION_VALUE', {
            field: condition.field,
            value: String(value),
            target: String(condition.value),
            op: condition.op,
          });
        }
        switch (condition.op) {
          case '>':
            return numValue > numTarget;
          case '<':
            return numValue < numTarget;
          case '>=':
            return numValue >= numTarget;
          case '<=':
            return numValue <= numTarget;
          default:
            throw new WorkflowExecutionError('UNSUPPORTED_OPERATOR', { op: condition.op });
        }
      }
      default:
        throw new WorkflowExecutionError('UNSUPPORTED_OPERATOR', {
          op: condition.op,
        });
    }
  }

  private resolvePath(path: string, obj: unknown): unknown {
    return path.split('.').reduce<unknown>((acc, key) => {
      if (acc === null || acc === undefined) return undefined;
      if (typeof acc === 'object') {
        return (acc as Record<string, unknown>)[key];
      }
      return undefined;
    }, obj);
  }
}
