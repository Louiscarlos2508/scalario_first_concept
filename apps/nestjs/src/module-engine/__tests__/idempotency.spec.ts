import { IdempotencyService } from '../services/idempotency.service';
import type { Repository } from 'typeorm';
import type { SyncMutation } from '../entities/sync-mutation.entity';

describe('IdempotencyService', () => {
  let service: IdempotencyService;
  let repo: jest.Mocked<Repository<SyncMutation>>;

  const mockCtx = {
    tenantId: 'tenant-1',
    userId: 'user-1',
    moduleId: 'stock',
    action: 'creer_produit',
    payload: { name: 'Tomate', price: 1.5 },
  };

  beforeEach(() => {
    repo = {
      findOne: jest.fn(),
      query: jest.fn(),
    } as unknown as jest.Mocked<Repository<SyncMutation>>;

    service = new IdempotencyService(repo);
  });

  it('returns alreadyDone=false for new mutation', async () => {
    repo.findOne.mockResolvedValue(null);

    const result = await service.checkAndReserve('new-mutation-id', mockCtx);

    expect(result.alreadyDone).toBe(false);
    expect(result.previousResult).toBeNull();
    expect(repo.query).toHaveBeenCalled();
  });

  it('returns alreadyDone=true for already-successful mutation', async () => {
    repo.findOne.mockResolvedValue({
      client_mutation_id: 'existing-id',
      status: 'success',
      result: { id: 'entity-1' } as Record<string, unknown>,
    } as SyncMutation);

    const result = await service.checkAndReserve('existing-id', mockCtx);

    expect(result.alreadyDone).toBe(true);
    expect(result.previousResult).not.toBeNull();
  });

  it('throws ConflictException for pending mutation', async () => {
    repo.findOne.mockResolvedValue({
      client_mutation_id: 'pending-id',
      status: 'pending',
    } as SyncMutation);

    await expect(service.checkAndReserve('pending-id', mockCtx)).rejects.toThrow(
      'Mutation in progress',
    );
  });

  it('allows retry for error-status mutation', async () => {
    repo.findOne
      .mockResolvedValueOnce({
        client_mutation_id: 'error-id',
        status: 'error',
      } as SyncMutation)
      .mockResolvedValueOnce(null);

    const result = await service.checkAndReserve('error-id', mockCtx);

    expect(result.alreadyDone).toBe(false);
  });

  it('marks mutation as success', async () => {
    repo.query.mockResolvedValue([]);

    await service.markSuccess('mutation-1', { id: 'entity-1' });

    expect(repo.query).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE sync_mutations'),
      expect.arrayContaining([expect.any(String), 'mutation-1']),
    );
  });

  it('marks mutation as error', async () => {
    repo.query.mockResolvedValue([]);

    await service.markError('mutation-1');

    expect(repo.query).toHaveBeenCalledWith(
      expect.stringContaining('UPDATE sync_mutations'),
      expect.arrayContaining(['mutation-1']),
    );
  });
});
