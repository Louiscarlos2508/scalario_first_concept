# Architecture v14 — Refonte Scalario

**Source** : `Scalario_Architecture_v14.pdf` (82 pages, 25 mai 2026)
**Auteur audit** : Carlos + Claude
**Date audit** : 2026-05-25
**Statut** : refonte en cours — code Sprint 1-4 reste sur `main`, refonte tracée ici

---

## Le pivot v14 en une page

### Avant (v13, livré Sprint 1-4)
- Modèle intégrateur certifié (60/40 MRR)
- Gate 0 Blandine 8 juillet 2026
- 1 template métier (`retail_fresh_produce.json`) avec 6 modules hardcodés
- Vocabulaire : BDUIEngine, ModuleEngine, WorkflowEngine, SyncEngine

### Après (v14)
- Modèle **SaaS pur** — "Shopify des ERP" pour PME africaines
- 3 phases produit : Mois 1-3 fondations → Mois 4-6 IA → Mois 7-12 scale
- **Modules génériques** (`ModuleList`, `ModuleForm`, `ModuleDetail`, `ModuleReport`, `ModuleKanban`, `ModuleDashboard`) + catalogue commun + override per-tenant
- Nomenclature produit : **Scalario Flow / Canvas / Form / Calc / Sense / Vault / Live / Forge / Stage / Mind / Memory / Search / Kit / Profile / Pipe / Shield / Sync / Watch**

---

## Les 7 engines + 12 services nommés

| Bloc | Nom Scalario | Rôle |
|---|---|---|
| Client | **Scalario** | Plateforme + client universel Flutter |
| Engine — orchestrateur | **Scalario Flow** | ActionEngine, pipelines JSON |
| Engine — UI | **Scalario Canvas** | ComponentRegistry + variantes + NavigationConfig |
| Engine — saisie | **Scalario Form** | FormEngine (orchestre Calc/Sense/Vault temps réel) |
| Engine — calcul | **Scalario Calc** | AlgoEngine, fonctions typées Zod/Dart dual runtime |
| Engine — hardware | **Scalario Sense** | CapabilityRegistry (scan/GPS/print BT/NFC/**Mobile Money**) |
| Engine — data | **Scalario Vault** | DataSourceRegistry (Drift offline + PostgreSQL + SQL catalogue) |
| Engine — realtime | **Scalario Live** | Realtime serveur → app (notif, refresh, badges) |
| Onboarding IA | **Scalario Forge** | Config Agent IA (FastAPI + LangChain + Instructor) |
| Test multi-rôles | **Scalario Stage** | Demo Space sandbox |
| LLM | **Scalario Mind** | DeepSeek V4-Flash hébergé sur cluster GPU |
| Mémoire IA | **Scalario Memory** | Mem0 cross-sessions |
| RAG | **Scalario Search** | Hybrid pgvector + BM25 + RRF + Cohere Rerank |
| Catalogue modules | **Scalario Kit** | `catalog/modules/` standards |
| Catalogue UX | **Scalario Profile** | `catalog/ux_profiles/` par métier |
| Pipelines IA | **Scalario Pipe** | Pipelines ActionEngine configurés par Forge |
| Sécurité | **Scalario Shield** | RBAC + ABAC (CASL + Casbin) + RLS PostgreSQL — 5 couches |
| Sync offline | **Scalario Sync** | CRDT Vector Clocks (Phase 2 — Phase 1 = server_wins) |
| Observabilité | **Scalario Watch** | Langfuse + NestJS Interceptors + audit logs |

---

## Décisions infra v14

- **5 services Docker** : `nestjs + fastapi + postgresql + redis + minio`
- **FastAPI microservice IA** dédié (RAG, Mem0, Config Agent, streaming LLM)
- **Cluster GPU** 2-4× RTX 4090 / A100 pour DeepSeek V4 distillé mutualisé
- **LLM principal** : DeepSeek V4-Flash hébergé
- **LLM fallback sensible** (paie/finance/santé) : Claude API Sonnet
- **Schema-per-tenant** PostgreSQL (`public.tenants` + `{tenant_id}.commandes`)
- **CASL + Casbin** pour ABAC (j'ai fait CASL seul dans STORY-019)
- **Mem0**, **Docling**, **LlamaIndex** ajoutés

---

## Fichiers de ce dossier

```
architecture-v14/
├── README.md                                  ← ce fichier
├── stories-audit/
│   └── STORY-AUDIT-v14.md                    ← tag des 43 stories existantes
├── prd/
│   └── PRD-v14.md                            ← PRD aligné v14
├── new-stories/
│   ├── NEW-STORIES-INDEX.md                  ← liste des ~15 nouvelles stories
│   └── STORY-V14-XXX-*.md                    ← stories détaillées
└── sprint-plan/
    └── sprint-plan-v14.md                    ← Sprint plan Phase 1 (Mois 1-3)
```

---

## Pourquoi le code Sprint 1-4 reste valide

- BDUI principe + ComponentRegistry + RuleEvaluator → renommé en **Scalario Canvas**
- WorkflowEngine FSM XState → renommé sous **Scalario Flow**
- ModuleEngine 2-endpoint pattern → refactor en **Scalario Flow** ActionEngine (pipelines JSON)
- Multi-tenant RBAC + ABAC + RLS → renommé **Scalario Shield**
- Offline Drift + sync queue → renommé **Scalario Vault** + **Scalario Sync**
- Idempotency HTTP cache → reste cohérent (Scalario Shield niveau request)
- Conflict Resolution Phase 1 (server_wins) → cohérent avec v14 Phase 1 (CRDT en Phase 2)
- PaymentAdapter NestJS → déplacé dans **Scalario Sense** (capability Flutter)

Le travail n'est pas perdu : c'est ~6000 lignes de code qui forment le squelette technique.
La refonte = renommage progressif + ajout des engines IA manquants (Forge, Stage, FastAPI).
