import { UpdateTenantHandleSchema } from '../dto/update-handle.dto';
import { ProvisionTenantSchema } from '../dto/provision.dto';

describe('ProvisionTenantSchema — handle', () => {
  it('accepts valid provision without handle', () => {
    const result = ProvisionTenantSchema.safeParse({
      name: 'Blandine Shop',
      slug: 'blandine-shop',
      owner_email: 'blandine@example.com',
      owner_password: 'Secret123',
    });
    expect(result.success).toBe(true);
  });

  it('accepts valid provision with handle', () => {
    const result = ProvisionTenantSchema.safeParse({
      name: 'Blandine Shop',
      slug: 'blandine-shop',
      owner_email: 'blandine@example.com',
      owner_password: 'Secret123',
      handle: 'blandine-shop',
    });
    expect(result.success).toBe(true);
  });

  it('rejects handle with uppercase', () => {
    const result = ProvisionTenantSchema.safeParse({
      name: 'Blandine Shop',
      slug: 'blandine-shop',
      owner_email: 'blandine@example.com',
      owner_password: 'Secret123',
      handle: 'Blandine-Shop',
    });
    expect(result.success).toBe(false);
  });

  it('rejects handle too short (< 3)', () => {
    const result = ProvisionTenantSchema.safeParse({
      name: 'B',
      slug: 'b-shop',
      owner_email: 'b@example.com',
      owner_password: 'Secret123',
      handle: 'ab',
    });
    expect(result.success).toBe(false);
  });

  it('rejects handle too long (> 32)', () => {
    const result = ProvisionTenantSchema.safeParse({
      name: 'Blandine',
      slug: 'blandine-shop',
      owner_email: 'blandine@example.com',
      owner_password: 'Secret123',
      handle: 'a'.repeat(33),
    });
    expect(result.success).toBe(false);
  });

  it('rejects handle with special chars', () => {
    const result = ProvisionTenantSchema.safeParse({
      name: 'Blandine',
      slug: 'blandine-shop',
      owner_email: 'blandine@example.com',
      owner_password: 'Secret123',
      handle: 'blandine_shop',
    });
    expect(result.success).toBe(false);
  });
});

describe('UpdateTenantHandleSchema', () => {
  it('accepts valid handle', () => {
    const result = UpdateTenantHandleSchema.safeParse({ handle: 'nouveau-handle' });
    expect(result.success).toBe(true);
  });

  it('rejects missing handle', () => {
    const result = UpdateTenantHandleSchema.safeParse({});
    expect(result.success).toBe(false);
  });

  it('rejects empty handle', () => {
    const result = UpdateTenantHandleSchema.safeParse({ handle: '' });
    expect(result.success).toBe(false);
  });

  it('rejects handle with @ prefix (stored without @)', () => {
    const result = UpdateTenantHandleSchema.safeParse({ handle: '@blandine' });
    expect(result.success).toBe(false);
  });
});
