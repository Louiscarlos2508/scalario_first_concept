import { AbacRuleSubstitutionError } from '../errors';
import type { AbacUser } from '../types';

const VAR_PREFIX = '$user.';

/**
 * STORY-019 — replaces `$user.<path>` strings inside a conditions tree by
 * the matching value from the authenticated user. Path resolution walks
 * dot-segments through `user.metadata.<key>` so tenant rules can target
 * custom attributes.
 *
 * Throws `AbacRuleSubstitutionError` on any unresolved variable — a
 * deny-by-misconfiguration is preferable to a silent allow on
 * `undefined`.
 */
export function substituteVariables(node: unknown, user: AbacUser, ruleIndex: number): unknown {
  if (typeof node === 'string') {
    if (!node.startsWith(VAR_PREFIX)) return node;
    const path = node.slice(VAR_PREFIX.length);
    if (!path) throw new AbacRuleSubstitutionError(node, ruleIndex);
    const value = path.split('.').reduce<unknown>((acc, key) => {
      if (acc === null || acc === undefined) return undefined;
      if (typeof acc !== 'object') return undefined;
      return (acc as Record<string, unknown>)[key];
    }, user as unknown);
    if (value === undefined) throw new AbacRuleSubstitutionError(node, ruleIndex);
    return value;
  }

  if (Array.isArray(node)) {
    return node.map((item) => substituteVariables(item, user, ruleIndex));
  }

  if (node !== null && typeof node === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(node)) {
      out[k] = substituteVariables(v, user, ruleIndex);
    }
    return out;
  }

  return node;
}
