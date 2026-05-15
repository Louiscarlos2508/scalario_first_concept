import { AbacRuleSubstitutionError } from '../errors';
import { substituteVariables } from '../parsers/variable-substitutor';
import type { AbacUser } from '../types';

const USER: AbacUser = {
  user_id: 'u-1',
  tenant_id: 't-1',
  roles: ['MANAGER'],
  department_id: 'dept-A',
  metadata: { region: 'BF', clearance: 3 },
};

describe('substituteVariables', () => {
  it('replaces $user.<top-level> values', () => {
    const out = substituteVariables(
      { department_id: '$user.department_id', tenant: '$user.tenant_id' },
      USER,
      0,
    );
    expect(out).toEqual({ department_id: 'dept-A', tenant: 't-1' });
  });

  it('walks dotted paths through metadata', () => {
    const out = substituteVariables({ region: '$user.metadata.region' }, USER, 0);
    expect(out).toEqual({ region: 'BF' });
  });

  it('preserves nested operator objects', () => {
    const out = substituteVariables(
      { amount: { $lt: 500000 }, department_id: '$user.department_id' },
      USER,
      0,
    );
    expect(out).toEqual({ amount: { $lt: 500000 }, department_id: 'dept-A' });
  });

  it('substitutes within arrays', () => {
    const out = substituteVariables(
      { department_id: { $in: ['$user.department_id', 'dept-X'] } },
      USER,
      0,
    );
    expect(out).toEqual({ department_id: { $in: ['dept-A', 'dept-X'] } });
  });

  it('throws AbacRuleSubstitutionError on unresolved variable', () => {
    expect(() => substituteVariables({ x: '$user.unknown' }, USER, 7)).toThrow(
      AbacRuleSubstitutionError,
    );
  });

  it('throws on empty $user. path', () => {
    expect(() => substituteVariables({ x: '$user.' }, USER, 0)).toThrow(AbacRuleSubstitutionError);
  });

  it('throws when descending into a non-object property', () => {
    expect(() => substituteVariables({ x: '$user.user_id.deeper' }, USER, 0)).toThrow(
      AbacRuleSubstitutionError,
    );
  });

  it('leaves non-$user strings untouched', () => {
    const out = substituteVariables({ x: 'literal' }, USER, 0);
    expect(out).toEqual({ x: 'literal' });
  });
});
