import type { ActionDefinition } from '../../catalogue/validators/module-config.zod';

export interface HandlerContext {
  tenantId: string;
  userId: string;
  moduleConfig: {
    id: string;
    entities: Array<{ name: string; fields?: Array<{ name: string; type: string }> }>;
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
