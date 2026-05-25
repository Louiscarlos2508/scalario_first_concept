import type { TenantConfig } from '../../../auth/entities/tenant.entity';
import { CaslAbacEngine } from '../engines/casl.engine';
import { AbacRuleParseError, AbacRuleSubstitutionError } from '../errors';
import type { AbacUser } from '../types';

const engine = new CaslAbacEngine();

function user(overrides: Partial<AbacUser> = {}): AbacUser {
  return {
    user_id: 'u-1',
    tenant_id: 't-1',
    roles: ['MANAGER'],
    department_id: 'dept-A',
    ...overrides,
  };
}

function configWithRules(rules: unknown[]): TenantConfig {
  return { roles: ['OWNER', 'MANAGER'], abac_rules: rules as never } as TenantConfig;
}

describe('CaslAbacEngine.buildAbility', () => {
  it('permissive default when no rules apply (AC-04)', () => {
    const ability = engine.buildAbility(user(), configWithRules([]));
    expect(ability.can('read', 'Invoice')).toBe(true);
    expect(ability.can('delete', 'Sale')).toBe(true);
  });

  it('permissive when rules exist but none match user roles', () => {
    const ability = engine.buildAbility(
      user({ roles: ['COMMERCIAL'] }),
      configWithRules([{ action: 'read', subject: 'Invoice', roles: ['MANAGER'] }]),
    );
    expect(ability.can('read', 'Invoice')).toBe(true);
  });

  it('grants matching rule with substituted conditions', () => {
    const ability = engine.buildAbility(
      user(),
      configWithRules([
        {
          action: 'read',
          subject: 'Invoice',
          roles: ['MANAGER'],
          conditions: {
            department_id: '$user.department_id',
            amount: { $lt: 500000 },
          },
        },
      ]),
    );
    expect(ability.can('read', 'Invoice')).toBe(true);
    expect(
      ability.can('read', {
        __type: 'Invoice',
        department_id: 'dept-A',
        amount: 100_000,
      } as never),
    ).toBe(true);
    expect(
      ability.can('read', {
        __type: 'Invoice',
        department_id: 'dept-B',
        amount: 100_000,
      } as never),
    ).toBe(false);
    expect(
      ability.can('read', {
        __type: 'Invoice',
        department_id: 'dept-A',
        amount: 700_000,
      } as never),
    ).toBe(false);
  });

  it('denies actions not granted by any rule', () => {
    const ability = engine.buildAbility(
      user(),
      configWithRules([{ action: 'read', subject: 'Invoice', roles: ['MANAGER'] }]),
    );
    expect(ability.can('delete', 'Invoice')).toBe(false);
  });

  it('honours inverted rule (cannot overrides can)', () => {
    const ability = engine.buildAbility(
      user(),
      configWithRules([
        { action: 'read', subject: 'Invoice', roles: ['MANAGER'] },
        {
          action: 'read',
          subject: 'Invoice',
          roles: ['MANAGER'],
          inverted: true,
          conditions: { status: 'archived' },
        },
      ]),
    );
    expect(ability.can('read', { __type: 'Invoice', status: 'open' } as never)).toBe(true);
    expect(ability.can('read', { __type: 'Invoice', status: 'archived' } as never)).toBe(false);
  });

  it('throws AbacRuleParseError on malformed rule', () => {
    expect(() =>
      engine.buildAbility(user(), configWithRules([{ subject: 'Invoice', roles: ['MANAGER'] }])),
    ).toThrow(AbacRuleParseError);
  });

  it('throws AbacRuleSubstitutionError when variable is unresolved', () => {
    expect(() =>
      engine.buildAbility(
        user(),
        configWithRules([
          {
            action: 'read',
            subject: 'Invoice',
            roles: ['MANAGER'],
            conditions: { x: '$user.unknown' },
          },
        ]),
      ),
    ).toThrow(AbacRuleSubstitutionError);
  });

  it('accepts a rule with only fields (no conditions)', () => {
    const ability = engine.buildAbility(
      user(),
      configWithRules([
        {
          action: 'read',
          subject: 'Invoice',
          roles: ['MANAGER'],
          fields: ['id', 'amount'],
        },
      ]),
    );
    expect(ability.can('read', 'Invoice')).toBe(true);
  });

  it('honours inverted-only rule (cannot, no conditions) — silenced by ordering', () => {
    const ability = engine.buildAbility(
      user(),
      configWithRules([
        { action: 'read', subject: 'Invoice', roles: ['MANAGER'] },
        { action: 'read', subject: 'Invoice', roles: ['MANAGER'], inverted: true },
      ]),
    );
    expect(ability.can('read', 'Invoice')).toBe(false);
  });

  it('honours inverted rule with fields-only', () => {
    const ability = engine.buildAbility(
      user(),
      configWithRules([
        { action: 'read', subject: 'Invoice', roles: ['MANAGER'] },
        {
          action: 'read',
          subject: 'Invoice',
          roles: ['MANAGER'],
          inverted: true,
          fields: ['internal_notes'],
        },
      ]),
    );
    expect(ability.can('read', 'Invoice')).toBe(true);
  });

  it('rules/fromRules roundtrip preserves decisions (cache support)', () => {
    const ability = engine.buildAbility(
      user(),
      configWithRules([
        {
          action: 'read',
          subject: 'Invoice',
          roles: ['MANAGER'],
          conditions: { department_id: '$user.department_id' },
          fields: ['id', 'amount'],
        },
      ]),
    );
    const rebuilt = engine.fromRules(engine.rules(ability));
    expect(rebuilt.can('read', { __type: 'Invoice', department_id: 'dept-A' } as never)).toBe(true);
    expect(rebuilt.can('read', { __type: 'Invoice', department_id: 'dept-B' } as never)).toBe(
      false,
    );
  });
});
