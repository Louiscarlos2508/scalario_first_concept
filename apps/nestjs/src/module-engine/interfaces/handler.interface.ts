import type { ActionDefinition } from '../../catalogue/validators/module-config.zod';

export interface HandlerContext {
  tenantId: string;
  userId: string;
  moduleConfig: {
    id: string;
    entities: Array<{ name: string; fields?: Array<{ name: string; type: string }> }>;
    // STORY-035 — optional per-module conflict resolution strategy.
    // Defaults to "server_wins" when absent.
    conflict_strategy?: 'server_wins' | 'client_wins' | 'manual';
  };
  actionDef: ActionDefinition;
  payload: Record<string, unknown>;
}

export interface HandlerResult {
  entity?: Record<string, unknown>;
  data: Record<string, unknown>;
}

export interface Handler {
  readonly type: string;
  execute(ctx: HandlerContext): Promise<HandlerResult>;
}
