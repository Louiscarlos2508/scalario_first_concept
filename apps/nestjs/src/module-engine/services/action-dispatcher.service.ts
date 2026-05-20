import {
  Injectable,
  Logger,
  UnprocessableEntityException,
  InternalServerErrorException,
} from '@nestjs/common';
import { ModuleResolverService, ModuleNotFoundError } from './module-resolver.service';
import { IdempotencyService } from './idempotency.service';
import { HandlerRegistry } from '../handlers/handler-registry';
import { AuditLogService } from '../../audit/services/audit-log.service';
import type { AuthenticatedUser } from '../../auth/interfaces/jwt-payload.interface';
import type { ExecuteActionBody } from '../dto/execute-action.dto';
import { createHash } from 'node:crypto';

export interface ActionResponse {
  entity?: Record<string, unknown>;
  result: Record<string, unknown>;
  mutation_id: string;
}

export interface ActionContext {
  tenantSlug: string;
  moduleId: string;
  mutationId: string;
  body: ExecuteActionBody;
  user: AuthenticatedUser;
}

@Injectable()
export class ActionDispatcherService {
  private readonly logger = new Logger(ActionDispatcherService.name);

  constructor(
    private readonly resolver: ModuleResolverService,
    private readonly registry: HandlerRegistry,
    private readonly idempotency: IdempotencyService,
    private readonly audit: AuditLogService,
  ) {}

  async dispatch(ctx: ActionContext): Promise<ActionResponse> {
    let moduleConfig;
    try {
      moduleConfig = await this.resolver.resolve(ctx.tenantSlug, ctx.moduleId);
    } catch (err) {
      if (err instanceof ModuleNotFoundError) {
        throw new UnprocessableEntityException({
          error: 'Module not found',
          moduleId: ctx.moduleId,
        });
      }
      throw err;
    }

    const actionDef = moduleConfig.actions?.[ctx.body.action];
    if (!actionDef) {
      throw new UnprocessableEntityException({
        error: 'Unknown action',
        moduleId: ctx.moduleId,
        action: ctx.body.action,
      });
    }

    const existing = await this.idempotency.checkAndReserve(ctx.mutationId, {
      tenantId: ctx.user.tenant_id,
      userId: ctx.user.user_id,
      moduleId: ctx.moduleId,
      action: ctx.body.action,
      payload: ctx.body.payload,
    });
    if (existing.alreadyDone && existing.previousResult) {
      this.logger.log(
        `Idempotent request: mutation_id=${ctx.mutationId} — returning cached result`,
      );
      return existing.previousResult;
    }

    const handler = this.registry.get(actionDef.handler);
    if (!handler) {
      await this.idempotency.markError(ctx.mutationId);
      throw new InternalServerErrorException(`Handler not registered: ${actionDef.handler}`);
    }

    try {
      const result = await handler.execute({
        tenantId: ctx.user.tenant_id,
        userId: ctx.user.user_id,
        moduleConfig,
        actionDef,
        payload: ctx.body.payload,
      });

      await this.idempotency.markSuccess(ctx.mutationId, result.data);

      await this.audit.log({
        tenant_id: ctx.user.tenant_id,
        user_id: ctx.user.user_id,
        action: ctx.body.action,
        module_id: ctx.moduleId,
        entity_id: result.entity?.id as string | undefined,
        payload: ctx.body.payload,
      });

      return {
        entity: result.entity,
        result: result.data,
        mutation_id: ctx.mutationId,
      };
    } catch (err) {
      await this.idempotency.markError(ctx.mutationId);
      throw err;
    }
  }

  private hashPayload(payload: unknown): string {
    return createHash('sha256').update(JSON.stringify(payload)).digest('hex');
  }
}
