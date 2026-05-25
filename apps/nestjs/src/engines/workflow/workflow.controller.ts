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
  BadRequestException,
  InternalServerErrorException,
  UseGuards,
  Logger,
} from '@nestjs/common';
import { WorkflowFsmService } from './fsm/workflow-fsm.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../core/auth/interfaces/jwt-payload.interface';
import {
  WorkflowTransitionDeniedError,
  WorkflowNotStartedError,
  WorkflowNotFoundError,
  WorkflowConfigError,
} from './fsm/workflow-fsm.types';
import { JwtAuthGuard } from '../../core/auth/guards/jwt-auth.guard';
import { RbacGuard } from '../../core/security/guards/rbac.guard';
import { AbacGuard } from '../../core/security/abac/guards/abac.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { AbacAction } from '../../core/security/abac/decorators/abac-action.decorator';

const SLUG_RE = /^[\w-]+$/;

@Controller(':tenant/:moduleId/entities/:id/workflow')
@UseGuards(JwtAuthGuard, RbacGuard, AbacGuard)
export class WorkflowController {
  private readonly logger = new Logger(WorkflowController.name);

  constructor(private readonly fsm: WorkflowFsmService) {}

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
    if (!body.event || typeof body.event !== 'string' || !body.event.trim()) {
      throw new BadRequestException({ error: 'INVALID_EVENT', message: 'event must be a non-empty string.' });
    }

    if (!SLUG_RE.test(moduleId)) {
      throw new BadRequestException({ error: 'INVALID_MODULE_ID', message: 'moduleId contains invalid characters.' });
    }

    const workflowId = `workflow_${moduleId}`;

    try {
      return await this.fsm.transition({
        tenantId: tenant,
        moduleId,
        entityId,
        workflowId,
        event: body.event.trim(),
        params: body.params,
        triggeredBy: user.user_id,
      });
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
        throw new NotFoundException({ error: 'WORKFLOW_NOT_STARTED', message: err.message });
      }
      if (err instanceof WorkflowNotFoundError) {
        throw new NotFoundException({ error: 'WORKFLOW_NOT_FOUND', message: err.message });
      }
      if (err instanceof WorkflowConfigError) {
        throw new InternalServerErrorException({ error: 'WORKFLOW_CONFIG_ERROR', message: err.message });
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
    if (!SLUG_RE.test(moduleId)) {
      throw new BadRequestException({ error: 'INVALID_MODULE_ID', message: 'moduleId contains invalid characters.' });
    }

    const workflowId = `workflow_${moduleId}`;

    try {
      return await this.fsm.getStatus(tenant, entityId, workflowId);
    } catch (err) {
      if (err instanceof WorkflowNotStartedError) {
        throw new NotFoundException({ error: 'WORKFLOW_NOT_STARTED', message: err.message });
      }
      if (err instanceof WorkflowNotFoundError) {
        throw new NotFoundException({ error: 'WORKFLOW_NOT_FOUND', message: err.message });
      }
      if (err instanceof WorkflowConfigError) {
        throw new InternalServerErrorException({ error: 'WORKFLOW_CONFIG_ERROR', message: err.message });
      }
      throw err;
    }
  }
}
