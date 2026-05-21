import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  HttpCode,
  HttpStatus,
  ConflictException,
  NotFoundException,
  UseGuards,
  Logger,
} from '@nestjs/common';
import { WorkflowFsmService } from './fsm/workflow-fsm.service';
import { WorkflowDefinitionResolver } from './fsm/workflow-definition.resolver';
import { FsmValidator } from './fsm/fsm-validator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/interfaces/jwt-payload.interface';
import { WorkflowTransitionDeniedError, WorkflowNotStartedError } from './fsm/workflow-fsm.types';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RbacGuard } from '../security/guards/rbac.guard';
import { AbacGuard } from '../security/abac/guards/abac.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { AbacAction } from '../security/abac/decorators/abac-action.decorator';

@Controller(':tenant/:moduleId/entities/:id/workflow')
@UseGuards(JwtAuthGuard, RbacGuard, AbacGuard)
export class WorkflowController {
  private readonly logger = new Logger(WorkflowController.name);

  constructor(
    private readonly fsm: WorkflowFsmService,
    private readonly defResolver: WorkflowDefinitionResolver,
    private readonly fsmValidator: FsmValidator,
  ) {}

  @Post('transition')
  @HttpCode(HttpStatus.OK)
  @Roles('OWNER', 'MANAGER', 'COMMERCIAL', 'LIVREUR')
  @AbacAction('workflow.transition', 'Workflow')
  async transition(
    @Param('tenant') tenant: string,
    @Param('moduleId') moduleId: string,
    @Param('id') entityId: string,
    @Body() body: { event: string; params?: Record<string, unknown> },
    @CurrentUser() user: AuthenticatedUser,
  ) {
    const workflowId = this.defResolver.resolveWorkflowId(moduleId);
    const def = this.defResolver.loadFsmDef(tenant, workflowId);

    if (!def) {
      throw new NotFoundException({
        error: 'WORKFLOW_NOT_FOUND',
        message: `Workflow '${workflowId}' not found for tenant '${tenant}'.`,
      });
    }

    try {
      const result = await this.fsm.transition(def, {
        tenantId: tenant,
        moduleId,
        entityId,
        workflowId,
        event: body.event,
        params: body.params,
        triggeredBy: user.user_id,
      });
      return result;
    } catch (err) {
      if (err instanceof WorkflowTransitionDeniedError) {
        throw new ConflictException({
          error: 'WORKFLOW_TRANSITION_DENIED',
          message: err.message,
          current_state: err.currentState,
          available_transitions: err.availableTransitions,
        });
      }
      if (err instanceof WorkflowNotStartedError) {
        throw new NotFoundException({
          error: 'WORKFLOW_NOT_STARTED',
          message: err.message,
        });
      }
      throw err;
    }
  }

  @Get()
  @Roles('OWNER', 'MANAGER', 'COMMERCIAL', 'LIVREUR')
  @AbacAction('read', 'Workflow')
  async getStatus(
    @Param('tenant') tenant: string,
    @Param('moduleId') moduleId: string,
    @Param('id') entityId: string,
  ) {
    const workflowId = this.defResolver.resolveWorkflowId(moduleId);
    const def = this.defResolver.loadFsmDef(tenant, workflowId);

    if (!def) {
      throw new NotFoundException({
        error: 'WORKFLOW_NOT_FOUND',
        message: `Workflow '${workflowId}' not found for tenant '${tenant}'.`,
      });
    }

    try {
      return await this.fsm.getStatus(tenant, entityId, workflowId, def);
    } catch (err) {
      if (err instanceof WorkflowNotStartedError) {
        throw new NotFoundException({
          error: 'WORKFLOW_NOT_STARTED',
          message: err.message,
        });
      }
      throw err;
    }
  }

  @HttpCode(HttpStatus.NO_CONTENT)
  @Post()
  noRoute() {
    return;
  }
}
