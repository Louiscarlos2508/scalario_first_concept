# Product Requirements Document : Scalario

**Date :** 2026-05-09
**Auteur :** Carlos Simpore
**Version :** 1.1
**Type de projet :** Instant Business OS — ERP IA UI-Driven, distribué par réseau d'intégrateurs certifiés
**Niveau :** 4 (plateforme complexe, multi-horizon)
**Statut :** Draft

---

## Aperçu du document

Ce PRD définit les exigences fonctionnelles et non-fonctionnelles de **Scalario** — un Business Operating System qui génère automatiquement une interface ERP et des APIs métier depuis un fichier de configuration JSON, sans coder ni les écrans ni les endpoints.

**Document de référence :** `ERP_IA_Architecture_v6.pdf` (directive technique principale)
**Brainstorm de fondation :** `_bmad-output/brainstorming/brainstorming-session-2026-05-08-21-41.md`

---

## Résumé exécutif

### La catégorie

Scalario crée une nouvelle catégorie : **l'Instant Business OS** — le premier système de gestion qu'une PME africaine peut avoir en production en 45 minutes, depuis une conversation, sur son téléphone, même sans connexion stable.

Ce n'est pas "un meilleur ERP." C'est un changement de terrain. La disruption n'est pas sur les fonctionnalités — elle est sur le **time-to-value** : 45 minutes vs 3-6 mois. Et sur la distribution : des **intégrateurs locaux certifiés** vs une force de vente directe.

### Ce qui différencie Scalario de tout ERP existant

| ERP classique | Scalario |
|---|---|
| Configuration : 3-6 mois | Configuration : 45 min de chat IA (Phase 2) |
| UI fixe pour tous | UI générée par rôle, contexte et permissions |
| RBAC simple | RBAC + ABAC + RLS multi-couche |
| Offline basique | Offline-first natif — fonctionne sans connexion |
| RAG absent ou basique | Hybrid search + reranking |
| Règles codées en dur | Moteur de règles Rete dynamique |
| Workflows figés | Workflows DAG déclarés en JSON |
| Modules hardcodés | Modules déclarés en JSON — aucun module fixe |
| Déployé par une équipe IT | Déployé par un intégrateur local certifié |

### Les 3 piliers fondamentaux

1. **Configuration conversationnelle (le claim de catégorie)** — Un nouveau client configure son ERP via un chat IA (30-45 min). L'IA extrait les entités métier, les rôles, les workflows et les règles depuis la conversation. La config est stockée par tenant en JSON et appliquée immédiatement. *Phase 1 : onboarding manuel par Carlos. Phase 2 : automatisé — c'est la priorité #1.*

2. **BDUI Engine + Catalogue de templates** — Le backend génère dynamiquement l'interface selon le rôle, le contexte et les permissions. Flutter reçoit un JSON schema et rend les composants — zéro `if` métier dans le code Flutter. Un nouveau secteur = un nouveau fichier JSON dans le catalogue. Zéro ligne de code.

3. **Sécurité 5 couches native** — JWT → RBAC Guard → ABAC CASL → pgvector filter → PostgreSQL RLS. Le LLM ne voit jamais de données non autorisées. Fonctionne pour multi-département, multi-rôle, multi-tenant.

### Le modèle de distribution

**Carlos n'est pas le canal. Les intégrateurs certifiés sont le canal.**

Scalario forme et certifie des consultants locaux (futurs intégrateurs) qui connaissent le tissu PME de leur marché. Ils configurent, déploient, forment et supportent les clients. Scalario fournit la plateforme, le catalogue et la certification. Revenue split : 60% Scalario / 40% intégrateur sur le MRR mensuel.

Ce modèle permet l'expansion géographique (Burkina → Côte d'Ivoire → Sénégal) sans que Carlos soit présent sur chaque marché.

### Beachhead marché

UEMOA — le marché techniquement le plus exigeant (connectivité instable, multi-devises, offline critique, confiance locale). "Si ça marche en UEMOA, ça marche partout."

Premier secteur : **fresh produce / épicerie fine** (`retail_fresh_produce.json`) — template de référence qui sert tous les acteurs du secteur, pas seulement Blandine.

---

## Objectifs produit

### Objectifs business

1. **Gate 0 — Blandine live (J+60)** — `retail_fresh_produce.json` déployé. 4 fonctions critiques opérationnelles (validation croisée, pertes segmentées, clôture caisse, dashboard proprio). Blandine utilise l'app quotidiennement sans aide. *Le template est conçu pour le secteur fresh produce — pas pour Blandine uniquement.*

2. **Gate 1 — Template validé (M3)** — 2ème client du même secteur onboardé depuis `retail_fresh_produce.json` sans modifier le JSON. Template `pharmacie.json` en cours. MRR : 80K FCFA.

3. **Gate 2 — Canal intégrateur opérationnel (M6)** — 5 clients payants. Config Conversationnelle IA en production (priorité absolue Phase 2). 3 intégrateurs certifiés dont 1 autonome. MRR : 200K FCFA.

4. **Gate 3 — Scale géographique (M12)** — 15+ clients. 1 intégrateur actif en Côte d'Ivoire (expansion sans Carlos). 5+ templates dans le catalogue. MRR : 750K FCFA.

5. **Horizon 3 — Infrastructure d'écosystème** — BDAPI ouvert aux apps tierces. B2B inter-tenants. Marketplace templates. Double network effect activé.

### Modèle de pricing

| Tier | Prix mensuel | Cible | Modules | Utilisateurs |
|---|---|---|---|---|
| **Standard** | 40–60K FCFA | Blandine — PME 3-10 personnes | 4–6 modules | 3–10 users |
| **Business** | 150–200K FCFA | Distributeur multi-dépôt, pharmacie, BTP | 8+ modules, multi-département | 10–50 users |

*Tier Solo (vendeur ambulant, 1 user) : Phase 3 uniquement — nécessite Config IA self-service. Hors scope Phase 1-2.*

### Métriques de succès

| Métrique | Gate 0 (J+60) | Gate 1 (M3) | Gate 2 (M6) | Gate 3 (M12) |
|---|---|---|---|---|
| Clients payants | 1 (Blandine) | 2 | 5 | 15+ |
| Templates sectoriels | 1 (fresh produce) | 1 validé secteur | 2 | 5+ |
| Intégrateurs certifiés actifs | 0 | 0 | 3 | 6+ |
| Config IA live | Non | Non | Oui | Oui |
| Temps onboarding | 2h (manuel) | 2h (manuel) | 45 min (IA) | 20 min |
| Uptime backend | 99.5% | 99.5% | 99.5% | 99.9% |
| MRR | 40K FCFA | 80K FCFA | 200K FCFA | 750K FCFA |
| Crashes prod | 0 | 0 | 0 | 0 |
| Churn mensuel | — | <0% | <3% | <5% |

---

## Architecture — Vue d'ensemble

### Les 3 niveaux du système

```
Niveau 1 — Design System Scalario (FIXE — jamais touché)
├── Composants UI : KPICard, DataTable, AlertBanner, FAB, ListTile, FormSection, ChartBar...
├── Design tokens : couleurs, spacing, typographie Scalario
├── BDUI Engine : ComponentRegistry + RuleEvaluator + LayoutResolver
└── Algorithmes : ModuleEngine, ABAC filter, WorkflowDAG

Niveau 2 — UX Profile sectoriel (JSON dans le catalogue)
├── catalog/domains/retail_fresh_produce.json   ← Premier template (Phase 1)
├── catalog/domains/pharmacie.json              ← Deuxième template (Phase 2)
├── catalog/domains/distribution_multi_depot.json
├── catalog/domains/btp.json
├── catalog/fusions/retail+wholesale.json
└── Nouveau domaine = nouveau fichier JSON, zéro code

Niveau 3 — Config client (JSON override, zéro code)
├── Modules activés pour ce tenant
├── Champs customs, règles RBAC adaptées
└── Workflows spécifiques au client
```

### Règle d'or absolue

> **Jamais de logique métier dans Flutter. Jamais d'endpoint NestJS spécifique à un domaine.**
> Tout ce qui est métier = fichier JSON dans le catalogue.
> Le backend est générique — 2 endpoints servent 100% des modules.

### Stack technique

| Couche | Technologie | Rôle |
|---|---|---|
| App mobile + web | Flutter (multi-plateforme) | BDUI renderer + offline-first |
| Admin web | Flutter Web | Config chat + preview BDUI (même engine) |
| API principal | NestJS | Auth, RBAC/ABAC, BDUI, ModuleEngine, Workflows |
| Auth | Passport.js + @nestjs/jwt | JWT, refresh tokens, multi-tenant |
| Realtime | NestJS WebSocket Gateway | Streaming IA, notifications |
| IA Inférence | FastAPI + LangChain | RAG, Config Agent, streaming LLM |
| Base de données | PostgreSQL + pgvector | Données + RAG vectoriel + RLS |
| Cache / Sessions | Redis | Sessions, config cache, rate limiting LLM |
| Storage fichiers | MinIO (S3-compatible) | PDFs, ordonnances, images |
| Mémoire IA | Mem0 | Contexte long terme par utilisateur |
| Parsing documents | Docling | PDF, Excel, Word → chunks indexables |
| RAG | LlamaIndex + pgvector | Indexation + hybrid search données métier |
| Permissions | CASL / Casbin | ABAC complexe dans NestJS |
| LLM | Claude API / Ollama | Cloud ou local selon connectivité client |
| Composants UI | Material 3 Flutter natif + DS Scalario | Design System cohérent, zéro dépendance UI externe |
| Maquettage | Widgetbook (Flutter) | Storybook vivant des composants BDUI |
| Déploiement | Docker Compose (5 services) | nestjs, fastapi, postgresql, redis, minio |

### Architecture de sécurité — 5 couches

```
Requête utilisateur
  ↓ Layer 1 : JWT Guard (NestJS) — authentification + tenant_id
  ↓ Layer 2 : RBAC Guard — le rôle a-t-il accès à cette route ?
  ↓ Layer 3 : ABAC CASL — les attributs autorisent-ils cet objet ?
  ↓ Layer 4 : pgvector filter — RAG filtré par dept/rôle
  ↓ Layer 5 : PostgreSQL RLS — sécurité au niveau base de données
  → Données retournées (déjà filtrées avant d'atteindre le LLM)
```

**Règle critique IA :** Le LLM n'est jamais un garde de sécurité. Les données sont filtrées AVANT d'appeler le LLM — le modèle ne reçoit que les données autorisées.

### ModuleEngine — Backend dynamique, pas statique

```
GET  /api/:tenant/:moduleId/data     → sert les données de n'importe quel module
POST /api/:tenant/:moduleId/action   → exécute n'importe quelle action

Le backend ne "connaît" pas POS, Stock, ni Pharmacie.
Il lit la config JSON du tenant → résout le module → retourne les données.
Ajouter un nouveau module = nouveau JSON dans le catalogue, zéro endpoint NestJS.
```

---

## Exigences Fonctionnelles

### Groupe A — BDUI Engine Flutter (Must Have — MVP)

#### FR-001 : ComponentRegistry
**Priorité :** Must Have

**Description :** Registry extensible qui résout un type string (issu du JSON) vers un widget Flutter builder. Le registry est la seule liste de composants disponibles — on ne peut pas rendre un composant non enregistré.

**Critères d'acceptation :**
- [ ] `ComponentRegistry.build(config, ctx)` résout tout type enregistré en widget Flutter
- [ ] Type inconnu → `UnknownComponent` affiché (pas de crash)
- [ ] Nouveaux composants s'ajoutent en une ligne sans toucher l'Engine
- [ ] Composants initiaux : KPICard, DataTable, AlertBanner, FAB, ListTile, FormSection, ChartBar

#### FR-001b : Multi-plateforme Flutter
**Priorité :** Must Have

**Description :** L'application Flutter cible Android, iOS et Web depuis un codebase unique. Les layouts s'adaptent automatiquement via le LayoutResolver selon le viewport.

**Critères d'acceptation :**
- [ ] Build Android (APK/AAB) fonctionnel — Android 8.0+ (API 26+)
- [ ] Build iOS fonctionnel — iOS 14+
- [ ] Build Flutter Web fonctionnel — Chrome 90+, Safari 14+, Firefox 88+
- [ ] PWA installable depuis navigateur (web)
- [ ] Breakpoints : mobile < 600px, tablet 600-1024px, desktop > 1024px

#### FR-002 : RuleEvaluator
**Priorité :** Must Have

**Description :** Évaluation des règles `visible_if` déclarées en JSON. Phase 1 : RBAC uniquement. Phase 2 : extension ABAC (attributs contextuels). Zéro `if` métier dans le code Flutter.

**Critères d'acceptation :**
- [ ] Opérateurs supportés : `AND`, `OR`, `role`, `>`, `<`, `==`
- [ ] `visible_if: { "role": ["MANAGER", "DG"] }` masque le composant pour les autres rôles
- [ ] `visible_if: null` → composant toujours visible
- [ ] Évaluation < 1ms par composant (pas de dégradation sur screens complexes)

**Dépendances :** FR-009 (JWT claims rôle)

#### FR-003 : LayoutResolver
**Priorité :** Must Have

**Description :** Résolution du layout à appliquer depuis le JSON. 4 layouts fixes codés une fois. L'IA choisit lequel utiliser — elle ne crée jamais de nouveaux layouts.

**Critères d'acceptation :**
- [ ] 4 layouts implémentés : `dashboard`, `list`, `form`, `detail`
- [ ] Chaque layout adapte ses zones selon le breakpoint (mobile/tablet/desktop)
- [ ] Layout inconnu → fallback `dashboard`
- [ ] `DashboardLayout` : zone kpis (GridView 2 cols), zone main, zone actions (FAB bas droite)

#### FR-004 : BDUIEngine
**Priorité :** Must Have

**Description :** Orchestrateur central du rendu. Lit un JSON schema → évalue les `visible_if` → résout les data sources → instancie les composants depuis le ComponentRegistry → applique le layout. Zéro if métier dans l'Engine.

**Critères d'acceptation :**
- [ ] Rendu complet d'un screen depuis JSON en < 200ms (cold, depuis cache local)
- [ ] Rendu < 50ms (hot, layout déjà en mémoire)
- [ ] Pipeline : parse JSON → RuleEvaluator → data resolution → ComponentRegistry → LayoutResolver
- [ ] Aucune logique métier dans l'Engine (validé à la code review)

#### FR-005 : Design Tokens Flutter
**Priorité :** Must Have

**Description :** Système de theming data-driven basé sur Material 3 Flutter natif. Tokens Scalario (couleurs, spacing, typographie) appliqués via `ThemeData` + `ThemeExtensions`. Aucune dépendance UI externe. Cohérence visuelle garantie sur toutes les plateformes.

**Critères d'acceptation :**
- [ ] Tokens définis : couleurs primary/success/danger/warning/surface, spacing scale (4-64px), typographie (h1-h2-body-caption)
- [ ] Material 3 natif Flutter utilisé — composants stock (FilledButton, Card, DataTable, Badge, TextField, DropdownMenu, Dialog) théméisés via `ThemeData`
- [ ] Theme appliqué globalement — aucun composant n'a de couleurs hardcodées
- [ ] Hot reload du theme en dev

#### FR-006 : Sandbox JSON
**Priorité :** Must Have

**Description :** Écran de développement qui charge un fichier JSON local (`assets/sandbox/`) et affiche le résultat rendu par l'Engine en temps réel. Preuve que le BDUI fonctionne bout en bout.

**Critères d'acceptation :**
- [ ] Chargement d'un JSON depuis `assets/sandbox/` → rendu immédiat
- [ ] Hot reload : modifier le JSON → rendu mis à jour sans redémarrer l'app
- [ ] Affiché seulement en mode debug (pas en production)
- [ ] Exemple inclus : `sandbox/retail_dashboard.json`

#### FR-007 : Widgetbook
**Priorité :** Must Have

**Description :** Documentation vivante de chaque composant BDUI avec tous ses états. Référence de non-régression visuelle pour toute la durée du projet.

**Critères d'acceptation :**
- [ ] Chaque composant du ComponentRegistry a une entrée Widgetbook
- [ ] Tous les états documentés : Normal, Warning, Danger, Loading, Vide, Erreur
- [ ] `WidgetbookComponent` pour : KPICard, DataTable, AlertBanner, FAB, ListTile, FormSection, ChartBar
- [ ] Compositions exemples : "Pharmacie Dashboard", "BTP Liste Chantiers"

#### FR-008 : Offline-first Mobile
**Priorité :** Must Have

**Description :** L'app mobile fonctionne entièrement sans connexion. La config JSON et les données sont persistées localement (Drift/Isar). Toutes les actions offline sont enregistrées dans une sync queue.

**Critères d'acceptation :**
- [ ] Premier lancement : télécharge et cache la config tenant (layouts + données init)
- [ ] Mode offline : navigation complète, saisie de données, exécution d'actions
- [ ] Config JSON chiffrée localement (pas de données sensibles en clair)
- [ ] Taille cache local configurable par tenant (limite par défaut : 500MB)

#### FR-050 : Error Boundaries BDUI
**Priorité :** Must Have

**Description :** Chaque composant rendu par le BDUIEngine est isolé dans un error boundary Flutter. Un composant qui échoue n'affecte jamais les autres ni ne crashe l'app.

**Critères d'acceptation :**
- [ ] JSON avec composant invalide → fallback UI "composant indisponible" localisé à ce composant
- [ ] Source de données manquante → état erreur isolé au composant, reste du screen fonctionnel
- [ ] Aucun appel non géré ne propage vers le root de l'app
- [ ] Erreurs loguées côté serveur (Audit Log) avec contexte tenant/screen/composant

#### FR-051 : Validation formulaires data-driven
**Priorité :** Must Have

**Description :** Les règles de validation des champs de formulaire sont déclarées dans le JSON (`validation` field). Évaluées côté Flutter avant envoi au backend. Jamais codées dans les widgets.

**Critères d'acceptation :**
- [ ] Règles supportées : `required`, `type`, `min`, `max`, `minLength`, `maxLength`, `regex`, `enum`
- [ ] Validation affichée en temps réel (onChange ou onBlur, configurable dans le JSON)
- [ ] Messages d'erreur localisables depuis le JSON
- [ ] Double validation : Flutter (UX) + NestJS (sécurité)

#### FR-052 : Offline Web
**Priorité :** Should Have

**Description :** Le client Flutter Web fonctionne en mode dégradé hors connexion. Cache via Drift web (IndexedDB). Sync identique à mobile à la reconnexion.

**Critères d'acceptation :**
- [ ] Flutter Web : Drift web (IndexedDB) pour persistance locale
- [ ] Mode offline web : données en lecture depuis cache, actions mises en queue
- [ ] Service Worker configuré pour mise en cache des assets Flutter
- [ ] Indicateur offline/online visible dans l'UI

---

### Groupe B — Backend NestJS (Must Have — MVP)

#### FR-009 : Auth JWT Multi-tenant
**Priorité :** Must Have

**Description :** Authentification JWT avec isolation multi-tenant. Chaque token contient le `tenant_id`, le `user_id` et les rôles. Refresh tokens avec rotation. OAuth2 préparé.

**Critères d'acceptation :**
- [ ] Access token JWT (15 min) + Refresh token (7 jours) avec rotation
- [ ] Claims obligatoires : `tenant_id`, `user_id`, `roles[]`, `department_id`
- [ ] Token d'un tenant A invalide sur les routes du tenant B (vérifié en test)
- [ ] Provisioning nouveau tenant < 30 secondes

#### FR-010 : RBAC Guards Dynamiques
**Priorité :** Must Have

**Description :** Rôles et permissions data-driven par tenant. Aucun rôle hardcodé dans le code NestJS. Les rôles sont définis dans la config JSON du tenant et chargés depuis la DB.

**Critères d'acceptation :**
- [ ] Rôles chargés depuis `tenant_config.roles` en DB (pas dans le code)
- [ ] Nouveau rôle = mise à jour JSON, zéro déploiement
- [ ] Guard `@Roles()` compatible avec rôles dynamiques
- [ ] Rôles par défaut retail : `OWNER`, `MANAGER`, `STAFF`

**Dépendances :** FR-009

#### FR-011 : BDUIService
**Priorité :** Must Have

**Description :** Service NestJS qui sert le JSON layout au client Flutter selon le tenant, le rôle et le contexte (module demandé). Résolution depuis le cache Redis en priorité.

**Critères d'acceptation :**
- [ ] `GET /api/:tenant/layout/:screenId` → JSON layout filtré par rôle
- [ ] Cache Redis : layout servi en < 20ms après premier chargement
- [ ] Cache invalidé automatiquement si la config tenant change
- [ ] JSON retourné pré-filtré : composants non autorisés absents du payload

**Dépendances :** FR-009, FR-010, FR-016

#### FR-012 : ModuleEngine
**Priorité :** Must Have

**Description :** Cœur du backend dynamique. Deux endpoints génériques couvrent 100% des opérations métier de tous les modules de tous les tenants. Le backend ne connaît aucun domaine métier.

**Critères d'acceptation :**
- [ ] `GET /api/:tenant/:moduleId/data` → données du module (liste, KPIs, stats)
- [ ] `POST /api/:tenant/:moduleId/action` → exécute une action (create, update, delete, custom)
- [ ] Le moduleId est résolu depuis la config JSON tenant (pas hardcodé)
- [ ] Tout module défini dans un JSON template fonctionne sans déploiement backend
- [ ] Idempotence : paramètre `client_mutation_id` sur tous les POST (FR-059)

#### FR-013 : Multi-tenant Basique
**Priorité :** Must Have

**Description :** Isolation des données par tenant via `tenant_id` sur toutes les tables (schéma partagé Phase 1). Migration vers schema-per-tenant en Phase 2 sans downtime.

**Critères d'acceptation :**
- [ ] Colonne `tenant_id` sur toutes les tables métier (migration auto via TypeORM/Prisma)
- [ ] Middleware NestJS injecte `tenant_id` automatiquement sur chaque requête
- [ ] Impossible de lire des données d'un autre tenant sans manipulation explicite du token
- [ ] Path de migration schema-per-tenant documenté et planifié

#### FR-014 : Zod Validator
**Priorité :** Must Have

**Description :** Validation de tous les fichiers JSON template contre le schéma du catalogue. Un JSON invalide ne peut jamais être déployé. Première ligne de défense de la robustesse.

**Critères d'acceptation :**
- [ ] Schema Zod couvre : `ComponentConfig`, `ScreenConfig`, `Rule`, `WorkflowStep`, `RBACRole`
- [ ] `POST /admin/templates/validate` → retourne erreurs détaillées si schéma invalide
- [ ] Validation exécutée en CI avant tout déploiement de catalogue
- [ ] Messages d'erreur lisibles par un intégrateur non-développeur

#### FR-015 : PostgreSQL RLS
**Priorité :** Must Have

**Description :** Row-Level Security PostgreSQL comme dernière ligne de défense. Même si une requête NestJS contourne les guards, la DB bloque les données d'un autre tenant.

**Critères d'acceptation :**
- [ ] Politique RLS active sur toutes les tables contenant des données métier
- [ ] Test d'intrusion : requête SQL directe avec `tenant_id` forgé → bloquée par RLS
- [ ] RLS paramétré via `SET app.current_tenant_id` par connexion
- [ ] Aucune performance significative dégradée (< 5% overhead mesuré)

#### FR-016 : Redis Sessions / Cache
**Priorité :** Must Have

**Description :** Redis pour sessions JWT (blacklist refresh tokens révoqués), cache des layouts BDUI, et (Phase 2) rate limiting des appels LLM par tenant.

**Critères d'acceptation :**
- [ ] Refresh tokens révoqués stockés dans Redis avec TTL
- [ ] Layouts BDUI cachés par clé `{tenant_id}:{screen_id}:{role}` avec TTL 5 min
- [ ] Invalidation cache sur modification config tenant
- [ ] Redis séparé du PostgreSQL (service Docker indépendant)

#### FR-017 : ABAC Basique (CASL)
**Priorité :** Must Have

**Description :** Contrôle d'accès attribut-based en Phase 1. CASL évalue les règles `(User + Resource + Context) → Decision`. Ex : MANAGER voit les factures DE SON DEPT si montant < 500k XOF.

**Critères d'acceptation :**
- [ ] CASL configuré dans NestJS pour les règles département/rôle
- [ ] Règles ABAC déclarées dans la config JSON tenant (pas dans le code)
- [ ] Chaque requête passe par CASL après le RBAC Guard (Layer 3)
- [ ] Extension Rete Algorithm planifiée Phase 3 (FR-037)

**Dépendances :** FR-010

#### FR-018 : Workflow DAG Engine
**Priorité :** Must Have

**Description :** Moteur de validation et d'exécution des workflows déclarés en JSON. Validation DAG (Kahn's algorithm — détection cycles, étapes inaccessibles). State Machine (XState) pour les transitions d'états.

**Critères d'acceptation :**
- [ ] Validation DAG : workflow circulaire → erreur bloquante au déploiement
- [ ] Exécution : étapes ordonnées, conditions évaluées, actions déclenchées
- [ ] XState : transitions illégales (ex: `livré → brouillon`) impossibles
- [ ] Tout workflow défini en JSON fonctionne sans déploiement backend

#### FR-019 : Audit Log
**Priorité :** Must Have

**Description :** Traçage de toutes les actions sensibles dans une table dédiée. Qui a demandé quoi, quand, avec quelles données. Requis pour la sécurité et pour les audits comptables futurs.

**Critères d'acceptation :**
- [ ] Chaque action `POST /:moduleId/action` loguée : `user_id`, `tenant_id`, `action`, `payload_hash`, `timestamp`
- [ ] Chaque appel LLM logué : `user_id`, `query_hash`, `model`, `tokens_used`, `timestamp`
- [ ] Logs immuables (insert-only, pas d'update/delete)
- [ ] Rétention configurable par tenant (défaut : 90 jours)

---

### Groupe C — Catalogue & Contrats JSON (Must Have — MVP)

#### FR-020 : JSON Schema BDUI
**Priorité :** Must Have

**Description :** Le contrat universel entre JSON et comportement. Définit précisément ce qu'un intégrateur peut déclarer. Source de vérité partagée entre TypeScript (NestJS) et Dart (Flutter).

**Critères d'acceptation :**
- [ ] Types définis : `ComponentConfig`, `ScreenConfig`, `Rule`, `LayoutConfig`, `WorkflowStep`, `ModuleConfig`
- [ ] Schema versionné (semver) — `"schema_version": "1.0.0"`
- [ ] Exemples valides inclus dans le catalogue pour chaque type
- [ ] Documentation du schema auto-générée depuis les types

#### FR-021 : Structure Catalogue
**Priorité :** Must Have

**Description :** Organisation des fichiers JSON du catalogue. Structure `catalog/` lisible par des humains et validée automatiquement. Ouvert aux intégrateurs tiers.

**Critères d'acceptation :**
- [ ] Structure : `catalog/domains/`, `catalog/modules/`, `catalog/fusions/`, `catalog/schemas/`
- [ ] Chaque fichier JSON validé par Zod au CI
- [ ] README catalogue : "comment créer un nouveau template sectoriel"
- [ ] Nouveau template = PR + validation CI, pas de déploiement backend

#### FR-022 : Template `retail_fresh_produce.json`
**Priorité :** Must Have

**Description :** Premier template sectoriel du catalogue. Conçu pour le secteur épicerie fine / fruits-légumes-épices UEMOA — pas pour Blandine spécifiquement. Déclare en JSON : navigation, 3 rôles (Propriétaire, Gestionnaire, Commercial), modules (validation croisée, pertes segmentées, clôture caisse, dashboard, alertes, réapprovisionnement), layouts, workflows DAG, règles RBAC. Preuve end-to-end que le moteur fonctionne.

**Critères d'acceptation :**
- [ ] 3 rôles déclarés en JSON : `OWNER`, `MANAGER`, `COMMERCIAL` — aucun hardcodé
- [ ] 4 fonctions critiques Phase 1 : validation croisée (Phase 3 workflow), pertes segmentées (Phase 4), clôture caisse quotidienne (Phase 7), dashboard proprio avec notification soir
- [ ] Workflow "clôture caisse" déclaré en DAG et exécutable
- [ ] Matrix RBAC complète : OWNER voit CA, MANAGER valide arrivages, COMMERCIAL vend — déclarée en JSON
- [ ] Testé avec Blandine (boutique fruits/légumes) ET validé sur un 2ème client du même secteur sans modifier le JSON
- [ ] Features différenciantes Phase 2 : Vrac→Sachet (épices), Taux de Frotte (déshydratation), code couleur fraîcheur
- [ ] Rendu fonctionnel sur Android sans une ligne de code Flutter spécifique au secteur

**Dépendances :** FR-001 à FR-019, FR-020, FR-021

#### FR-023 : Contraintes Global Scale
**Priorité :** Must Have

**Description :** Contraintes architecturales non-négociables dès le MVP. Permettent la croissance vers d'autres marchés sans refactoring.

**Critères d'acceptation :**
- [ ] **i18n** : 0 string visible par l'utilisateur hardcodée dans Flutter ou NestJS
- [ ] **Multi-devises** : format monétaire configurable par tenant (FCFA par défaut, extensible)
- [ ] **Compliance pluggable** : OHADA sera un plugin, pas une dépendance core
- [ ] **Payment adapters** : interface `PaymentAdapter` définie — Wave = 1 implémentation

#### FR-053 : Validation JSON Bidirectionnelle
**Priorité :** Must Have

**Description :** Double validation du JSON : Zod côté NestJS (déploiement) + JSON Schema côté Flutter (runtime). Un JSON cassé ne peut jamais atteindre le moteur de rendu.

**Critères d'acceptation :**
- [ ] NestJS : Zod valide avant stockage en DB
- [ ] Flutter : JSON Schema validé avant parsing par le BDUIEngine
- [ ] Erreur côté Flutter → fallback UI + log d'erreur, jamais crash
- [ ] Les deux validateurs partagent le même contrat (FR-054)

#### FR-054 : Code-gen Contrat Partagé
**Priorité :** Must Have

**Description :** Le JSON Schema BDUI génère automatiquement les types TypeScript (NestJS) et les classes Dart (Flutter). Désynchronisation impossible entre backend et frontend.

**Critères d'acceptation :**
- [ ] Script de génération : `json-schema → TypeScript interfaces + Dart classes`
- [ ] Exécuté en CI à chaque modification du schema
- [ ] Compilation TypeScript ou Dart échoue si types générés utilisés incorrectement
- [ ] Version du schema dans chaque payload API

#### FR-055 : Tests Coverage Moteur
**Priorité :** Must Have

**Description :** Couverture de tests suffisante pour garantir la non-régression du moteur sur la durée du projet.

**Critères d'acceptation :**
- [ ] Unit tests ComponentRegistry : chaque composant enregistré testé (rendu nominal + états erreur)
- [ ] Unit tests RuleEvaluator : tous les opérateurs testés + cas limites
- [ ] Unit tests LayoutResolver : 4 layouts × 3 breakpoints
- [ ] Integration tests ModuleEngine : GET + POST pour 3 modules différents
- [ ] Widgetbook comme référence de non-régression visuelle (snapshot tests)
- [ ] Coverage ≥ 90% sur le code moteur

---

### Groupe D — Sync Offline & Robustesse (Must Have — MVP)

#### FR-056 : Sync Queue Locale
**Priorité :** Must Have

**Description :** Toutes les mutations effectuées en mode offline sont enregistrées dans une queue ordonnée (Drift). À la reconnexion, les mutations partent dans l'ordre chronologique d'occurrence.

**Critères d'acceptation :**
- [ ] Queue persistée dans Drift (survit à un redémarrage de l'app)
- [ ] Chaque entrée : `mutation_id`, `module_id`, `action`, `payload`, `timestamp`, `status`
- [ ] Statuts : `pending`, `sending`, `success`, `conflict`, `error`
- [ ] Reprise automatique à la reconnexion (sans intervention utilisateur)

#### FR-057 : Conflict Resolution Phase 1
**Priorité :** Must Have

**Description :** Strategy de résolution des conflits de sync. Phase 1 : server-wins par défaut avec conflict queue pour les cas ambigus. Chaque module peut déclarer sa stratégie dans le JSON.

**Critères d'acceptation :**
- [ ] Stratégies supportées : `server_wins` (défaut), `client_wins`, `manual`
- [ ] Stratégie déclarée dans le JSON du module : `"conflict_strategy": "server_wins"`
- [ ] Conflit `manual` → entrée dans la conflict queue visible par l'utilisateur autorisé
- [ ] Interface de résolution de conflit : affiche version locale vs serveur, choix utilisateur

#### FR-058 : Sync Status UI
**Priorité :** Must Have

**Description :** Indicateur de statut de synchronisation visible dans l'UI, généré depuis le JSON template (pas hardcodé). L'utilisateur sait toujours si ses données sont synchronisées.

**Critères d'acceptation :**
- [ ] États affichés : "Hors ligne", "Sync en cours…", "À jour", "X conflits en attente"
- [ ] Indicateur configurable dans le JSON (position, style, seuil d'alerte)
- [ ] Badge sur l'icône de l'app si conflits en attente (mobile)
- [ ] Détail expandable : liste des mutations en attente avec timestamp

#### FR-059 : Idempotence Endpoints
**Priorité :** Must Have

**Description :** Tous les endpoints POST sont idempotents via une clé de mutation client. Rejouer la même mutation deux fois (après un timeout réseau) ne crée pas de doublon.

**Critères d'acceptation :**
- [ ] Header obligatoire : `X-Client-Mutation-Id: {uuid}` sur tous les POST
- [ ] Backend stocke les `client_mutation_id` traités (TTL 24h)
- [ ] Requête dupliquée → retourne le résultat original sans ré-exécuter l'action
- [ ] Testé en E2E : simulation de timeout réseau + replay

---

### Groupe E — Phase 2 : IA Intégrée (Should Have — Mois 4-6)

#### FR-024 : FastAPI Microservice IA
**Priorité :** Should Have

**Description :** Microservice Python séparé pour toutes les opérations IA. LangChain + streaming SSE vers NestJS. Indépendant du backend principal — peut scaler séparément.

**Critères d'acceptation :**
- [ ] FastAPI service dans le docker-compose (service `fastapi`)
- [ ] Streaming SSE depuis FastAPI → NestJS WebSocket → Flutter
- [ ] Health check + circuit breaker si FastAPI down (NestJS continue sans IA)
- [ ] Rate limiting par tenant (via Redis)

#### FR-025 : RAG Hybride
**Priorité :** Should Have

**Description :** Recherche hybride vecteur + keyword avec reranking. LlamaIndex + pgvector pour l'indexation. BM25 pour keyword. Cross-encoder pour reranking. 30-40% de pertinence en plus vs RAG basique.

**Critères d'acceptation :**
- [ ] Indexation : données métier du tenant → embeddings → pgvector
- [ ] Recherche hybride : vecteur + BM25, fusion via Reciprocal Rank Fusion
- [ ] Reranking : cross-encoder ou Cohere Rerank sur le top-20
- [ ] Filtre ABAC appliqué avant retour au LLM (données non autorisées jamais indexées)

#### FR-026 : Config Conversationnelle
**Priorité :** Should Have

**Description :** Onboarding ERP complet via conversation IA (30-45 min). L'IA extrait automatiquement les entités métier, rôles, workflows et règles. Génère un JSON config valide, validé Zod, déployé immédiatement.

**Critères d'acceptation :**
- [ ] 4 étapes : Découverte (secteur) → Rôles & équipe → Workflows → Génération JSON
- [ ] JSON config généré validé automatiquement par Zod avant déploiement
- [ ] Tenant opérationnel < 45 min depuis le début de la conversation
- [ ] L'intégrateur peut ajuster le JSON généré avant validation finale

#### FR-027 : Extraction Structurée NER
**Priorité :** Should Have

**Description :** Instructor/Pydantic force le LLM à retourner uniquement du JSON valide contre un schéma Pydantic. Élimine les JSON cassés ou hallucinations de structure.

**Critères d'acceptation :**
- [ ] Tous les appels LLM de la Config Conversationnelle passent par Instructor
- [ ] Schémas Pydantic pour : `EntityExtraction`, `RoleConfig`, `WorkflowConfig`, `RuleConfig`
- [ ] Retry automatique (max 3) si le LLM retourne un JSON invalide
- [ ] Aucun JSON cassé ne peut être injecté dans le catalogue

#### FR-028 : FSM Auto-généré
**Priorité :** Should Have

**Description :** State Machine (XState) générée automatiquement depuis la config conversationnelle. Modélise les états et transitions d'une entité métier (commande, facture, etc.).

**Critères d'acceptation :**
- [ ] Config IA décrit workflow → XState FSM générée et stockée dans la config tenant
- [ ] FSM exécutée par NestJS pour valider les transitions
- [ ] Transition illégale → erreur 409 avec état actuel + transitions autorisées

#### FR-029 : Admin Flutter Web
**Priorité :** Should Have

**Description :** Interface d'administration en Flutter Web — même BDUIEngine, même Design System, même JSON Schema que l'app mobile. Chat IA conversationnel pour configurer un tenant. Preview BDUI identique au rendu mobile par construction.

**Critères d'acceptation :**
- [ ] Flutter Web app distincte (ou même app avec route `/admin` réservée OWNER/ADMIN)
- [ ] Chat IA conversationnel pour onboarding et modification de config
- [ ] Preview BDUI temps réel : modifier le JSON → aperçu immédiat
- [ ] Gestion tenants : créer, activer, désactiver, voir statistiques

#### FR-030 : BDAPI
**Priorité :** Should Have

**Description :** Génération automatique d'APIs REST + documentation OpenAPI depuis la config JSON. `POST /api/{tenant}/commandes` auto-généré depuis le module "commandes" — zéro code backend.

**Critères d'acceptation :**
- [ ] Chaque module déclaré dans la config génère automatiquement ses routes CRUD
- [ ] OpenAPI documentation auto-générée et accessible sur `/docs`
- [ ] APIs sécurisées par les mêmes 5 couches de sécurité que l'app interne
- [ ] Versionning des APIs (`/v1/`, `/v2/`)

#### FR-031 : MinIO Storage
**Priorité :** Should Have

**Description :** Stockage fichiers S3-compatible (PDFs, images, documents). Remplace Supabase Storage. Intégré dans le docker-compose.

**Critères d'acceptation :**
- [ ] Service MinIO dans docker-compose
- [ ] Upload/download via NestJS storage proxy (clients ne touchent pas MinIO directement)
- [ ] Isolation par tenant : bucket `{tenant_id}/`
- [ ] Taille max fichier configurable par tenant

#### FR-032 : Schema-per-tenant
**Priorité :** Should Have

**Description :** Migration de l'isolation shared schema vers schema PostgreSQL dédié par tenant. Isolation complète sans downtime.

**Critères d'acceptation :**
- [ ] Migration automatisée (script + rollback) sans downtime
- [ ] Chaque tenant dans son propre schéma PostgreSQL
- [ ] RLS encore active comme double protection
- [ ] Migration testée sur dataset de production simulé avant déploiement

#### FR-033 : Mem0
**Priorité :** Should Have

**Description :** Mémoire long terme par utilisateur pour le Config Agent. L'IA se souvient du contexte des sessions précédentes.

**Critères d'acceptation :**
- [ ] Mémoire stockée dans Redis/PostgreSQL par `user_id`
- [ ] TTL configurable (défaut : 30 jours)
- [ ] Purge sur demande de l'utilisateur (RGPD)

#### FR-034 : Notifications Push / WebSocket
**Priorité :** Should Have

**Description :** Alertes temps réel vers l'app Flutter : seuils stock dépassés, approbations en attente, clôtures journalières. Canal WebSocket NestJS Gateway.

**Critères d'acceptation :**
- [ ] WebSocket Gateway NestJS fonctionnel
- [ ] Flutter se connecte au WebSocket à l'ouverture de l'app
- [ ] Types de notifications configurables dans le JSON du module
- [ ] File de notifications en cache si client offline (livrées à la reconnexion)

#### FR-035 : AI Excel/CSV Import
**Priorité :** Should Have

**Description :** Upload d'un fichier Excel/CSV du catalogue produits → l'IA auto-configure le module correspondant (entités, champs, variantes).

**Critères d'acceptation :**
- [ ] Formats supportés : `.xlsx`, `.csv`
- [ ] IA extrait : entités, colonnes → champs du module, unités, variantes
- [ ] Preview de la config générée avant validation
- [ ] Erreurs de parsing affichées ligne par ligne

---

### Groupe F — Phase 3 : Robustesse (Could Have — Mois 7-9)

#### FR-036 : CRDT Offline Avancé
**Priorité :** Could Have

**Description :** Upgrade de la sync Phase 1 (server-wins) vers CRDT complet. Vector Clocks pour merge automatique sans conflit. LWW-Register pour les cas simples.

**Critères d'acceptation :**
- [ ] Chaque enregistrement modifiable porte un Vector Clock
- [ ] Merge automatique sans intervention humaine dans 95%+ des cas
- [ ] Conflict queue Phase 1 rétrocompatible (CRDT gère les nouveaux cas)

#### FR-037 : Rete Algorithm
**Priorité :** Could Have

**Description :** Moteur de règles ABAC O(1) après compilation. Remplace CASL pour les tenants avec 100+ règles ABAC complexes. Évaluation massive de règles sans dégradation.

**Critères d'acceptation :**
- [ ] Règles ABAC compilées en réseau Rete au déploiement de la config
- [ ] Évaluation d'une règle : O(1) indépendamment du nombre de règles total
- [ ] Compatibilité descendante avec CASL (migration progressive)

#### FR-038 : Docling
**Priorité :** Could Have

**Description :** Ingestion de documents clients existants (PDF, Excel, Word) vers des chunks indexables dans le RAG. Permet à l'IA de répondre sur les données historiques du client.

**Critères d'acceptation :**
- [ ] Formats : PDF, .xlsx, .docx
- [ ] Chunking intelligent (pas de découpe arbitraire au milieu d'une phrase)
- [ ] Chunks filtrés par tenant dans pgvector avant toute requête RAG

#### FR-039 : Observabilité Langfuse
**Priorité :** Could Have

**Description :** Traçage complet des appels LLM (prompt, réponse, tokens, coût, latence) via Langfuse. Permet d'optimiser les prompts et de contrôler les coûts.

**Critères d'acceptation :**
- [ ] Chaque appel LLM tracé dans Langfuse avec metadata tenant
- [ ] Dashboard coûts par tenant / par mois
- [ ] Alertes si coût LLM dépasse seuil configuré

#### FR-040 : Fine-tuning Modèle Local
**Priorité :** Could Have

**Description :** Fine-tuner un modèle léger (Phi-3, Mistral 7B) spécialisé extraction d'entités métier ERP. Réduction de la dépendance au cloud et amélioration de la précision.

#### FR-041 : Ollama — LLM Local
**Priorité :** Could Have

**Description :** Déploiement LLM local pour clients sans connexion stable (sites miniers, zones rurales). Même Config Agent, même qualité, sans dépendance internet.

---

### Groupe G — Plateforme Intégrateur (Could Have — H2-H3)

#### FR-042 : Template Builder
**Priorité :** Could Have

**Description :** Outil no-code/IA en Flutter Web permettant aux intégrateurs de créer des templates sectoriels sans écrire de JSON à la main. Génère un JSON valide contre le catalogue Scalario.

#### FR-043 : SDK Intégrateur
**Priorité :** Could Have

**Description :** API/SDK pour intégrateurs avancés créant des modules custom. Versionning, sandbox de validation, documentation générée.

#### FR-044 : Marketplace Templates
**Priorité :** Could Have

**Description :** Place de marché des templates sectoriels créés par les intégrateurs. Système de review, versionning, garantie de compatibilité avec les versions du moteur.

---

### Groupe H — Templates Métier Post-MVP (Should / Could Have)

#### FR-045 : Comptabilité OHADA
**Priorité :** Should Have (H2)

**Description :** Plugin comptabilité conforme OHADA — plan comptable, journaux de saisie, bilan, compte de résultat. Déclaré en JSON comme tout autre module. OHADA est un plugin, pas une dépendance core.

#### FR-046 : Module RH
**Priorité :** Should Have (H2)

**Description :** Gestion des ressources humaines : fiches employés, contrats, congés, bulletins de paie. Déclaré en JSON.

#### FR-047 : Module CRM
**Priorité :** Could Have (H3)

**Description :** Gestion clients, leads, pipeline commercial. Déclaré en JSON.

#### FR-048 : Module Production / Fabrication
**Priorité :** Could Have (H3)

**Description :** Gestion de la production industrielle, ordres de fabrication, matières premières. Déclaré en JSON.

#### FR-049 : Canal B2B Inter-entreprises
**Priorité :** Could Have (H3 — Gate 20+ clients)

**Description :** Commandes inter-entreprises entre tenants Scalario. Déclenché quand 20+ clients dans une même ville.

---

## Exigences Non-Fonctionnelles

### NFR-001 : Performance — Rendu BDUI
**Priorité :** Must Have

**Description :** Le BDUIEngine rend un screen complet depuis JSON en moins de 200ms (cold) et 50ms (hot).

**Critères d'acceptation :**
- [ ] Rendu cold (depuis cache Drift) < 200ms sur Android mid-range (Snapdragon 680 ou équivalent)
- [ ] Rendu hot (depuis mémoire) < 50ms
- [ ] Navigation entre screens (avec animation) < 100ms perçue

---

### NFR-002 : Performance — API Backend
**Priorité :** Must Have

**Description :** Endpoints NestJS répondent en moins de 300ms au p95. Layouts BDUI depuis Redis < 20ms.

**Critères d'acceptation :**
- [ ] `GET /:moduleId/data` p95 < 300ms
- [ ] `POST /:moduleId/action` p95 < 400ms
- [ ] Layout BDUI depuis Redis < 20ms après premier chargement
- [ ] Opérations longues (IA) : streaming SSE — jamais de timeout > 2s sans réponse partielle

---

### NFR-003 : Sécurité — Isolation Multi-tenant
**Priorité :** Must Have

**Description :** Un tenant ne peut jamais accéder aux données d'un autre. 5 couches de sécurité. Le LLM ne reçoit que des données filtrées.

**Critères d'acceptation :**
- [ ] JWT avec `tenant_id` vérifié sur chaque requête
- [ ] RLS PostgreSQL actif sur toutes les tables métier
- [ ] Test d'intrusion : token tenant A ne peut pas lire les données tenant B
- [ ] Le LLM ne reçoit jamais de données non filtrées par RBAC/ABAC
- [ ] Audit log complet (qui, quoi, quand, données concernées)

---

### NFR-004 : Robustesse — Tolérance aux Erreurs BDUI
**Priorité :** Must Have

**Description :** Un JSON invalide ou une erreur de composant ne crashe jamais l'app. Dégradation gracieuse garantie.

**Critères d'acceptation :**
- [ ] JSON invalide → fallback UI clair, jamais crash application
- [ ] Composant inconnu → `UnknownComponent` affiché, reste du screen fonctionnel
- [ ] Source de données manquante → état erreur isolé au composant
- [ ] Validation bidirectionnelle Zod/JSON Schema bloque les templates invalides avant déploiement
- [ ] Coverage tests moteur ≥ 90% (ComponentRegistry, RuleEvaluator, LayoutResolver)

---

### NFR-005 : Disponibilité
**Priorité :** Must Have

**Description :** 99.5% uptime mensuel. Les clients continuent en offline pendant les pannes.

**Critères d'acceptation :**
- [ ] 99.5% uptime mensuel (≤ 3h36 d'indisponibilité/mois)
- [ ] Panne backend → app mobile continue en mode offline sans message d'erreur intrusif
- [ ] Recovery automatique après restart Docker (health checks + restart policy)
- [ ] Backup PostgreSQL quotidien automatique

---

### NFR-006 : Scalabilité — Multi-tenant
**Priorité :** Must Have

**Description :** Architecture supporte 1 000+ tenants actifs. Migration schéma partagé → schema-per-tenant planifiée Phase 2 sans downtime.

**Critères d'acceptation :**
- [ ] Phase 1 : 100 tenants actifs sans dégradation de performance
- [ ] Phase 2 : migration schema-per-tenant sans perte de données ni downtime
- [ ] 50 utilisateurs simultanés par tenant sans impact cross-tenant
- [ ] Provisioning nouveau tenant < 30 secondes

---

### NFR-007 : Maintenabilité — Règle Zéro Logique Métier Flutter
**Priorité :** Must Have

**Description :** Aucune règle métier codée dans Flutter. Tout ce qui est métier est dans le JSON. Vérifiable et enforçable automatiquement.

**Critères d'acceptation :**
- [ ] Aucun `if` métier dans le code Flutter (linting rule custom en CI)
- [ ] Toute condition d'affichage dans `visible_if` du JSON
- [ ] Toute validation de champ dans `validation` du JSON
- [ ] Tout nouveau module = nouveau JSON, zéro ligne Flutter
- [ ] Guide développeur : "comment ajouter un module" (checklist sans toucher Flutter)

---

### NFR-008 : Compatibilité — Multi-plateforme
**Priorité :** Must Have

**Description :** App Flutter fonctionne sur Android 8+, iOS 14+, et navigateurs modernes depuis un codebase unique.

**Critères d'acceptation :**
- [ ] Android 8.0+ (API 26) testé et fonctionnel
- [ ] iOS 14+ testé et fonctionnel
- [ ] Flutter Web : Chrome 90+, Safari 14+, Firefox 88+
- [ ] Responsive : breakpoints mobile/tablet/desktop gérés par LayoutResolver
- [ ] PWA installable depuis le navigateur

---

### NFR-009 : Qualité du Code
**Priorité :** Must Have

**Description :** Code maintenable par un solo dev sur le long terme. CI/CD strict. Documentation technique auto-générée.

**Critères d'acceptation :**
- [ ] Flutter : `flutter analyze` 0 warning en CI
- [ ] NestJS : ESLint + Prettier 0 erreur en CI
- [ ] Tests : ≥ 80% coverage global, ≥ 90% sur le code moteur
- [ ] CI/CD GitHub Actions : lint + tests + build sur chaque PR
- [ ] OpenAPI auto-généré depuis les décorateurs NestJS

---

### NFR-010 : Internationalisation & Scale Global
**Priorité :** Must Have

**Description :** Aucune string hardcodée. Multi-devises natif. Compliance et payment adapters pluggables.

**Critères d'acceptation :**
- [ ] Flutter `flutter_localizations` + `intl` — 0 string hardcodée dans les widgets
- [ ] NestJS : messages d'erreur = codes traduits, pas de strings françaises
- [ ] Multi-devises : format configurable par tenant (FCFA par défaut)
- [ ] OHADA = plugin interchangeable (pas de dépendance core)
- [ ] Wave = adapter (interface `PaymentAdapter` implémentée)

---

## Epics

### EPIC-001 : Design System Scalario
**Phase :** 1 — MVP | **Priorité :** Must Have | **Stories estimées :** 5-7

Construire le Design System Scalario une fois, pour toujours. Design tokens, theming Material 3 natif (zéro dépendance UI externe), composants BDUI métier (KPICard, DataTable, AlertBanner, FAB, ListTile, FormSection, ChartBar), documentation vivante Widgetbook avec tous les états de chaque composant.

**FRs :** FR-005, FR-007 | **Valeur :** Base immuable. Widgetbook = référence de non-régression visuelle permanente.

---

### EPIC-002 : BDUI Engine Flutter
**Phase :** 1 — MVP | **Priorité :** Must Have | **Stories estimées :** 6-8

ComponentRegistry, RuleEvaluator, LayoutResolver, BDUIEngine. Sandbox JSON. Support Android + iOS + Web. Error boundaries sur chaque composant. Validation formulaires data-driven.

**FRs :** FR-001, FR-001b, FR-002, FR-003, FR-004, FR-006, FR-050, FR-051 | **Valeur :** Quand cet epic est livré, n'importe quel JSON devient un screen fonctionnel.

---

### EPIC-003 : Backend Foundation — Auth, Sécurité, Multi-tenant
**Phase :** 1 — MVP | **Priorité :** Must Have | **Stories estimées :** 6-8

Auth JWT multi-tenant, RBAC Guards dynamiques, ABAC basique CASL, PostgreSQL RLS, Redis, Audit Log, multi-tenant isolation `tenant_id`.

**FRs :** FR-009, FR-010, FR-013, FR-015, FR-016, FR-017, FR-019 | **Valeur :** Sécurité non-négociable. 5 couches de protection garanties.

---

### EPIC-004 : Module Engine & Catalogue JSON
**Phase :** 1 — MVP | **Priorité :** Must Have | **Stories estimées :** 5-7

BDUIService, ModuleEngine (2 endpoints génériques → 100% des modules), JSON Schema BDUI, Zod Validator, structure catalogue, validation bidirectionnelle, code-gen contrat partagé, tests coverage moteur.

**FRs :** FR-011, FR-012, FR-014, FR-020, FR-021, FR-053, FR-054, FR-055 | **Valeur :** Le "impossible de sortir du catalogue" est garanti ici. Backend 100% dynamique — zéro endpoint spécifique à un domaine.

---

### EPIC-005 : Workflow DAG Engine
**Phase :** 1 — MVP | **Priorité :** Must Have | **Stories estimées :** 4-5

Validation DAG (Kahn's algorithm), exécution ordonnée des étapes, State Machine XState pour transitions d'états. Tout workflow déclaré en JSON, aucun codé.

**FRs :** FR-018, FR-028 | **Valeur :** N'importe quel workflow métier (retail, pharmacie, BTP) déclarable en JSON et exécuté sans coder.

---

### EPIC-006 : Offline-First & Sync
**Phase :** 1 — MVP | **Priorité :** Must Have | **Stories estimées :** 6-8

Drift/Isar offline mobile, Drift web offline, sync queue ordonnée, idempotence endpoints, conflict resolution server-wins + conflict queue, sync status UI data-driven.

**FRs :** FR-008, FR-052, FR-056, FR-057, FR-058, FR-059 | **Valeur :** Critique pour UEMOA (connexions instables). Sans ça, l'app est inutilisable en conditions terrain.

---

### EPIC-007 : Premier Template — `retail_fresh_produce.json`
**Phase :** 1 — MVP | **Priorité :** Must Have | **Stories estimées :** 3-5

Template sectoriel épicerie fine / fruits-légumes-épices UEMOA. Conçu pour le secteur, pas pour un seul client. 3 rôles (OWNER, MANAGER, COMMERCIAL), 4 fonctions critiques Phase 1 (validation croisée, pertes segmentées, clôture caisse, dashboard proprio), workflows DAG, RBAC déclaré en JSON. Features différenciantes Phase 2 : Vrac→Sachet, Taux de Frotte, code couleur fraîcheur.

**FRs :** FR-022, FR-023 | **Valeur :** Preuve end-to-end de l'architecture. Valide le cas Blandine ET le 2ème client du même secteur sans modification. Modèle de référence pour tout futur template.

---

### EPIC-008 : Config Conversationnelle IA
**Phase :** 2 — Mois 4-6 | **Priorité :** Should Have | **Stories estimées :** 8-10

FastAPI microservice, RAG hybride (LlamaIndex + pgvector + BM25 + reranking), Config Agent (extraction NER avec Instructor), FSM auto-générée, Mem0, AI Excel/CSV import.

**FRs :** FR-024, FR-025, FR-026, FR-027, FR-028, FR-033, FR-035 | **Valeur :** Ce qui différencie Scalario de tout concurrent. Config SAP = 6 mois. Config Scalario = 45 min.

---

### EPIC-009 : Admin Flutter Web & BDAPI
**Phase :** 2 — Mois 4-6 | **Priorité :** Should Have | **Stories estimées :** 5-7

Interface d'administration Flutter Web (même BDUIEngine, même Design System). Chat IA pour onboarding tenant. Preview BDUI temps réel. BDAPI : génération auto d'APIs REST + OpenAPI depuis config JSON.

**FRs :** FR-029, FR-030 | **Valeur :** L'intégrateur configure via Flutter Web, voit le résultat identique à l'app mobile — un seul codebase.

---

### EPIC-010 : Infrastructure Phase 2
**Phase :** 2 — Mois 4-6 | **Priorité :** Should Have | **Stories estimées :** 4-6

MinIO S3, migration schema-per-tenant (sans downtime), notifications WebSocket, observabilité Langfuse.

**FRs :** FR-031, FR-032, FR-034, FR-039 | **Valeur :** Passage de "marche pour 10 clients" à "marche pour 1000 clients".

---

### EPIC-011 : Robustesse Phase 3
**Phase :** 3 — Mois 7-9 | **Priorité :** Could Have | **Stories estimées :** 5-7

CRDT avancé (Vector Clocks), Rete Algorithm ABAC O(1), Docling ingestion documents, fine-tuning modèle local, Ollama LLM offline.

**FRs :** FR-036, FR-037, FR-038, FR-040, FR-041 | **Valeur :** Ce qui sépare "solide" de "indestructible". Prévu à ≥ 50 clients.

---

### EPIC-012 : Canal Intégrateur Certifié
**Phase :** 2 — M6-M9 | **Priorité :** Must Have | **Stories estimées :** 4-6

Programme de certification intégrateur : formation (2 jours), certification officielle, kit complet (pitch deck, démo app, contrats types). Revenue split 60/40 (Scalario/intégrateur) sur MRR mensuel. Certification payante (75K FCFA one-time) + renouvellement annuel (40K FCFA). Contrat avec clause non-concurrence sur le moteur BDUI.

**Ce que l'intégrateur peut faire :** Choisir un template du catalogue, configurer le tenant JSON pour le client, déployer, former l'équipe, assurer le support tier-1. Zéro compétence dev requise.

**Critères d'acceptation :**
- [ ] Programme de formation documenté — 2 jours suffisent pour onboarder un 1er client
- [ ] Kit intégrateur complet livré à la certification
- [ ] Dashboard intégrateur : ses clients, son MRR, ses commissions
- [ ] 3 intégrateurs certifiés Phase 2 — au moins 1 autonome (onboarde sans Carlos)
- [ ] 1 intégrateur actif hors Burkina Faso (Côte d'Ivoire ou Sénégal) à M12

**FRs :** FR-042 (simplifié), FR-044 | **Valeur :** Canal de distribution qui scale sans Carlos. Chaque intégrateur = équipe commerciale + support externalisée. Expansion géographique sans présence physique de Carlos.

---

### EPIC-012b : Marketplace Templates
**Phase :** H2-H3 | **Priorité :** Could Have | **Stories estimées :** 4-6

Intégrateurs tiers publient leurs templates sectoriels sur la marketplace. Review qualité, versionning, garantie compatibilité moteur. Commission Scalario : 20% par vente.

**FRs :** FR-043, FR-044 | **Valeur :** Catalogue auto-alimenté. Revenus passifs. Chaque template ouvre un marché sans que Carlos code.

---

### EPIC-013 : Templates Métier Post-MVP
**Phase :** H2-H3 | **Priorité :** Should / Could Have | **Stories estimées :** 10-15

Comptabilité OHADA (H2 — prioritaire), RH (H2), CRM (H3), Production/Fabrication (H3), Canal B2B (H3 — gate 20+ clients). Tous déclarés en JSON, zéro code moteur.

**FRs :** FR-045, FR-046, FR-047, FR-048, FR-049 | **Valeur :** Chaque template ouvre un nouveau marché sans modifier le moteur.

---

## Personas Utilisateurs

### P-001 : L'Intégrateur Scalario
Technicien local formé et certifié par Scalario. Configure l'ERP pour les clients via l'Admin Flutter Web et le chat IA. Crée des templates sectoriels. Gagne sa vie en vendant des configurations et templates.
**Accès :** Admin Flutter Web (config tenant, template builder)

### P-002 : L'Owner / Gérant
Propriétaire d'entreprise (ex: Blandine). Veut voir son business en temps réel depuis son téléphone, même à distance. Pas technique. Approuve les actions importantes.
**Accès :** App Flutter mobile — vue complète, toutes approbations

### P-003 : Le Manager / Gestionnaire
Responsable opérationnel sur le terrain. Supervise les stocks, valide les livraisons, résout les conflits.
**Accès :** App Flutter mobile — modules opérationnels selon template

### P-004 : Le Staff / Employé
Vendeur, caissier, livreur. Interface simplifiée, modules limités à son rôle déclaré dans le JSON.
**Accès :** App Flutter mobile — interface réduite par RuleEvaluator selon rôle

### P-005 : L'Administrateur Scalario
Carlos + future équipe. Gère la plateforme, valide les templates du marketplace, monitore les tenants.
**Accès :** Admin Flutter Web — accès total plateforme

---

## Flux Utilisateurs Clés

### Flux 1 : Onboarding nouveau client (Phase 2)
```
Intégrateur ouvre Admin Flutter Web
  → Démarre chat IA conversationnel
  → Répond : secteur, rôles/équipe, workflows, modules
  → Config Agent extrait → génère JSON config
  → Zod valide le JSON
  → Tenant provisionné automatiquement (< 30 sec)
  → App mobile disponible pour les employés
  → Durée totale : < 45 min
```

### Flux 2 : Utilisation quotidienne offline/online (Phase 1)
```
Employé ouvre app Flutter
  → BDUIEngine charge layout depuis cache Drift local
  → Effectue ses opérations (vente, stock, etc.)
  → Si offline : actions mises en sync queue ordonnée
  → Connexion rétablie : sync automatique en arrière-plan
  → Indicateur "À jour" dans l'UI
  → Conflit détecté : notification + interface de résolution
```

### Flux 3 : Ajout d'un nouveau template sectoriel
```
Intégrateur crée pharmacie.json dans catalog/domains/
  → Zod valide en CI (impossible de sortir du catalogue)
  → PR merged → catalogue publié
  → Nouveau client pharmacie configuré en < 45 min (Phase 2)
  → Zéro ligne de code Flutter ou NestJS modifiée
```

---

## Dépendances

### Dépendances internes (ordre de build)

1. **JSON Schema BDUI (FR-020)** doit être finalisé avant tout développement Flutter ou NestJS — c'est le contrat
2. **Design System EPIC-001** avant BDUI Engine EPIC-002
3. **Backend Foundation EPIC-003** avant Module Engine EPIC-004
4. **EPIC-001 + EPIC-002 + EPIC-003 + EPIC-004** tous requis avant Template Retail EPIC-007
5. **Workflow DAG EPIC-005** peut être développé en parallèle de EPIC-002 et EPIC-003
6. **Offline & Sync EPIC-006** peut être développé en parallèle de EPIC-004
7. **Phase 2 (EPIC-008 à EPIC-010)** démarre seulement après validation Phase 1 complète

### Dépendances externes

| Dépendance | Usage | Criticité |
|---|---|---|
| Flutter SDK (stable) | App mobile + web + admin | Critique |
| NestJS | Backend API principal | Critique |
| PostgreSQL + pgvector | Données + RAG vectoriel + RLS | Critique |
| Docker + Docker Compose | 5 services (nestjs, fastapi, postgresql, redis, minio) | Critique |
| Claude API (Anthropic) | Config Agent Phase 2 | Phase 2 |
| Ollama | LLM local Phase 3 | Phase 3 |
| Material 3 Flutter natif | Design System base (zéro dépendance externe) | Critique |
| Widgetbook | Documentation composants | Critique |
| CASL / Casbin | ABAC NestJS | Critique |
| Drift / Isar | Offline persistence Flutter | Critique |
| LangChain / LlamaIndex | RAG + Config Agent Phase 2 | Phase 2 |
| Instructor / Pydantic | Extraction structurée Phase 2 | Phase 2 |
| XState | Workflow FSM | Phase 1 |

---

## Hypothèses

1. L'intégrateur Phase 1 est Carlos — onboarding manuel jusqu'à la Phase 2 (Config IA)
2. Les clients Phase 1 ont une connexion mobile suffisante pour la sync périodique (pas forcément stable)
3. Flutter Web est suffisant pour l'interface Admin — pas besoin de React
4. Le template `retail_fresh_produce.json` couvre le cas Blandine ET est généralisable au secteur sans modification par client
5. PostgreSQL schéma partagé suffit pour < 100 tenants en Phase 1
6. Claude API (cloud) est acceptable pour Phase 2 — Ollama (local) est un upgrade Phase 3
7. Un seul codebase Flutter couvre mobile (Android/iOS) + web sans duplication

### Hypothèses critiques à valider (Gates)

- **H1 (Gate 0 — J+90)** : Blandine utilise l'app quotidiennement et réfère au moins 1 business de son réseau. *Si faux : revoir la proposition de valeur avant tout autre client.*
- **H2 (Gate 1 — M3)** : Un intégrateur externe peut onboarder un client sans Carlos en 2 jours de formation. *Si faux : simplifier le produit ou la formation avant de certifier.*
- **H3 (Gate 1 — M3)** : Le template `retail_fresh_produce.json` fonctionne pour le 2ème client du même secteur sans modification JSON. *Si faux : le template est trop Blandine-specific — retravail avant industrialisation.*
- **H4 (Gate 2 — M6)** : 40–60K FCFA/mois est soutenable pour Blandine sur 12 mois sans relance. *Si faux : repricing ou modèle freemium à étudier.*

---

## Hors Périmètre

- Portals clients externes (site e-commerce, espace client public)
- Génération de sites web
- Logique métier hardcodée dans Flutter ou NestJS (principe fondamental)
- Support Supabase (remplacé par NestJS + PostgreSQL + MinIO)
- Interface admin en React/Next.js (tout est Flutter)
- Modules métier hardcodés (tout est JSON dans le catalogue)
- Supabase, Firebase ou tout BaaS
- Application desktop native séparée (Flutter desktop = bonus si ça marche, pas une cible explicite)

---

## Questions Ouvertes

| # | Question | Impact | Deadline |
|---|---|---|---|
| Q-001 | ~~Revenue share intégrateur sur templates Marketplace~~ **Décidé : 60% Scalario / 40% intégrateur sur MRR. Commission marketplace : 20% Scalario.** | EPIC-012 | ✅ Résolu |
| Q-002 | Versionning catalogue : comment gérer les updates moteur sans casser les templates existants ? | EPIC-004 | Phase 2 |
| Q-003 | LLM local Ollama vs cloud Claude API : critères de basculement par client ? | FR-041 | Phase 3 |
| Q-004 | Certification intégrateur : processus, coût, durée ? | Canal intégrateur | M8 |
| Q-005 | Drift web (IndexedDB) : limites de stockage sur navigateur (5-10MB par défaut) — suffisant ? | FR-052 | Phase 1 |

---

## Parties Prenantes

| Rôle | Personne | Responsabilité |
|---|---|---|
| Product Owner / CEO | Carlos Simpore | Décisions produit et stratégie |
| Lead Developer | Carlos Simpore | Architecture et implémentation |
| Premier Client de Référence | Blandine | Validation cas retail (produits frais) |
| Intégrateurs futurs | TBD (M8-12) | Canal de distribution, templates sectoriels |

---

## Statut d'approbation

- [ ] Product Owner (Carlos Simpore)
- [ ] Architecture (à valider avec `/bmad:architecture`)

---

## Historique des révisions

| Version | Date | Auteur | Modifications |
|---|---|---|---|
| 1.0 | 2026-05-09 | Carlos Simpore | PRD initial — refondation BDUI Engine + Templates |
| 1.1 | 2026-05-09 | Carlos Simpore | Mise à jour stratégique — catégorie Instant Business OS, modèle intégrateur certifié (60/40), pricing Standard/Business, `retail_fresh_produce.json`, EPIC-012 promu Must Have M6-M9, hypothèses H1-H4, Q-001 résolu |

---

## Étapes suivantes

### Phase 3 : Architecture
Lancer `/bmad:architecture` pour concevoir l'architecture système qui répond à ces 59 FRs et 10 NFRs.

L'architecture couvrira :
- Schéma de données PostgreSQL (multi-tenant, pgvector, RLS)
- Structure monorepo (Flutter app + Flutter web admin + NestJS + FastAPI)
- Définition complète du JSON Schema BDUI (contrat TypeScript/Dart)
- Pipeline CI/CD GitHub Actions
- Infrastructure Docker Compose (5 services)
- Stratégie de migration Phase 1 → Phase 2 → Phase 3

### Phase 4 : Sprint Planning
Après architecture, lancer `/bmad:sprint-planning` pour :
- Décomposer les 7 epics Phase 1 en stories détaillées (35-48 stories)
- Estimer la complexité
- Planifier les sprints
- Commencer l'implémentation story par story avec `/bmad:dev-story`

---

## Annexe A — Matrice de Traçabilité

| Epic | Nom | Functional Requirements | Stories estimées | Phase |
|---|---|---|---|---|
| EPIC-001 | Design System Scalario | FR-005, FR-007 | 5-7 | 1 |
| EPIC-002 | BDUI Engine Flutter | FR-001, FR-001b, FR-002, FR-003, FR-004, FR-006, FR-050, FR-051 | 6-8 | 1 |
| EPIC-003 | Backend Foundation | FR-009, FR-010, FR-013, FR-015, FR-016, FR-017, FR-019 | 6-8 | 1 |
| EPIC-004 | Module Engine & Catalogue | FR-011, FR-012, FR-014, FR-020, FR-021, FR-053, FR-054, FR-055 | 5-7 | 1 |
| EPIC-005 | Workflow DAG Engine | FR-018, FR-028 | 4-5 | 1 |
| EPIC-006 | Offline-First & Sync | FR-008, FR-052, FR-056, FR-057, FR-058, FR-059 | 6-8 | 1 |
| EPIC-007 | Template Retail | FR-022, FR-023 | 3-5 | 1 |
| EPIC-008 | Config Conversationnelle IA | FR-024, FR-025, FR-026, FR-027, FR-028, FR-033, FR-035 | 8-10 | 2 |
| EPIC-009 | Admin Flutter Web & BDAPI | FR-029, FR-030 | 5-7 | 2 |
| EPIC-010 | Infrastructure Phase 2 | FR-031, FR-032, FR-034, FR-039 | 4-6 | 2 |
| EPIC-011 | Robustesse Phase 3 | FR-036, FR-037, FR-038, FR-040, FR-041 | 5-7 | 3 |
| EPIC-012 | Plateforme Intégrateur | FR-042, FR-043, FR-044 | 6-8 | H2-H3 |
| EPIC-013 | Templates Métier Post-MVP | FR-045, FR-046, FR-047, FR-048, FR-049 | 10-15 | H2-H3 |
| **Total** | | **59 FRs** | **79-101 stories** | |

**Phase 1 seule : 35-48 stories** (EPIC-001 à EPIC-007)

---

## Annexe B — Résumé des Priorités

| Catégorie | Must Have | Should Have | Could Have | Total |
|---|---|---|---|---|
| Functional Requirements | 30 | 15 | 14 | **59** |
| Non-Functional Requirements | 10 | 0 | 0 | **10** |

**Phase 1 (MVP) = 30 FRs Must Have + 10 NFRs = fondation complète.**

---

*Document créé avec BMAD Method v6 — Phase 2 (Planning)*
*Référence technique : `ERP_IA_Architecture_v6.pdf` — Avril 2026*
*Pour continuer : lancer `/bmad:architecture`*
