# STORY-V14-034 : i18n Phase 3 — Bambara, Wolof, Dioula, Haoussa, Arabe (RTL)

**Epic :** EPIC-V14-004 — i18n
**Priorité :** Should Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-14 (Phase 3)
**Dépendances :** V14-008 (i18n base FR/EN), V14-019 (Scalario Forge pour traduction auto)

---

## User Story

> **En tant que** PME en zone non-francophone (Sénégal Wolof, Mali Bambara, Nigeria/Niger Haoussa, Maghreb Arabe),
> **je veux** utiliser Scalario en langue locale,
> **so that** mes vendeurs/livreurs/commerciaux qui ne maîtrisent pas le français peuvent travailler dans leur langue.

---

## Description

### Background

PRD v14 §8b.1 — Phase 2/3 i18n langues africaines. Phase 1/2 = FR/EN (V14-008). Phase 3 = ARB Bambara + Wolof + Dioula + Haoussa + Arabe (RTL).

### Scope

**In scope :**
- 5 ARB files : `app_bm.arb` (Bambara), `app_wo.arb` (Wolof), `app_dy.arb` (Dioula), `app_ha.arb` (Haoussa), `app_ar.arb` (Arabe RTL).
- Couverture initiale : 100% navigation + rôles + modules + screens titles + messages critiques (errors). ~40-60% du total.
- Traduction : combo (a) Scalario Forge LLM traduit les clés depuis FR, (b) revue humaine par traducteur natif (~$200/langue), (c) post-edit.
- Locale `ar` testé en RTL : `Directionality.rtl` switch automatique.
- Tests : screenshot test par locale (golden tests) — vérifie le rendu RTL.

**Out of scope :**
- Variations dialectales (Wolof Lebou vs Wolof Saint-Louis) — Phase 4+
- Voice input multilangue (Phase 4+)

---

## Acceptance Criteria

- [ ] **AC-01** — 5 ARB files créés avec couverture ≥ 40% initialement.
- [ ] **AC-02** — Locale Bambara (`bm`), Wolof (`wo`), Dioula (`dy`), Haoussa (`ha`), Arabe (`ar`) ajoutées à `MaterialApp.supportedLocales`.
- [ ] **AC-03** — `Directionality.rtl` automatique pour `ar`.
- [ ] **AC-04** — Helper `Currency.format` adapté RTL (signe avant ou après selon locale).
- [ ] **AC-05** — DateFmt adapté formats locaux (Hijri optional pour Arabe).
- [ ] **AC-06** — Scalario Forge fallback auto : si une clé n'existe pas en `bm` → fallback `fr` (jamais texte brut).
- [ ] **AC-07** — Golden tests : Login screen + Dashboard + Form en `ar` (RTL) — layout cohérent.
- [ ] **AC-08** — Test : changement locale runtime (FR → AR) → UI flip RTL sans restart app.

---

## Technical Notes

### Stratégie traduction

1. Scalario Forge LLM traduit FR → langues cibles
2. Export ARB → fichier de revue manuelle (`docs/i18n-review-<lang>.md`)
3. Traducteur natif annote (15-25h par langue à $20-30/h)
4. Post-edit + commit final
5. CI lint vérifie qu'aucune clé fr n'est en valeur (signe de non-traduction)

### Edge cases

- Arabe RTL avec chiffres LTR (montants) → `bidi` algorithm gère
- Wolof avec caractères spéciaux Unicode → font subset complet
- Bambara : tons (lettres accentuées) → vérifier rendu Roboto/Inter

---

## Dependencies

- **Prérequis :** V14-008, V14-019
- **Stories bloquées :** Phase 3 extension géographique (Maghreb, Nigeria, Sénégal)

---

## Definition of Done

- [ ] 5 ARB files (40%+ couverture)
- [ ] RTL Arabe testé
- [ ] Forge fallback FR opérationnel
- [ ] Golden tests RTL
- [ ] sprint-status.yaml V14-034 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| 5 ARB files + traduction Forge | 2.0 |
| Revue humaine native (coordination) | 0.5 |
| RTL Arabe + Directionality | 1.0 |
| Tests goldens RTL | 1.0 |
| Docs | 0.5 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
