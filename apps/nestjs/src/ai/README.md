# `ai/` — Pont NestJS ↔ FastAPI (Phase 2)

**Status :** Placeholder. À implémenter en Phase 2 (V14-014 — FastAPI microservice).

## Rôle (cf PRD v14 §19.1, §19.5)

Le module `ai/` est le **client HTTP** entre NestJS (couche métier) et le microservice **FastAPI/Python** qui héberge l'IA Scalario (DeepSeek V4 + LangChain + LlamaIndex + pgvector + Mem0).

NestJS reste le **gardien** (RBAC + ABAC + RLS + audit) ; FastAPI fait l'inférence LLM brute.

## Contenu attendu (Phase 2)

```
ai/
├── ai.client.ts             # HTTP client typé vers FastAPI (Axios + Zod)
├── streaming.service.ts     # SSE relay FastAPI → Flutter (chunks LLM)
├── rag.client.ts            # Wrapper sur LlamaIndex + pgvector
├── memory.client.ts         # Wrapper sur Mem0 (user/session/long-term)
└── __tests__/
```

## Flow type

```
Flutter → NestJS (auth/rbac/abac) → ai/ai.client.ts → FastAPI (LLM) → ai/streaming.service.ts → Flutter (SSE)
                                  ↑                                  ↓
                                  └──── Scalario Watch (audit) ──────┘
```

## Dépendances futures

- FastAPI microservice (image Docker séparée, port 8000)
- `core/audit/` (log toutes les requêtes IA pour traçabilité)
- `config-agent/` (premier consommateur en Phase 2)

## Liens

- Story Phase 2 : `_bmad-output/stories/STORY-V14-014.md`
- PRD v14 §19.5 — Stack 5 services Docker
