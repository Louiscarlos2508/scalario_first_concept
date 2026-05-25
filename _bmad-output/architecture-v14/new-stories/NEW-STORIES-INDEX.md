# Nouvelles Stories v14 — Index

**Convention** : `V14-XXX` pour distinguer des stories v13 (S1-S43).
**Date** : 2026-05-25

---

## Récap

| Catégorie | Count |
|---|---|
| Renommages (refactor de naming sans nouveau code) | 6 (couvert dans l'audit, pas de story dédiée — script de migration suffit) |
| Refactor structurel (existant à réorganiser) | 7 stories V14 |
| Nouvelles features (composants/engines IA n'existant pas) | 10 stories V14 |
| **Total nouvelles stories** | **17** |

---

## Phase 1 (Mois 1-3) — Fondations Scalario

### Refactor structurel (existant → v14)

| Story | Titre | Pts | Bloc | Dépend de |
|---|---|---|---|---|
| **V14-001** | Rename Sprint 1-4 → nomenclature Scalario (script migration) | 2 | Tooling | — |
| **V14-002** | Schéma BDUI — ajout `variant: string` à ComponentConfig + `actions[]` + `children[]` | 3 | Scalario Canvas | S23 |
| **V14-003** | ComponentRegistry → dispatch par variante (KPICard.fromConfig avec resolveVariant) | 5 | Scalario Canvas | S5, V14-002 |
| **V14-004** | Catalogue de composants × variantes (12 composants, ~50 variantes) | 5 | Scalario Canvas | V14-003 |
| **V14-005** | Restructure NestJS : `src/core/ + engines/ + bdui/ + config-agent/ + modules/ + ai/` | 3 | Backend | S13, S21 |
| **V14-006** | Catalogue v14 : `catalog/modules/` génériques + `catalog/ux_profiles/` par métier + `catalog/queries/` SQL nommé | 5 | Scalario Kit/Profile/Vault | S25, S39, S40 |
| **V14-007** | Module générique ModuleList + ModuleForm + ModuleDetail + ModuleReport + ModuleKanban + ModuleDashboard (6 moteurs codés une fois) | 8 | Scalario Kit | V14-006, S22 |

### Nouvelles fondations Phase 1

| Story | Titre | Pts | Bloc | Dépend de |
|---|---|---|---|---|
| **V14-008** | i18n complet ARB FR/EN + lint `no_hardcoded_strings` (analyzer plugin) | 5 | i18n | S42 |
| **V14-009** | @nestjs/swagger global + @ApiHeader X-Tenant-ID + @ApiBearerAuth tous controllers | 3 | Backend docs | S13 |
| **V14-010** | Widgetbook setup (12 composants × variantes × états) | 5 | Scalario Canvas | V14-004, S4 |
| **V14-011** | Scalario Calc — ~30 fonctions atomiques (math, logique, listes, dates, texte) + AlgoEngine.eval | 5 | Scalario Calc | — |
| **V14-012** | Scalario Live — WebSocket Gateway NestJS + Flutter listener + FCM/APN enregistrement | 5 | Scalario Live | S14 |
| **V14-013** | tenant_handle + network_public columns (préparation Phase 4) — migration légère | 2 | Scalario Network anticipation | S013 |

---

## Phase 2 (Mois 4-6) — Engines & IA

### Engines IA

| Story | Titre | Pts | Bloc | Dépend de |
|---|---|---|---|---|
| **V14-014** | FastAPI microservice IA : `chat.py + rag.py + config_agent.py + embeddings.py + memory.py` | 8 | Scalario Mind | Docker compose, cluster GPU |
| **V14-015** | DeepSeek V4-Flash hébergé sur cluster GPU (2× RTX 4090) | 8 | Scalario Mind | Infra GPU |
| **V14-016** | Hybrid RAG (pgvector + BM25 + Reciprocal Rank Fusion + Cohere Rerank) | 8 | Scalario Search | V14-014 |
| **V14-017** | Mem0 cross-sessions — extraction faits importants + injection prompt | 5 | Scalario Memory | V14-014 |
| **V14-018** | Docling parsing — PDF/Excel/Word → chunks indexables | 3 | Scalario Search | V14-014 |
| **V14-019** | **Scalario Forge** — Config Agent IA (LangChain + Instructor + Pydantic) | 13 | Scalario Forge | V14-014, V14-015, V14-017 |
| **V14-020** | **Scalario Stage** — Demo Space multi-rôles (3 modes : Joueur, Réalisateur, Formation) | 8 | Scalario Stage | V14-019, S9 |
| **V14-021** | Business Profile Document — formulaire libre + sauvegarde auto + extraction IA | 5 | Scalario Forge | V14-019 |
| **V14-022** | Anti-hallucination 6 couches (Instructor + ConfigValidator + Dry Run + Résumé NL + Demo Space + Rollback 30j) | 8 | Scalario Watch | V14-019, V14-020 |

### Engines client

| Story | Titre | Pts | Bloc | Dépend de |
|---|---|---|---|---|
| **V14-023** | Scalario Form — orchestrateur saisie temps réel (Calc + Sense + Vault) | 8 | Scalario Form | S11, V14-011 |
| **V14-024** | Scalario Sense — CapabilityRegistry Flutter (scan, GPS, camera, signature, NFC, print BT) | 8 | Scalario Sense | S12 |
| **V14-025** | Scalario Sense — Mobile Money APIs (Wave + Orange Money + MTN MoMo + webhooks NestJS HMAC) | 8 | Scalario Sense | V14-024, S42 |
| **V14-026** | Scalario Sync — CRDT Vector Clocks + ConflictReviewScreen | 13 | Scalario Sync | S35 |
| **V14-027** | Casbin integration — ABAC complexe multi-attributs (paie, finances cross-département) | 5 | Scalario Shield | S19 |
| **V14-028** | Scalario Vault niveau 3 — catalogue SQL nommé par métier + vues matérialisées | 5 | Scalario Vault | V14-006 |

---

## Phase 3 (Mois 7-12) — Robustesse & Scale

| Story | Titre | Pts | Bloc | Dépend de |
|---|---|---|---|---|
| **V14-029** | Schema-per-tenant migration PostgreSQL (`public.*` + `{tenant_id}.*`) | 13 | Scalario Vault | S16 (refactor) |
| **V14-030** | Rete Algorithm — ABAC O(1) pour milliers d'users | 13 | Scalario Shield | V14-027 |
| **V14-031** | Langfuse intégration — observabilité LLM complète | 5 | Scalario Watch | V14-014 |
| **V14-032** | FSM XState générée automatiquement par Scalario Forge | 8 | Scalario Forge + Flow | V14-019, S31 |
| **V14-033** | Performance — memoization Scalario Calc + vues matérialisées PostgreSQL | 5 | Scalario Calc/Vault | V14-011 |
| **V14-034** | i18n Phase 3 — Haoussa + Arabe (RTL) — extension Maghreb/Sahel | 5 | i18n | V14-008 |
| **V14-035** | Multi-région — réplication DB pour clients multi-pays | 8 | Infra | V14-029 |
| **V14-036** | Swagger public + portail intégrateurs Phase 3 | 5 | Backend docs | V14-009 |

---

## Total Phase 1 — pts à committer

**Phase 1 (Mois 1-3)** : V14-001 à V14-013 = 13 stories, ~50 points

Avec 42 pts capacity / sprint × 2 semaines, Phase 1 = ~6 sprints (3 mois). Cohérent.

---

## Note sur la transition v13 → v14

- **Les 43 stories Sprint 1-4 restent dans `_bmad-output/stories/` comme historique**.
- Les nouvelles stories V14 sont créées dans `_bmad-output/architecture-v14/new-stories/`.
- Une fois la Phase 1 v14 démarrée, le sprint-status.yaml passera à un format `phase_1_v14` avec les nouvelles stories.
- Le code Sprint 1-4 sur `main` reste — il sera **renommé/refactoré progressivement** via V14-001 (script migration) + V14-002 à V14-007.

Le travail Sprint 4 est posé comme fondations techniques. Le pivot v14 réorganise + ajoute Forge / Stage / FastAPI.
