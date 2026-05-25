# STORY-V14-014 : FastAPI microservice IA (chat + rag + config-agent + embeddings + memory)

**Epic :** EPIC-V14-009 — Scalario Mind (Microservice IA)
**Priorité :** Must Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-7 (Phase 2 — Mois 4-6)
**Dépendances :** V14-005 (restructure NestJS), Docker compose cluster GPU

---

## User Story

> **En tant que** Scalario,
> **je veux** un microservice Python FastAPI dédié à l'IA (RAG hybride, Mem0 mémoire, Config Agent, streaming LLM SSE token-par-token, embeddings indexation Docling),
> **so that** la stack IA (LangChain + Instructor + Pydantic + LlamaIndex + Mem0 + Docling) reste isolée de NestJS (Node.js), et qu'on bénéficie de l'écosystème Python pour l'IA tout en gardant NestJS pour le métier ERP.

---

## Description

### Background

PRD v14 §23 spécifie le microservice IA en FastAPI. NestJS appelle FastAPI via HTTP + SSE relay pour le streaming. L'isolement par service Docker permet de :
- Utiliser LangChain/Instructor (Python) sans polluer NestJS
- Scaler indépendamment IA vs API métier
- Mettre à jour les modèles sans toucher au métier

### Scope

**In scope :**
- `services/fastapi/` nouveau service Docker
- `pyproject.toml` (Poetry ou uv) : `fastapi`, `langchain`, `instructor`, `pydantic`, `llama-index`, `mem0`, `docling`, `pgvector`
- 5 routers : `chat.py` (SSE streaming), `rag.py` (hybrid search), `config_agent.py` (extraction ERPConfig), `embeddings.py` (indexation), `memory.py` (Mem0 facade)
- 3 agents : `config_agent.py`, `query_agent.py`, `summarizer.py`
- Healthcheck `/healthz` consommé par Docker
- Pont NestJS → FastAPI : `src/ai/ai.client.ts` + `streaming.service.ts` (SSE relay)

**Out of scope :**
- DeepSeek V4 hébergement cluster GPU — V14-015
- Implémentation Hybrid RAG — V14-016
- Mem0 plein — V14-017
- Docling parsing détaillé — V14-018
- Scalario Forge (Config Agent) implémentation — V14-019

---

## Acceptance Criteria

- [ ] **AC-01** — `services/fastapi/Dockerfile` + `pyproject.toml` + `docker-compose.yml` ajout du service.
- [ ] **AC-02** — Structure : `ai-service/{routers,agents,rag,memory,config}/`.
- [ ] **AC-03** — Healthcheck `GET /healthz` retourne `{status: 'ok', llm: 'connected'|'degraded'}`.
- [ ] **AC-04** — Auth via API key partagée FASTAPI_INTERNAL_KEY (header `X-Internal-Key`) — accès interne NestJS-only Phase 2 ; Phase 3 = JWT propre.
- [ ] **AC-05** — Stub routes : `POST /chat`, `POST /rag/search`, `POST /config-agent/extract`, `POST /embeddings/index`, `GET /memory/:userId` — toutes return 501 Not Implemented sauf healthz.
- [ ] **AC-06** — NestJS `src/ai/ai.client.ts` configuré avec HTTP client typed + retry.
- [ ] **AC-07** — `streaming.service.ts` : SSE relay `FastAPI → NestJS → Flutter` (proxy SSE).
- [ ] **AC-08** — Test E2E : NestJS appelle `POST /chat` → FastAPI répond stub → relay vers Flutter.
- [ ] **AC-09** — Docs `services/fastapi/README.md` (setup, env vars, comment ajouter un router).

---

## Technical Notes

### Stack Python

```
fastapi[all]==0.115.x
uvicorn[standard]==0.34.x
pydantic==2.10.x
instructor==1.7.x        # Structured outputs from LLMs
langchain==0.3.x         # LLM orchestration
langchain-community==0.3.x
llama-index==0.12.x      # RAG
pgvector==0.3.x          # PostgreSQL vector store
mem0ai==0.1.x            # Memory layer
docling==2.x             # Docs parsing
httpx==0.28.x            # HTTP client to DeepSeek V4
anthropic==0.40.x        # Claude fallback
```

### Docker compose

```yaml
services:
  fastapi:
    build: ./services/fastapi
    ports: ["8001:8001"]
    environment:
      DEEPSEEK_HOST: http://deepseek-gpu:8000
      DATABASE_URL: ${DATABASE_URL}
      REDIS_URL: ${REDIS_URL}
      FASTAPI_INTERNAL_KEY: ${FASTAPI_INTERNAL_KEY}
    depends_on: [postgresql, redis]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/healthz"]
```

---

## Dependencies

- **Prérequis :** V14-005 (`src/ai/` placeholder), V14-009 (Swagger pour documenter le pont NestJS↔FastAPI)
- **Stories bloquées :** V14-015, V14-016, V14-017, V14-018, V14-019, V14-020

---

## Definition of Done

- [ ] Service FastAPI buildable + run
- [ ] 5 routers stubbed + healthcheck OK
- [ ] NestJS ai.client + streaming.service opérationnels
- [ ] Tests E2E + docs
- [ ] sprint-status.yaml V14-014 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Setup FastAPI + Poetry/uv + Dockerfile | 2.0 |
| 5 routers stubbed + healthcheck + auth API key | 2.0 |
| NestJS ai.client + streaming.service SSE relay | 2.0 |
| Docker compose + env vars | 1.0 |
| Tests E2E + docs | 1.0 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
