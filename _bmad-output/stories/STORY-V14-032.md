# STORY-V14-032 : FSM XState générée automatiquement par Scalario Forge

**Epic :** EPIC-V14-012 — Scalario Forge
**Priorité :** Should Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-12 (Phase 3)
**Dépendances :** V14-019 (Forge), STORY-031 v13 (XState FSM)

---

## User Story

> **En tant que** Scalario Forge configurant un workflow ERP (commande approval, congés validation, livraison),
> **je veux** que l'IA génère directement la FSM XState (states + transitions + guards) depuis la description naturelle du Business Profile,
> **so that** le client décrit en français "commande > 500k validée par DG, sinon auto-confirmée" et la FSM XState valide + déployable apparaît automatiquement.

---

## Description

### Background

PRD v14 §22.4 — FSM XState généré par Forge. Couplé avec validation DAG (STORY-029 v13) pour s'assurer que la FSM est cohérente.

### Scope

**In scope :**
- Extension Pydantic schema `Workflow` dans ERPConfig (V14-019) :
  - `states: Dict[str, StateDef]` (XState format)
  - `initial_state: str`
  - `guards: Dict[str, str]` (expressions évaluables AlgoEngine)
  - `actions: Dict[str, ActionStep]`
- Agent `services/fastapi/agents/workflow_generator.py` qui prend la description NL et génère FSM XState valide
- Validation : DAG check + reachability check + transition coverage check
- Si invalide → Forge re-prompt LLM avec erreurs (anti-hallucination layer 2)
- Tests : 5 workflows types (commande approval, congés, livraison, paie, retour produit) → FSM générée + DAG valide

**Out of scope :**
- Visualisation XState (Phase 3+ — Stately viz integration)

---

## Acceptance Criteria

- [ ] **AC-01** — Pydantic `Workflow` schema avec `states`, `initial_state`, `guards`, `actions`.
- [ ] **AC-02** — `workflow_generator.py` agent retourne `Workflow` validé Instructor.
- [ ] **AC-03** — DAG validation (STORY-029 v13) appliqué post-generation.
- [ ] **AC-04** — Reachability check : tous les états doivent être atteignables depuis `initial_state`.
- [ ] **AC-05** — Transition coverage : chaque transition a un event ET un target valide.
- [ ] **AC-06** — Si validation fail → Forge re-prompt avec erreurs spécifiques (couche 2 anti-hallucination).
- [ ] **AC-07** — Tests : 5 workflows sectoriels générés correctement.
- [ ] **AC-08** — Test négatif : description ambiguë → Forge pose question de clarification.

---

## Technical Notes

### Workflow Pydantic

```python
class StateDef(BaseModel):
    on: Dict[str, Union[str, TransitionDef]]
    type: Optional[Literal['final']] = None
    meta: Optional[Dict[str, str]] = None

class TransitionDef(BaseModel):
    target: str
    cond: Optional[str] = None  # nom d'un guard

class Workflow(BaseModel):
    id: str  # 'wf_commande_approval'
    initial_state: str
    states: Dict[str, StateDef]
    guards: Dict[str, str] = {}  # nom → expression AlgoEngine
    actions: Dict[str, ActionStep] = {}
```

### Edge cases

- État unreachable → erreur claire "State 'X' est unreachable depuis 'initial'"
- Transition vers état inexistant → erreur "Transition 'submit' target 'unknown_state' n'existe pas"
- Cycle de validation infini → DAG validator catches

---

## Dependencies

- **Prérequis :** V14-019, STORY-031 v13
- **Stories bloquées :** Phase 3 — automatisation Forge avancée

---

## Definition of Done

- [ ] workflow_generator agent
- [ ] Validation DAG + reachability
- [ ] 5 tests sectoriels
- [ ] sprint-status.yaml V14-032 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Pydantic Workflow schema | 1.0 |
| workflow_generator agent | 3.0 |
| Validation DAG + reachability + coverage | 2.0 |
| 5 tests sectoriels | 1.5 |
| Docs | 0.5 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
