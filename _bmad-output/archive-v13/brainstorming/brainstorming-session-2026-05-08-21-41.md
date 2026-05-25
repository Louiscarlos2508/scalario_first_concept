---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: ['ERP_IA_Architecture_v6.pdf']
session_topic: 'Refondation Scalario — BDUI Engine + Système de Templates'
session_goals: 'Définir la vraie vision, clarifier ce qui se supprime, poser les bases du workflow BMAD pour repartir propre'
selected_approach: 'progressive-flow'
techniques_used: ['first-principles-thinking', 'constraint-mapping', 'scamper', 'decision-tree-mapping']
ideas_generated: []
context_file: 'ERP_IA_Architecture_v6.pdf'
---

# Brainstorming Session — Refondation Scalario

**Date :** 2026-05-08
**Facilitateur :** Carlos Simpore

---

## Session Overview

**Topic :** Refondation Scalario vers ERP BDUI avec système de templates sectoriels
**Goals :** Clarifier la vision, identifier ce qu'on supprime, poser les bases du build

### Contexte de départ

Carlos constate que l'implémentation actuelle (101k lignes Flutter, 20k lignes NestJS) va à l'opposé de la vision du PDF `ERP_IA_Architecture_v6.pdf`. L'ancien code est un ERP retail classique codé screen par screen — la vision est un Business Operating System BDUI.

**Décision : tout supprimer sauf les agents (\_bmad, \_wds-learn, .claude) et repartir propre.**

---

## Phase 1 — First Principles Thinking

### La vérité fondamentale de Scalario

**Scalario est un Business Operating System** qui génère automatiquement une interface ERP et des APIs métier depuis un fichier de configuration JSON — sans coder ni les écrans ni les endpoints. Les règles UI/UX Scalario s'appliquent toujours. N'importe quel intégrateur peut créer un template sectoriel dans le catalogue.

### Les 3 niveaux du système

**Niveau 1 — Design System Scalario (absolument fixe, jamais touché) :**
- Composants UI : KPICard, DataTable, AlertBanner, FAB, ListTile, FormSection...
- Design tokens : couleurs, spacing, typographie Scalario (via WDS/Widgetbook)
- Le moteur de rendu BDUI lui-même (lit JSON → rend composants)
- Les algorithmes : ModuleEngine, ABAC filter, WorkflowDAG

**Niveau 2 — UX Profile sectoriel (déclaré par template JSON, varie par domaine) :**
- Règles UX propres au secteur : pharmacie, retail, BTP ont chacun leurs patterns
- Fichiers JSON dans un catalogue : `catalog/domains/retail.json`, `pharmacie.json`...
- Règles de fusion pour clients multi-domaine : `catalog/fusions/retail+wholesale.json`
- Nouveau domaine = nouveau fichier JSON, zéro code

**Niveau 3 — Config client (override JSON, zéro code) :**
- Ce qui diffère du template standard pour CE client spécifique
- Modules activés, champs customs, règles RBAC, workflows adaptés

### L'insight plateforme

> N'importe quel intégrateur peut créer son template sectoriel — mais TOUTES les règles UI/UX Scalario s'appliquent. Le JSON est validé contre le schema (Zod/Pydantic) avant déploiement. Impossible de sortir du catalogue.

Comme iOS (HIG s'imposent à tous les devs) ou Shopify (standards s'appliquent à tous les thèmes).

### BDUI + BDAPI

- **BDUI** → écrans ERP pour utilisateurs internes (générés depuis JSON)
- **BDAPI** → APIs métier auto-générées depuis la config (pour services externes)

```
Config ERP restaurant → module "commandes"
→ Scalario génère automatiquement :
   POST /api/{tenant}/commandes
   PATCH /api/{tenant}/commandes/{id}/confirmer
   GET  /api/{tenant}/commandes/{id}/statut
→ + documentation OpenAPI auto-générée
```

**Hors scope (pour l'instant) :** portals clients, génération de sites web externes.

---

## Phase 2 — Constraint Mapping

### Colonne A — MVP (à construire)

**Flutter :**
- `ComponentRegistry` — map `type → widget`
- `RuleEvaluator` — évalue `visible_if` avec rôles RBAC uniquement (pas ABAC pour MVP)
- `LayoutResolver` — 4 layouts : dashboard, list, form, detail
- `BDUIEngine` — lit JSON, résout règles, instancie composants
- Design System Scalario (composants propres via WDS/Widgetbook)

**NestJS :**
- Auth JWT + RBAC Guards (owner, manager, staff...)
- `BDUIService` — sert le JSON screen selon tenant + rôle
- `ModuleEngine` — 2 endpoints génériques : `GET /:moduleId/data` + `POST /:moduleId/create`
- Multi-tenant basique (tenant_id pour MVP)
- JSON Schema validator (Zod) — impossible de sortir du catalogue

**Config :**
- `retail.json` — premier template dans le catalogue
- Structure catalogue : `catalog/domains/`, `catalog/modules/`, `catalog/fusions/`

### Colonne B — Phase 2 (après MVP)

ABAC attributs contextuels, Workflow DAG engine, BDAPI auto-générée, FastAPI/IA microservice, Config Agent conversationnel, Redis, MinIO, Schema-per-tenant, Widgetbook documentation complète

### Colonne C — Jamais codé

Modules métier, règles UX sectorielles, permissions par client — toujours déclarés en JSON dans le catalogue.

---

## Phase 3 — SCAMPER

**Substitute :** Supabase auth → JWT NestJS natif. Screens Flutter codés → BDUIEngine. Controllers spécifiques → ModuleEngine générique.

**Eliminate :** Tout `apps/`, `supabase/`, `docs/`, `scripts/`. Aucune logique métier dans Flutter. Aucun endpoint NestJS spécifique à un domaine.

**Adapt :** La connaissance métier retail (acquise pendant l'ancien dev) alimente `retail.json` — sans relire une ligne de l'ancien code.

---

## Phase 4 — Plan d'Action

### Décision : Grand nettoyage

**Supprimer :**
- `apps/` (frontend Flutter + backend NestJS — ancien code hors scope)
- `supabase/` (on n'utilise pas Supabase)
- `docs/` (ancienne documentation obsolète)
- `scripts/`
- `packages/`
- `design-process/`
- `package.json` + `package-lock.json` + `node_modules/` (root)
- `_bmad-output/` sauf `brainstorming/` (cette session)

**Garder :**
- `_bmad/` — agents BMAD
- `_wds-learn/` — agent WDS
- `.claude/` — config Claude Code
- `ERP_IA_Architecture_v6.pdf` — la directive
- `_bmad-output/brainstorming/` — cette session

### Workflow de Build

```
1. /bmad:prd          → PRD Scalario BDUI Engine + Templates
2. /bmad:architecture  → Architecture technique (NestJS + Flutter + Catalogue)
3. WDS                → Design System Scalario (composants via Widgetbook)
4. /bmad:sprint-planning → Sprint 1 MVP
5. /bmad:dev-story    → Story par story
```

---

## Insights Clés de la Session

1. **Scalario = OS, pas un ERP** — l'engine est le produit, les templates sont le catalogue
2. **3 niveaux** : Design System fixe → UX Profile sectoriel → Config client
3. **Catalogue ouvert** : n'importe quel intégrateur peut créer un template, les règles Scalario s'appliquent toujours
4. **BDUI + BDAPI** : même config génère l'UI interne ET les APIs externes
5. **MVP scope** : BDUI Engine + RBAC simple + retail.json — ABAC et workflows après
6. **L'ancien code** : hors scope depuis le début, la connaissance métier reste dans la tête

---

*Session complète — Prochaine étape : nettoyage puis `/bmad:prd`*
