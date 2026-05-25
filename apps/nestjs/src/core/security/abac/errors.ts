/**
 * STORY-019 — ABAC errors.
 *
 * RuleParseError surfaces a malformed JSON rule (caught at boot or at
 * tenant.config PATCH). SubstitutionError surfaces an unresolved
 * `$user.<path>` variable — almost always a typo in the tenant template.
 */

export class AbacRuleParseError extends Error {
  constructor(
    message: string,
    public readonly ruleIndex: number,
  ) {
    super(`ABAC rule[${ruleIndex}] invalid: ${message}`);
    this.name = 'AbacRuleParseError';
  }
}

export class AbacRuleSubstitutionError extends Error {
  constructor(
    public readonly variable: string,
    public readonly ruleIndex: number,
  ) {
    super(`ABAC rule[${ruleIndex}] cannot resolve variable: ${variable}`);
    this.name = 'AbacRuleSubstitutionError';
  }
}
