import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, SelectQueryBuilder } from 'typeorm';
import { EntityRecord } from '../entities/entity.entity';
import { ModuleResolverService } from './module-resolver.service';
import type { GetDataQuery } from '../dto/get-data.dto';

export interface DataResponse {
  items: EntityRecord[];
  total: number;
  kpis?: Record<string, number>;
  meta: { page: number; limit: number };
}

export interface DataContext {
  tenantSlug: string;
  moduleId: string;
  query: GetDataQuery;
  userId: string;
}

@Injectable()
export class DataDispatcherService {
  private readonly logger = new Logger(DataDispatcherService.name);

  constructor(
    @InjectRepository(EntityRecord)
    private readonly repo: Repository<EntityRecord>,
    private readonly resolver: ModuleResolverService,
  ) {}

  async dispatch(ctx: DataContext): Promise<DataResponse> {
    const moduleConfig = await this.resolver.resolve(ctx.tenantSlug, ctx.moduleId);
    const page = ctx.query.page;
    const limit = ctx.query.limit;
    const offset = (page - 1) * limit;

    const qb = this.repo
      .createQueryBuilder('e')
      .where('e.tenant_id = :tenantId', { tenantId: ctx.tenantSlug })
      .andWhere('e.module_id = :moduleId', { moduleId: ctx.moduleId })
      .andWhere('e.status != :deleted', { deleted: 'deleted' });

    this.applyEntityTypeFilter(qb, moduleConfig);
    this.applyJsonFilters(qb, ctx.query.filters);
    this.applySort(qb, ctx.query.sort);

    const total = await qb.getCount();

    qb.skip(offset).take(limit);

    const items = await qb.getMany();

    const kpis = await this.computeKpis(qb, moduleConfig, ctx.tenantSlug, ctx.moduleId);

    return { items, total, kpis, meta: { page, limit } };
  }

  private applyEntityTypeFilter(
    qb: SelectQueryBuilder<EntityRecord>,
    config: { entities?: Array<{ name: string }> },
  ): void {
    const names = config.entities?.map((e) => e.name).filter(Boolean);
    if (names && names.length > 0) {
      qb.andWhere('e.entity_type IN (:...types)', { types: names });
    }
  }

  private applyJsonFilters(
    qb: SelectQueryBuilder<EntityRecord>,
    filtersRaw: string | undefined,
  ): void {
    if (!filtersRaw) return;

    let filters: Record<string, unknown>;
    try {
      filters = JSON.parse(filtersRaw) as Record<string, unknown>;
    } catch {
      this.logger.warn(`Invalid filters JSON: ${filtersRaw}`);
      return;
    }

    for (const [field, condition] of Object.entries(filters)) {
      if (condition !== null && typeof condition === 'object' && !Array.isArray(condition)) {
        const cond = condition as Record<string, unknown>;
        for (const [op, val] of Object.entries(cond)) {
          const paramKey = `f_${field}_${op}`.replace(/[^a-zA-Z0-9_]/g, '_');
          switch (op) {
            case '$eq':
              qb.andWhere(`e.data->>'${field}' = :${paramKey}`, { [paramKey]: String(val) });
              break;
            case '$ne':
              qb.andWhere(`e.data->>'${field}' != :${paramKey}`, { [paramKey]: String(val) });
              break;
            case '$gt':
              qb.andWhere(`(e.data->>'${field}')::numeric > :${paramKey}`, {
                [paramKey]: Number(val),
              });
              break;
            case '$gte':
              qb.andWhere(`(e.data->>'${field}')::numeric >= :${paramKey}`, {
                [paramKey]: Number(val),
              });
              break;
            case '$lt':
              qb.andWhere(`(e.data->>'${field}')::numeric < :${paramKey}`, {
                [paramKey]: Number(val),
              });
              break;
            case '$lte':
              qb.andWhere(`(e.data->>'${field}')::numeric <= :${paramKey}`, {
                [paramKey]: Number(val),
              });
              break;
            case '$in':
              if (Array.isArray(val)) {
                qb.andWhere(`e.data->>'${field}' IN (:...${paramKey})`, {
                  [paramKey]: val.map(String),
                });
              }
              break;
            case '$nin':
              if (Array.isArray(val)) {
                qb.andWhere(`e.data->>'${field}' NOT IN (:...${paramKey})`, {
                  [paramKey]: val.map(String),
                });
              }
              break;
            default:
              this.logger.warn(`Unknown filter operator: ${op}`);
          }
        }
      } else {
        qb.andWhere(`e.data @> :${field}_match`, { [`${field}_match`]: { [field]: condition } });
      }
    }
  }

  private applySort(qb: SelectQueryBuilder<EntityRecord>, sortRaw: string | undefined): void {
    if (!sortRaw) {
      qb.orderBy('e.created_at', 'DESC');
      return;
    }

    const parts = sortRaw.split(':');
    const field = parts[0];
    const dir = parts[1]?.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    qb.orderBy(`e.data->>'${field}'`, dir);
    qb.addOrderBy('e.created_at', 'DESC');
  }

  private async computeKpis(
    qb: SelectQueryBuilder<EntityRecord>,
    _config: Record<string, unknown>,
    _tenantId: string,
    moduleId: string,
  ): Promise<Record<string, number> | undefined> {
    const kpis: Record<string, number> = {};

    const countResult = await this.repo.count({
      where: {
        module_id: moduleId,
        status: 'active',
      },
    });
    kpis.total_active = countResult;

    return Object.keys(kpis).length > 0 ? kpis : undefined;
  }
}
