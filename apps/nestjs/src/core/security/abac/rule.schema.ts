import { z } from 'zod';

/**
 * STORY-019 — Zod mirror of `catalog/schemas/abac-rule.schema.json`.
 *
 * Use this at PATCH /tenants/:slug/config time (Sprint 3+) to reject
 * malformed ABAC payloads before they reach Postgres. AbilityFactory
 * also defends against malformed rules at runtime — see
 * RuleParseError handling.
 */

const SUBJECT_RE = /^[A-Z][A-Za-z0-9]{0,63}$/;
const ROLE_RE = /^[A-Z][A-Z0-9_]{0,31}$/;
const FIELD_RE = /^[a-zA-Z_][a-zA-Z0-9_]{0,63}$/;
const CUSTOM_ACTION_RE = /^[a-z][a-z0-9_]{0,31}$/;
const STANDARD_ACTIONS = ['read', 'create', 'update', 'delete', 'manage'] as const;

export const abacActionSchema = z
  .string()
  .refine((v) => (STANDARD_ACTIONS as readonly string[]).includes(v) || CUSTOM_ACTION_RE.test(v), {
    message: 'action must be CRUD verb, "manage", or lower_snake_case ≤32',
  });

export const abacRuleSchema = z
  .object({
    action: abacActionSchema,
    subject: z.string().regex(SUBJECT_RE),
    roles: z.array(z.string().regex(ROLE_RE)).min(1),
    conditions: z.record(z.unknown()).optional(),
    fields: z.array(z.string().regex(FIELD_RE)).min(1).optional(),
    inverted: z.boolean().optional(),
    reason: z.string().max(256).optional(),
  })
  .strict();

export const abacRulesSchema = z.array(abacRuleSchema);

export type AbacRule = z.infer<typeof abacRuleSchema>;
export type AbacRules = AbacRule[];
