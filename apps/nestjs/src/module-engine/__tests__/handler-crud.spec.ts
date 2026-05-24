/* eslint-disable @typescript-eslint/no-explicit-any */
import { CrudCreateHandler } from '../handlers/crud-create.handler';
import { CrudUpdateHandler } from '../handlers/crud-update.handler';
import { CrudDeleteHandler } from '../handlers/crud-delete.handler';
import { HandlerRegistry } from '../handlers/handler-registry';
import type { Repository } from 'typeorm';
import type { EntityRecord } from '../entities/entity.entity';
import type { HandlerContext } from '../interfaces/handler.interface';

describe('CRUD Handlers', () => {
  let repo: jest.Mocked<Pick<Repository<EntityRecord>, 'create' | 'save' | 'findOne'>>;

  const mockCtx: HandlerContext = {
    tenantId: 'tenant-1',
    userId: 'user-1',
    moduleConfig: { id: 'stock', entities: [{ name: 'produit' }] },
    actionDef: { handler: 'crud.create', entity_type: 'produit' },
    payload: { name: 'Tomate', price: 1.5, category: 'legume' },
  };

  beforeEach(() => {
    repo = {
      create: jest.fn().mockReturnValue({} as any),
      save: jest.fn().mockResolvedValue({} as any),
      findOne: jest.fn().mockResolvedValue({} as any),
    } as any;
  });

  describe('CrudCreateHandler', () => {
    it('creates a new entity record', async () => {
      repo.create.mockReturnValue({
        id: 'new-id',
        entity_type: 'produit',
        data: mockCtx.payload,
      } as any);
      repo.save.mockResolvedValue({
        id: 'new-id',
        entity_type: 'produit',
        data: mockCtx.payload as Record<string, unknown>,
        created_at: new Date(),
      } as any);

      const handler = new CrudCreateHandler(repo as any);
      const result = await handler.execute(mockCtx);

      expect(result.entity).toBeDefined();
      expect(result.data).toHaveProperty('id', 'new-id');
      expect(repo.create).toHaveBeenCalled();
      expect(repo.save).toHaveBeenCalled();
    });

    it('throws if entity_type is missing', async () => {
      const handler = new CrudCreateHandler(repo as any);
      await expect(
        handler.execute({ ...mockCtx, actionDef: { handler: 'crud.create' } }),
      ).rejects.toThrow('crud.create handler requires entity_type');
    });
  });

  describe('CrudUpdateHandler', () => {
    it('updates an existing entity', async () => {
      repo.findOne.mockResolvedValue({
        id: 'entity-1',
        data: { name: 'Old Name', price: 1.0 },
        version: 1,
        updated_at: new Date(),
      } as any);
      repo.save.mockResolvedValue({
        id: 'entity-1',
        data: { name: 'New Name', price: 2.0 },
        version: 2,
        entity_type: 'produit',
        updated_at: new Date(),
      } as any);

      const handler = new CrudUpdateHandler(repo as any);
      const result = await handler.execute({
        ...mockCtx,
        actionDef: { handler: 'crud.update', entity_type: 'produit' },
        payload: { id: 'entity-1', name: 'New Name', price: 2.0 },
      });

      expect(result.data).toHaveProperty('version', 2);
      expect(repo.findOne).toHaveBeenCalled();
      expect(repo.save).toHaveBeenCalled();
    });

    it('throws if entity not found', async () => {
      repo.findOne.mockResolvedValue(null);

      const handler = new CrudUpdateHandler(repo as any);
      await expect(
        handler.execute({
          ...mockCtx,
          actionDef: { handler: 'crud.update', entity_type: 'produit' },
          payload: { id: 'nonexistent' },
        }),
      ).rejects.toThrow('Entity not found');
    });

    describe('STORY-035 — optimistic concurrency (base_updated_at)', () => {
      const entityNow = new Date('2026-05-24T10:00:00Z');
      const olderBase = new Date('2026-05-24T09:00:00Z');

      it('AC-01 — 409 ConflictException when entity.updated_at > base_updated_at', async () => {
        repo.findOne.mockResolvedValue({
          id: 'entity-1',
          data: { name: 'Server Name', price: 5.0 },
          version: 2,
          updated_at: entityNow,
        } as any);

        const handler = new CrudUpdateHandler(repo as any);
        await expect(
          handler.execute({
            ...mockCtx,
            moduleConfig: { id: 'stock', entities: [], conflict_strategy: 'manual' },
            actionDef: { handler: 'crud.update', entity_type: 'produit' },
            payload: {
              id: 'entity-1',
              name: 'Client Name',
              price: 3.0,
              base_updated_at: olderBase.toISOString(),
            },
          }),
        ).rejects.toMatchObject({
          status: 409,
          response: expect.objectContaining({
            error: 'CONFLICT',
            conflict_data: expect.objectContaining({
              server_state: expect.objectContaining({ name: 'Server Name' }),
              client_state: expect.objectContaining({ name: 'Client Name' }),
              conflict_strategy: 'manual',
            }),
          }),
        });
        // Conflict means save() must NOT have been called.
        expect(repo.save).not.toHaveBeenCalled();
      });

      it('AC-02 — defaults to server_wins when moduleConfig has no conflict_strategy', async () => {
        repo.findOne.mockResolvedValue({
          id: 'entity-1',
          data: {},
          version: 1,
          updated_at: entityNow,
        } as any);

        const handler = new CrudUpdateHandler(repo as any);
        await expect(
          handler.execute({
            ...mockCtx,
            moduleConfig: { id: 'stock', entities: [] }, // no conflict_strategy
            actionDef: { handler: 'crud.update', entity_type: 'produit' },
            payload: { id: 'entity-1', base_updated_at: olderBase.toISOString() },
          }),
        ).rejects.toMatchObject({
          response: expect.objectContaining({
            conflict_data: expect.objectContaining({ conflict_strategy: 'server_wins' }),
          }),
        });
      });

      it('AC-08 — force: true bypasses the optimistic check (client_wins replay)', async () => {
        repo.findOne.mockResolvedValue({
          id: 'entity-1',
          data: { name: 'Server' },
          version: 2,
          updated_at: entityNow,
        } as any);
        repo.save.mockResolvedValue({
          id: 'entity-1',
          data: { name: 'Client' },
          version: 3,
          entity_type: 'produit',
          updated_at: new Date(),
        } as any);

        const handler = new CrudUpdateHandler(repo as any);
        const result = await handler.execute({
          ...mockCtx,
          actionDef: { handler: 'crud.update', entity_type: 'produit' },
          payload: {
            id: 'entity-1',
            name: 'Client',
            force: true,
            base_updated_at: olderBase.toISOString(),
          },
        });
        expect(result.data).toHaveProperty('version', 3);
        expect(repo.save).toHaveBeenCalled();
      });

      it('no conflict when base_updated_at == entity.updated_at (exact match)', async () => {
        const sameTs = new Date('2026-05-24T09:00:00Z');
        repo.findOne.mockResolvedValue({
          id: 'entity-1',
          data: {},
          version: 1,
          updated_at: sameTs,
        } as any);
        repo.save.mockResolvedValue({
          id: 'entity-1',
          data: {},
          version: 2,
          entity_type: 'produit',
          updated_at: new Date(),
        } as any);

        const handler = new CrudUpdateHandler(repo as any);
        await expect(
          handler.execute({
            ...mockCtx,
            actionDef: { handler: 'crud.update', entity_type: 'produit' },
            payload: { id: 'entity-1', base_updated_at: sameTs.toISOString() },
          }),
        ).resolves.toBeDefined();
      });

      it('strips base_updated_at + force control fields before merging into entity data', async () => {
        repo.findOne.mockResolvedValue({
          id: 'entity-1',
          data: { existing: 'value' },
          version: 1,
          updated_at: entityNow,
        } as any);
        repo.save.mockImplementation(async (e: any) => e);

        const handler = new CrudUpdateHandler(repo as any);
        await handler.execute({
          ...mockCtx,
          actionDef: { handler: 'crud.update', entity_type: 'produit' },
          payload: {
            id: 'entity-1',
            name: 'New',
            force: true,
            base_updated_at: olderBase.toISOString(),
          },
        });

        const saved = repo.save.mock.calls[0][0] as any;
        expect(saved.data).not.toHaveProperty('base_updated_at');
        expect(saved.data).not.toHaveProperty('force');
        expect(saved.data).toMatchObject({ existing: 'value', name: 'New' });
      });
    });
  });

  describe('CrudDeleteHandler', () => {
    it('soft-deletes an entity', async () => {
      repo.findOne.mockResolvedValue({
        id: 'entity-1',
        status: 'active',
      } as any);
      repo.save.mockResolvedValue({
        id: 'entity-1',
        status: 'deleted',
      } as any);

      const handler = new CrudDeleteHandler(repo as any);
      const result = await handler.execute({
        ...mockCtx,
        actionDef: { handler: 'crud.delete', entity_type: 'produit' },
        payload: { id: 'entity-1' },
      });

      expect(result.data).toHaveProperty('status', 'deleted');
    });

    it('throws if entity not found', async () => {
      repo.findOne.mockResolvedValue(null);

      const handler = new CrudDeleteHandler(repo as any);
      await expect(
        handler.execute({
          ...mockCtx,
          actionDef: { handler: 'crud.delete', entity_type: 'produit' },
          payload: { id: 'nonexistent' },
        }),
      ).rejects.toThrow('Entity not found');
    });
  });

  describe('HandlerRegistry', () => {
    it('registers and retrieves handlers', () => {
      const registry = new HandlerRegistry();
      const createHandler = new CrudCreateHandler(repo as any);

      registry.register(createHandler);

      expect(registry.get('crud.create')).toBe(createHandler);
      expect(registry.get('nonexistent')).toBeUndefined();
    });
  });
});
