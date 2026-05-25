import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EntityRecord } from '../entities/entity.entity';
import type { Handler, HandlerContext, HandlerResult } from '../interfaces/handler.interface';

@Injectable()
export class CrudCreateHandler implements Handler {
  readonly type = 'crud.create';

  constructor(
    @InjectRepository(EntityRecord)
    private readonly repo: Repository<EntityRecord>,
  ) {}

  async execute(ctx: HandlerContext): Promise<HandlerResult> {
    const entityType = ctx.actionDef.entity_type;
    if (!entityType) {
      throw new Error('crud.create handler requires entity_type in action definition');
    }

    const record = this.repo.create({
      tenant_id: ctx.tenantId,
      module_id: ctx.moduleConfig.id,
      entity_type: entityType,
      data: ctx.payload,
      created_by: ctx.userId,
      updated_by: ctx.userId,
    });

    const saved = await this.repo.save(record);

    return {
      entity: { id: saved.id, ...saved.data } as Record<string, unknown>,
      data: {
        id: saved.id,
        entity_type: saved.entity_type,
        created_at: saved.created_at.toISOString(),
      },
    };
  }
}
