# STORY-V14-022 : Anti-hallucination 6 couches opérationnelles (Instructor + ConfigValidator + Dry Run + Résumé NL + Demo Space + Rollback 30j)

**Epic :** EPIC-V14-014 — Scalario Watch (Observabilité + Anti-hallucination)
**Priorité :** Must Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-10 (Phase 2)
**Dépendances :** V14-019, V14-020, V14-031 (Langfuse Phase 3)

---

## User Story

> **En tant que** Scalario Labs livrant des ERP IA-driven à des clients réels,
> **je veux** 6 couches de protection anti-hallucination opérationnelles, de telle sorte qu'un LLM qui invente une fonction, une référence ou un workflow soit **détecté à minimum 1 couche** avant que le client ne soit impacté,
> **so that** la fiabilité des ERP générés par Scalario Forge approche les 100% — pas 99% — sur les modules critiques (paie, finance, santé).

---

## Description

### Background

PRD v14 §16.1 — 6 couches anti-hallucination explicites :

| Couche | Mécanisme | Ce qu'elle détecte |
|---|---|---|
| 1 Structure | Instructor + Zod/Pydantic | Fonctions inexistantes, JSON invalide |
| 2 Logique | ConfigValidator NestJS | Types incohérents, refs manquantes, cycles DAG |
| 3 Exécution | Dry Run données fictives | Bugs runtime |
| 4 Métier | Résumé langage naturel | Mauvaise compréhension client |
| 5 Test réel | Demo Space sandbox | Le client teste lui-même |
| 6 Filet | Rollback 30 jours | Tout bug passé en prod → retour 1 clic |

Cette story orchestre + teste ces 6 couches **ensemble**.

### Scope

**In scope :**
- Couche 1 : déjà fait via Instructor dans V14-019 — ajouter logs structurés Langfuse
- Couche 2 : `src/bdui/bdui.validator.ts` étendu pour valider TYPES + REFS + CYCLES sur ERPConfig
- Couche 3 : `services/fastapi/agents/dry_run.py` — run pipeline ActionEngine avec mocked data, détecte runtime errors
- Couche 4 : `services/fastapi/agents/summarizer.py` — génère résumé en français du ERPConfig pour client
- Couche 5 : Demo Space (V14-020) avec instrumentation des erreurs
- Couche 6 : `tenant_config_history` table + endpoint `POST /tenants/:slug/rollback?version=N` (30 jours retention)
- Test E2E : injecter une hallucination à chaque couche → vérifier détection
- Monitoring : dashboard Grafana "Anti-hallucination" avec métriques par couche

**Out of scope :**
- Langfuse setup détaillé — V14-031 (Phase 3)
- Auto-mitigation (l'IA se corrige) — Phase 3+

---

## Acceptance Criteria

### Couche 1 — Instructor

- [ ] **AC-01** — Pydantic ERPConfig (V14-019) rejette toute valeur hors catalogue avec message clair.
- [ ] **AC-02** — Test : LLM invente module `module_xyz` → Instructor retry 3 fois → final reject + erreur user-friendly.
- [ ] **AC-03** — Logs structurés : `{layer: 1, type: 'structure_rejection', llm_attempts: 3, rejected_value: 'module_xyz'}`.

### Couche 2 — ConfigValidator NestJS

- [ ] **AC-04** — `bdui.validator.ts` détecte refs `inherits: 'catalog/modules/zzz'` vers fichiers inexistants.
- [ ] **AC-05** — Détecte cycles DAG dans workflows (via STORY-029 v13 DAG validator).
- [ ] **AC-06** — Détecte types incohérents (ex: `field.type: 'currency'` mais `currency_source` absent).

### Couche 3 — Dry Run

- [ ] **AC-07** — `services/fastapi/agents/dry_run.py` accepte `ERPConfig` + `mocked_data` → exécute chaque pipeline + workflow → collecte erreurs runtime.
- [ ] **AC-08** — Test : pipeline qui référence variable inexistante `$inexistant` → Dry Run détecte + return erreur claire.

### Couche 4 — Résumé NL

- [ ] **AC-09** — Summarizer agent génère résumé en français : "Voici la config de votre ERP : 6 modules (Commandes, Stock, Factures...), 3 rôles (Vendeur, Manager, DG), workflow validation > 500k XOF par DG. Confirmez-vous ?".
- [ ] **AC-10** — Client clique "Modifier" → reformule en chat.

### Couche 5 — Demo Space instrumentée

- [ ] **AC-11** — Demo Space (V14-020) capture chaque erreur user + traces dans `audit_logs` avec `event: 'demo_space_error'`.
- [ ] **AC-12** — Dashboard Grafana stub affiche count erreurs par scénario.

### Couche 6 — Rollback 30j

- [ ] **AC-13** — Table `tenant_config_history` créée (id, tenant_id, version, config JSONB, diff JSONB, created_at).
- [ ] **AC-14** — Trigger PostgreSQL : à chaque INSERT sur `tenant_configs`, snapshot dans `tenant_config_history`.
- [ ] **AC-15** — Endpoint `POST /api/v1/tenants/:slug/rollback?version=N` (OWNER + SUPER_ADMIN) — restore en 1 clic.
- [ ] **AC-16** — Rétention 30j : cron quotidien purge `WHERE created_at < NOW() - INTERVAL '30 days'`.

### Tests E2E par couche

- [ ] **AC-17** — 6 tests E2E, 1 par couche, qui injectent une hallucination + vérifient détection.
- [ ] **AC-18** — Test combiné : hallucination passe couches 1+2 (genre type valide mais sémantiquement faux) → couche 3 Dry Run la rattrape.

---

## Technical Notes

### Dashboard métriques

```
Couche 1 (Instructor) : N rejets / heure, top 5 fonctions rejetées
Couche 2 (ConfigValidator) : N rejets / heure, top 5 erreurs (cycle DAG, ref manquante...)
Couche 3 (Dry Run) : N erreurs runtime / 100 dry runs
Couche 4 (Résumé NL) : N rejets client après lecture résumé
Couche 5 (Demo Space) : N erreurs user / scénario
Couche 6 (Rollback) : N rollbacks effectués / mois
```

### Edge cases

- Hallucination passe les 6 couches (très rare) → audit log alerte CEO + post-mortem
- Couche 1 Instructor relance infinie → cap 3 retries + return clarification questions
- Rollback en cas de migration DB en cours → impossible (verrou Postgres)

---

## Dependencies

- **Prérequis :** V14-019, V14-020, V14-031 (Langfuse pour logs structurés)
- **Stories bloquées :** Confiance Phase 2 (semi-self-service ne peut pas démarrer sans anti-hallucination opérationnelle)

---

## Definition of Done

- [ ] 6 couches opérationnelles + tests E2E
- [ ] Dashboard Grafana minimal
- [ ] Rollback 30j fonctionnel
- [ ] Docs `docs/anti-hallucination.md`
- [ ] sprint-status.yaml V14-022 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Couche 1 Instructor logs + tests | 0.5 |
| Couche 2 ConfigValidator étendu | 1.5 |
| Couche 3 Dry Run agent FastAPI | 2.0 |
| Couche 4 Summarizer agent | 1.0 |
| Couche 5 Demo Space instrumentation | 0.5 |
| Couche 6 Rollback 30j + cron | 1.5 |
| Tests E2E 6 couches + combiné | 1.0 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
