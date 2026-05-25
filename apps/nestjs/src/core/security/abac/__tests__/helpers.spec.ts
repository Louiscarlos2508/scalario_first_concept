import { CaslAbacEngine } from '../engines/casl.engine';
import { filterFieldsByAbility } from '../helpers/filter-fields-by-ability';
import { applyAbilityToQuery } from '../helpers/apply-ability-to-query';
import type { TenantConfig } from '../../../auth/entities/tenant.entity';

const engine = new CaslAbacEngine();

function user(roles = ['MANAGER']) {
  return {
    user_id: 'u-1',
    tenant_id: 't-1',
    roles,
    department_id: 'dept-A',
  };
}

function cfg(rules: unknown[]): TenantConfig {
  return { roles: ['MANAGER'], abac_rules: rules as never } as TenantConfig;
}

describe('filterFieldsByAbility', () => {
  it('keeps only whitelisted fields (AC-12)', () => {
    const ability = engine.buildAbility(
      user(),
      cfg([
        {
          action: 'read',
          subject: 'Invoice',
          roles: ['MANAGER'],
          fields: ['id', 'amount'],
        },
      ]),
    );
    const out = filterFieldsByAbility(
      { id: 'i-1', amount: 100, customer_id: 'c-1', internal_notes: 'secret' },
      ability,
      'read',
      'Invoice',
    );
    expect(out).toEqual({ id: 'i-1', amount: 100 });
  });

  it('returns a copy intact when no rule restricts fields (AC-11)', () => {
    const ability = engine.buildAbility(
      user(),
      cfg([{ action: 'read', subject: 'Invoice', roles: ['MANAGER'] }]),
    );
    const out = filterFieldsByAbility(
      { id: 'i-1', amount: 100, notes: 'x' },
      ability,
      'read',
      'Invoice',
    );
    expect(out).toEqual({ id: 'i-1', amount: 100, notes: 'x' });
  });
});

describe('applyAbilityToQuery', () => {
  function fakeQb() {
    const wheres: { clause: string; params: Record<string, unknown> }[] = [];
    const qb = {
      alias: 'invoice',
      andWhere(clause: string, params?: Record<string, unknown>) {
        wheres.push({ clause, params: params ?? {} });
        return qb;
      },
      _wheres: wheres,
    };
    return qb;
  }

  it('emits WHERE 1=0 when matching rules exist but none grant the action', () => {
    // MANAGER has a `read Invoice` rule — trying `delete Invoice` should
    // be denied (no rule grants it), unlike the permissive default
    // that only kicks in when no rule applies to the user's roles.
    const ability = engine.buildAbility(
      user(),
      cfg([{ action: 'read', subject: 'Invoice', roles: ['MANAGER'] }]),
    );
    const qb = fakeQb();
    applyAbilityToQuery(qb as never, ability, 'delete', 'Invoice');
    expect(qb._wheres.some((w) => w.clause === '1 = 0')).toBe(true);
  });

  it('adds equality WHERE clauses for $user-substituted conditions (AC-14)', () => {
    const ability = engine.buildAbility(
      user(),
      cfg([
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
    const qb = fakeQb();
    applyAbilityToQuery(qb as never, ability, 'read', 'Invoice');
    const joined = qb._wheres.map((w) => w.clause).join(' && ');
    expect(joined).toContain('invoice.department_id = :');
    expect(joined).toContain('invoice.amount < :');
    const paramValues = qb._wheres.flatMap((w) => Object.values(w.params));
    expect(paramValues).toContain('dept-A');
    expect(paramValues).toContain(500000);
  });

  it('emits no WHERE for unconditional grant', () => {
    const ability = engine.buildAbility(
      user(),
      cfg([{ action: 'read', subject: 'Invoice', roles: ['MANAGER'] }]),
    );
    const qb = fakeQb();
    applyAbilityToQuery(qb as never, ability, 'read', 'Invoice');
    expect(qb._wheres.length).toBe(0);
  });

  it('supports each comparison operator', () => {
    const ability = engine.buildAbility(
      user(),
      cfg([
        {
          action: 'read',
          subject: 'Invoice',
          roles: ['MANAGER'],
          conditions: {
            amount: { $gt: 1, $gte: 1, $lt: 9, $lte: 9, $ne: 5 },
            status: { $nin: ['archived'] },
          },
        },
      ]),
    );
    const qb = fakeQb();
    applyAbilityToQuery(qb as never, ability, 'read', 'Invoice');
    const joined = qb._wheres.map((w) => w.clause).join('||');
    expect(joined).toContain('>');
    expect(joined).toContain('>=');
    expect(joined).toContain('<');
    expect(joined).toContain('<=');
    expect(joined).toContain('!=');
    expect(joined).toContain('NOT IN');
  });

  it('emits NOT fragment for inverted rule with conditions', () => {
    const ability = engine.buildAbility(
      user(),
      cfg([
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
    const qb = fakeQb();
    applyAbilityToQuery(qb as never, ability, 'read', 'Invoice');
    expect(qb._wheres.some((w) => w.clause.startsWith('NOT'))).toBe(true);
  });

  it('emits WHERE 1=0 when an unconditional cannot is in play', () => {
    const ability = engine.buildAbility(
      user(),
      cfg([
        { action: 'read', subject: 'Invoice', roles: ['MANAGER'] },
        { action: 'read', subject: 'Invoice', roles: ['MANAGER'], inverted: true },
      ]),
    );
    const qb = fakeQb();
    applyAbilityToQuery(qb as never, ability, 'read', 'Invoice');
    expect(qb._wheres.some((w) => w.clause === '1 = 0')).toBe(true);
  });

  it('supports $in operator', () => {
    const ability = engine.buildAbility(
      user(),
      cfg([
        {
          action: 'read',
          subject: 'Invoice',
          roles: ['MANAGER'],
          conditions: { status: { $in: ['open', 'paid'] } },
        },
      ]),
    );
    const qb = fakeQb();
    applyAbilityToQuery(qb as never, ability, 'read', 'Invoice');
    expect(qb._wheres.some((w) => w.clause.includes('IN (:...'))).toBe(true);
  });
});
