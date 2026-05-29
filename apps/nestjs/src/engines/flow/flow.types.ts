import type { AstNode } from '../shared/engine-core';

export type FlowTriggerType = 'manual' | 'event' | 'schedule' | 'webhook';

export interface FlowTrigger {
  type: FlowTriggerType;
  event?: string;
  schedule?: string;
  webhook?: string;
}

export interface FlowDef {
  id: string;
  name: string;
  trigger: FlowTrigger;
  steps: FlowStepNode[];
}

export interface FlowStepNode extends AstNode {
  type: 'condition' | 'delay' | 'approval' | 'notify' | 'loop' | 'assign' | 'webhook' | 'end';
  label?: string;
  expression?: string;
  then?: string[];
  else?: string[];
  duration?: number;
  role?: string;
  message?: string;
  on_approved?: string[];
  on_rejected?: string[];
  channel?: string;
  to?: string;
  template?: string;
  data?: Record<string, unknown>;
  over?: string;
  as?: string;
  steps?: string[];
  target?: string;
  value?: unknown;
  value_type?: string;
  url?: string;
  method?: string;
  headers?: Record<string, string>;
  body?: unknown;
  on_success?: string[];
  on_error?: string[];
  output?: Record<string, unknown>;
}

export interface FlowAstPayload {
  version: 'v0.9';
  engine: 'flow';
  flow: FlowDef;
}

export interface CompiledFlow {
  id: string;
  name: string;
  trigger: FlowTrigger;
  steps: CompiledStep[];
  adjacency: Map<string, { onSuccess: string[]; onFailure?: string[] }>;
}

export interface CompiledStep {
  id: string;
  type: FlowStepNode['type'];
  config: Record<string, unknown>;
}
