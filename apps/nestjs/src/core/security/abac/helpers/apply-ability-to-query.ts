import type { ObjectLiteral, SelectQueryBuilder } from 'typeorm';
import type { AbacAbility } from '../types';

/**
 * STORY-019 — AC-13 row-level filter helper.
 *
 * Translates the rules that apply to `(action, subject)` into TypeORM
 * `WHERE` clauses on the given query builder. Operators supported in
 * Phase 1 mirror the JSON schema : `$eq, $ne, $lt, $gt, $lte, $gte,
 * $in, $nin`. Implicit equality (plain value) is handled like `$eq`.
 *
 * Phase 2 will translate nested boolean operators (`$and`, `$or`) and
 * field projections through joins — both are out of scope here.
 *
 * Strategy : we read `ability.rulesFor(action, subject)`. Each
 * non-inverted rule with conditions contributes to a top-level `OR`
 * (CASL semantics — any matching rule grants). Inverted rules add
 * `AND NOT (...)` clauses (a `cannot` shadows a `can`).
 *
 * If no rule matches, we add `WHERE 1 = 0` — no rule = no row.
 * A rule without conditions matches every row, so no extra WHERE.
 */
export function applyAbilityToQuery<T extends ObjectLiteral>(
  qb: SelectQueryBuilder<T>,
  ability: AbacAbility,
  action: string,
  subject: string,
): SelectQueryBuilder<T> {
  const rules = ability.rulesFor(action, subject);
  if (rules.length === 0) {
    qb.andWhere('1 = 0');
    return qb;
  }

  const alias = qb.alias;
  const orFragments: string[] = [];
  const notFragments: string[] = [];
  const params: Record<string, unknown> = {};
  let counter = 0;

  let hasUnconditionalAllow = false;

  for (const rule of rules) {
    const cond = rule.conditions as Record<string, unknown> | undefined;
    const isInverted = Boolean(rule.inverted);

    if (!cond || Object.keys(cond).length === 0) {
      if (isInverted) {
        // `cannot('read', 'Invoice')` with no conditions denies everything.
        qb.andWhere('1 = 0');
        return qb;
      }
      hasUnconditionalAllow = true;
      continue;
    }

    const fragment = buildFragment(alias, cond, params, () => `abac_${counter++}`);
    if (!fragment) continue;
    if (isInverted) notFragments.push(`NOT (${fragment})`);
    else orFragments.push(`(${fragment})`);
  }

  if (!hasUnconditionalAllow) {
    if (orFragments.length === 0) {
      qb.andWhere('1 = 0');
      return qb;
    }
    qb.andWhere(orFragments.join(' OR '), params);
  }

  for (const not of notFragments) qb.andWhere(not, params);

  return qb;
}

function buildFragment(
  alias: string,
  cond: Record<string, unknown>,
  params: Record<string, unknown>,
  nextName: () => string,
): string {
  const pieces: string[] = [];
  for (const [field, raw] of Object.entries(cond)) {
    if (field.startsWith('$')) continue;
    if (raw !== null && typeof raw === 'object' && !Array.isArray(raw)) {
      for (const [op, value] of Object.entries(raw as Record<string, unknown>)) {
        pieces.push(opToSql(alias, field, op, value, params, nextName));
      }
    } else {
      const p = nextName();
      params[p] = raw;
      pieces.push(`${alias}.${field} = :${p}`);
    }
  }
  return pieces.join(' AND ');
}

function opToSql(
  alias: string,
  field: string,
  op: string,
  value: unknown,
  params: Record<string, unknown>,
  nextName: () => string,
): string {
  const p = nextName();
  switch (op) {
    case '$eq':
      params[p] = value;
      return `${alias}.${field} = :${p}`;
    case '$ne':
      params[p] = value;
      return `${alias}.${field} != :${p}`;
    case '$lt':
      params[p] = value;
      return `${alias}.${field} < :${p}`;
    case '$lte':
      params[p] = value;
      return `${alias}.${field} <= :${p}`;
    case '$gt':
      params[p] = value;
      return `${alias}.${field} > :${p}`;
    case '$gte':
      params[p] = value;
      return `${alias}.${field} >= :${p}`;
    case '$in':
      params[p] = value;
      return `${alias}.${field} IN (:...${p})`;
    case '$nin':
      params[p] = value;
      return `${alias}.${field} NOT IN (:...${p})`;
    default:
      throw new Error(`Unsupported ABAC operator: ${op}`);
  }
}
