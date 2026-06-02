import {
  Controller,
  Post,
  Param,
  Body,
  UseGuards,
  Logger,
  ConflictException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import {
  ActionDispatcherService,
  type ActionResponse,
} from '../engines/action/services/action-dispatcher.service';
import { MutationInProgressError } from '../engines/action/services/idempotency.service';
import type { AuthenticatedUser } from '../core/auth/interfaces/jwt-payload.interface';
import {
  SyncMutationsBatchSchema,
  SyncMutationsBatch,
  SyncBatchResponse,
  SyncResultItem,
} from './dto/sync-mutations.dto';

@Controller(':tenant/sync')
@UseGuards(AuthGuard('jwt'))
export class SyncController {
  private readonly logger = new Logger(SyncController.name);

  constructor(private readonly actionDispatcher: ActionDispatcherService) {}

  @Post('mutations')
  @Roles('OWNER', 'MANAGER')
  async postMutations(
    @Param('tenant') tenant: string,
    @Body(new ZodValidationPipe(SyncMutationsBatchSchema)) body: SyncMutationsBatch,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SyncBatchResponse> {
    if (tenant !== user.tenant_id) {
      throw new UnprocessableEntityException({
        error: 'Cross-tenant access denied',
        tenant,
      });
    }

    const results: SyncResultItem[] = [];

    for (const mutation of body.mutations) {
      // Workflow actions (start_workflow, transition_workflow) require synchronous
      // request/response semantics (the client needs current_state + available_transitions
      // to render the next step). The bulk sync endpoint is FIFO-drain for offline CRUD
      // mutations only; mixing the two would silently truncate the workflow response.
      if (mutation.action === 'start_workflow' || mutation.action === 'transition_workflow') {
        results.push({
          mutation_id: mutation.mutation_id,
          status: 'error',
          error: 'WORKFLOW_ACTION_NOT_SUPPORTED_IN_BULK_SYNC',
        });
        continue;
      }

      try {
        const response = (await this.actionDispatcher.dispatch({
          tenantSlug: tenant,
          moduleId: mutation.module_id,
          mutationId: mutation.mutation_id,
          body: {
            action: mutation.action,
            payload: mutation.payload,
          },
          user: {
            user_id: user.user_id,
            tenant_id: user.tenant_id,
            roles: user.roles,
            department_id: user.department_id,
            jti: user.jti,
            exp: user.exp,
          },
        })) as ActionResponse;

        results.push({
          mutation_id: mutation.mutation_id,
          status: 'success',
          entity: response.entity,
        });
      } catch (err) {
        if (err instanceof ConflictException || err instanceof MutationInProgressError) {
          results.push({
            mutation_id: mutation.mutation_id,
            status: 'conflict',
            error: err.message,
          });
        } else {
          const message = err instanceof Error ? err.message : 'Unknown error';
          results.push({
            mutation_id: mutation.mutation_id,
            status: 'error',
            error: message,
          });
          this.logger.warn(
            `Sync mutation ${mutation.mutation_id} (${mutation.module_id}/${mutation.action}) failed: ${message}`,
          );
        }
      }
    }

    return { results };
  }
}
