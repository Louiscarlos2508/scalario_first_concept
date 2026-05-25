# Story Audit — Sprint 1-4 vs Architecture v14

**Date** : 2026-05-25
**Auteur** : Carlos + Claude
**Total stories auditées** : 43 (S1-S43)

---

## Légende des tags

| Tag | Signification | Action |
|---|---|---|
| **KEEP** | Code valide tel quel, nom OK | Aucune action |
| **RENAME** | Code OK, juste nom à changer (BDUIEngine → Scalario Canvas) | Refactor par recherche/remplacement |
| **REFACTOR** | Code conceptuellement bon mais structure à changer | Story de refactor à créer |
| **EXTEND** | Story à étendre avec du nouveau (variantes, Casbin, schema-per-tenant…) | Nouvelle story qui consume l'existant |
| **DEPRECATE** | Approche abandonnée, code à remplacer | Story à supprimer du catalogue |

---

## Sprint 1 — Design System + BDUI Engine (EPIC-001 + EPIC-002)

| Story | Titre | Statut | Tag v14 | Justification + Action |
|---|---|---|---|---|
| STORY-001 | Design Tokens Flutter | done | **KEEP** | Tokens (couleurs, spacing, typo) inchangés. Nom alignera avec "Couche 1 — Design Tokens (jamais touchés par l'IA)" du v14. |
| STORY-002 | Material 3 + ThemeData Scalario | done | **KEEP** | Material 3 natif explicite v14 §3.7. ThemeData custom = couche 2 v14. |
| STORY-003 | Composants BDUI Métier | done | **EXTEND** | Composants existent, mais v14 introduit **variantes** (KPICard.default / .compact / .with-icon / .hero + variant:'auto'). Nouvelle story V14-004 pour ajouter le système. |
| STORY-004 | Showcase + Widget Preview | done | **RENAME** | Devient "Widgetbook" v14 §8.6. Conversion `_<feature>_showcase.dart` → Widgetbook UseCase. |
| STORY-005 | ComponentRegistry | done | **RENAME** | Devient **Scalario Canvas**. Le registre reste, ajouter dispatch `KPICard.fromConfig(config, ctx)` qui résout `variant: 'auto'`. |
| STORY-006 | RuleEvaluator | done | **KEEP** | Sous Scalario Canvas. Toujours nécessaire pour `visible_if`. |
| STORY-007 | LayoutResolver | done | **KEEP** | Sous Scalario Canvas, applique grammaire v14 §3.8 couche 3 (max 4 KPIs, max 5 champs par section, etc.). |
| STORY-008 | BDUIEngine Orchestrateur | done | **REFACTOR** | Devient **Scalario Flow** — ActionEngine qui exécute pipelines JSON. Le code pipeline runner existe (action-dispatcher), refactor pour accepter pipelines arbitraires (`steps[].registry/fn`) au lieu de routes 2-endpoints. |
| STORY-009 | Sandbox JSON + Hot Reload | done | **REFACTOR** | Devient base pour **Scalario Stage** (Demo Space). La sandbox dev → mode "Joueur" du Demo Space. Mode "Réalisateur" + Formation = nouvelles stories V14. |
| STORY-010 | Error Boundaries BDUI | done | **KEEP** | Sous "State & Error — couche technique Flutter" v14 §13.7. Riverpod loading/error layer. |
| STORY-011 | Validation Formulaires Data-driven | done | **REFACTOR** | Devient **Scalario Form** — engine à part qui orchestre Calc + Sense + Vault en temps réel. v14 §7 insiste : "1 frappe = peut déclencher AlgoEngine, scan déclenche CapabilityRegistry, recherche déclenche DataSourceRegistry". Story V14 à créer. |
| STORY-012 | Support Multi-plateforme | done | **KEEP** | Android + iOS + Web + Windows/macOS/Linux explicite v14. PlatformInfo + conditional imports déjà OK. |

---

## Sprint 2 — Backend Foundation (EPIC-003)

| Story | Titre | Statut | Tag v14 | Justification + Action |
|---|---|---|---|---|
| STORY-013 | NestJS Setup + Docker Compose 5 services | done | **REFACTOR** | v14 explicite 5 services : nestjs + **fastapi** + postgresql + redis + minio. FastAPI microservice manque. Story V14 nouvelle. |
| STORY-014 | Auth JWT Multi-tenant | done | **KEEP** | Sous **Scalario Shield** Layer 1. JWT + Passport OK. |
| STORY-015 | RBAC Guards Dynamiques | done | **KEEP** | Sous Scalario Shield Layer 2. Roles data-driven en tenant.config OK. |
| STORY-016 | Multi-tenant Isolation (ALS + GUC) | done | **EXTEND** | Phase 1 utilise schéma partagé + GUC `app.current_tenant_id`. v14 §22.1 demande **schema-per-tenant** PostgreSQL. Migration story V14 à créer (gros changement DB, à prévoir Phase 2). |
| STORY-017 | PostgreSQL RLS | done | **KEEP** | Sous Scalario Shield Layer 5. RLS reste pertinent même avec schema-per-tenant. |
| STORY-018 | Redis Sessions + Cache Layouts | done | **KEEP** | Cache config + sessions + rate limiting (Phase 2). |
| STORY-019 | ABAC CASL | done | **EXTEND** | v14 demande **CASL + Casbin** (§5.3 + §23.2). Casbin pour les règles ABAC complexes (paie, finances, multi-departement). Nouvelle story V14 pour intégrer Casbin. |
| STORY-020 | Audit Log | done | **RENAME** | Devient **Scalario Watch**. Insert-only OK, ajouter intégration Langfuse pour les LLM events. |
| STORY-021 | BDUIService NestJS | done | **REFACTOR** | Devient `bdui/bdui.service.ts` dans la nouvelle structure v14 §19.1. Sert `tenant_config.screens` filtré par ABAC. |
| STORY-022 | ModuleEngine 2 Endpoints | done | **REFACTOR** | Refactor majeur. v14 dit "Scalario Flow exécute des pipelines JSON" — pas 2 endpoints fixes. Le code idempotency + dispatching reste, devient executor de pipelines arbitraires (`registry: capability/datasource/algo/canvas/form/sense/vault/live`). |

---

## Sprint 3 — Module Engine + Workflow + Offline (EPIC-004 à EPIC-006)

| Story | Titre | Statut | Tag v14 | Justification + Action |
|---|---|---|---|---|
| STORY-023 | JSON Schema BDUI v1.0.0 | done | **EXTEND** | Schema reste. Ajouter champ **`variant: string`** au ComponentConfig (v14 §12.5). Nouvelle story V14. |
| STORY-024 | Zod Validator + API Validation | done | **KEEP** | Pipeline Zod existe. |
| STORY-025 | Structure Catalogue + README | done | **REFACTOR** | v14 introduit `catalog/ux_profiles/` (par métier) + `catalog/modules/` (génériques) + `catalog/capabilities/` (Scalario Sense) + `catalog/queries/` (SQL nommé Vault niveau 3). Restructuration. |
| STORY-026 | Validation Bidirectionnelle JSON Runtime | done | **KEEP** | Validation Flutter + NestJS du même schéma. |
| STORY-027 | Code-gen Contrat Partagé (STRETCH) | defined | **KEEP** | Stretch reste utile. |
| STORY-028 | Tests Coverage ≥90% (STRETCH) | defined | **KEEP** | Stretch reste utile. |
| STORY-029 | DAG Validator Kahn | done | **KEEP** | Algorithm core, reste sous Scalario Flow. |
| STORY-030 | Workflow Executor | done | **REFACTOR** | Devient le pipeline executor de **Scalario Flow** (mêmes primitives `step.registry`, `step.fn`, variables partagées `$nom_variable`). |
| STORY-031 | XState State Machine | done | **KEEP** | Sous Scalario Flow. FSM utilisée pour FSM-style workflows (commande draft→soumise→validée). |
| STORY-032 | Integration Workflow↔ModuleEngine | done | **DEPRECATE** | Plus de séparation Workflow/ModuleEngine en v14 : tout est pipeline Scalario Flow. Cette story disparaît, ses tests deviennent partie de Scalario Flow E2E. |
| STORY-033 | Drift/Isar Setup Mobile | done | **RENAME** | Sous **Scalario Vault** niveau 1 + 2 (Drift offline + agrégations). |
| STORY-034 | Sync Queue Locale Drift | done | **RENAME** | Sous **Scalario Sync** Phase 1 (timestamp + server_wins). CRDT en Phase 2. |

---

## Sprint 4 — Gate 0 (EPIC-006 + EPIC-007)

| Story | Titre | Statut | Tag v14 | Justification + Action |
|---|---|---|---|---|
| STORY-035 | Conflict Resolution Phase 1 | done | **KEEP** | v14 §22.2 dit explicitement : *"Alternative pour commencer : Timestamp + server-wins avec conflict queue pour les cas ambigus"*. C'est exactement ce qu'on a livré. CRDT vrai = Phase 2 story V14 nouvelle. |
| STORY-036 | Idempotence Endpoints POST | done | **KEEP** | HTTP-level Redis cache. Reste critique en Phase 1. |
| STORY-037 | Sync Status UI core | done | **EXTEND** | Logic OK (4 états). v14 §8.2 ajoute `SyncStatusBar` comme composant DS permanent du layout avec variantes (syncing/synced/conflict/offline). Widget UI à compléter Sprint 5 + ConflictReviewScreen pour CRDT Phase 2. |
| STORY-038 | Drift Web Offline + PWA | deferred | **KEEP** | Toujours différé post-Phase 1. |
| STORY-039 | Template retail_fresh_produce.json | done | **REFACTOR** | Concept "1 fichier `domain_*.json` = 1 secteur métier complet" devient `catalog/ux_profiles/<sector>/` + tenant `inherits` + `overrides`. La pharmacie/BTP/restauration ont chacun leur UX Profile. Le tenant blandine_real `inherits = catalog/ux_profiles/commerce_general/`. Story V14 à créer. |
| STORY-040 | Modules Phase 1 JSON (6 modules) | done | **DEPRECATE** | Modèle métier `module_dashboard_owner / module_ventes / module_pertes` etc. abandonné. v14 §16 dit : 6 **moteurs génériques** (ModuleList, ModuleForm, ModuleDetail, ModuleReport, ModuleKanban, ModuleDashboard) + catalogue **commun** (gestion/commandes, finance/factures, rh/employes…). Le tenant `inherits` un module standard et `overrides` ce qui diffère. Story V14 majeure : refactor du catalogue. |
| STORY-041 | Workflow DAG Clôture Caisse | done | **REFACTOR** | Le workflow JSON reste, devient un pipeline Scalario Flow + FSM. Move vers `catalog/modules/gestion/cloture_caisse.json` comme module standard. |
| STORY-042 | Global Scale (i18n + PaymentAdapter) | done | **REFACTOR** | (a) i18n ARB FR/EN reste à compléter — v14 §8b dit OBLIGATOIRE dès Phase 1. (b) PaymentAdapter NestJS → migré dans **Scalario Sense** comme capability Flutter (Wave/OM/MTN APIs platform channels). Webhook NestJS reste pour confirmation asynchrone. |
| STORY-043 | Validation E2E Gate 0 | review | **REFACTOR** | Devient "Validation E2E Phase 1 — premier client réel configuré par Scalario Forge manuellement". Carlos opère Forge en chat pour livrer un ERP en 45 min au lieu de 6 mois. |

---

## Récapitulatif par tag

| Tag | Count | Stories |
|---|---|---|
| KEEP | **17** | S1, S2, S6, S7, S10, S12, S14, S15, S17, S18, S24, S26, S27, S28, S29, S31, S35, S36, S38 |
| RENAME | **6** | S4, S5, S20, S33, S34 |
| REFACTOR | **11** | S8, S9, S11, S13, S21, S22, S25, S30, S37, S39, S41, S42, S43 |
| EXTEND | **5** | S3, S16, S19, S23 |
| DEPRECATE | **2** | S32, S40 |
| **Total** | **43** | |

**Bilan** : 17 stories (~40%) restent telles quelles, 6 (~14%) juste un renommage, 11 (~26%) un refactor structurel modéré, 5 (~12%) une extension, 2 (~5%) à abandonner.

**Le code Sprint 1-4 n'est pas perdu** — il forme le squelette technique. Le pivot v14 réorganise + ajoute les briques IA manquantes (Forge, Stage, FastAPI, Mind, Memory, Search).

---

## Stories DEPRECATE — détails

### STORY-032 (Integration Workflow↔ModuleEngine)
- Raison : v14 unifie ModuleEngine + WorkflowEngine sous **Scalario Flow** comme exécuteur unique de pipelines JSON. La "glue" entre les deux n'a plus de sens.
- Devenir code : les patches de review (action-dispatcher.service handleStartWorkflow/handleTransitionWorkflow) deviennent partie intégrante de Scalario Flow.
- Tests (28 verts) : à intégrer dans la suite Scalario Flow E2E.

### STORY-040 (Modules Phase 1 JSON — 6 modules métier)
- Raison : modèle "6 modules métier hardcodés pour retail" remplacé par "6 moteurs génériques + catalogue commun + overrides per-tenant".
- Devenir code : les 6 fichiers JSON `module_dashboard_owner.json`, `module_ventes.json` etc. seront supprimés. Le catalogue v14 sera `catalog/modules/gestion/commandes.json`, `catalog/modules/finance/factures.json`, `catalog/modules/rh/employes.json`, etc. — modules génériques inherités par chaque tenant avec overrides.
- Le test `modules-phase1.spec.ts` deviendra `modules-generic-catalog.spec.ts`.
