export type ValidationResult =
  | { valid: true; sortedSteps: string[]; entryPoints: string[]; terminalSteps: string[] }
  | { valid: false; errors: WorkflowValidationError[] };

export interface WorkflowValidationError {
  code:
    | 'WF_CYCLE'
    | 'WF_UNKNOWN_DEPENDENCY'
    | 'WF_UNREACHABLE'
    | 'WF_NO_ENTRY_POINT'
    | 'WF_DUPLICATE_ID'
    | 'WF_SELF_LOOP';
  message: string;
  stepId?: string;
  cyclicSteps?: string[];
  missingDependencyId?: string;
  workflowId: string;
}

export interface WorkflowStep {
  id: string;
  type: 'action' | 'condition' | 'notification' | 'approval';
  dependsOn?: string[];
  next?: string | { rules: Array<{ condition: unknown; next: string }>; default?: string };
  action?: string;
  params?: Record<string, unknown>;
  condition?: { field: string; op: '>' | '<' | '==' | '!='; value: unknown };
}
