/* eslint-disable @typescript-eslint/no-explicit-any */
import { DataDispatcherService } from '../services/data-dispatcher.service';
import { ModuleResolverService } from '../services/module-resolver.service';
import type { Repository } from 'typeorm';
import type { EntityRecord } from '../entities/entity.entity';
import type { ModuleConfig } from '../../../catalog-loader/validators/module-config.zod';

describe('DataDispatcherService', () => {
  let service: DataDispatcherService;
  let repo: jest.Mocked<Pick<Repository<EntityRecord>, 'createQueryBuilder' | 'count'>>;
  let resolver: jest.Mocked<ModuleResolverService>;

  const mockModuleConfig: ModuleConfig = {
    id: 'stock',
    schema_version: '1.0.0',
    name: 'Gestion Stock',
    entities: [{ name: 'produit' }],
    rbac_roles: [],
    abac_rules: [],
    conflict_strategy: 'server_wins',
  };

  function makeQueryBuilder(overrides?: Record<string, any>) {
    return {
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      skip: jest.fn().mockReturnThis(),
      take: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      addOrderBy: jest.fn().mockReturnThis(),
      getCount: jest.fn().mockResolvedValue(10),
      getMany: jest.fn().mockResolvedValue([
        {
          id: '1',
          data: { name: 'Tomate', price: 1.5 },
          entity_type: 'produit',
          module_id: 'stock',
        },
      ]),
      ...overrides,
    } as any;
  }

  beforeEach(() => {
    repo = {
      createQueryBuilder: jest.fn().mockReturnValue(makeQueryBuilder()),
      count: jest.fn().mockResolvedValue(5),
    } as any;

    resolver = {
      resolve: jest.fn().mockResolvedValue(mockModuleConfig),
    } as any;

    service = new DataDispatcherService(repo as any, resolver);
  });

  it('returns paginated data for a valid module', async () => {
    const result = await service.dispatch({
      tenantSlug: 'acme',
      moduleId: 'stock',
      query: { page: 1, limit: 50 },
      userId: 'u1',
    });

    expect(result.items).toHaveLength(1);
    expect(result.total).toBe(10);
    expect(result.meta).toEqual({ page: 1, limit: 50 });
    expect(result.kpis).toBeDefined();
  });

  it('applies JSON filters when provided', async () => {
    const qb = makeQueryBuilder({
      getCount: jest.fn().mockResolvedValue(0),
      getMany: jest.fn().mockResolvedValue([]),
    });

    repo.createQueryBuilder.mockReturnValue(qb);

    await service.dispatch({
      tenantSlug: 'acme',
      moduleId: 'stock',
      query: { page: 1, limit: 50, filters: JSON.stringify({ status: { $eq: 'low' } }) },
      userId: 'u1',
    });

    expect(qb.andWhere).toHaveBeenCalled();
  });

  it('returns 404 for unknown module', async () => {
    resolver.resolve.mockRejectedValue(new Error('Module not found: unknown'));

    await expect(
      service.dispatch({
        tenantSlug: 'acme',
        moduleId: 'unknown',
        query: { page: 1, limit: 50 },
        userId: 'u1',
      }),
    ).rejects.toThrow('Module not found: unknown');
  });
});
