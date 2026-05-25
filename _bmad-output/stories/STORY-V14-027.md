# STORY-V14-027 : Casbin integration — ABAC complexe multi-attributs (paie, finances cross-département)

**Epic :** EPIC-V14-018 — Scalario Shield
**Priorité :** Should Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-10 (Phase 2)
**Dépendances :** STORY-019 v13 (CASL ABAC base)

---

## User Story

> **En tant que** Scalario Shield gérant des règles ABAC complexes (ex: "Le comptable RH ne peut voir QUE les paies de son département SAUF si le montant > 500k auquel cas il faut l'approval du DG"),
> **je veux** Casbin intégré en complément de CASL,
> **so that** les règles métier complexes (multi-attributs, conditions imbriquées, plafonds dynamiques) sont déclarées en `policy.csv` plutôt qu'en code Dart, et Scalario Forge peut les générer depuis le Business Profile.

---

## Description

### Background

PRD v14 §5.2 + §23.2 — CASL gère 80% des cas (RBAC + attributs simples). Casbin gère les 20% restants (règles complexes type "si X ET (Y OU Z) ET attribut.dept = user.dept").

### Scope

**In scope :**
- `pnpm add casbin` + `node-casbin` dans NestJS
- `src/core/abac/casbin/` — modèle Casbin (model.conf) + politiques par tenant (policy.csv ou DB)
- Wrapper `CasbinService` qui charge le model + policies du tenant
- `CasbinGuard` complémentaire à `AbacGuard` (CASL) — appelé si règle est marquée "complex"
- Migration : ajout colonne `tenant.config.casbin_policies` (CSV ou JSONB)
- Tests : 3 règles complexes (paie cross-dept, plafond dynamique, multi-condition AND/OR/NOT)

**Out of scope :**
- Rete Algorithm pour scalabilité (Phase 3 — V14-030)
- Editor visuel de policies (Phase 3+)

---

## Acceptance Criteria

- [ ] **AC-01** — `casbin` installé + `CasbinService` initialisé par tenant (caching policies en Redis).
- [ ] **AC-02** — Model Casbin RBAC + ABAC fusion : `m = r.sub == p.sub && r.obj.dept == p.obj.dept && (r.act == p.act || p.act == '*')`.
- [ ] **AC-03** — `CasbinService.canAccess(userId, obj, action, attributes)` retourne `bool`.
- [ ] **AC-04** — Hook dans `AbacGuard` : si règle déclarée `complex: true` → délègue à Casbin.
- [ ] **AC-05** — `tenant.config.casbin_policies` accepte format CSV ou JSONB.
- [ ] **AC-06** — Endpoint admin `PATCH /tenants/:slug/casbin_policies` (OWNER+SUPER_ADMIN).
- [ ] **AC-07** — Test 1 : paie cross-dept — comptable RH dept_A tente voir paie dept_B → 403.
- [ ] **AC-08** — Test 2 : plafond dynamique — vente 600k XOF nécessite role MANAGER (au-dessus de 500k seuil).
- [ ] **AC-09** — Test 3 : multi-condition — "MANAGER OU DG ET (vente_du_jour OR validation_pending)".
- [ ] **AC-10** — Performance : Casbin policies < 100 règles → décision < 5ms.

---

## Technical Notes

### Casbin model (model.conf)

```ini
[request_definition]
r = sub, obj, act, attrs

[policy_definition]
p = sub, obj, act, conds

[role_definition]
g = _, _

[policy_effect]
e = some(where (p.eft == allow))

[matchers]
m = g(r.sub, p.sub) && (r.obj == p.obj || p.obj == '*') && (r.act == p.act || p.act == '*') && eval(p.conds)
```

### Policy CSV exemple

```csv
# sub, obj, act, conds (expression evaluable)
p, MANAGER, ventes, read, r.attrs.dept == p.sub_dept
p, COMPTABLE, paies, read, r.attrs.dept == p.sub_dept
p, DG, *, *, true
p, DG, ventes, validate, r.attrs.montant > 500000
g, alice, COMPTABLE
g, bob, MANAGER
```

### Edge cases

- Policies > 1000 → switcher vers Rete (V14-030 Phase 3)
- Policies invalides (syntax error) → fail-closed + log audit
- Tenant sans policies Casbin → CASL only (rétro-compat)

---

## Dependencies

- **Prérequis :** STORY-019 v13 (CASL base)
- **Stories bloquées :** V14-030 (Rete Algorithm = optimisation Phase 3)

---

## Definition of Done

- [ ] Casbin installé + service
- [ ] AbacGuard hook complexe
- [ ] 3 tests règles complexes
- [ ] Docs `docs/scalario-shield-casbin.md`
- [ ] sprint-status.yaml V14-027 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Casbin setup + model.conf | 1.0 |
| CasbinService + caching Redis | 1.5 |
| Hook AbacGuard | 1.0 |
| 3 tests règles complexes | 1.0 |
| Docs | 0.5 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
