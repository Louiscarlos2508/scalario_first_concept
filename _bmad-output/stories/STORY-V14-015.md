# STORY-V14-015 : DeepSeek V4-Flash hébergé sur cluster GPU (2× RTX 4090 ou A100)

**Epic :** EPIC-V14-009 — Scalario Mind
**Priorité :** Must Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-7 (Phase 2)
**Dépendances :** Cluster GPU (infra), V14-014 (FastAPI)

---

## User Story

> **En tant que** Scalario Labs,
> **je veux** héberger DeepSeek V4-Flash sur mon cluster GPU (2× RTX 4090 ou A100), avec un endpoint OpenAI-compatible, hot reload pour upgrades du modèle, monitoring GPU usage,
> **so that** chaque tenant utilise le LLM **sans coût marginal par requête** (vs OpenAI/Anthropic API), avec latence p95 < 800ms (premier token) et throughput suffisant pour 100 tenants concurrents.

---

## Description

### Background

PRD v14 §5.2 + §23.3 : DeepSeek V4-Flash hébergé sur cluster GPU = avantage économique majeur. Distillé pour tenir sur 2× RTX 4090 (~48 Go VRAM combined). Endpoint OpenAI-compatible (`/v1/chat/completions`) permet de switcher facilement entre providers.

### Scope

**In scope :**
- Setup vLLM ou TGI (Text Generation Inference) avec DeepSeek V4-Flash distillé
- Endpoint OpenAI-compatible (`POST /v1/chat/completions` + `streaming` true)
- Healthcheck `/health` (GPU memory, model loaded)
- Logging structuré (request id, tokens in/out, latency, GPU usage)
- Monitoring Prometheus metrics (tokens/s, GPU temp, mem)
- Configuration `services/fastapi/` pour utiliser ce LLM par défaut (env `DEEPSEEK_HOST`)
- Fallback Claude API (Anthropic Sonnet) configuré pour données sensibles (paie, finance, santé) via env `CLAUDE_API_KEY`

**Out of scope :**
- Multi-region GPU clusters — V14-035 (Phase 3)
- Fine-tuning sur données métier — Phase 3+
- DeepSeek V4-Pro pour tâches complexes (raisonnement Config Agent) — sous-story future

---

## Acceptance Criteria

- [ ] **AC-01** — Infrastructure GPU (2× RTX 4090 ou A100) provisionnée + accessible.
- [ ] **AC-02** — vLLM ou TGI déployé avec DeepSeek V4-Flash distillé.
- [ ] **AC-03** — Endpoint `POST /v1/chat/completions` compatible OpenAI : accepte `messages[]`, `stream: true|false`, `temperature`, `max_tokens`.
- [ ] **AC-04** — Streaming SSE token-par-token fonctionnel.
- [ ] **AC-05** — Healthcheck `/health` retourne `{status, gpu_memory_gb, model_loaded, gpu_util_pct}`.
- [ ] **AC-06** — Latency p95 premier token < 800ms (bench sur 100 requêtes typiques).
- [ ] **AC-07** — Throughput soutenu ≥ 50 req/min en parallèle (bench).
- [ ] **AC-08** — Logs structurés (JSON) : request_id, tokens_in, tokens_out, latency_ms, model_version.
- [ ] **AC-09** — Métriques Prometheus exposées (`/metrics`).
- [ ] **AC-10** — `services/fastapi/` utilise ce LLM par défaut via `env DEEPSEEK_HOST=http://gpu-cluster:8000`.
- [ ] **AC-11** — Fallback Claude API câblé (Phase 2 minimum : route fallback si DeepSeek down).
- [ ] **AC-12** — Documentation runbook : redémarrage cluster, swap modèle, monitoring.

---

## Technical Notes

### Choix vLLM vs TGI

- vLLM : meilleur throughput, PagedAttention, batch inference dynamique. Recommandé.
- TGI (Hugging Face) : alternative avec quantization 4-bit.

### Modèle distillé

DeepSeek V4-Flash distillé = version compressée du modèle full. Garde 80-90% des performances sur les tâches ERP-typiques (génération JSON structuré, classification métier, résumé conversationnel).

### Edge cases

- GPU saturé → queue de requêtes (vLLM le gère natif)
- Modèle non chargé au boot → retry exponentiel
- Crash GPU → restart automatique container

---

## Dependencies

- **Prérequis :** Infra cluster GPU (achat ou cloud), V14-014 (FastAPI)
- **Stories bloquées :** V14-019 (Scalario Forge), V14-022 (anti-hallucination)

---

## Definition of Done

- [ ] Cluster GPU opérationnel
- [ ] DeepSeek V4-Flash hébergé + healthcheck OK
- [ ] Bench latency + throughput documenté
- [ ] FastAPI utilise ce LLM par défaut
- [ ] Fallback Claude API câblé
- [ ] Runbook ops
- [ ] sprint-status.yaml V14-015 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Provisionnement infra GPU + vLLM setup | 3.0 |
| Modèle DeepSeek V4-Flash distillé + healthcheck | 2.0 |
| FastAPI integration + fallback Claude | 1.5 |
| Monitoring Prometheus + logs structurés | 1.0 |
| Bench latency + runbook | 0.5 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
