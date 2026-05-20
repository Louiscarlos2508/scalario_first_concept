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
