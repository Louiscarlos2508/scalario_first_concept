/* eslint-disable @typescript-eslint/no-explicit-any */
import {
  ActionDispatcherService,
  type ActionResponse,
} from '../services/action-dispatcher.service';
import { ModuleResolverService } from '../services/module-resolver.service';
import { IdempotencyService } from '../services/idempotency.service';
import { HandlerRegistry } from '../handlers/handler-registry';
import { AuditLogService } from '../../audit/services/audit-log.service';
import { WorkflowResponseMapper } from '../workflow-response.mapper';
import { CrudCreateHandler } from '../handlers/crud-create.handler';
import type { Repository } from 'typeorm';
import type { EntityRecord } from '../entities/entity.entity';
import type { AuthenticatedUser } from '../../auth/interfaces/jwt-payload.interface';

describe('ActionDispatcherService', () => {
  let service: ActionDispatcherService;
  let resolver: jest.Mocked<ModuleResolverService>;
  let idempotency: jest.Mocked<IdempotencyService>;
  let audit: jest.Mocked<AuditLogService>;
  let handlerRegistry: HandlerRegistry;
  let entityRepo: jest.Mocked<Pick<Repository<EntityRecord>, 'create' | 'save' | 'findOne'>>;

  const mockUser: AuthenticatedUser = {
    user_id: 'user-1',
    tenant_id: 'acme',
    roles: ['OWNER'],
    department_id: null,
    jti: 'jti-1',
    exp: 9999999999,
  };

  const mockModuleConfig = {
    id: 'stock',
    schema_version: '1.0.0',
    name: 'Gestion Stock',
    entities: [{ name: 'produit' }],
    actions: {
      creer_produit: {
        handler: 'crud.create',
        entity_type: 'produit',
      },
    },
    rbac_roles: ['OWNER', 'MANAGER'],
    abac_rules: [],
    conflict_strategy: 'server_wins',
  };

  beforeEach(() => {
    entityRepo = {
      create: jest.fn().mockReturnValue({} as any),
      save: jest.fn().mockResolvedValue({} as any),
      findOne: jest.fn(),
    } as any;

    handlerRegistry = new HandlerRegistry();
    handlerRegistry.register(new CrudCreateHandler(entityRepo as any));

    resolver = {
      resolve: jest.fn().mockResolvedValue(mockModuleConfig),
      invalidate: jest.fn(),
    } as any;

    idempotency = {
      checkAndReserve: jest.fn(),
      markSuccess: jest.fn(),
      markError: jest.fn(),
    } as any;

    audit = {
      log: jest.fn().mockResolvedValue(undefined),
    } as any;

    service = new ActionDispatcherService(
      resolver,
      handlerRegistry,
      idempotency,
      audit,
      new WorkflowResponseMapper(),
      undefined,
      undefined,
      undefined,
    );
  });

  it('returns 422 for unknown action', async () => {
    await expect(
      service.dispatch({
        tenantSlug: 'acme',
        moduleId: 'stock',
        mutationId: 'mutation-1',
        body: { action: 'unknown_action', payload: {} },
        user: mockUser,
      }),
    ).rejects.toThrow('Unprocessable');
  });

  it('returns cached result for idempotent request', async () => {
    idempotency.checkAndReserve.mockResolvedValue({
      alreadyDone: true,
      previousResult: { result: { id: 'entity-1' }, mutation_id: 'mutation-1' },
    });

    const result = (await service.dispatch({
      tenantSlug: 'acme',
      moduleId: 'stock',
      mutationId: 'mutation-1',
      body: { action: 'creer_produit', payload: { name: 'Tomate' } },
      user: mockUser,
    })) as ActionResponse;

    expect(result.result).toEqual({ id: 'entity-1' });
  });

  it('executes valid action and returns result', async () => {
    idempotency.checkAndReserve.mockResolvedValue({
      alreadyDone: false,
      previousResult: null,
    });

    entityRepo.create.mockReturnValue({ id: 'new-entity' } as any);
    entityRepo.save.mockResolvedValue({
      id: 'new-entity',
      entity_type: 'produit',
      data: { name: 'Tomate' },
      created_at: new Date(),
    } as any);

    const result = (await service.dispatch({
      tenantSlug: 'acme',
      moduleId: 'stock',
      mutationId: 'mutation-2',
      body: { action: 'creer_produit', payload: { name: 'Tomate' } },
      user: mockUser,
    })) as ActionResponse;

    expect(result.entity).toBeDefined();
    expect(result.mutation_id).toBe('mutation-2');
    expect(audit.log).toHaveBeenCalled();
  });

  it('marks error and rethrows on handler failure', async () => {
    idempotency.checkAndReserve.mockResolvedValue({
      alreadyDone: false,
      previousResult: null,
    });

    entityRepo.create.mockReturnValue({} as any);
    entityRepo.save.mockRejectedValue(new Error('DB error'));

    await expect(
      service.dispatch({
        tenantSlug: 'acme',
        moduleId: 'stock',
        mutationId: 'mutation-3',
        body: { action: 'creer_produit', payload: { name: 'Tomate' } },
        user: mockUser,
      }),
    ).rejects.toThrow('DB error');

    expect(idempotency.markError).toHaveBeenCalledWith('mutation-3');
  });
});
