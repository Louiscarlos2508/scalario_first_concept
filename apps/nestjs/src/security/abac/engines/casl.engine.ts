import { Injectable } from '@nestjs/common';
import {
  AbilityBuilder,
  createMongoAbility,
  type MongoAbility,
  type RawRuleOf,
} from '@casl/ability';
import type { TenantConfig } from '../../../auth/entities/tenant.entity';
import { AbacRuleParseError } from '../errors';
import { substituteVariables } from '../parsers/variable-substitutor';
import { abacRuleSchema, type AbacRule } from '../rule.schema';
import type { ABACEngine } from './abac-engine.interface';
import type { AbacAbility, AbacUser } from '../types';

/**
 * STORY-019 — CASL implementation of ABACEngine (Phase 1).
 *
 * Translates tenant `abac_rules[]` into a `MongoAbility`. Rule order
 * is preserved : CASL applies them sequentially, and `cannot` (inverted)
 * shadows previous `can` rules — standard CASL semantics.
 *
 * Permissive default : if no rule applies to the user's roles, return
 * an ability that allows `manage` on `all`. Layer 2 RBAC and Layer 5 RLS
 * remain the active gates ; ABAC is opt-in per tenant.
 */
@Injectable()
export class CaslAbacEngine implements ABACEngine {
  buildAbility(user: AbacUser, tenantConfig: TenantConfig): AbacAbility {
    const rawRules = Array.isArray(tenantConfig.abac_rules) ? tenantConfig.abac_rules : [];

    const applicable: { rule: AbacRule; index: number }[] = [];
    for (let i = 0; i < rawRules.length; i++) {
      const parsed = abacRuleSchema.safeParse(rawRules[i]);
      if (!parsed.success) {
        throw new AbacRuleParseError(parsed.error.issues[0]?.message ?? 'invalid shape', i);
      }
      const rule = parsed.data;
      if (rule.roles.some((r) => user.roles.includes(r))) {
        applicable.push({ rule, index: i });
      }
    }

    const builder = new AbilityBuilder<MongoAbility>(createMongoAbility);

    if (applicable.length === 0) {
      // Permissive by default — see story AC-04. RBAC + RLS remain in place.
      builder.can('manage', 'all');
      return builder.build();
    }

    for (const { rule, index } of applicable) {
      const conditions = rule.conditions
        ? (substituteVariables(rule.conditions, user, index) as Record<string, unknown>)
        : undefined;
      // CASL signature : (action, subject, fields?, conditions?). Both
      // `can` and `cannot` share it, but TS loses the overload through a
      // union — keep the call inline so each branch picks its overload.
      if (rule.inverted) {
        if (rule.fields && conditions) {
          builder.cannot(rule.action, rule.subject, rule.fields, conditions);
        } else if (rule.fields) {
          builder.cannot(rule.action, rule.subject, rule.fields);
        } else if (conditions) {
          builder.cannot(rule.action, rule.subject, conditions);
        } else {
          builder.cannot(rule.action, rule.subject);
        }
      } else {
        if (rule.fields && conditions) {
          builder.can(rule.action, rule.subject, rule.fields, conditions);
        } else if (rule.fields) {
          builder.can(rule.action, rule.subject, rule.fields);
        } else if (conditions) {
          builder.can(rule.action, rule.subject, conditions);
        } else {
          builder.can(rule.action, rule.subject);
        }
      }
    }

    return builder.build({
      detectSubjectType: (object) => {
        if (object && typeof object === 'object') {
          const o = object as { __type?: string; constructor?: { name?: string } };
          return o.__type ?? o.constructor?.name ?? 'Object';
        }
        return 'Object';
      },
    }) as AbacAbility;
  }

  evaluate(ability: AbacAbility, action: string, subject: unknown): boolean {
    // CASL accepts both a string subject name and a tagged object.
    return ability.can(action, subject as Parameters<AbacAbility['can']>[1]);
  }

  /**
   * Snapshot of the ability rules for cache (de)serialization — CASL
   * `MongoAbility#rules` is the canonical, replayable representation.
   */
  rules(ability: AbacAbility): unknown[] {
    return ability.rules as unknown as RawRuleOf<MongoAbility>[];
  }

  fromRules(rules: unknown[]): AbacAbility {
    return createMongoAbility(rules as RawRuleOf<MongoAbility>[], {
      detectSubjectType: (object) => {
        if (object && typeof object === 'object') {
          const o = object as { __type?: string; constructor?: { name?: string } };
          return o.__type ?? o.constructor?.name ?? 'Object';
        }
        return 'Object';
      },
    }) as AbacAbility;
  }
}
