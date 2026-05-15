import { tenantContext, TenantContextMissingError } from '../../context/tenant-context';
import '../current-tenant.decorator';

describe('@CurrentTenant() factory (AC-15 / AC-16)', () => {
  it('returns tenant_id from AsyncLocalStorage', () => {
    let observed: string | undefined;
    tenantContext.run({ tenant_id: 'T1' }, () => {
      observed = tenantContext.getOrThrow().tenant_id;
    });
    expect(observed).toBe('T1');
  });

  it('throws TenantContextMissingError outside a tenant scope', () => {
    expect(() => tenantContext.getOrThrow()).toThrow(TenantContextMissingError);
  });
});
