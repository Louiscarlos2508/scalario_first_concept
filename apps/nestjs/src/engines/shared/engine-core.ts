export type EngineType = 'ui' | 'flow' | 'algo' | 'datasource' | 'capability' | 'live' | 'permission';

export interface PropDef {
  type: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'ref';
  required?: boolean;
  description?: string;
  enum?: string[];
  default?: unknown;
}

export interface PrimitiveDef {
  name: string;
  description: string;
  props: Record<string, PropDef>;
}

export interface AstNode {
  id: string;
  type: string;
  label?: string;
  [key: string]: unknown;
}

export type EngineAst = AstNode[];

export interface EngineCompiler<TConfig> {
  compile(ast: EngineAst, context?: Record<string, unknown>): TConfig;
}

export interface ExecutionContext {
  tenantId: string;
  userId: string;
  data: Record<string, unknown>;
  stepResults?: Map<string, unknown>;
}

export interface ExecutionResult {
  success: boolean;
  data?: Record<string, unknown>;
  error?: string;
  stepResults?: Array<{ stepId: string; status: string; output?: unknown }>;
}

export interface EngineRuntime<TConfig> {
  execute(config: TConfig, context: ExecutionContext): Promise<ExecutionResult>;
}
