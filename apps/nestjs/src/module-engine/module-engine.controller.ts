import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  Headers,
  UseGuards,
  Logger,
  BadRequestException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DataDispatcherService } from './services/data-dispatcher.service';
import { ActionDispatcherService, type ActionResponse } from './services/action-dispatcher.service';
import type { WorkflowActionResponse } from './workflow-response.mapper';
import { GetDataQuerySchema, type GetDataQuery } from './dto/get-data.dto';
import { ExecuteActionBodySchema, type ExecuteActionBody } from './dto/execute-action.dto';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AbacAction } from '../security/abac/decorators/abac-action.decorator';
import { MutationInProgressError } from './services/idempotency.service';
import type { AuthenticatedUser } from '../auth/interfaces/jwt-payload.interface';

@Controller('api/v1/:tenant/:moduleId')
@UseGuards(JwtAuthGuard)
export class ModuleEngineController {
  private readonly logger = new Logger(ModuleEngineController.name);

  constructor(
    private readonly data: DataDispatcherService,
    private readonly action: ActionDispatcherService,
  ) {}

  @Get('data')
  @Roles('OWNER', 'MANAGER')
  @AbacAction('read', 'ModuleData')
  async getData(
    @Param('tenant') tenantSlug: string,
    @Param('moduleId') moduleId: string,
    @Query(new ZodValidationPipe(GetDataQuerySchema)) query: GetDataQuery,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    if (tenantSlug !== user.tenant_id) {
      throw new ForbiddenException('Cross-tenant access denied');
    }

    return this.data.dispatch({ tenantSlug, moduleId, query, userId: user.user_id });
  }

  @Post('action')
  @Roles('OWNER', 'MANAGER')
  @AbacAction('execute', 'ModuleAction')
  async executeAction(
    @Param('tenant') tenantSlug: string,
    @Param('moduleId') moduleId: string,
    @Headers('x-client-mutation-id') mutationId: string,
    @Body(new ZodValidationPipe(ExecuteActionBodySchema)) body: ExecuteActionBody,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ActionResponse | WorkflowActionResponse> {
    if (tenantSlug !== user.tenant_id) {
      throw new ForbiddenException('Cross-tenant access denied');
    }

    if (!mutationId) {
      throw new BadRequestException({
        error: 'X-Client-Mutation-Id header is required',
      });
    }

    try {
      return await this.action.dispatch({
        tenantSlug,
        moduleId,
        mutationId,
        body,
        user,
      });
    } catch (err) {
      if (err instanceof MutationInProgressError) {
        throw new ConflictException({
          error: 'Mutation in progress',
          mutation_id: mutationId,
        });
      }
      throw err;
    }
  }
}
