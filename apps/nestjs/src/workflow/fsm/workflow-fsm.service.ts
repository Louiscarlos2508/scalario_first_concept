import { Injectable, Logger } from '@nestjs/common';
import { transition, getNextTransitions } from 'xstate';
import { AnyMachineSnapshot } from 'xstate';
import { FsmBuilder } from './fsm-builder';
import { FsmValidator } from './fsm-validator';
import { WorkflowDefinitionResolver } from './workflow-definition.resolver';
import { WorkflowStateRepository, WorkflowStateRowNotFoundError } from '../executor/workflow-state.repository';
import { AuditLogService } from '../../audit/services/audit-log.service';
import type {
  WorkflowFsmDef,
  TransitionInput,
  TransitionResult,
  TransitionDescriptor,
  WorkflowStatus,
  FsmHistoryEntry,
} from './workflow-fsm.types';
import {
  WorkflowTransitionDeniedError,
  WorkflowNotStartedError,
  WorkflowNotFoundError,
  WorkflowConfigError,
} from './workflow-fsm.types';

@Injectable()
export class WorkflowFsmService {
  private readonly logger = new Logger(WorkflowFsmService.name);

  constructor(
    private readonly stateRepo: WorkflowStateRepository,
    private readonly fsmBuilder: FsmBuilder,
    private readonly auditLog: AuditLogService,
    private readonly defResolver: WorkflowDefinitionResolver,
    private readonly fsmValidator: FsmValidator,
  ) {}

  buildMachine(def: WorkflowFsmDef) {
    return this.fsmBuilder.build(def);
  }

  async transition(input: TransitionInput): Promise<TransitionResult> {
    const def = this.loadAndValidateDef(input.tenantId, input.workflowId);
    const machine = this.fsmBuilder.build(def);

    try {
      return await this.stateRepo.transactionWithLock(
        input.entityId,
        input.workflowId,
        async (lockedRow, manager) => {
          const currentValue = lockedRow.current_state;

          const resolved = machine.resolveState({
            value: currentValue,
          } as Parameters<typeof machine.resolveState>[0]);

          const availableForCheck = getNextTransitions(resolved);
          const isEventValid = availableForCheck.some(
            (t) => (typeof t.eventType === 'string' ? t.eventType : String(t.eventType)) === input.event,
          );

          if (!isEventValid) {
            const available = this.availableEvents(resolved);
            await this.auditLog.log({
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
          const is_terminal = nextSnapshot.status === 'done';

          const historyEntry: FsmHistoryEntry = {
            from: currentValue,
            event: input.event,
            to: nextValue,
            timestamp: new Date().toISOString(),
            triggered_by: input.triggeredBy,
          };

          const updated_history = Array.isArray(lockedRow.history)
            ? [...lockedRow.history, historyEntry]
            : [historyEntry];

          await this.stateRepo.updateInManager(manager, lockedRow.id, {
            currentState: nextValue,
            history: updated_history,
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
            current_state: nextValue,
            previous_state: currentValue,
            event: input.event,
            available_transitions: this.availableEvents(nextSnapshot),
            is_terminal,
            history_length: updated_history.length,
          };
        },
      );
    } catch (err) {
      if (err instanceof WorkflowStateRowNotFoundError) {
        throw new WorkflowNotStartedError(input.entityId, input.workflowId);
      }
      throw err;
    }
  }

  async getStatus(
    tenantId: string,
    entityId: string,
    workflowId: string,
  ): Promise<WorkflowStatus> {
    const def = this.loadAndValidateDef(tenantId, workflowId);
    const row = await this.stateRepo.findByEntityAndWorkflow(tenantId, entityId, workflowId);

    if (!row) {
      throw new WorkflowNotStartedError(entityId, workflowId);
    }

    const machine = this.fsmBuilder.build(def);
    const resolved = machine.resolveState({
      value: row.current_state,
    } as Parameters<typeof machine.resolveState>[0]);

    const fsmHistory: FsmHistoryEntry[] = Array.isArray(row.history)
      ? (row.history as any[]).filter(
          (e) => typeof e?.from === 'string' && typeof e?.event === 'string' && typeof e?.to === 'string',
        )
      : [];

    return {
      current_state: row.current_state,
      available_transitions: this.availableEvents(resolved),
      history: fsmHistory,
      is_terminal: resolved.status === 'done',
    };
  }

  private loadAndValidateDef(tenantId: string, workflowId: string): WorkflowFsmDef {
    const def = this.defResolver.loadFsmDef(tenantId, workflowId);
    if (!def) {
      throw new WorkflowNotFoundError(workflowId, tenantId);
    }
    const validation = this.fsmValidator.validate(def);
    if (!validation.valid) {
      throw new WorkflowConfigError(workflowId, validation.errors);
    }
    return def;
  }

  private availableEvents(snapshot: AnyMachineSnapshot): TransitionDescriptor[] {
    const available = getNextTransitions(snapshot);
    return available.map((t) => {
      const targetName = t.target && t.target.length > 0 ? t.target[0].key : undefined;
      const eventStr = typeof t.eventType === 'string' ? t.eventType : String(t.eventType);
      return {
        event: eventStr,
        target: targetName ?? eventStr,
      };
    });
  }
}
