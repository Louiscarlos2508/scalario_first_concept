# STORY-V14-016 : Hybrid RAG (pgvector + BM25 + Reciprocal Rank Fusion + Cohere Reranking)

**Epic :** EPIC-V14-010 — Scalario Search
**Priorité :** Must Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-7 (Phase 2)
**Dépendances :** V14-014, V14-015, V14-018 (Docling)

---

## User Story

> **En tant que** Scalario Mind (LLM) répondant à une question utilisateur basée sur les données ERP,
> **je veux** un RAG hybride qui combine recherche vectorielle (sémantique via pgvector) + recherche full-text (lexicale via BM25), fusionne via Reciprocal Rank Fusion, puis rerank avec Cohere Cross-Encoder pour top-5,
> **so that** la pertinence des sources retournées au LLM passe de ~50-60% (RAG basique embedding-only) à 85-90%, et le LLM hallucine moins.

---

## Description

### Background

PRD v14 §22.5 — Hybrid RAG + Cross-Encoder Reranking = niveau Avancé. La plupart des ERP IA s'arrêtent au RAG basique (embedding seul = 30-40% des résultats pertinents perdus).

Flow :
1. Query → embed (OpenAI ada ou Cohere ou local)
2. **Dual search en parallèle** :
   - pgvector cosine similarity → top 20 docs sémantiques
   - PostgreSQL `to_tsvector` BM25 → top 20 docs lexicaux
3. **Reciprocal Rank Fusion (RRF)** : merge les 2 listes avec score 1/(60+rank)
4. **Cross-Encoder Reranking** (Cohere Rerank API ou local) : trie les top 60 mergés avec un modèle plus précis
5. Return top 5

### Scope

**In scope :**
- Endpoint `services/fastapi/rag.py` : `POST /rag/search { query, user_ctx } → top 5 docs`
- Helper `hybrid_search(query, user_ctx)` avec dual search + RRF + reranking
- ABAC filter appliqué **AVANT** la recherche (security §11)
- Tests : 50 queries de référence, mesure @top-5 pertinence ≥ 85%
- Métriques : latence p95 < 500ms

**Out of scope :**
- Indexation docs (Docling) — V14-018
- Mem0 cross-sessions — V14-017
- Multi-tenant pgvector index — déjà existe dans `tenant_<id>.embeddings`

---

## Acceptance Criteria

- [ ] **AC-01** — `POST /rag/search { query: str, user_ctx: UserContext, limit?: int=5 }` retourne `{ results: [{ content, metadata, score }] }`.
- [ ] **AC-02** — ABAC filter (`departement_id`, `visible_roles`) appliqué **AVANT** la recherche pgvector ET BM25.
- [ ] **AC-03** — Dual search parallèle via `asyncio.gather` (vector + BM25).
- [ ] **AC-04** — RRF merge implémenté correctement : `score = sum(1/(60+rank) for each list)`.
- [ ] **AC-05** — Cross-encoder reranking via Cohere Rerank API (ou local fallback `bge-reranker-v2-m3`).
- [ ] **AC-06** — Top 5 retournés, ordre par score reranked.
- [ ] **AC-07** — Cas vide : si 0 résultat → return `{ results: [] }` (pas crash).
- [ ] **AC-08** — Latency p95 < 500ms (bench sur 100 requêtes).
- [ ] **AC-09** — Tests pertinence : 50 queries de référence métier (pharma, commerce, BTP) — top-5 contient ≥ 85% des docs attendus.

---

## Technical Notes

### Code core

```python
async def hybrid_search(query: str, user_ctx: UserContext) -> List[Document]:
    embedding = await embed(query)

    abac_filter = {
        'departement_id': user_ctx.dept_id,
        'visible_roles': {'$in': user_ctx.roles}
    }

    vector_results, keyword_results = await asyncio.gather(
        pgvector.query(embedding, filter=abac_filter, limit=20),
        pg_fulltext.search(query, filter=abac_filter, limit=20)
    )

    merged = reciprocal_rank_fusion(vector_results, keyword_results, k=60)
    reranked = await cohere_rerank(query=query, documents=merged, top_n=5)
    return reranked
```

### Reciprocal Rank Fusion

```python
def reciprocal_rank_fusion(list1, list2, k=60):
    scores = defaultdict(float)
    for rank, doc in enumerate(list1):
        scores[doc.id] += 1 / (k + rank + 1)
    for rank, doc in enumerate(list2):
        scores[doc.id] += 1 / (k + rank + 1)
    return sorted(set(list1 + list2), key=lambda d: -scores[d.id])
```

---

## Dependencies

- **Prérequis :** V14-014, V14-015 (LLM pour fallback queries), V14-018 (Docling pour indexer)
- **Stories bloquées :** V14-019 (Scalario Forge utilise RAG pour comprendre contexte client), V14-022 (anti-hallucination — RAG est la couche 1)

---

## Definition of Done

- [ ] Endpoint `/rag/search` opérationnel
- [ ] RRF + Cohere reranking testés
- [ ] ABAC filter appliqué (vérification sécurité)
- [ ] Bench 50 queries pertinence ≥ 85%
- [ ] Bench latency p95 < 500ms
- [ ] sprint-status.yaml V14-016 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Hybrid search (vector + BM25) | 2.0 |
| Reciprocal Rank Fusion | 1.0 |
| Cohere Rerank API integration | 1.5 |
| ABAC filter pre-search | 1.5 |
| Tests pertinence (50 queries) | 1.5 |
| Bench latency | 0.5 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
