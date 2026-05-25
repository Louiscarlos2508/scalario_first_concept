import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EntityRecord } from '../entities/entity.entity';
import type { Handler, HandlerContext, HandlerResult } from '../interfaces/handler.interface';

/**
 * STORY-035 — payload field used for optimistic concurrency. The client
 * (Flutter Drift) records the server's `updated_at` when it last fetched
 * the entity; on update it sends that back as `base_updated_at`. If the
 * server's current `updated_at` is newer, there's a conflict.
 *
 * Modules can declare a `conflict_strategy` ("server_wins" | "client_wins"
 * | "manual") in their config. When set to "client_wins" the client
 * re-sends with `force: true`; that bypasses the optimistic check.
 */
const BASE_UPDATED_AT_KEY = 'base_updated_at';
const FORCE_KEY = 'force';

@Injectable()
export class CrudUpdateHandler implements Handler {
  readonly type = 'crud.update';

  constructor(
    @InjectRepository(EntityRecord)
    private readonly repo: Repository<EntityRecord>,
  ) {}

  async execute(ctx: HandlerContext): Promise<HandlerResult> {
    const entityType = ctx.actionDef.entity_type;
    if (!entityType) {
      throw new Error('crud.update handler requires entity_type in action definition');
    }

    const entityId = ctx.payload.id as string;
    if (!entityId) {
      throw new Error('crud.update handler requires payload.id');
    }

    const existing = await this.repo.findOne({
      where: { id: entityId, tenant_id: ctx.tenantId, entity_type: entityType },
    });

    if (!existing) {
      throw new NotFoundException(`Entity not found: ${entityId}`);
    }

    // AC-01: optimistic concurrency check.
    // The check is skipped when the client explicitly forces the write
    // (client_wins strategy after a prior 409) or when the payload has no
    // base_updated_at (legacy callers or create-then-update flows).
    const force = ctx.payload[FORCE_KEY] === true;
    const baseUpdatedAtRaw = ctx.payload[BASE_UPDATED_AT_KEY];
    if (!force && baseUpdatedAtRaw) {
      const baseUpdatedAt = new Date(baseUpdatedAtRaw as string);
      if (!isNaN(baseUpdatedAt.getTime()) && existing.updated_at > baseUpdatedAt) {
        const conflictStrategy =
          (ctx.moduleConfig?.conflict_strategy as string | undefined) ?? 'server_wins';
        throw new ConflictException({
          error: 'CONFLICT',
          message: `Entity '${entityId}' has been modified since base_updated_at.`,
          conflict_data: {
            server_state: { id: existing.id, ...existing.data, updated_at: existing.updated_at },
            client_state: ctx.payload,
            conflict_strategy: conflictStrategy,
          },
        });
      }
    }

    const mergeFields = ctx.actionDef.merge as Record<string, unknown> | undefined;

    // Strip control fields before merging into entity data.
    const { [BASE_UPDATED_AT_KEY]: _baseUpd, [FORCE_KEY]: _force, ...payloadData } =
      ctx.payload as Record<string, unknown>;
    void _baseUpd;
    void _force;

    existing.data = {
      ...existing.data,
      ...payloadData,
      ...(mergeFields ?? {}),
    };
    existing.version += 1;
    existing.updated_by = ctx.userId;

    const saved = await this.repo.save(existing);

    return {
      entity: { id: saved.id, ...saved.data } as Record<string, unknown>,
      data: {
        id: saved.id,
        entity_type: saved.entity_type,
        version: saved.version,
        updated_at: saved.updated_at.toISOString(),
      },
    };
  }
}
