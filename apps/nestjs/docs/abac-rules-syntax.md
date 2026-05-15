# ABAC Rules Syntax — Integrator Guide

STORY-019. ABAC (Attribute-Based Access Control) is Layer 3 of the
Scalario security chain. It runs after Layer 1 JWT and Layer 2 RBAC,
and before Layer 5 RLS. Rules are declared in **JSON inside the
tenant config**, never hardcoded.

```
JWT (Layer 1) → @Roles (Layer 2 RBAC) → @AbacAction (Layer 3 ABAC) → ... → RLS (Layer 5)
```

## Storage

Rules live in `tenants.config.abac_rules`. Tenant templates ship a
sensible default ; tenants without rules are evaluated permissively
(see "Permissive default" below).

## Rule shape

```json
{
  "action": "read | create | update | delete | manage | <custom>",
  "subject": "Invoice",
  "roles": ["MANAGER"],
  "conditions": {
    "department_id": "$user.department_id",
    "amount": { "$lt": 500000 }
  },
  "fields": ["id", "amount", "customer_id"],
  "inverted": false,
  "reason": "MANAGER reads only invoices of their dept, under 500K"
}
```

- `action` — CRUD verb, `manage` (wildcard), or a custom `lower_snake_case` action (≤32 chars).
- `subject` — `PascalCase` resource name. Must match `__type` field on POJOs or `constructor.name` on TypeORM entities.
- `roles` — tenant roles the rule applies to (`UPPER_SNAKE`, ≤32 chars). The rule activates iff `roles ∩ user.roles ≠ ∅`.
- `conditions` — MongoDB-style operators. Supported : `$eq, $ne, $lt, $gt, $lte, $gte, $in, $nin`. Implicit equality (`field: value`) is `$eq`.
- `fields` — whitelist of readable/writable fields. Omitted = all fields. Used by `filterFieldsByAbility()`.
- `inverted` — `true` declares a `cannot` rule. Order matters : a later inverted rule shadows an earlier `can`.
- `reason` — free-text label for audit/debugging (≤256).

## Variables

- `$user.user_id`
- `$user.tenant_id`
- `$user.department_id`
- `$user.roles[]`
- `$user.metadata.<key>`

Resolved at ability-build time. An unresolved variable throws
`AbacRuleSubstitutionError` — the tenant config has a typo, no request
is served.

## Permissive default

If no rule applies to the user's roles, the ability allows
`manage` on `all`. ABAC is opt-in per tenant ; RBAC (Layer 2) and RLS
(Layer 5) remain the active gates. Templates carry their own
`abac_rules` so a tenant that starts from `retail_fresh_produce.json`
has ABAC active out of the box.

## In NestJS

```typescript
@Controller('invoices')
export class InvoicesController {
  @Get(':id')
  @Roles('MANAGER', 'OWNER')         // Layer 2 — gate by role
  @AbacAction('read', 'Invoice')     // Layer 3 — gate by attributes
  async getOne(@Param('id') id: string, @Req() req: Request) {
    const ability = req.ability!;
    const invoice = await this.repo.findOneBy({ id });
    if (!invoice || !ability.can('read', { __type: 'Invoice', ...invoice })) {
      // 404, never 403 — do not leak existence (AC-15).
      throw new NotFoundException();
    }
    return filterFieldsByAbility(invoice, ability, 'read', 'Invoice');
  }
}
```

Row-level filter on a list :

```typescript
const qb = repo.createQueryBuilder('invoice');
applyAbilityToQuery(qb, req.ability!, 'read', 'Invoice');
return qb.getMany();
```

## Performance

- Build : <5 ms for ≤20 rules (in-process).
- Cache : per-`(tenant_id, user_id, config_version)`, Redis TTL 5 min. Bumping `tenants.config.version` invalidates every active ability.
- Phase 3 (FR-037) swaps `CaslAbacEngine` for `ReteAbacEngine` once a tenant exceeds ~50 rules or p95 evaluate() crosses 5 ms.

## Threat model — what ABAC does NOT do

- It does not replace Layer 2 RBAC. A user with no rule still has tenant-scoped role gating.
- It does not replace Layer 5 RLS. Cross-tenant intrusion attempts are blocked by Postgres policies, not by CASL.
- It does not auto-filter responses. Services must explicitly call `filterFieldsByAbility()` or `applyAbilityToQuery()`. A CI lint check on `Repository.find()` without an ABAC call is on the roadmap (Phase 2, when more business services come online).

## Reference

- Schema : [`catalog/schemas/abac-rule.schema.json`](../../../catalog/schemas/abac-rule.schema.json)
- Zod mirror : `src/security/abac/rule.schema.ts`
- E2E proof : `src/security/abac/__tests__/abac-invoice.e2e.spec.ts`
