# STORY-V14-033 : Performance — memoization Scalario Calc + vues matérialisées PostgreSQL

**Epic :** EPIC-V14-020 — Performance
**Priorité :** Should Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-12 (Phase 3)
**Dépendances :** V14-011 (Calc), V14-028 (Vault niveau 3)

---

## User Story

> **En tant qu'**utilisateur saisissant une facture de 1000 lignes (rare mais critique),
> **je veux** que les calculs live (total HT, TVA, TTC, remises) ne ralentissent pas l'UI au-delà de 60fps,
> **so that** même les cas extrêmes (gros bon de livraison, gros rapport financier) restent fluides en saisie.

---

## Description

### Background

PRD v14 §10.3 — 6 pièges AlgoEngine, dont #5 : "Performance — memoization + compilation closure Dart au premier appel pour 1000+ lignes calculées". Cette story livre la memoization + l'optimisation des vues matérialisées.

### Scope

**In scope :**
- `AlgoEngine.eval` avec memoization : si `formula + inputs` identique cache hit → résultat instant
- Compilation closure : si une formule est invoquée > 100 fois → compile en closure Dart/JS native
- Vues matérialisées PostgreSQL : `dashboard_kpis_mv`, `audit_summary_mv`, refresh par pg_cron 1h
- Benchmarks : 1000 lignes calc → < 200ms (vs 2000ms sans memoization)

**Out of scope :**
- GPU compute (Phase 4+)
- Cache distribué cross-node (Phase 4+)

---

## Acceptance Criteria

- [ ] **AC-01** — `AlgoEngine.eval(formula, inputs)` memoize via hashKey(formula + inputs) → cache LRU 1000 entrées.
- [ ] **AC-02** — Compilation closure : `compileFormula(formula): (inputs) => result` au 100ème call.
- [ ] **AC-03** — Vues matérialisées créées : `dashboard_kpis_mv`, `audit_summary_mv`.
- [ ] **AC-04** — Cron pg_cron : `REFRESH MATERIALIZED VIEW CONCURRENTLY` toutes les heures.
- [ ] **AC-05** — Bench : facture 1000 lignes (calc live) < 200ms p95.
- [ ] **AC-06** — Bench : dashboard KPIs query < 50ms (vs ~500ms sans MV).
- [ ] **AC-07** — Métriques Prometheus : `algoengine_cache_hits`, `algoengine_compilations`, `mv_refresh_duration`.

---

## Technical Notes

### Memoization simple

```dart
final _cache = LinkedHashMap<String, dynamic>();
const _maxCacheSize = 1000;

dynamic memoEval(Map formula, Map inputs) {
  final key = jsonEncode({...formula, ...inputs});
  if (_cache.containsKey(key)) return _cache[key];

  final result = _eval(formula, inputs);

  if (_cache.length >= _maxCacheSize) {
    _cache.remove(_cache.keys.first); // LRU
  }
  _cache[key] = result;
  return result;
}
```

### Edge cases

- Cache size memory > 100MB → reduce maxCacheSize
- Formula avec timestamp `today()` → ne pas cacher (changera demain)
- Vue matérialisée refresh fail → log + fallback live query

---

## Dependencies

- **Prérequis :** V14-011, V14-028
- **Stories bloquées :** Phase 3 scaling

---

## Definition of Done

- [ ] Memoization AlgoEngine
- [ ] Vues matérialisées + pg_cron
- [ ] Benchmarks 1000 lignes + dashboard
- [ ] Métriques Prometheus
- [ ] sprint-status.yaml V14-033 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Memoization AlgoEngine (Dart + NestJS) | 1.5 |
| Compilation closure | 1.0 |
| Vues matérialisées + pg_cron | 1.0 |
| Benchmarks + métriques | 1.5 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
