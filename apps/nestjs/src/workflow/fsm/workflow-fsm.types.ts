import { AnyStateMachine } from 'xstate';

export interface WorkflowFsmDef {
  id: string;
  initial: string;
  states: Record<
    string,
    {
      on?: Record<string, string | { target: string; cond?: string }>;
      type?: 'final';
      meta?: { i18n_key?: string; ui_step_id?: string };
    }
  >;
}

export interface TransitionDescriptor {
  event: string;
  target: string;
}

export interface TransitionInput {
  tenantId: string;
  moduleId: string;
  entityId: string;
  workflowId: string;
  event: string;
  params?: Record<string, unknown>;
  triggeredBy: string;
}

export interface TransitionResult {
  currentState: string;
  previousState: string;
  event: string;
  availableTransitions: TransitionDescriptor[];
  isTerminal: boolean;
  historyLength?: number;
}

export interface WorkflowStatus {
  current_state: string;
  available_transitions: TransitionDescriptor[];
  history: FsmHistoryEntry[];
  is_terminal: boolean;
}

export interface FsmHistoryEntry {
  from: string;
  event: string;
  to: string;
  timestamp: string;
  triggered_by: string;
}

export interface FsmValidationError {
  code: string;
  message: string;
  stepId?: string;
  target?: string;
  workflowId: string;
}

export interface FsmValidationResult {
  valid: boolean;
  errors: FsmValidationError[];
}

export class WorkflowTransitionDeniedError extends Error {
  constructor(
    public readonly event: string,
    public readonly currentState: string,
    public readonly availableTransitions: TransitionDescriptor[],
  ) {
    super(`Transition '${event}' non autorisee depuis l'etat '${currentState}'.`);
    this.name = 'WorkflowTransitionDeniedError';
  }
}

export class WorkflowNotStartedError extends Error {
  constructor(
    public readonly entityId: string,
    public readonly workflowId: string,
  ) {
    super(`Workflow '${workflowId}' not started for entity '${entityId}'.`);
    this.name = 'WorkflowNotStartedError';
  }
}

export interface FsmBuilderPort {
  build(def: WorkflowFsmDef): AnyStateMachine;
}
