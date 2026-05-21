import {
  Injectable,
  Logger,
  UnprocessableEntityException,
  InternalServerErrorException,
  BadRequestException,
  NotFoundException,
  ConflictException,
  Optional,
} from '@nestjs/common';
import { ZodError } from 'zod';
import { ModuleResolverService, ModuleNotFoundError } from './module-resolver.service';
import { IdempotencyService } from './idempotency.service';
import { HandlerRegistry } from '../handlers/handler-registry';
import { AuditLogService } from '../../audit/services/audit-log.service';
import { WorkflowResponseMapper } from '../workflow-response.mapper';
import type { WorkflowActionResponse } from '../workflow-response.mapper';
import { WorkflowExecutorService } from '../../workflow/executor/workflow-executor.service';
import { WorkflowFsmService } from '../../workflow/fsm/workflow-fsm.service';
import { WorkflowStateRepository } from '../../workflow/executor/workflow-state.repository';
import type { AuthenticatedUser } from '../../auth/interfaces/jwt-payload.interface';
import type { ExecuteActionBody } from '../dto/execute-action.dto';
import { StartWorkflowActionSchema } from '../dto/start-workflow-action.dto';
import { TransitionWorkflowActionSchema } from '../dto/transition-workflow-action.dto';
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
    private readonly mapper: WorkflowResponseMapper,
    @Optional() private readonly workflowExecutor?: WorkflowExecutorService,
    @Optional() private readonly workflowFsm?: WorkflowFsmService,
    @Optional() private readonly stateRepo?: WorkflowStateRepository,
  ) {}

  async dispatch(ctx: ActionContext): Promise<ActionResponse | WorkflowActionResponse> {
    if (ctx.body.action_type) {
      return this.dispatchWorkflowAction(ctx);
    }
    return this.dispatchStandardAction(ctx);
  }

  private async dispatchWorkflowAction(ctx: ActionContext): Promise<WorkflowActionResponse> {
    switch (ctx.body.action_type) {
      case 'start_workflow':
        return this.handleStartWorkflow(ctx);
      case 'transition_workflow':
        return this.handleTransitionWorkflow(ctx);
      default:
        throw new BadRequestException({
          error: 'UNKNOWN_ACTION_TYPE',
          message: `Unknown action_type: '${ctx.body.action_type}'`,
        });
    }
  }

  private async handleStartWorkflow(ctx: ActionContext): Promise<WorkflowActionResponse> {
    if (!this.workflowExecutor) {
      throw new InternalServerErrorException('WorkflowExecutorService is not available');
    }
    if (!this.stateRepo) {
      throw new InternalServerErrorException('WorkflowStateRepository is not available');
    }

    let dto;
    try {
      dto = StartWorkflowActionSchema.parse(ctx.body);
    } catch (err) {
      if (err instanceof ZodError) {
        throw new BadRequestException({ message: 'Invalid payload', errors: err.errors });
      }
      throw err;
    }

    const moduleConfig = await this.resolveModule(ctx.tenantSlug, ctx.moduleId);

    if (!moduleConfig.workflows || !(dto.workflow_id in moduleConfig.workflows)) {
      throw new BadRequestException({
        error: 'WORKFLOW_NOT_IN_MODULE',
        message: `Workflow '${dto.workflow_id}' n'est pas declare dans le module '${ctx.moduleId}'.`,
      });
    }

    const existingIdem = await this.idempotency.checkAndReserve(ctx.mutationId, {
      tenantId: ctx.user.tenant_id,
      userId: ctx.user.user_id,
      moduleId: ctx.moduleId,
      action: 'start_workflow',
      payload: { workflow_id: dto.workflow_id, entity_id: dto.entity_id },
    });
    if (existingIdem.alreadyDone && existingIdem.previousResult) {
      this.logger.log(
        `Idempotent start_workflow: mutation_id=${ctx.mutationId} — returning cached result`,
      );
      return existingIdem.previousResult as unknown as WorkflowActionResponse;
    }

    try {
      const execResult = await this.workflowExecutor.run({
        tenantId: ctx.user.tenant_id,
        workflowId: dto.workflow_id,
        entityId: dto.entity_id,
        triggeredBy: ctx.user.user_id,
        initialContext: dto.initial_context ?? {},
      });

      const response = this.mapper.fromExecutionResult(execResult);

      await this.idempotency.markSuccess(
        ctx.mutationId,
        response as unknown as Record<string, unknown>,
      );

      await this.audit.log({
        tenant_id: ctx.user.tenant_id,
        user_id: ctx.user.user_id,
        action: 'start_workflow',
        module_id: ctx.moduleId,
        entity_id: dto.entity_id,
        metadata: {
          workflow_id: dto.workflow_id,
          run_id: response.run_id,
          final_state: response.final_state,
        },
      });

      return response;
    } catch (err) {
      await this.idempotency.markError(ctx.mutationId);

      const error = err as Error & {
        name?: string;
        currentState?: string;
        availableTransitions?: Array<{ event: string; target: string }>;
      };

      if (error.name === 'WorkflowAlreadyRunningError') {
        throw new ConflictException({
          error: 'WORKFLOW_ALREADY_RUNNING',
          message: error.message,
        });
      }

      throw err;
    }
  }

  private async handleTransitionWorkflow(ctx: ActionContext): Promise<WorkflowActionResponse> {
    if (!this.workflowFsm) {
      throw new InternalServerErrorException('WorkflowFsmService is not available');
    }
    if (!this.stateRepo) {
      throw new InternalServerErrorException('WorkflowStateRepository is not available');
    }

    let dto;
    try {
      dto = TransitionWorkflowActionSchema.parse(ctx.body);
    } catch (err) {
      if (err instanceof ZodError) {
        throw new BadRequestException({ message: 'Invalid payload', errors: err.errors });
      }
      throw err;
    }

    const existingIdem = await this.idempotency.checkAndReserve(ctx.mutationId, {
      tenantId: ctx.user.tenant_id,
      userId: ctx.user.user_id,
      moduleId: ctx.moduleId,
      action: 'transition_workflow',
      payload: { run_id: dto.run_id, event: dto.event },
    });
    if (existingIdem.alreadyDone && existingIdem.previousResult) {
      this.logger.log(
        `Idempotent transition_workflow: mutation_id=${ctx.mutationId} — returning cached result`,
      );
      return existingIdem.previousResult as unknown as WorkflowActionResponse;
    }

    const runState = await this.stateRepo.findByRunId(dto.run_id);
    if (!runState) {
      throw new NotFoundException({
        error: 'WORKFLOW_RUN_NOT_FOUND',
        message: `Workflow run '${dto.run_id}' not found.`,
      });
    }

    if (runState.tenant_id !== ctx.user.tenant_id) {
      throw new NotFoundException({
        error: 'WORKFLOW_RUN_NOT_FOUND',
        message: `Workflow run '${dto.run_id}' not found.`,
      });
    }

    if (!runState.entity_id) {
      throw new BadRequestException({
        error: 'WORKFLOW_NO_ENTITY',
        message: `Workflow run '${dto.run_id}' has no entity_id — cannot transition.`,
      });
    }

    try {
      const transResult = await this.workflowFsm.transition({
        tenantId: ctx.user.tenant_id,
        moduleId: ctx.moduleId,
        entityId: runState.entity_id,
        workflowId: runState.workflow_id,
        event: dto.event,
        params: dto.params ?? {},
        triggeredBy: ctx.user.user_id,
      });

      const response = this.mapper.fromTransitionResult(
        transResult,
        dto.run_id,
        runState.workflow_id,
      );

      await this.idempotency.markSuccess(
        ctx.mutationId,
        response as unknown as Record<string, unknown>,
      );

      await this.audit.log({
        tenant_id: ctx.user.tenant_id,
        user_id: ctx.user.user_id,
        action: 'transition_workflow',
        module_id: ctx.moduleId,
        entity_id: runState.entity_id,
        metadata: {
          run_id: dto.run_id,
          workflow_id: runState.workflow_id,
          event: dto.event,
          from: transResult.previous_state,
          to: transResult.current_state,
        },
      });

      return response;
    } catch (err) {
      await this.idempotency.markError(ctx.mutationId);

      const error = err as Error & {
        constructor?: { name: string };
        currentState?: string;
        availableTransitions?: Array<{ event: string; target: string }>;
      };

      if (error.name === 'WorkflowTransitionDeniedError') {
        throw new ConflictException({
          error: 'WORKFLOW_TRANSITION_DENIED',
          message: error.message,
          current_state: error.currentState,
          available_transitions: error.availableTransitions ?? [],
        });
      }

      if (error.name === 'WorkflowNotStartedError') {
        throw new NotFoundException({
          error: 'WORKFLOW_NOT_STARTED',
          message: error.message,
        });
      }

      throw err;
    }
  }

  private async dispatchStandardAction(ctx: ActionContext): Promise<ActionResponse> {
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

    const actionDef = moduleConfig.actions?.[ctx.body.action!];
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
      action: ctx.body.action!,
      payload: ctx.body.payload ?? {},
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
        payload: ctx.body.payload ?? {},
      });

      await this.idempotency.markSuccess(ctx.mutationId, result.data);

      await this.audit.log({
        tenant_id: ctx.user.tenant_id,
        user_id: ctx.user.user_id,
        action: ctx.body.action!,
        module_id: ctx.moduleId,
        entity_id: result.entity?.id as string | undefined,
        payload: ctx.body.payload ?? {},
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

  private async resolveModule(tenantSlug: string, moduleId: string) {
    return this.resolver.resolve(tenantSlug, moduleId);
  }

  private hashPayload(payload: unknown): string {
    return createHash('sha256').update(JSON.stringify(payload)).digest('hex');
  }
}
