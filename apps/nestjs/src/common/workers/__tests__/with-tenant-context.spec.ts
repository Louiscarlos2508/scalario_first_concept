import { tenantContext } from '../../context/tenant-context';
import { withTenantContext } from '../with-tenant-context';

describe('withTenantContext (AC-17)', () => {
  it('opens an AsyncLocalStorage scope readable by inner async code', async () => {
    let seen: string | undefined;
    await withTenantContext('tenant-Z', async () => {
      await Promise.resolve();
      seen = tenantContext.getOrThrow().tenant_id;
    });
    expect(seen).toBe('tenant-Z');
  });

  it('passes the inner return value through', async () => {
    const result = await withTenantContext('t1', async () => 42);
    expect(result).toBe(42);
  });

  it('isolates sibling jobs — each sees its own tenant_id', async () => {
    const observed: Array<{ want: string; got: string }> = [];
    await Promise.all(
      ['A', 'B', 'C', 'D'].map((want) =>
        withTenantContext(want, async () => {
          await new Promise<void>((resolve) => setImmediate(resolve));
          observed.push({ want, got: tenantContext.getOrThrow().tenant_id });
        }),
      ),
    );
    for (const o of observed) expect(o.got).toBe(o.want);
  });
});
