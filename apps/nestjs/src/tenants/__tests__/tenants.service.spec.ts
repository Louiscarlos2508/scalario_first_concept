import { TenantsService } from '../tenants.service';

describe('TenantsService cache (AC-08)', () => {
  let repo: { findOne: jest.Mock };
  let svc: TenantsService;

  beforeEach(() => {
    repo = { findOne: jest.fn() };
    svc = new TenantsService(repo as never);
  });

  it('returns the id when active, null when not', async () => {
    repo.findOne.mockResolvedValueOnce({ id: 'A', is_active: true });
    expect(await svc.getActive('A')).toBe('A');

    repo.findOne.mockResolvedValueOnce({ id: 'B', is_active: false });
    expect(await svc.getActive('B')).toBeNull();

    repo.findOne.mockResolvedValueOnce(null);
    expect(await svc.getActive('C')).toBeNull();
  });

  it('caches subsequent reads (single DB hit per id)', async () => {
    repo.findOne.mockResolvedValueOnce({ id: 'A', is_active: true });
    await svc.getActive('A');
    await svc.getActive('A');
    await svc.getActive('A');
    expect(repo.findOne).toHaveBeenCalledTimes(1);
  });

  it('invalidate() forces re-read on next call', async () => {
    repo.findOne
      .mockResolvedValueOnce({ id: 'A', is_active: true })
      .mockResolvedValueOnce({ id: 'A', is_active: false });
    expect(await svc.getActive('A')).toBe('A');
    svc.invalidate('A');
    expect(await svc.getActive('A')).toBeNull();
    expect(repo.findOne).toHaveBeenCalledTimes(2);
  });
});
