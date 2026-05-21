import { Injectable, Logger } from '@nestjs/common';
import { transition, getNextTransitions } from 'xstate';
import { AnyMachineSnapshot } from 'xstate';
import { FsmBuilder } from './fsm-builder';
import { WorkflowStateRepository } from '../executor/workflow-state.repository';
import { AuditLogService } from '../../audit/services/audit-log.service';
import type {
  WorkflowFsmDef,
  TransitionInput,
  TransitionResult,
  TransitionDescriptor,
  WorkflowStatus,
} from './workflow-fsm.types';
import { WorkflowTransitionDeniedError, WorkflowNotStartedError } from './workflow-fsm.types';

@Injectable()
export class WorkflowFsmService {
  private readonly logger = new Logger(WorkflowFsmService.name);

  constructor(
    private readonly stateRepo: WorkflowStateRepository,
    private readonly fsmBuilder: FsmBuilder,
    private readonly auditLog: AuditLogService,
  ) {}

  buildMachine(def: WorkflowFsmDef) {
    return this.fsmBuilder.build(def);
  }

  async transition(def: WorkflowFsmDef, input: TransitionInput): Promise<TransitionResult> {
    const machine = this.fsmBuilder.build(def);

    const row = await this.stateRepo.findByEntityWorkflow(input.entityId, input.workflowId);

    if (!row) {
      throw new WorkflowNotStartedError(input.entityId, input.workflowId);
    }

    return this.stateRepo.transactionWithLock(
      input.entityId,
      input.workflowId,
      async (lockedRow) => {
        const currentValue = lockedRow.current_state;

        const resolved = machine.resolveState({
          value: currentValue,
        } as Parameters<typeof machine.resolveState>[0]);

        const transitions = machine.getTransitionData(resolved, {
          type: input.event,
        } as Parameters<typeof machine.getTransitionData>[1]);

        if (!transitions || transitions.length === 0) {
          const available = this.availableEvents(resolved);
          void this.auditLog.log({
            action: 'workflow.transition_rejected',
            tenant_id: input.tenantId,
            user_id: input.triggeredBy,
            module_id: input.moduleId,
            entity_id: input.entityId,
            metadata: {
              event: input.event,
              currentState: currentValue,
              availableEvents: available.map((a) => a.event),
            },
          });
          throw new WorkflowTransitionDeniedError(input.event, currentValue, available);
        }

        const [nextSnapshot] = transition(machine, resolved, {
          type: input.event,
        } as Parameters<typeof transition>[2]);

        const nextValue = nextSnapshot.value as string;
        const isTerminal = nextSnapshot.status === 'done';

        const historyEntry = {
          from: currentValue,
          event: input.event,
          to: nextValue,
          timestamp: new Date().toISOString(),
          triggered_by: input.triggeredBy,
        };

        const updatedHistory = Array.isArray(lockedRow.history)
          ? [...lockedRow.history, historyEntry]
          : [historyEntry];

        await this.stateRepo.update(lockedRow.id, {
          currentState: nextValue,
          history: updatedHistory,
        });

        await this.auditLog.log({
          action: 'workflow.transition',
          tenant_id: input.tenantId,
          user_id: input.triggeredBy,
          module_id: input.moduleId,
          entity_id: input.entityId,
          metadata: {
            runId: lockedRow.id,
            from: currentValue,
            to: nextValue,
            event: input.event,
          },
        });

        return {
          currentState: nextValue,
          previousState: currentValue,
          event: input.event,
          availableTransitions: this.availableEvents(nextSnapshot),
          isTerminal,
          historyLength: updatedHistory.length,
        };
      },
    );
  }

  async getStatus(
    tenantId: string,
    entityId: string,
    workflowId: string,
    def: WorkflowFsmDef,
  ): Promise<WorkflowStatus> {
    const row = await this.stateRepo.findByEntityAndWorkflow(tenantId, entityId, workflowId);

    if (!row) {
      throw new WorkflowNotStartedError(entityId, workflowId);
    }

    const machine = this.fsmBuilder.build(def);
    const resolved = machine.resolveState({
      value: row.current_state,
    } as Parameters<typeof machine.resolveState>[0]);

    return {
      current_state: row.current_state,
      available_transitions: this.availableEvents(resolved),
      history: Array.isArray(row.history) ? row.history : [],
      is_terminal: resolved.status === 'done',
    };
  }

  private availableEvents(snapshot: AnyMachineSnapshot): TransitionDescriptor[] {
    const available = getNextTransitions(snapshot);
    return available.map((t) => {
      const targetName = t.target && t.target.length > 0 ? t.target[0].id : undefined;
      return {
        event: typeof t.eventType === 'string' ? t.eventType : String(t.eventType),
        target: targetName ?? (typeof t.eventType === 'string' ? t.eventType : String(t.eventType)),
      };
    });
  }
}
