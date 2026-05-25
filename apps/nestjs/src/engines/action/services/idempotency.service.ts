import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SyncMutation } from '../entities/sync-mutation.entity';

export interface IdempotencyCheckResult {
  alreadyDone: boolean;
  previousResult: {
    entity?: Record<string, unknown>;
    result: Record<string, unknown>;
    mutation_id: string;
  } | null;
}

export interface MutationContext {
  tenantId: string;
  userId: string;
  moduleId: string;
  action: string;
  payload: Record<string, unknown>;
}

@Injectable()
export class IdempotencyService {
  private readonly logger = new Logger(IdempotencyService.name);

  constructor(
    @InjectRepository(SyncMutation)
    private readonly repo: Repository<SyncMutation>,
  ) {}

  async checkAndReserve(mutationId: string, ctx: MutationContext): Promise<IdempotencyCheckResult> {
    const existing = await this.repo.findOne({
      where: { client_mutation_id: mutationId as unknown as undefined },
    });
    if (existing) {
      if (existing.status === 'success') {
        return {
          alreadyDone: true,
          previousResult: {
            entity: (existing.result?.entity as Record<string, unknown>) ?? undefined,
            result: existing.result as Record<string, unknown>,
            mutation_id: mutationId,
          },
        };
      }
      if (existing.status === 'pending') {
        throw new MutationInProgressError(mutationId);
      }
      if (existing.status === 'error') {
        return { alreadyDone: false, previousResult: null };
      }
      return { alreadyDone: false, previousResult: null };
    }

    await this.repo.query(
      `INSERT INTO sync_mutations (client_mutation_id, tenant_id, user_id, module_id, action, payload, status) VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5, $6::jsonb, 'pending')`,
      [mutationId, ctx.tenantId, ctx.userId, ctx.moduleId, ctx.action, JSON.stringify(ctx.payload)],
    );

    return { alreadyDone: false, previousResult: null };
  }

  async markSuccess(mutationId: string, result: Record<string, unknown>): Promise<void> {
    await this.repo.query(
      `UPDATE sync_mutations SET status = 'success', result = $1::jsonb, processed_at = NOW() WHERE client_mutation_id = $2::uuid`,
      [JSON.stringify(result), mutationId],
    );
  }

  async markError(mutationId: string): Promise<void> {
    await this.repo.query(
      `UPDATE sync_mutations SET status = 'error', processed_at = NOW() WHERE client_mutation_id = $1::uuid`,
      [mutationId],
    );
  }
}

export class MutationInProgressError extends Error {
  constructor(mutationId: string) {
    super(`Mutation in progress: ${mutationId}`);
    this.name = 'MutationInProgressError';
  }
}
