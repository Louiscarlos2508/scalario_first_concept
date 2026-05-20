import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EntityRecord } from '../entities/entity.entity';
import type { Handler, HandlerContext, HandlerResult } from '../interfaces/handler.interface';

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

    const mergeFields = ctx.actionDef.merge as Record<string, unknown> | undefined;

    existing.data = {
      ...existing.data,
      ...(ctx.payload as Record<string, unknown>),
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
