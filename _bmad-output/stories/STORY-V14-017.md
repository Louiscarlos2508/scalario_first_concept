# STORY-V14-017 : Scalario Memory — Mem0 cross-sessions + injection prompt

**Epic :** EPIC-V14-011 — Scalario Memory
**Priorité :** Must Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-7 (Phase 2)
**Dépendances :** V14-014 (FastAPI)

---

## User Story

> **En tant qu'**utilisateur Scalario interagissant avec le LLM (Scalario Forge ou query agent),
> **je veux** que le système se souvienne de mes préférences (ex: "Je préfère exporter en XLS", "Je cherche souvent les commandes du mois") sans que j'aie à les re-spécifier à chaque session,
> **so that** Scalario apprend mon usage métier et personnalise les réponses, sans stocker l'historique complet de toutes mes conversations.

---

## Description

### Background

PRD v14 §23 + §21.3 : Mem0 est une lib qui extrait les **faits importants** d'une conversation, les stocke par user, et les injecte dans les prompts ultérieurs. ≠ d'un historique brut (Mem0 distille).

Exemple :
- Session 1 : User : "Donne-moi le CA du mois en XLS" → LLM : [retourne XLS] → Mem0 stocke `user.export_pref = XLS`
- Session 2 (jour suivant) : User : "Donne-moi le CA semaine" → LLM : reçoit memory `user.export_pref = XLS` dans system prompt → retourne XLS directement

### Scope

**In scope :**
- Endpoint `services/fastapi/memory.py` : `POST /memory/add { user_id, content }`, `GET /memory/search { user_id, query, limit }`.
- Hook automatique dans `chat.py` : après chaque interaction LLM significative, extraire les faits avec Mem0 + stocker.
- Injection prompt : avant chaque appel LLM, fetch top 5 memories du user + inject dans system prompt.
- ABAC : memories scopés par `user_id` + `tenant_id` (jamais cross-tenant).
- Tests : conversation Session 1 → Session 2, vérifier que le LLM use la préférence stockée.

**Out of scope :**
- Mem0 entreprise (cross-user dans même tenant) — Phase 3
- Mem0 forgetting (GDPR right to delete) — Phase 3

---

## Acceptance Criteria

- [ ] **AC-01** — `POST /memory/add { user_id, tenant_id, content }` extrait faits Mem0 + stocke.
- [ ] **AC-02** — `GET /memory/search { user_id, tenant_id, query, limit=5 }` retourne top memories pertinentes.
- [ ] **AC-03** — Hook dans `chat.py` : après réponse LLM, si conversation contient choix utilisateur clair → Mem0 add.
- [ ] **AC-04** — System prompt builder : avant call LLM, injecte top 5 memories formatées : "User context: {memories}".
- [ ] **AC-05** — ABAC : memory de user A ne peut JAMAIS être retournée à user B (filtre `WHERE user_id = $1 AND tenant_id = $2`).
- [ ] **AC-06** — Tests session 1→2 : préférence stockée en S1, automatiquement appliquée en S2.
- [ ] **AC-07** — Latency add < 200ms (Mem0 extraction async possible).
- [ ] **AC-08** — Latency search < 100ms (cache Redis).

---

## Technical Notes

### Mem0 setup

```python
from mem0 import Memory

memory = Memory(config={
    'vector_store': {'provider': 'pgvector', 'config': {'connection_string': DATABASE_URL}},
    'llm': {'provider': 'custom', 'config': {'endpoint': DEEPSEEK_HOST}},
})

# Ajouter une mémoire
memory.add(content="L'utilisateur préfère exporter en XLS", user_id=user_id, metadata={'tenant_id': tenant_id})

# Rechercher
memories = memory.search(query="format export préféré", user_id=user_id, limit=5)
```

### Hook chat.py

```python
@router.post('/chat')
async def chat(req: ChatRequest):
    # 1. Fetch memories
    memories = memory.search(query=req.message, user_id=req.user_id, limit=5)

    # 2. System prompt
    system = f"Tu es Scalario. Contexte user : {memories}"

    # 3. LLM call
    response = await llm_call(system=system, messages=req.messages)

    # 4. Async hook : extract + store new memories
    asyncio.create_task(memory.add(
        content=f"User asked: {req.message}. Assistant: {response.text}",
        user_id=req.user_id,
        metadata={'tenant_id': req.tenant_id}
    ))

    return response
```

### Edge cases

- Memory vide pour nouvel user → prompt minimal sans contexte
- Mem0 down → fail-open (LLM call sans memories, log warning)
- User supprimé → `DELETE FROM mem0_data WHERE user_id = $1` (Phase 3 GDPR)

---

## Dependencies

- **Prérequis :** V14-014 (FastAPI), V14-015 (LLM pour Mem0 extraction)
- **Stories bloquées :** V14-019 (Scalario Forge utilise memory pour personnalisation)

---

## Definition of Done

- [ ] Endpoints add + search
- [ ] Hook auto chat.py
- [ ] System prompt builder
- [ ] ABAC test (cross-user isolation)
- [ ] Tests session 1→2
- [ ] sprint-status.yaml V14-017 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Mem0 setup + endpoints | 1.5 |
| Hook auto chat.py + system prompt builder | 1.5 |
| ABAC tenant+user scoping | 1.0 |
| Tests E2E session | 1.0 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
