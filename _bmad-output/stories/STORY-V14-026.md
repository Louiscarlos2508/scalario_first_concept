# STORY-V14-026 : Scalario Sync — CRDT Vector Clocks + ConflictReviewScreen (résolution automatique)

**Epic :** EPIC-V14-017 — Scalario Sync
**Priorité :** Must Have
**Story Points :** 13
**Status :** defined
**Sprint :** v14-10 (Phase 2)
**Dépendances :** STORY-033 v13 (Drift), STORY-034 v13 (Sync Queue), STORY-035 v13 (Conflict Resolution Phase 1)

---

## User Story

> **En tant qu'**utilisateur ERP offline (livreur Aïcha en zone sans réseau pendant 6h),
> **je veux** que mes modifications offline (livraisons confirmées, photos, signatures) soient mergées **automatiquement** avec celles que d'autres ont faites en ligne pendant ce temps, sans conflit ni perte de données dans 95% des cas,
> **so that** quand je reconnecte, l'app fait juste un merge intelligent en background — je vois `SyncStatusBar` passer "syncing" → "synced" sans dialog ni question, sauf dans les <5% de cas vraiment ambigus.

---

## Description

### Background

PRD v14 §22.2 — CRDT (Conflict-free Replicated Data Types) avec Vector Clocks = niveau Avancé. C'est l'upgrade de la STORY-035 v13 (server_wins/client_wins/manual) vers une vraie résolution automatique sans perte.

Principe :
- Chaque entité a un vector clock `{ user_a: 3, user_b: 1, user_c: 0 }` qui tracke la causalité des modifications
- Sync = merge déterministe basé sur les clocks :
  - Si clock A dominate B → A wins (B perdant)
  - Si A et B concurrent (pas de dominance) → merge field-level (last-write-wins par field) si pas chevauchement, sinon → ConflictReviewScreen

### Scope

**In scope :**
- Drift table : ajouter colonne `vector_clock JSONB` à `local_data` + `entities` (NestJS)
- Algo CRDT merge : `mergeCRDT(local, remote, base) → merged + conflicts`
- `ConflictReviewScreen` Flutter (UI résolution manuelle quand merge automatique impossible)
- ConflictDao étendu : list + resolve manuels
- Sync worker : intègre CRDT merge avant POST mutations
- Test : 5 scénarios CRDT (last-write-wins par field, concurrent edits, delete vs update, multi-user 3-way merge)
- Migration STORY-035 v13 : strategies `server_wins`/`client_wins`/`manual` restent pour Phase 1, **CRDT par défaut** pour les nouveaux tenants Phase 2

**Out of scope :**
- CRDT pour fichiers/blobs (photos, PDFs) — Phase 3
- Operational Transform (OT) pour texte collaboratif — Phase 3+

---

## Acceptance Criteria

### Schema

- [ ] **AC-01** — Migration NestJS : `ALTER TABLE entities ADD COLUMN vector_clock JSONB DEFAULT '{}'`.
- [ ] **AC-02** — Drift Flutter : `local_data.vector_clock TEXT (JSON serialized)`.
- [ ] **AC-03** — `tenant.config.conflict_strategy` accepte `'crdt'` (default Phase 2).

### Algo CRDT merge

- [ ] **AC-04** — `mergeCRDT(local: Entity, remote: Entity, base: Entity)` retourne `{ merged: Entity, conflicts: Conflict[] }`.
- [ ] **AC-05** — Cas A — clock local dominate remote → return local (no conflict).
- [ ] **AC-06** — Cas B — clock remote dominate local → return remote (no conflict).
- [ ] **AC-07** — Cas C — concurrent (pas de dominance) → merge field-level :
  - Si champ modifié seulement par local → local wins
  - Si champ modifié seulement par remote → remote wins
  - Si champ modifié par les deux → conflict reporté
- [ ] **AC-08** — Vector clock du résultat : `merge(local.clock, remote.clock)` (max par user).

### ConflictReviewScreen

- [ ] **AC-09** — Flutter `lib/features/sync_conflict_review/conflict_review_screen.dart` — liste des conflits non résolus.
- [ ] **AC-10** — Vue détail : 2 colonnes side-by-side (Local vs Remote) avec field highlights diff.
- [ ] **AC-11** — Boutons : "Garder ma version", "Garder serveur", "Fusionner manuel" (Phase 3).
- [ ] **AC-12** — Resolve → POST `/api/v1/:tenant/sync/conflicts/:id/resolve { choice }` → Scalario Live `data_updated`.

### Sync worker

- [ ] **AC-13** — Sync worker (STORY-034 v13) modifié : avant POST mutations, fetch remote state + apply mergeCRDT + send merged.
- [ ] **AC-14** — Si conflicts non résolvables auto → insert dans `ConflictDao` avec status `manual_review`.

### Tests

- [ ] **AC-15** — Test scénario A (clock dominate) : 3 users edit same entity séquentiel → no conflict.
- [ ] **AC-16** — Test scénario B (concurrent fields différents) : user A edit `qty`, user B edit `prix` simultané → merge OK auto.
- [ ] **AC-17** — Test scénario C (concurrent same field) : user A edit `qty=5`, user B edit `qty=8` simultané → conflict UI.
- [ ] **AC-18** — Test delete vs update : 1 user delete, autre update → conflict UI (politique : update wins par défaut, configurable).

---

## Technical Notes

### Vector Clock

```typescript
type VectorClock = Record<string /* userId */, number>;

function dominates(a: VectorClock, b: VectorClock): boolean {
  return Object.keys({...a, ...b}).every(k => (a[k] ?? 0) >= (b[k] ?? 0))
      && Object.keys({...a, ...b}).some(k => (a[k] ?? 0) > (b[k] ?? 0));
}

function merge(a: VectorClock, b: VectorClock): VectorClock {
  const result: VectorClock = {};
  for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) {
    result[k] = Math.max(a[k] ?? 0, b[k] ?? 0);
  }
  return result;
}
```

### Edge cases

- 3-way merge (A modifie, B modifie, C modifie) → applique CRDT pairwise
- Vector clock vide (tenant nouveau) → traité comme `{}`, no conflicts au start
- Clock corrompu (JSONB invalide) → fail-open vers server_wins, alerte audit

---

## Dependencies

- **Prérequis :** STORY-033/034/035 v13 (Drift + Sync queue + Conflict res Phase 1)
- **Stories bloquées :** rien (CRDT Phase 2 est la dernière brique offline)

---

## Definition of Done

- [ ] Schema vector_clock NestJS + Flutter
- [ ] Algo mergeCRDT testé sur 4 scénarios
- [ ] ConflictReviewScreen UI fonctionnel
- [ ] Sync worker intègre CRDT
- [ ] Docs `docs/scalario-sync-crdt.md`
- [ ] sprint-status.yaml V14-026 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Schema + migrations (NestJS + Drift) | 1.0 |
| Algo mergeCRDT + Vector Clocks | 4.0 |
| ConflictReviewScreen UI Flutter | 3.0 |
| Sync worker integration | 2.0 |
| Tests 4 scénarios + 3-way merge | 2.0 |
| Docs + memory | 1.0 |
| **Total** | **13** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
