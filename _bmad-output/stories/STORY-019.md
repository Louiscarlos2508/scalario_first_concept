# STORY-019 : ABAC CASL — Layer 3 Sécurité

**Epic :** EPIC-003 — Backend Foundation
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** STORY-015 (RBAC dispo, AbacGuard chaîné après RbacGuard)

---

## User Story

> **En tant que** MANAGER d'un département dans un tenant Scalario,
> **je veux** que mes permissions soient contextuelles (voir uniquement les ventes/factures DE MON DÉPARTEMENT, ou avec montant < 500K FCFA),
> **so that** Scalario fournit un contrôle d'accès attribute-based précis qui dépasse le simple rôle — règles déclarées en JSON dans la config tenant, évaluées par CASL au runtime, sans aucune logique métier hardcodée dans NestJS.

---

## Description

### Background

Layer 3 de la chaîne sécurité (architecture line 630, 1352-1363). Après Layer 1 (JWT) et Layer 2 (RBAC rôle), Layer 3 ABAC évalue des règles contextuelles `(User + Resource + Context) → Decision`. Exemple canonique architecture line 1356 :

```
"MANAGER peut voir les factures DE SON DÉPARTEMENT si montant < 500k XOF"
→ defineAbility((can) => {
    can('read', 'Invoice', {
      department_id: user.department_id,
      amount: { $lt: 500000 }
    });
  });
```

Principe non-négociable : **règles ABAC déclarées en JSON dans la config tenant**, jamais hardcodées en TypeScript. CASL est le moteur d'évaluation — il consomme un AST de règles défini en JSON et émet des `can/cannot` au runtime.

Cette story couvre l'ABAC basique (FR-017). Phase 3 introduira Rete Algorithm pour scaler à 100+ règles par tenant (FR-037).

### Scope

**In scope :**

- Module `apps/nestjs/src/security/abac/` complet : `abac.module.ts`, `abac-guard.ts`, `ability.factory.ts`, `casl-rule.parser.ts`, `__tests__/`.
- Package `@casl/ability` + `@casl/nestjs` ajoutés.
- Interface `ABACEngine` (préparation Rete Phase 3) : méthodes `buildAbility(user, tenantConfig)`, `evaluate(action, subject, resource): Decision`.
- Implémentation `CaslAbacEngine` Phase 1.
- Définition JSON Schema des règles ABAC dans `catalog/schemas/abac-rule.schema.json` :
  ```json
  {
    "action": "read | create | update | delete | manage",
    "subject": "Invoice | Sale | Product | ...",
    "conditions": { "department_id": "$user.department_id", "amount": { "$lt": 500000 } },
    "fields": ["id", "amount", "customer_id"],   // field-level filtering
    "inverted": false                              // can vs cannot
  }
  ```
- `AbilityFactory.createForUser(user, tenant)` charge `tenant.config.abac_rules[]`, parse les règles JSON, retourne un `MongoAbility` CASL.
- Decorator `@CaslPolicies(...handlers)` qui décore les controllers : `@CaslPolicies(new ReadInvoicePolicy())`.
- Decorator `@AbacAction(action: string, subject: string)` simplifié pour cas standard CRUD : `@AbacAction('read', 'Invoice')`.
- `AbacGuard` (`CanActivate`) :
  1. Lit le decorator `@AbacAction` ou `@CaslPolicies`.
  2. Récupère `req.ability` (peuplé par `AbilityMiddleware`).
  3. `ability.can(action, subject)` → si false → 403.
- `AbilityMiddleware` ou interceptor qui peuple `req.ability` à partir de `req.user` + `tenant.config.abac_rules[]`.
- Field-level filtering : helper `filterFieldsByAbility(resource, ability, action, subject)` qui retire les champs non lisibles (utilisé en post-processing par les services).
- Row-level filtering : helper `applyAbilityToQuery(qb, ability, action, subject)` qui ajoute des WHERE clauses TypeORM (`accessibleBy()` from CASL).
- 1 exemple fonctionnel : `InvoiceService.list()` avec policy MANAGER département → test E2E qui prouve le filtrage.
- Variables `$user.department_id`, `$user.user_id`, `$user.tenant_id` interpolées au runtime depuis le JWT context.
- Audit log des décisions ABAC critiques (`deny` events) — STORY-020.

**Out of scope (autres stories) :**

- Rete Algorithm performance scaling Phase 3 → FR-037, juste l'interface est définie ici.
- UI admin pour éditer les règles ABAC → EPIC-008 admin.
- Règles temporelles complexes (ex: "MANAGER peut approuver entre 8h et 18h") → Phase 2 si demande.
- ABAC sur pgvector RAG → Layer 4 Phase 2 (architecture line 631).

### Runtime Flow (ABAC Decision)

1. Client `GET /api/acme/invoices/123` (Authorization Bearer).
2. **Layer 1** JwtAuthGuard valide JWT, peuple `req.user = { user_id, tenant_id, roles: ['MANAGER'], department_id: 'dept-456' }`.
3. **Layer 2** RbacGuard vérifie rôle MANAGER autorisé sur cette route.
4. **AbilityMiddleware** :
   - Charge `tenant.config.abac_rules` via `RolesService` (cache Redis STORY-018).
   - Filtre les règles applicables aux rôles de `req.user`.
   - Substitue `$user.department_id` → `'dept-456'`.
   - Construit `MongoAbility` : `can('read', 'Invoice', { department_id: 'dept-456', amount: { $lt: 500000 } })`.
   - `req.ability = ability`.
5. **Layer 3** AbacGuard lit `@AbacAction('read', 'Invoice')` → `req.ability.can('read', 'Invoice')` → true (basé sur les rules).
6. Service charge invoice 123 depuis DB.
7. Service applique field-level filtering : `filterFieldsByAbility(invoice, req.ability, 'read', 'Invoice')` → retire `internal_notes` si non listé dans `fields`.
8. Service applique aussi `req.ability.can('read', invoice)` sur l'instance pour vérifier les conditions (`department_id === 'dept-456'`, `amount < 500000`).
9. Si l'invoice ne match pas les conditions → 404.
10. Sinon → retourne JSON filtré.

---

## Acceptance Criteria

### Schema JSON ABAC

- [ ] AC-01 — `catalog/schemas/abac-rule.schema.json` défini, valide contre Zod, couvre :
  - `action: 'read'|'create'|'update'|'delete'|'manage'|string`
  - `subject: string` (nom de la ressource)
  - `roles: string[]` (rôles auxquels la règle s'applique)
  - `conditions?: object` (MongoDB-like operators : `$eq, $ne, $lt, $gt, $lte, $gte, $in, $nin`)
  - `fields?: string[]` (champs lisibles ; absent = tous)
  - `inverted?: boolean` (cannot au lieu de can ; default false)
  - Variables interpolables : `$user.user_id`, `$user.tenant_id`, `$user.department_id`, `$user.roles[]`, `$user.metadata.<key>`.
- [ ] AC-02 — Règles ABAC stockées dans `tenants.config.abac_rules[]` JSONB. Migration ajoute clé default `[]` pour les tenants existants.

### `AbilityFactory`

- [ ] AC-03 — `AbilityFactory.createForUser(user, tenant)` :
  1. Filtre `tenant.config.abac_rules[]` aux rules dont `roles ∩ user.roles ≠ ∅`.
  2. Substitue les variables `$user.<key>` par les valeurs de `user`.
  3. Construit un `MongoAbility` (CASL) avec les règles.
  4. Retourne l'instance `Ability`.
- [ ] AC-04 — Si `tenant.config.abac_rules` est vide → ability `manage` `all` (allow all par défaut — sécurité Phase 1 : ABAC est opt-in tenant par tenant). Documenter ce default explicitement comme "permissive par défaut".
- [ ] AC-05 — Variables non résolues → throw `AbacRuleSubstitutionError` au build (caught au boot, jamais en runtime).

### `AbacGuard`

- [ ] AC-06 — Decorator `@AbacAction(action: string, subject: string)` exposé.
- [ ] AC-07 — `AbacGuard` chaîné APRÈS `RbacGuard` dans `app.module.ts` (ordre : JwtAuthGuard → RbacGuard → AbacGuard).
- [ ] AC-08 — Si la route a `@AbacAction('read', 'Invoice')` et `req.ability.can('read', 'Invoice')` → true → continue.
- [ ] AC-09 — Si false → throw `ForbiddenException('ABAC denied')` + audit log STORY-020.
- [ ] AC-10 — Si la route n'a PAS de `@AbacAction()` → AbacGuard skip (tous les endpoints publics ou strict-RBAC fonctionnent toujours).

### Field-level filtering

- [ ] AC-11 — Helper `filterFieldsByAbility(resource, ability, action, subject)` retire les champs non listés dans `rule.fields[]`. Si aucune rule restrictive → retourne resource intact.
- [ ] AC-12 — Test : MANAGER lit un Invoice avec rule `fields: ['id', 'amount']` → response contient uniquement `{ id, amount }`. Aucun `customer_id`, `internal_notes` etc.

### Row-level filtering (TypeORM)

- [ ] AC-13 — Helper `applyAbilityToQuery(qb, ability, action, subject)` ajoute des WHERE clauses dans le QueryBuilder TypeORM. Utilise `accessibleBy(ability, action)` from `@casl/ability/extra` qui produit un MongoDB-like filter, converti en SQL par mapper custom.
- [ ] AC-14 — Test : MANAGER avec rule `department_id: $user.department_id` → `SELECT * FROM invoices` génère `WHERE department_id = '<user_dept>'` automatiquement.

### Exemple fonctionnel (architecture line 1356)

- [ ] AC-15 — Test E2E `abac-invoice.e2e-spec.ts` :
  - Setup : tenant retail avec rule MANAGER `read Invoice WHERE department_id = $user.department_id AND amount < 500000`.
  - 3 invoices : (dept A, 100K) (dept A, 600K) (dept B, 100K).
  - Login MANAGER tenant_id=acme department_id=dept-A.
  - `GET /invoices` → retourne uniquement 1 invoice (dept A, 100K).
  - Direct call `GET /invoices/{dept-A-600K-id}` → 404 (NotFound, pas 403, pour ne pas leak l'existence).
  - Direct call `GET /invoices/{dept-B-100K-id}` → 404.

### Interface Rete préparée

- [ ] AC-16 — Interface `ABACEngine` exposée :
  ```typescript
  interface ABACEngine {
    buildAbility(user: User, tenantConfig: TenantConfig): Ability;
    evaluate(ability: Ability, action: string, subject: any): boolean;
  }
  ```
  Implémentations : `CaslAbacEngine` (Phase 1, this story), `ReteAbacEngine` (Phase 3, FR-037, stub interface only).

### Performance

- [ ] AC-17 — Build ability < 5ms pour tenant avec ≤ 20 rules. Cache l'ability par `(user_id, tenant_config_version)` en Redis (clé `ability:<user_id>:<config_version>`, TTL 5 min, invalidé sur PATCH config).
- [ ] AC-18 — Évaluation `ability.can(...)` < 1ms pour ≤ 20 rules.

### Audit & sécurité

- [ ] AC-19 — Chaque deny ABAC log dans audit_logs : `{ action: 'ABAC_DENY', user_id, tenant_id, requested_action, requested_subject, resource_id?, conditions_unmet }`.
- [ ] AC-20 — Coverage `security/abac/` ≥ 90%.

---

## Technical Notes

### Composants concernés

- **Module ABAC :** `apps/nestjs/src/security/abac/` (création).
- **Schema :** `catalog/schemas/abac-rule.schema.json`.
- **Auth interaction :** `req.ability` peuplé par `AbilityMiddleware` après JwtAuthGuard.

### Structure de fichiers (cible)

```
apps/nestjs/src/security/abac/
├── abac.module.ts
├── ability.factory.ts                # buildAbility from JSON rules
├── ability.middleware.ts             # populates req.ability
├── guards/
│   ├── abac.guard.ts                 # Layer 3
│   └── __tests__/
├── decorators/
│   ├── abac-action.decorator.ts      # @AbacAction(action, subject)
│   └── casl-policies.decorator.ts    # @CaslPolicies(...handlers)
├── parsers/
│   ├── rule.parser.ts                # JSON → CASL ast
│   ├── variable.substitutor.ts       # $user.dept → 'dept-456'
│   └── condition.translator.ts       # $lt → MongoDB filter
├── engines/
│   ├── abac-engine.interface.ts
│   └── casl.engine.ts                # CaslAbacEngine
├── helpers/
│   ├── filter-fields-by-ability.ts
│   └── apply-ability-to-query.ts     # TypeORM QB integration
└── __tests__/
    └── abac-invoice.e2e-spec.ts

catalog/schemas/
└── abac-rule.schema.json
```

### Pattern : JSON rule example

```json
// tenant.config.abac_rules
[
  {
    "action": "read",
    "subject": "Invoice",
    "roles": ["MANAGER"],
    "conditions": {
      "department_id": "$user.department_id",
      "amount": { "$lt": 500000 }
    },
    "fields": ["id", "amount", "customer_id", "issued_at", "status"]
  },
  {
    "action": "manage",
    "subject": "Invoice",
    "roles": ["OWNER"]
  },
  {
    "action": "read",
    "subject": "Invoice",
    "roles": ["COMMERCIAL"],
    "conditions": { "created_by": "$user.user_id" }
  }
]
```

### Pattern : AbilityFactory

```typescript
// apps/nestjs/src/security/abac/ability.factory.ts
@Injectable()
export class AbilityFactory {
  buildAbility(user: AuthUser, tenantConfig: TenantConfig): MongoAbility {
    const rules = (tenantConfig.abac_rules ?? []).filter((r) =>
      r.roles.some((role) => user.roles.includes(role)),
    );

    if (rules.length === 0) {
      // No ABAC rules defined for this tenant — permissive by default.
      // (Sécurité par construction : RBAC layer 2 + RLS layer 5 restent en place.)
      return new AbilityBuilder(createMongoAbility).build({
        // Effectively ability.can('manage', 'all') — but documented.
      });
    }

    const { can, cannot, build } = new AbilityBuilder(createMongoAbility);
    for (const rule of rules) {
      const conditions = substituteVariables(rule.conditions, user);
      const method = rule.inverted ? cannot : can;
      method(rule.action, rule.subject, rule.fields, conditions);
    }
    return build({
      detectSubjectType: (object) => object?.constructor?.name ?? 'Object',
    });
  }
}

function substituteVariables(conditions: any, user: AuthUser): any {
  if (typeof conditions === 'string' && conditions.startsWith('$user.')) {
    const key = conditions.slice(6);
    const value = key.split('.').reduce((acc, k) => acc?.[k], user as any);
    if (value === undefined) throw new AbacRuleSubstitutionError(`Cannot resolve ${conditions}`);
    return value;
  }
  if (Array.isArray(conditions)) return conditions.map((c) => substituteVariables(c, user));
  if (typeof conditions === 'object' && conditions !== null) {
    return Object.fromEntries(
      Object.entries(conditions).map(([k, v]) => [k, substituteVariables(v, user)]),
    );
  }
  return conditions;
}
```

### Pattern : AbacGuard

```typescript
// apps/nestjs/src/security/abac/guards/abac.guard.ts
@Injectable()
export class AbacGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const required = this.reflector.get<{ action: string; subject: string }>(
      ABAC_ACTION_KEY,
      ctx.getHandler(),
    );
    if (!required) return true;

    const req = ctx.switchToHttp().getRequest();
    const ability = req.ability as MongoAbility;
    if (!ability) {
      throw new InternalServerErrorException('Ability not built — ABAC middleware missing?');
    }

    if (!ability.can(required.action, required.subject)) {
      throw new ForbiddenException('ABAC denied');
    }
    return true;
  }
}
```

### Pattern : Service usage with row + field filtering

```typescript
// Example InvoiceService (illustration only — Sprint 3+)
@Injectable()
export class InvoiceService {
  async list(@CurrentTenant() tenantId: string, @Req() req: Request): Promise<Invoice[]> {
    const ability = req.ability;
    const qb = this.repo.createQueryBuilder('invoice');
    accessibleBy(ability, 'read').Invoice && qb.andWhere(/* … from CASL filter */);
    const invoices = await qb.getMany();
    return invoices.map((inv) =>
      filterFieldsByAbility(inv, ability, 'read', 'Invoice'),
    );
  }
}
```

### Edge cases

- **Variable non résolue (`$user.unknown_field`) :** throw `AbacRuleSubstitutionError` au build de l'ability. Le tenant a un bug config — alerte ops, le user reçoit 500. Phase 2 : config validée à l'écriture (PATCH config) avec dry-run substitution.
- **Conflit can vs cannot :** CASL applique les rules dans l'ordre ; cannot override can (architecture CASL standard).
- **Resource sans `constructor.name` (POJO de DB) :** Convention TypeORM entities avec name : `@Entity('invoice')` → constructor.name = 'Invoice'. Test : si subject est un POJO, fallback sur string explicite passé au `can(action, subject_string)`.
- **Performance avec 100+ rules :** Phase 1 = O(N) per check. Phase 3 Rete = O(1) amortized. Mesurer dégradation à partir de N=50.
- **Permissive par défaut (no rules) :** Documenté comme intentionnel. Sécurité repose sur Layer 2 RBAC + Layer 5 RLS. Les tenants veulent activer ABAC explicitement quand besoin (templates fournissent `abac_rules` per default).
- **Cache ability invalidation :** Clé `ability:<user_id>:<config_version>` — incrémenter `tenant.config.version` à chaque PATCH config invalide tous les utilisateurs en chaîne.

### Sécurité — première classe

| Menace | Layer | Mitigation |
|---|---|---|
| MANAGER lit invoices d'un autre département | 3 | ABAC condition `department_id = $user.department_id` |
| MANAGER lit invoice montant > 500K (cas escalade) | 3 | ABAC condition `amount: { $lt: 500000 }` |
| Bug code applicatif retourne tous les invoices | 3 + 5 | ABAC `applyAbilityToQuery` filtre + RLS Layer 5 isolation tenant |
| Field-level leak (internal_notes) | 3 | `filterFieldsByAbility` retire champs non listés |
| Règle ABAC mal écrite (variable typo) | 3 | Validation Zod schema + boot check `AbacRuleSubstitutionError` |
| Tenant change rules pour étendre permissions sans audit | 3 | PATCH `tenants.config.abac_rules` audited (STORY-020) |
| Bypass via call direct repository sans WHERE | 3 → 5 | Layer 5 RLS isolation tenant, mais ABAC row filtering reste applicatif. Convention : tous les services métier appellent `applyAbilityToQuery`. CI lint check sur les `Repository.find()` non protégés. |
| Performance dégradée au-delà 50 rules | 3 | Cache ability + monitoring p95 → trigger Rete Phase 3 |
| Ability cache empoisonnée | 3 | Cache key inclut `config_version` ; PATCH config bump version → invalidation auto |

### Threat model — bypass scenarios

1. **Service oublie d'appeler `applyAbilityToQuery`**
   ABAC row-level filter manqué → MANAGER voit tous invoices du tenant. Mitigation : Layer 5 RLS limite à son tenant ; **mais pas à son département**. C'est une vraie fuite ABAC. CI lint check obligatoire qui scan tous les services et flag `Repository.find()` sans appel ABAC.

2. **Field non listé dans `rule.fields` mais retourné par le service (bug serializer)**
   `filterFieldsByAbility` doit être appelé avant le response. Si oublié, leak. Convention : interceptor global `AbilityResponseInterceptor` qui filtre automatiquement les responses des controllers `@AbacAction()`.

3. **Variable `$user.metadata.X` utilisée pour escalation**
   Si user metadata est éditable par le user lui-même (Phase 2), il pourrait modifier ses attributs ABAC. Phase 1 : metadata éditable uniquement par OWNER+ → vérifié par RBAC.

4. **Permissive par défaut (tenant sans rules)**
   Trade-off accepté Phase 1. Les tenants critiques (santé) doivent activer ABAC dans leur template. Documenté.

### Conflit avec PRD/sprint plan

PRD ligne 425 : "MANAGER voit les factures DE SON DEPT si montant < 500k XOF". Sprint plan ligne 435 : "MANAGER voit les ventes de SON département uniquement". Cette story implémente l'exemple invoice (PRD plus complet). L'exemple ventes est trivial à dériver une fois l'invoice OK. ✅

---

## Dependencies

**Prérequis :**
- STORY-013 (NestJS bootstrap)
- STORY-014 (JWT avec `department_id` claim)
- STORY-015 (RBAC Layer 2 + `tenants.config` storage)
- STORY-018 (cache Redis pour ability)

**Stories bloquées par celle-ci :**
- STORY-021 (BDUIService — peut consommer `req.ability` pour filtrer les composants visibles)
- Toutes les stories métier qui exposent des endpoints filtrés par attributs (factures, ventes, RH).

**Externes :** `@casl/ability`, `@casl/nestjs` (npm packages).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-019-abac-casl`.
- [ ] `pnpm --filter @scalario/nestjs run lint` + `typecheck` + `test` verts.
- [ ] Coverage `security/abac/` ≥ 90%.
- [ ] Test E2E `abac-invoice.e2e-spec.ts` (AC-15) vert.
- [ ] AbacGuard chaîné dans `app.module.ts` après RbacGuard (ordre 1→2→3).
- [ ] Field-level filtering testé (AC-12).
- [ ] Row-level filtering testé (AC-14).
- [ ] Variable substitution + erreurs documentées.
- [ ] Cache Redis ability fonctionnel (AC-17).
- [ ] Audit log deny events (AC-19).
- [ ] Documentation `apps/nestjs/docs/abac-rules-syntax.md` : guide intégrateur.
- [ ] Code review passé (`/codex review` recommandé).
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-019 status `completed`, completed_points sprint 2 += 3.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| JSON Schema ABAC + validation Zod + variable substitutor + condition translator | 0.5 | Petit mais le DSL doit être stable. |
| `AbilityFactory` (build CASL ability from JSON rules + cache Redis) | 0.75 | Substitution + caching + invalidation. |
| `AbilityMiddleware` (populates req.ability per request) | 0.25 | Standard NestJS middleware. |
| `AbacGuard` + `@AbacAction` decorator + `@CaslPolicies` decorator | 0.5 | NestJS pattern standard. |
| Helpers field-level + row-level filtering + tests | 0.5 | `accessibleBy` + TypeORM QB integration non triviale. |
| Test E2E `abac-invoice.e2e-spec.ts` (3 invoices, 3 scenarios) | 0.25 | Le test prouve la valeur produit. |
| Interface `ABACEngine` + `CaslAbacEngine` impl + `ReteAbacEngine` stub | 0.25 | Préparation Phase 3. |
| Documentation syntax règles ABAC pour intégrateurs | 0.25 | Critique — c'est le DX du produit. |
| **Total** | **3** | Fibonacci 3 — moderate. |

**Rationale :** CASL fait le gros du travail ; le challenge est la traduction JSON → CASL AST + variable substitution + tests rigoureux. La complexité est dans la qualité de la spec JSON, pas dans le code Phase 1.

---

## Notes additionnelles

- **Pourquoi CASL et pas Casbin ou OPA ?** Architecture line 2202 : "Intégration NestJS native, DSL TypeScript, performant". CASL a `@casl/nestjs` officiel, syntax MongoDB-like familière, et performance suffisante Phase 1.
- **Permissive par défaut documenté :** Trade-off Phase 1. Les templates Scalario (retail_fresh_produce.json par défaut) embarquent des `abac_rules` par défaut → un tenant qui démarre depuis un template a déjà de l'ABAC actif.
- **Rete Phase 3 :** L'interface `ABACEngine` permet de swap CASL → Rete sans toucher les services. Trigger Phase 3 : > 50 rules ou p95 > 5ms par check.
- **Field-level filtering vs DTO :** Phase 1 utilise `filterFieldsByAbility`. Phase 2 pourrait migrer vers des DTO classes décorées `@FieldsByRole` pour générer la sérialisation au build-time.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
