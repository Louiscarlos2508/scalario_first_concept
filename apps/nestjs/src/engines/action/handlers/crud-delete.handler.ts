import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EntityRecord } from '../entities/entity.entity';
import type { Handler, HandlerContext, HandlerResult } from '../interfaces/handler.interface';

@Injectable()
export class CrudDeleteHandler implements Handler {
  readonly type = 'crud.delete';

  constructor(
    @InjectRepository(EntityRecord)
    private readonly repo: Repository<EntityRecord>,
  ) {}

  async execute(ctx: HandlerContext): Promise<HandlerResult> {
    const entityType = ctx.actionDef.entity_type;
    if (!entityType) {
      throw new Error('crud.delete handler requires entity_type in action definition');
    }

    const entityId = ctx.payload.id as string;
    if (!entityId) {
      throw new Error('crud.delete handler requires payload.id');
    }

    const existing = await this.repo.findOne({
      where: { id: entityId, tenant_id: ctx.tenantId, entity_type: entityType },
    });

    if (!existing) {
      throw new NotFoundException(`Entity not found: ${entityId}`);
    }

    existing.status = 'deleted';
    existing.updated_by = ctx.userId;
    await this.repo.save(existing);

    return {
      entity: { id: entityId },
      data: { id: entityId, status: 'deleted' },
    };
  }
}
