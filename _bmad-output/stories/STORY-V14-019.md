# STORY-V14-019 : Scalario Forge — Config Agent IA (Business Profile → ERPConfig via Instructor + Pydantic)

**Epic :** EPIC-V14-012 — Scalario Forge (Onboarding IA)
**Priorité :** Must Have (LE différentiant Phase 2)
**Story Points :** 13 (story la plus complexe v14)
**Status :** defined
**Sprint :** v14-9 (Phase 2)
**Dépendances :** V14-014, V14-015, V14-016, V14-017, V14-021

---

## User Story

> **En tant que** PME africaine sans DSI qui veut un ERP sur mesure,
> **je veux** remplir un Business Profile (formulaire libre 30 min), répondre à 3-7 questions de précision, et voir un ERP configuré pour mon métier apparaître sur mon Demo Space en quelques minutes,
> **so that** ce qui prenait 6 mois (consultant + dev) prend 45 minutes (Forge IA), et je peux tester mon ERP avant le go live avec des données fictives réalistes.

---

## Description

### Background

PRD v14 §17-§19 — Scalario Forge est le moteur d'onboarding IA. Pipeline complet :

1. Client remplit Business Profile (formulaire libre sauvegarde auto) — V14-021
2. Scalario Forge analyse → génère résumé technique en français
3. Forge pose 3-7 questions de précision (choix multiples) — anti-procrastination
4. Forge appelle DeepSeek V4-Pro avec Instructor → extrait `ERPConfig` structuré (Pydantic)
5. ConfigValidator NestJS valide (anti-hallucination couche 2)
6. Dry Run avec données fictives (anti-hallucination couche 3)
7. Résumé en français pour validation client (anti-hallucination couche 4)
8. → Demo Space (V14-020) pour test réel client

### Scope

**In scope :**
- `services/fastapi/agents/config_agent.py` — LangChain agent avec Instructor + Pydantic schema
- `services/fastapi/routers/config_agent.py` — endpoint `POST /config-agent/extract { business_profile, clarifications }` → `ERPConfig`
- Pydantic schema `ERPConfig` (metier, modules, roles, workflows, abac_rules, pipelines, ux_profile)
- Logique question de précision : si confiance < 80% sur un module/rôle/règle → générer question choix multiples (max 7 questions, jamais texte libre)
- NestJS `src/config-agent/tenant-generator.ts` consomme le ERPConfig + génère le `tenant_config` JSON
- Tests : 5 Business Profiles types (pharma, BTP, commerce, cabinet médical, restauration) → ERPConfig valide

**Out of scope :**
- Demo Space (V14-020)
- Anti-hallucination couches 5+6 (V14-022)
- UI Business Profile (V14-021)

---

## Acceptance Criteria

### Pydantic schema ERPConfig

- [ ] **AC-01** — Schema `ERPConfig` avec : `metiers[str]`, `modules[Module]` (héritage + overrides), `roles[Role]` (RBAC + attributs ABAC), `workflows[Workflow]` (FSM validés DAG), `abac_rules[ABACRule]`, `pipelines[Pipeline]`, `ux_profile[str]` (UNIQUEMENT dans UX_PROFILES catalogue).
- [ ] **AC-02** — `metiers` doit être dans METIERS_CATALOGUE (whitelist) — Instructor rejette toute valeur hors.
- [ ] **AC-03** — `ux_profile` doit être dans UX_PROFILES (whitelist).

### Config Agent (LangChain + Instructor)

- [ ] **AC-04** — Endpoint `POST /config-agent/extract { business_profile_text, clarifications? }` retourne `{ erp_config: ERPConfig, confidence: float, remaining_questions: [Question] }`.
- [ ] **AC-05** — Si JSON invalide → Instructor relance automatique jusqu'à 3 fois.
- [ ] **AC-06** — Si toujours invalide après 3 → return `{ questions: [...] }` pour le client.

### Anti-procrastination questions

- [ ] **AC-07** — Maximum 7 questions de précision.
- [ ] **AC-08** — Jamais de texte libre — toujours choix multiples (`type: 'choice', options: [...]`).
- [ ] **AC-09** — Chaque question doit changer quelque chose d'important dans la config (si info corrigeable post-go-live → ne pas demander maintenant).

### NestJS tenant-generator

- [ ] **AC-10** — `src/config-agent/tenant-generator.ts` accepte `ERPConfig` validé → génère `tenant.config` (JSONB) avec modules `inherits` + `overrides`.
- [ ] **AC-11** — Stocke dans `public.tenant_configs` + version snapshot dans `tenant_config_history`.

### Tests sectoriels

- [ ] **AC-12** — 5 Business Profiles types testés (pharma, BTP, commerce, cabinet médical, restauration) → ERPConfig valide produit dans chacun.
- [ ] **AC-13** — Test négatif : Business Profile contradictoire (ex: "Je veux des modules cargo + spa") → Forge pose questions de clarification.

---

## Technical Notes

### Pydantic schema (extrait)

```python
from pydantic import BaseModel
from typing import Literal

METIERS_CATALOGUE = ['pharmacie', 'btp', 'commerce_general', 'cabinet_medical', 'restauration']

class Module(BaseModel):
    module_id: str  # doit matcher catalog/modules/<sector>/<name>.json
    inherits: str | None = None
    overrides: dict = {}

class ERPConfig(BaseModel):
    metiers: list[Literal['pharmacie','btp','commerce_general','cabinet_medical','restauration']]
    modules: list[Module]
    roles: list[Role]
    workflows: list[Workflow]
    abac_rules: list[ABACRule]
    pipelines: list[Pipeline]
    ux_profile: Literal['pharmacie','btp','commerce_general','cabinet_medical']
```

### Edge cases

- Business Profile trop court (< 100 chars) → demande de compléter
- Business Profile contradictoire → pose questions
- Métier inconnu (ex: "garage automobile" non dans catalogue) → fallback `commerce_general` + alerte Carlos pour ajouter au catalogue
- Multiple métiers (ex: pharma + commerce général) → 2 espaces séparés (PRD v14 §13.2)

---

## Dependencies

- **Prérequis :** V14-014 (FastAPI), V14-015 (DeepSeek V4-Pro pour Config Agent), V14-016 (RAG pour contextualiser), V14-017 (Mem0 pour mémoriser ajustements), V14-021 (Business Profile UI)
- **Stories bloquées :** V14-020 (Demo Space utilise la config générée), V14-022 (anti-hallucination)

---

## Definition of Done

- [ ] Pydantic ERPConfig schema complet
- [ ] Config Agent endpoint + Instructor + retry 3x
- [ ] Anti-procrastination 7 questions max + choix multiples
- [ ] NestJS tenant-generator
- [ ] 5 tests sectoriels + 1 négatif
- [ ] Docs `docs/scalario-forge.md`
- [ ] sprint-status.yaml V14-019 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Pydantic ERPConfig schema (modules, roles, workflows, abac, pipelines, ux) | 2.5 |
| Config Agent (LangChain + Instructor + DeepSeek V4-Pro) | 4.0 |
| Anti-procrastination questions logic | 1.5 |
| NestJS tenant-generator | 2.0 |
| Tests 5 sectoriels + négatif | 2.0 |
| Docs | 1.0 |
| **Total** | **13** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
