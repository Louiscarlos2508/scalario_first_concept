# Archive v13 — Mai 2026

**Statut** : ARCHIVED
**Date d'archivage** : 2026-05-25
**Superseded par** : [`_bmad-output/architecture-v14/`](../architecture-v14/README.md)

---

## Pourquoi cet archive

Le 2026-05-25, Scalario a pivoté du **modèle intégrateur certifié (v13)** vers le **modèle SaaS pur (v14)**, suite à `Scalario_Architecture_v14.pdf` (82 pages).

Les documents de ce dossier décrivent le modèle business v13 et restent ici à des fins de :

1. **Traçabilité** : les 13 commits + ~1424 tests sur `main` ont été produits sur la base de ces specs.
2. **Référence technique** : 8 phases Blandine, principes BDUI, décisions BMAD agents — le contenu technique reste utile, c'est le **modèle business** qui pivote.
3. **Audit-trail** : si on revient sur une décision, le contexte d'origine est ici.

---

## Contenu archivé

| Fichier | Description | Status v14 |
|---|---|---|
| `architecture-scalario-2026-05-09.md` (99 KB) | Architecture v13 complète | Superseded — voir `architecture-v14/prd/PRD-v14.md` §3 (Architecture) |
| `prd-scalario-2026-05-09.md` (65 KB) | PRD v1.1 modèle intégrateur | Superseded — voir `architecture-v14/prd/PRD-v14.md` |
| `sprint-plan-scalario-2026-05-09.md` (58 KB) | Sprint plan v13 (Gate 0 Blandine 8 juillet) | Superseded — voir `architecture-v14/sprint-plan/sprint-plan-v14.md` |
| `product-brief-scalario-2026-05-09.md` (9 KB) | Product brief catégorie Instant Business OS | Superseded — repositionnement SaaS "Shopify des ERP PME africaines" |
| `phase1-brief.md` (5 KB) | Brief Phase 1 v13 (livrer Gate 0 Blandine) | Superseded — Phase 1 v14 = livrer manuellement 3 clients réels |
| `innovation-strategy-2026-05-09.md` (14 KB) | Stratégie innovation Mai 2026 | Contenu pertinent — repositionnement modulaire v14 |
| `innovation-strategy-2026-03-29.md` (85 KB) | Stratégie initiale Mars 2026 | Historique |
| `design-thinking-2026-03-29.md` (90 KB) | Design thinking session | Historique |
| `planning-artifacts/architecture.md` (23 KB) | Architecture BMAD v13 | Superseded |
| `planning-artifacts/epics.md` (7 KB) | Epics v13 (EPIC-001 à EPIC-007) | Mapping vers nouveaux engines dans `architecture-v14/stories-audit/STORY-AUDIT-v14.md` |
| `planning-artifacts/sprint-change-proposal-2026-03-13.md` (17 KB) | Proposition changement sprint | Historique |
| `brainstorming/brainstorming-session-2026-05-08-21-41.md` | Session brainstorming d'origine | Historique |

---

## Ce qui reste actif et n'est PAS archivé

- `_bmad-output/architecture-v14/` — actuelle source de vérité
- `_bmad-output/stories/STORY-001.md` à `STORY-043.md` — 43 stories Sprint 1-4 v13, taggées dans l'audit (17 KEEP, 6 RENAME, 11 REFACTOR, 5 EXTEND, 2 DEPRECATE). Restent comme référence d'audit, code sur `main`.
- `_bmad-output/architecture-notes/phase2-schema-per-tenant.md` — note technique de STORY-016, toujours pertinente pour V14-029 (schema-per-tenant Phase 3 v14).
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — statut Sprint 1-4 (43 stories), garde l'historique de livraison.
- `_bmad-output/bmm-workflow-status.yaml` — BMAD workflow tracking.

---

## Comment naviguer la transition v13 → v14

Voir `_bmad-output/architecture-v14/stories-audit/STORY-AUDIT-v14.md` pour le mapping détaillé.

Résumé :

| Bloc v13 | Devient en v14 |
|---|---|
| BDUIEngine | Scalario Canvas (UI) + Scalario Flow (orchestrateur) |
| ModuleEngine | Scalario Flow (pipelines JSON) |
| WorkflowEngine FSM | sous Scalario Flow |
| SyncEngine | Scalario Vault (data) + Scalario Sync (CRDT Phase 2) |
| SecurityChain (RBAC+ABAC+RLS) | Scalario Shield |
| AuditLog | Scalario Watch |
| PaymentAdapter NestJS | Scalario Sense (capability Flutter) |
| `module_dashboard_owner` + 5 autres modules métier hardcodés | 6 moteurs génériques (ModuleList/Form/Detail/Report/Kanban/Dashboard) + catalogue commun + overrides per-tenant |
| Template `retail_fresh_produce.json` | UX Profile `commerce_general/` + tenant `inherits` + `overrides` |
| Gate 0 Blandine 8 juillet | Phase 1 = livrer 3 clients réels (M1-3) ; pas de date hardcodée client unique |

---

## Restaurer un document si nécessaire

```bash
# Voir le contenu sans restaurer
cat _bmad-output/archive-v13/prd-scalario-2026-05-09.md

# Restaurer (si vraiment nécessaire) — non recommandé
git mv _bmad-output/archive-v13/prd-scalario-2026-05-09.md _bmad-output/prd-scalario-2026-05-09.md
```

Le contenu reste accessible via `git log --follow _bmad-output/archive-v13/<file>` pour voir tout l'historique des modifications avant archivage.
