import { ConfigMigrator } from '../config-migrator';

describe('ConfigMigrator', () => {
  const migrator = new ConfigMigrator();

  it('migrates from 1.0.0 to 1.1.0 adding variant: default', () => {
    const config = {
      schema_version: '1.0.0',
      modules: [{ type: 'KPICard', props: { label: 'test' } }],
    } as any;

    const result = migrator.migrate(config, '1.1.0');
    expect(result.schema_version).toBe('1.1.0');
    expect((result as any).modules[0].variant).toBe('default');
  });

  it('migrates from 1.0.0 to 1.2.0 in two steps', () => {
    const config = { schema_version: '1.0.0', modules: [] } as any;
    const result = migrator.migrate(config, '1.2.0');
    expect(result.schema_version).toBe('1.2.0');
  });

  it('throws on unknown migration path', () => {
    const config = { schema_version: '0.9.0' } as any;
    expect(() => migrator.migrate(config, '1.1.0')).toThrow();
  });
});
