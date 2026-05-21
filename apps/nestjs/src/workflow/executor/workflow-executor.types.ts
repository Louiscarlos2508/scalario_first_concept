export interface ExecutionInput {
  tenantId: string;
  workflowId: string;
  entityId?: string;
  triggeredBy: string;
  initialContext: Record<string, unknown>;
  clientMutationId?: string;
}

export interface ExecutionResult {
  runId: string;
  workflowId: string;
  finalState: 'completed' | 'failed' | 'awaiting_approval';
  history: StepExecution[];
  error?: WorkflowError;
}

export interface WorkflowError {
  stepId: string;
  code: string;
  message: string;
}

export interface StepExecution {
  stepId: string;
  startedAt: string;
  completedAt?: string;
  status: 'pending' | 'running' | 'success' | 'skipped' | 'failed' | 'awaiting_approval';
  output?: unknown;
  attempts: number;
}

export interface ExecutionContext {
  runId: string;
  tenantId: string;
  entityId?: string;
  triggeredBy: string;
  data: Record<string, unknown>;
  stepStatus: Map<string, StepStatus>;
  stepOutput: Map<string, unknown>;
  history: StepExecution[];
  clientMutationId?: string;
}

export interface StepStatus {
  status: 'pending' | 'running' | 'success' | 'skipped' | 'failed';
  attempts: number;
}

export interface StepCondition {
  field: string;
  op: '>' | '<' | '==' | '!=' | '>=' | '<=';
  value: unknown;
}

export type StepNext =
  | string
  | { true: string; false: string }
  | { rules: Array<{ condition: StepCondition; next: string }>; default?: string };

export type WorkflowStepType = 'action' | 'condition' | 'notification' | 'approval';

export interface ExecutableWorkflowStep {
  id: string;
  type: WorkflowStepType;
  dependsOn?: string[];
  next?: StepNext;
  action?: string;
  params?: Record<string, unknown>;
  condition?: StepCondition;
}

export class WorkflowInvalidError extends Error {
  constructor(
    public readonly workflowId: string,
    public readonly validationErrors: Array<{ code: string; message: string }>,
  ) {
    super(
      `Workflow '${workflowId}' is invalid: ${validationErrors.map((e) => e.message).join('; ')}`,
    );
    this.name = 'WorkflowInvalidError';
  }
}

export class WorkflowExecutionError extends Error {
  constructor(
    public readonly code: string,
    public readonly details?: Record<string, unknown>,
  ) {
    super(`Workflow execution error: ${code}`);
    this.name = 'WorkflowExecutionError';
  }
}

export class WorkflowAlreadyRunningError extends Error {
  constructor(
    public readonly workflowId: string,
    public readonly entityId: string,
  ) {
    super(`Workflow '${workflowId}' is already running for entity '${entityId}'`);
    this.name = 'WorkflowAlreadyRunningError';
  }
}

export interface ActionDispatcherPort {
  executeAction(
    tenantId: string,
    moduleId: string,
    actionId: string,
    payload: Record<string, unknown>,
    opts: { clientMutationId: string; userId: string },
  ): Promise<Record<string, unknown>>;
}

export interface NotificationQueuePort {
  publish(params: {
    tenantId: string;
    recipientUserId?: string;
    template: string;
    params: Record<string, unknown>;
  }): Promise<void>;
}
