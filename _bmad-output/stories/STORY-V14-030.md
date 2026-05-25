# STORY-V14-030 : Rete Algorithm — ABAC O(1) pour milliers d'utilisateurs

**Epic :** EPIC-V14-018 — Scalario Shield
**Priorité :** Should Have (Phase 3 scaling)
**Story Points :** 13
**Status :** defined
**Sprint :** v14-13 (Phase 3)
**Dépendances :** V14-027 (Casbin)

---

## User Story

> **En tant que** Scalario Shield à des milliers d'utilisateurs Phase 3 avec des centaines de règles ABAC par tenant,
> **je veux** que la décision "Cet user peut-il valider cette commande ?" soit évaluée en O(1) après pré-compilation, plutôt qu'en O(n×m) naivement (n users × m règles),
> **so that** la latence de décision reste < 5ms même à grande échelle, et l'ERP scale linéairement avec le nombre de tenants/users.

---

## Description

### Background

PRD v14 §22.3 — Rete Algorithm = niveau Avancé. Précalcule un réseau de patterns à partir des règles. Décision = walk du réseau (O(1)) au lieu de loop naïf (O(n×m)).

### Scope

**In scope :**
- Lib `nools` (Node.js Rete) ou implémentation custom NestJS
- `ReteService` qui charge les règles ABAC d'un tenant + compile en réseau Rete au boot (cached Redis)
- Hook dans `AbacGuard` : si tenant a > 50 règles ABAC → utilise Rete au lieu de CASL/Casbin
- Invalidation cache à chaque update policies tenant
- Tests perfs : 1000 règles × 100k évaluations < 500ms total

**Out of scope :**
- Multi-tenant cache éviction (Phase 3+)

---

## Acceptance Criteria

- [ ] **AC-01** — `nools` installé OU implémentation Rete custom.
- [ ] **AC-02** — `ReteService.compile(tenantId, rules)` retourne `ReteNetwork` cached Redis.
- [ ] **AC-03** — `ReteService.decide(network, user, obj, action) → bool` en < 1ms.
- [ ] **AC-04** — Hook `AbacGuard` : seuil 50 règles → bascule Rete (cache + decide).
- [ ] **AC-05** — Invalidation Redis sur `PATCH /tenants/:slug/abac_rules`.
- [ ] **AC-06** — Test perfs : 1000 règles × 100k évaluations < 500ms (vs ~30s naïf).
- [ ] **AC-07** — Test fonctionnel : 5 règles complexes → décision identique vs CASL/Casbin (parité).
- [ ] **AC-08** — Métriques Prometheus : `rete_decisions_total`, `rete_decision_duration_ms_p95`.

---

## Technical Notes

Rete précompile un réseau de patterns. Avantage : ajouter une règle ne ré-évalue pas tout. Inconvénient : compilation initiale coûteuse — d'où caching Redis.

### Edge cases

- Tenant avec règles dynamiques temps réel → invalidation immédiate
- Reset cache global Redis → recompile à la prochaine évaluation (warm-up délai 50-100ms)
- Règle malformée → log + ignore

---

## Dependencies

- **Prérequis :** V14-027 (Casbin sert de fallback < 50 règles)
- **Stories bloquées :** Phase 3 scaling (milliers users)

---

## Definition of Done

- [ ] Rete intégré
- [ ] Tests perfs + fonctionnels
- [ ] Métriques Prometheus
- [ ] Docs `docs/scalario-shield-rete.md`
- [ ] sprint-status.yaml V14-030 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| nools/Rete setup + ReteService | 4.0 |
| Hook AbacGuard + cache Redis | 3.0 |
| Tests perfs + fonctionnels | 4.0 |
| Métriques + docs | 2.0 |
| **Total** | **13** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
