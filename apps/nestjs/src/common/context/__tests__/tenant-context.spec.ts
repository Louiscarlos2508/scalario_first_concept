import { tenantContext, TenantContextMissingError } from '../tenant-context';

describe('tenantContext (AsyncLocalStorage)', () => {
  it('AC-01 — exposes run / get / getOrThrow', () => {
    expect(typeof tenantContext.run).toBe('function');
    expect(typeof tenantContext.get).toBe('function');
    expect(typeof tenantContext.getOrThrow).toBe('function');
  });

  it('AC-02 — propagates tenant_id through async stack', async () => {
    await tenantContext.run({ tenant_id: 'A' }, async () => {
      await Promise.resolve();
      expect(tenantContext.get()?.tenant_id).toBe('A');
    });
  });

  it('AC-03 — concurrent runs keep their own context (100 parallel)', async () => {
    const observed: string[] = [];
    const tasks: Array<Promise<void>> = [];
    for (let i = 0; i < 100; i += 1) {
      const tenant = i % 2 === 0 ? 'A' : 'B';
      tasks.push(
        tenantContext.run({ tenant_id: tenant }, async () => {
          // Random microtask jitter to interleave the call stacks.
          await new Promise<void>((resolve) => setImmediate(resolve));
          observed.push(tenantContext.getOrThrow().tenant_id);
        }),
      );
    }
    await Promise.all(tasks);
    expect(observed).toHaveLength(100);
    expect(observed.filter((t) => t === 'A')).toHaveLength(50);
    expect(observed.filter((t) => t === 'B')).toHaveLength(50);
  });

  it('AC-04 — getOrThrow outside any run throws TenantContextMissingError', () => {
    expect(() => tenantContext.getOrThrow()).toThrow(TenantContextMissingError);
  });

  it('get() returns undefined outside any run', () => {
    expect(tenantContext.get()).toBeUndefined();
  });
});
