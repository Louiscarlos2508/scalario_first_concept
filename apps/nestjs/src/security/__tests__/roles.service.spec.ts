import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import type { Repository } from 'typeorm';
import { Tenant } from '../../auth/entities/tenant.entity';
import { RolesService } from '../services/roles.service';

describe('RolesService', () => {
  let service: RolesService;
  let repo: jest.Mocked<Pick<Repository<Tenant>, 'findOne' | 'update'>>;

  const TENANT: Tenant = {
    id: 't1',
    name: 'Acme',
    slug: 'acme',
    is_active: true,
    config: { roles: ['OWNER', 'MANAGER', 'COMMERCIAL'] },
    created_at: new Date(),
    updated_at: new Date(),
  };

  beforeEach(async () => {
    repo = {
      findOne: jest.fn(),
      update: jest.fn(),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [RolesService, { provide: getRepositoryToken(Tenant), useValue: repo }],
    }).compile();
    service = moduleRef.get(RolesService);
  });

  it('returns roles from tenant.config and caches the result', async () => {
    repo.findOne.mockResolvedValue(TENANT);

    const a = await service.getRolesForTenant('t1');
    const b = await service.getRolesForTenant('t1');

    expect(a).toEqual(['OWNER', 'MANAGER', 'COMMERCIAL']);
    expect(b).toEqual(a);
    expect(repo.findOne).toHaveBeenCalledTimes(1);
  });

  it('throws NotFound when tenant does not exist', async () => {
    repo.findOne.mockResolvedValue(null);
    await expect(service.getRolesForTenant('missing')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns empty array when tenant.config.roles is absent', async () => {
    repo.findOne.mockResolvedValue({ ...TENANT, config: {} });
    expect(await service.getRolesForTenant('t1')).toEqual([]);
  });

  it('invalidateCache() forces a re-fetch on next read', async () => {
    repo.findOne.mockResolvedValueOnce(TENANT);
    await service.getRolesForTenant('t1');

    repo.findOne.mockResolvedValueOnce({
      ...TENANT,
      config: { roles: ['OWNER', 'LIVREUR'] },
    });
    service.invalidateCache('t1');

    expect(await service.getRolesForTenant('t1')).toEqual(['OWNER', 'LIVREUR']);
    expect(repo.findOne).toHaveBeenCalledTimes(2);
  });

  it('setRolesForTenant persists and invalidates the cache', async () => {
    repo.findOne.mockResolvedValue(TENANT);
    await service.getRolesForTenant('t1'); // prime cache

    repo.update.mockResolvedValue({ affected: 1 } as never);
    const next = await service.setRolesForTenant('t1', ['OWNER', 'LIVREUR']);

    expect(next).toEqual(['OWNER', 'LIVREUR']);
    expect(repo.update).toHaveBeenCalledWith(
      { id: 't1' },
      { config: { roles: ['OWNER', 'LIVREUR'] } },
    );

    // Re-read forces a DB hit because the cache was invalidated.
    repo.findOne.mockResolvedValueOnce({
      ...TENANT,
      config: { roles: ['OWNER', 'LIVREUR'] },
    });
    expect(await service.getRolesForTenant('t1')).toEqual(['OWNER', 'LIVREUR']);
  });
});
