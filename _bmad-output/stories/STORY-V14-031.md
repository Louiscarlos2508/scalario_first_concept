# STORY-V14-031 : Langfuse intégration — observabilité LLM complète

**Epic :** EPIC-V14-014 — Scalario Watch
**Priorité :** Must Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-11 (Phase 3)
**Dépendances :** V14-014, V14-015, V14-022

---

## User Story

> **En tant que** Scalario Labs surveillant le comportement de tous les LLM calls cross-tenant,
> **je veux** Langfuse intégré pour tracer chaque call LLM (latency, tokens in/out, coût équivalent, prompt, response, anti-hallucination layer reached, user/tenant),
> **so that** je peux : (a) débugger les hallucinations en live, (b) mesurer le coût marginal réel de l'IA hébergée, (c) identifier les patterns d'usage par tenant, (d) optimiser les prompts.

---

## Description

### Background

PRD v14 §23 — Langfuse = observabilité LLM open-source. Self-hosted ou cloud. Hooks dans FastAPI + NestJS pour tracer toutes les interactions IA.

### Scope

**In scope :**
- Langfuse self-hosted via Docker compose (ajout 1 service)
- SDK Langfuse Python intégré dans FastAPI (`chat.py`, `config_agent.py`)
- SDK Langfuse Node.js intégré dans NestJS (relay calls)
- Auto-tracing : chaque call LLM crée une trace avec spans (RAG retrieval, LLM call, post-processing)
- Annotations anti-hallucination : tracer "layer 1 passed", "layer 2 passed", etc.
- Dashboard Langfuse : top traces longues, top hallucinations détectées par couche, coût par tenant (Phase 3 = $0 car hébergé)
- Alertes : si > 5% hallucinations layer 1 rejetées sur 1h → notification Slack/email Carlos

**Out of scope :**
- Coût $ par tenant (Phase 4 quand on facture l'IA aux tenants)
- A/B testing prompts (Phase 3+)

---

## Acceptance Criteria

- [ ] **AC-01** — Langfuse self-hosted dans `docker-compose.yml` (service `langfuse:`).
- [ ] **AC-02** — `services/fastapi/` : `from langfuse import Langfuse` initialisé. Chaque LLM call wrapped via `@observe()`.
- [ ] **AC-03** — `src/ai/ai.client.ts` NestJS : Langfuse SDK pour les calls relay.
- [ ] **AC-04** — Métadonnées : `{user_id, tenant_id, layer_passed, model, latency_ms, tokens_in, tokens_out}`.
- [ ] **AC-05** — Dashboard Langfuse accessible en dev (`localhost:3001`).
- [ ] **AC-06** — Alerte Slack/email : > 5% hallucinations layer 1 sur 1h.
- [ ] **AC-07** — Test : 10 LLM calls → 10 traces visibles dans Langfuse avec metadata complète.

---

## Technical Notes

### Setup FastAPI

```python
from langfuse import Langfuse
from langfuse.decorators import observe

langfuse = Langfuse()

@observe()
async def llm_call(messages, user_id, tenant_id):
    langfuse.update_current_observation(user_id=user_id, metadata={'tenant_id': tenant_id})
    response = await deepseek.chat(messages)
    return response
```

### Edge cases

- Langfuse down → fail-open (log warning, LLM continue)
- Trace > 10 MB (gros context) → tronque + flag

---

## Dependencies

- **Prérequis :** V14-014, V14-015, V14-022 (couches anti-hallucination)
- **Stories bloquées :** Phase 3 — monitoring opérationnel

---

## Definition of Done

- [ ] Langfuse self-hosted
- [ ] SDK FastAPI + NestJS
- [ ] Métadonnées complètes
- [ ] Alertes
- [ ] sprint-status.yaml V14-031 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Langfuse self-hosted Docker | 1.5 |
| SDK FastAPI integration | 1.5 |
| SDK NestJS integration | 1.0 |
| Alertes + tests | 1.0 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
