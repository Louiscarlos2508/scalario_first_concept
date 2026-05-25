import { Injectable, Logger } from '@nestjs/common';
import type { WorkflowFsmDef, FsmValidationResult, FsmValidationError } from './workflow-fsm.types';

@Injectable()
export class FsmValidator {
  private readonly logger = new Logger(FsmValidator.name);

  validate(def: WorkflowFsmDef): FsmValidationResult {
    const errors: FsmValidationError[] = [];

    if (!def.initial) {
      errors.push({
        code: 'WF_FSM_INVALID',
        message: `FSM '${def.id}' : missing 'initial' state.`,
        workflowId: def.id,
      });
      return { valid: false, errors };
    }

    const stateNames = Object.keys(def.states);

    if (!stateNames.includes(def.initial)) {
      errors.push({
        code: 'WF_FSM_INVALID',
        message: `FSM '${def.id}' : initial state '${def.initial}' does not exist in states.`,
        stepId: def.initial,
        workflowId: def.id,
      });
    }

    for (const [name, state] of Object.entries(def.states)) {
      if (state.on) {
        for (const [event, target] of Object.entries(state.on)) {
          const targetName = typeof target === 'string' ? target : target.target;
          if (!stateNames.includes(targetName)) {
            errors.push({
              code: 'WF_UNKNOWN_DEPENDENCY',
              message: `FSM '${def.id}' : state '${name}' transition '${event}' targets '${targetName}' which does not exist.`,
              stepId: name,
              target: targetName,
              workflowId: def.id,
            });
          }
          if (typeof target === 'object' && target.cond) {
            errors.push({
              code: 'WF_FSM_INVALID',
              message: `FSM '${def.id}' : state '${name}' transition '${event}' declares 'cond' which is not supported in Phase 1. Use DAG guards via WorkflowExecutorService instead.`,
              stepId: name,
              workflowId: def.id,
            });
          }
        }
      }
    }

    const hasFinal = Object.values(def.states).some((s) => s.type === 'final');
    if (!hasFinal) {
      this.logger.warn(
        `FSM '${def.id}' : no 'final' state — workflow infini (verify intentional).`,
      );
    }

    const reachable = new Set<string>();
    const queue: string[] = [def.initial];
    reachable.add(def.initial);

    while (queue.length > 0) {
      const current = queue.shift()!;
      const transitions = def.states[current]?.on;
      if (transitions) {
        for (const target of Object.values(transitions)) {
          const targetName = typeof target === 'string' ? target : target.target;
          if (!reachable.has(targetName)) {
            reachable.add(targetName);
            queue.push(targetName);
          }
        }
      }
    }

    const orphans = stateNames.filter((n) => !reachable.has(n));
    for (const orphan of orphans) {
      errors.push({
        code: 'WF_FSM_INVALID',
        message: `FSM '${def.id}' : state '${orphan}' is unreachable from initial state '${def.initial}'.`,
        stepId: orphan,
        workflowId: def.id,
      });
    }

    if (errors.length > 0) {
      return { valid: false, errors };
    }

    return { valid: true, errors: [] };
  }
}
