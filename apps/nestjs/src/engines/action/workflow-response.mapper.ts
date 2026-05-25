import { Injectable } from '@nestjs/common';
import type { ExecutionResult } from '../workflow/executor/workflow-executor.types';
import type { TransitionResult, TransitionDescriptor } from '../workflow/fsm/workflow-fsm.types';

export interface WorkflowActionResponse {
  run_id: string;
  workflow_id: string;
  current_state: string;
  previous_state?: string;
  available_transitions: Array<{ event: string; target: string }>;
  is_terminal: boolean;
  history_length: number;
  final_state?: 'completed' | 'failed' | 'awaiting_approval';
  error?: { step_id: string; code: string; message: string };
}

@Injectable()
export class WorkflowResponseMapper {
  fromExecutionResult(
    r: ExecutionResult,
    availableTransitions: TransitionDescriptor[] = [],
  ): WorkflowActionResponse {
    const lastStep = r.history[r.history.length - 1];

    return {
      run_id: r.runId,
      workflow_id: r.workflowId,
      current_state: lastStep?.stepId ?? r.finalState ?? 'unknown',
      available_transitions: availableTransitions,
      is_terminal: r.finalState === 'completed' || r.finalState === 'failed',
      history_length: r.history.length,
      final_state: r.finalState,
      error: r.error
        ? { step_id: r.error.stepId, code: r.error.code, message: r.error.message }
        : undefined,
    };
  }

  fromTransitionResult(
    r: TransitionResult,
    runId: string,
    workflowId: string,
  ): WorkflowActionResponse {
    return {
      run_id: runId,
      workflow_id: workflowId,
      current_state: r.current_state,
      previous_state: r.previous_state,
      available_transitions: r.available_transitions,
      is_terminal: r.is_terminal,
      history_length: r.history_length ?? 0,
    };
  }
}
