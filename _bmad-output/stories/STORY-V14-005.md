# STORY-V14-005 : Restructure NestJS (src/core/ + engines/ + bdui/ + config-agent/ + modules/ + ai/)

**Epic :** EPIC-V14-001 — Migration v13→v14
**Priorité :** Must Have
**Story Points :** 3
**Status :** defined
**Sprint :** v14-1 (2026-05-26 → 2026-06-08)
**Dépendances :** V14-001 (migration nomenclature)

---

## User Story

> **En tant que** dev backend Scalario,
> **je veux** que `apps/nestjs/src/` adopte la structure v14 (`core/`, `engines/`, `bdui/`, `config-agent/`, `modules/`, `ai/`),
> **so that** la navigation devient évidente, chaque couche a son dossier, et préparer Phase 2 (config-agent/ + ai/) ne demandera plus de gros déplacement.

---

## Description

### Background

PRD v14 §19.1 explicite la structure NestJS cible :

```
src/
├── core/               ← Global, chargé une fois
│   ├── auth/           JWT, OAuth2, sessions
│   ├── rbac/           Guards, Decorators, Roles
│   ├── abac/           CASL abilities, règles dynamiques
│   ├── tenant/         Résolution du tenant par attributs
│   └── audit/          Log chaque action sensible
│
├── engines/            ← Les 6 engines côté NestJS
│   ├── algo/           AlgoEngine TypeScript
│   ├── datasource/     DataSourceRegistry + queries
│   ├── action/         ActionEngine pipeline executor
│   └── workflow/       FSM + DAG validator
│
├── bdui/               ← Génère le JSON UI (reste)
│   ├── bdui.service.ts
│   ├── bdui.resolver.ts
│   └── bdui.validator.ts
│
├── config-agent/       ← Onboarding IA (Phase 2 — placeholder Phase 1)
│   ├── chat.gateway.ts        (WebSocket + SSE)
│   ├── extraction.service.ts  (LLM → ERPConfig)
│   └── tenant-generator.ts
│
├── modules/            ← Modules ERP génériques
│   └── [commandes|stock|facturation|rh|rapports]/
│
└── ai/                 ← Pont vers FastAPI
    ├── ai.client.ts        (HTTP client vers FastAPI)
    └── streaming.service.ts (SSE relay FastAPI → Flutter)
```

V14-001 a renommé sans déplacer. Cette story déplace effectivement les fichiers vers la nouvelle structure.

### Scope

**In scope :**
- Migration `git mv` des dossiers existants vers la nouvelle structure
- Mise à jour des imports relatifs
- Création des dossiers placeholders `config-agent/` et `ai/` (vides Phase 1, prêts Phase 2)
- Mise à jour `app.module.ts` (chemins d'import)
- Tests existants 100% verts après migration

**Out of scope :**
- Implémentation `config-agent/` ou `ai/` — V14-014 (FastAPI microservice) + V14-019 (Scalario Forge)
- Refactor du contenu de `modules/` (modèle 6 moteurs génériques) — V14-007
- Catalogue v14 restructure — V14-006

---

## Acceptance Criteria

- [ ] **AC-01** — Dossier `src/core/` contient `auth/`, `rbac/`, `abac/`, `tenant/`, `audit/`.
- [ ] **AC-02** — `src/security/` (v13) entièrement vidé → split entre `core/rbac/` et `core/abac/`.
- [ ] **AC-03** — `src/audit/` (v13) déplacé vers `src/core/audit/`.
- [ ] **AC-04** — Dossier `src/engines/` contient `algo/`, `datasource/`, `action/`, `workflow/`.
- [ ] **AC-05** — `src/module-engine/` (v13) déplacé vers `src/engines/action/`.
- [ ] **AC-06** — `src/workflow/` (v13) déplacé vers `src/engines/workflow/`.
- [ ] **AC-07** — `src/bdui/` reste à `src/bdui/` (déjà aligné v14).
- [ ] **AC-08** — Dossier vide `src/config-agent/` créé avec `.gitkeep` et `README.md` Phase 2.
- [ ] **AC-09** — Dossier vide `src/ai/` créé avec `.gitkeep` et `README.md` Phase 2.
- [ ] **AC-10** — Dossier `src/modules/` créé pour Phase 2 (les modules génériques V14-007 iront là).
- [ ] **AC-11** — `app.module.ts` imports mis à jour.
- [ ] **AC-12** — `pnpm typecheck` = 0 erreur.
- [ ] **AC-13** — `pnpm test` = tous tests verts (~616 active).
- [ ] **AC-14** — `git log --follow src/core/auth/` retrace l'historique depuis `src/auth/`.

---

## Technical Notes

### Migration table

| Source v13 | Cible v14 |
|---|---|
| `src/auth/` | `src/core/auth/` |
| `src/security/` (RBAC parts) | `src/core/rbac/` |
| `src/security/abac/` | `src/core/abac/` |
| `src/security/middleware/tenant.middleware.ts` | `src/core/tenant/tenant.middleware.ts` |
| `src/audit/` | `src/core/audit/` |
| `src/module-engine/handlers/`, `services/`, `dto/` | `src/engines/action/` |
| `src/workflow/executor/` | `src/engines/workflow/executor/` |
| `src/workflow/fsm/` | `src/engines/workflow/fsm/` |
| `src/workflow/validator/` | `src/engines/workflow/validator/` |
| `src/bdui/` | `src/bdui/` (no change) |
| `src/cache/` | `src/core/cache/` |
| `src/catalogue/` | `src/catalog-loader/` |
| `src/payment/` | (reste — sera supprimé V14-025 quand Mobile Money migre dans Scalario Sense Flutter) |
| `src/idempotency/` | `src/core/idempotency/` |
| `src/sync/` | (reste — sera migré dans `engines/action/sync.controller.ts` V14-026) |

### Edge cases

- Imports circulaires : si une refactor crée un cycle, splitter avec un fichier `types.ts` partagé
- Tests qui mockent des modules par chemin (`jest.mock('../../module-engine/...')`) → update via sed
- Migrations TypeORM : restent où elles sont (chemins SQL stables)

---

## Dependencies

- **Prérequis :** V14-001 (migration nomenclature) — pour avoir les noms à jour avant de déplacer
- **Stories bloquées :** V14-007 (6 moteurs ERP — vont dans `modules/`), V14-014 (FastAPI — câblage via `ai/`), V14-019 (Scalario Forge — code dans `config-agent/`)

---

## Definition of Done

- [ ] Migration committée par batches (1 commit par dossier de premier niveau)
- [ ] Tests + typecheck + lint verts
- [ ] `src/README.md` documentant la nouvelle structure
- [ ] sprint-status.yaml V14-005 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Migration `git mv` par batches | 1.0 |
| Update imports (sed + revues manuelles cas edge) | 1.0 |
| Création placeholders `config-agent/` `ai/` `modules/` | 0.25 |
| `src/README.md` documentation | 0.25 |
| Tests verts + typecheck | 0.5 |
| **Total** | **3** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
