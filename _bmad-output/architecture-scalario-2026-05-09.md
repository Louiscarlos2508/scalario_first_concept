# Architecture Système : Scalario

**Date :** 2026-05-09
**Architecte :** Carlos Simpore
**Version :** 1.1
**Type de projet :** Instant Business OS — ERP IA UI-Driven, distribué par réseau d'intégrateurs certifiés
**Niveau :** 4 (plateforme complexe, multi-horizon)
**Statut :** Draft

**Documents de référence :**
- PRD : `_bmad-output/prd-scalario-2026-05-09.md`
- Directive technique : `ERP_IA_Architecture_v6.pdf` (Avril 2026)
- Brainstorm fondation : `_bmad-output/brainstorming/brainstorming-session-2026-05-08-21-41.md`

---

## Vue d'ensemble

Scalario est l'**Instant Business OS** — le premier système de gestion qu'une PME africaine peut avoir en production en 45 minutes, depuis une conversation, sur son téléphone, même sans connexion stable. Il génère automatiquement une interface ERP et des APIs métier depuis un fichier de configuration JSON — sans coder ni les écrans ni les endpoints.

L'architecture repose sur 3 niveaux immuables : un Design System fixe (code), un catalogue de templates sectoriels (JSON), et des configs client (JSON override). Elle supporte deux modèles d'utilisation : **direct** (Carlos onboarde manuellement Phase 1) et **intégrateur certifié** (Phase 2 — consultant local certifié qui configure, déploie et supporte les clients, 60/40 revenue split).

**Le principe directeur :** la puissance de Scalario ne vient pas d'une seule technologie mais de leur combinaison — BDUI + Config IA + RBAC/ABAC multi-couche + RAG hybride + Workflows DAG + sync offline CRDT. Chaque couche renforce les autres.

**Règle d'or absolue :** Jamais de logique métier dans Flutter. Jamais d'endpoint NestJS spécifique à un domaine. Tout ce qui est métier = fichier JSON dans le catalogue.

---

## Drivers Architecturaux

Les NFRs qui impactent le plus les décisions de conception :

**Driver 1 — NFR-007 : Zéro logique métier Flutter**
Impose l'architecture BDUI complète. ComponentRegistry, RuleEvaluator, LayoutResolver sont codés une fois. Toute condition = `visible_if` JSON. Contrainte non-négociable qui détermine comment Flutter et NestJS communiquent.

**Driver 2 — NFR-003 : Isolation multi-tenant 5 couches**
JWT → RBAC Guard → ABAC CASL → pgvector filter → PostgreSQL RLS. Aucun compromis. Le LLM ne reçoit jamais de données non filtrées. Détermine l'entièreté de la chaîne sécurité backend.

**Driver 3 — NFR-001/002 : Performance BDUI + API**
Rendu cold < 200ms (Drift local), hot < 50ms (mémoire). Layout Redis < 20ms. API p95 < 300ms. Impose un cache multi-couche obligatoire à chaque niveau.

**Driver 4 — NFR-005 : 99.5% uptime + offline-first**
L'app mobile fonctionne entièrement sans connexion. Drift/Isar est la première source de vérité — le backend est un service de synchronisation, pas une dépendance de démarrage.

**Driver 5 — NFR-006 : Multi-tenant scalable**
Shared schema Phase 1 (tenant_id + RLS), migration schema-per-tenant Phase 2 sans downtime. Provisioning nouveau tenant < 30 secondes. Architecture DB doit anticiper cette migration dès le schéma initial.

**Driver 6 — NFR-004 : Error boundaries BDUI**
Chaque composant Flutter est isolé dans un error boundary. JSON invalide → fallback UI localisé, jamais crash. Validation bidirectionnelle Zod/JSON Schema bloque les templates cassés avant le moteur.

**Driver 7 — NFR-010 : i18n + global scale dès le jour 1**
Zéro string hardcodée dans Flutter ou NestJS. Adapter pattern pour paiements (Wave) et compliance (OHADA). Configurable par tenant. Contrainte appliquée dès la première ligne de code.

**Driver 8 — NFR-009 : Qualité code solo dev**
CI/CD GitHub Actions strict, lint rule custom no-business-logic-in-flutter, coverage 90%+ moteur, 80%+ global. Architecture testable par construction — composants isolés, contrats partagés générés.

---

## Vue d'ensemble Système

### Pattern Architectural

**Pattern :** Modular Monolith NestJS + AI Microservice FastAPI + BDUI Client Flutter

**Rationale :** Pour un solo dev sur un projet Level 4, les microservices introduiraient une complexité opérationnelle prohibitive (service mesh, distributed tracing, coordination de déploiements). Le modular monolith NestJS donne des frontières claires entre modules (chaque module = domaine fonctionnel isolé) sans la surcharge opérationnelle. FastAPI est isolé uniquement parce que l'IA nécessite Python (LangChain, LlamaIndex, Instructor) — et il peut tomber sans impacter le backend principal (circuit breaker).

**Trade-off :** Scalabilité module par module impossible (tout NestJS scale ensemble). Acceptable Phase 1-2, migration vers microservices ciblée Phase 3+ si un module spécifique crée un bottleneck.

### Architecture Haute Niveau

```
┌─────────────────────────────────────────────────────────────┐
│           CLIENTS (Flutter — même codebase)                  │
│  ┌─────────────────────┐  ┌──────────────────────────────┐  │
│  │   App Mobile/Web    │  │       Admin Flutter Web      │  │
│  │  Android + iOS + Web│  │  Config chat + BDUI preview  │  │
│  │  BDUI Engine        │  │  Route /admin (OWNER/ADMIN)  │  │
│  │  Drift/Isar offline │  │  Même BDUIEngine + DS        │  │
│  └──────────┬──────────┘  └──────────────┬───────────────┘  │
└─────────────┼──────────────────────────┬─┘
              │  REST + WebSocket + SSE   │
              ▼                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    NestJS (Orchestrateur central)            │
│  ┌──────────┐ ┌────────────┐ ┌──────────────┐ ┌─────────┐  │
│  │   Auth   │ │ BDUIService│ │ ModuleEngine │ │Workflow │  │
│  │JWT+RBAC  │ │Layout→JSON │ │GET+POST genér│ │DAG+FSM  │  │
│  └──────────┘ └────────────┘ └──────────────┘ └─────────┘  │
│  ┌──────────┐ ┌────────────┐ ┌──────────────┐ ┌─────────┐  │
│  │ ABAC CASL│ │ Catalogue  │ │  SyncEngine  │ │AI Relay │  │
│  │Tenant RLS│ │Zod Validatr│ │Mutations+Idem│ │→FastAPI │  │
│  └──────────┘ └────────────┘ └──────────────┘ └─────────┘  │
└──────┬────────────────────────────────┬──────────┬──────────┘
       │                                │          │
       ▼                                ▼          ▼
┌─────────────┐    ┌──────────────────────────┐  ┌──────────┐
│   FastAPI   │    │  PostgreSQL + pgvector    │  │  MinIO   │
│ IA + RAG    │    │  RLS + Schema/tenant      │  │  (S3)    │
│ LlamaIndex  │    ├──────────────────────────┤  └──────────┘
│ Streaming   │    │         Redis            │
│ Mem0        │    │  Sessions + Config cache  │
│ Instructor  │    └──────────────────────────┘
└──────┬──────┘
       ▼
┌─────────────┐
│ Claude API  │
│   / Ollama  │
└─────────────┘
```

### Diagramme de flux principal

```
Client Flutter (offline-first)
  │
  ├─ Démarrage app
  │   ├─ Charge config depuis Drift local (< 200ms)
  │   ├─ Rendu BDUI immédiat depuis cache
  │   └─ Background sync avec NestJS si connecté
  │
  ├─ Action utilisateur (online)
  │   ├─ POST /api/v1/:tenant/:moduleId/action
  │   │   ├─ JWT Guard → tenant_id extrait
  │   │   ├─ RBAC Guard → rôle vérifié
  │   │   ├─ ABAC CASL → attributs vérifiés
  │   │   ├─ ModuleEngine résout la config JSON
  │   │   ├─ Business logic exécutée
  │   │   ├─ PostgreSQL RLS → sécurité finale
  │   │   └─ Audit log → insert-only
  │   └─ Réponse Flutter → update Drift local
  │
  └─ Action utilisateur (offline)
      ├─ Écrite dans Drift SyncQueue
      └─ Envoyée à NestJS à la reconnexion
```

---

## Stack Technologique

### Frontend — Flutter (Android + iOS + Web)

**Choix :** Flutter (Dart) — codebase unique pour Android 8+, iOS 14+, Web (Chrome/Safari/Firefox)

**Rationale :** Flutter est le seul framework qui produit un vrai codebase unique pour mobile + web avec des performances natives. React Native a trop de divergences platform. Flutter Web avec Drift (IndexedDB) couvre le besoin admin. Le BDUIEngine est identique sur toutes les plateformes — même JSON, même composants, même comportement.

**Trade-offs :**
- Gain : un seul codebase à maintenir, BDUIEngine cohérent partout, shadcn_ui Flutter unifie le Design System
- Perte : Flutter Web est moins mature que React/Next.js pour des interfaces admin complexes (scrolling, SEO). Acceptable car l'admin est une app interne, pas un site public.

**Packages clés :**
| Package | Rôle |
|---|---|
| `flutter_riverpod` | State management — Provider pattern, réactif, testable |
| `drift` | ORM offline SQLite (mobile) + IndexedDB (web) |
| `shadcn_ui` | Composants primitifs du Design System |
| `widgetbook` | Documentation vivante des composants BDUI |
| `json_schema_dart` | Validation JSON Schema côté Flutter |
| `flutter_localizations` + `intl` | i18n — 0 string hardcodée |
| `go_router` | Routing déclaratif + navigation protégée par rôle |
| `dio` | Client HTTP avec interceptors JWT |
| `web_socket_channel` | WebSocket pour notifications temps réel |
| `flutter_secure_storage` | Stockage JWT tokens chiffré |

### Backend Principal — NestJS

**Choix :** NestJS (TypeScript) — Framework Node.js opinionné, modules isolés, DI intégré

**Rationale :** NestJS impose une structure modulaire naturelle (chaque module = domaine isolé). TypeScript partage le même écosystème que le JSON Schema (Zod, quicktype). Passport.js + @nestjs/jwt intégrés. CASL natif Node. WebSocket Gateway inclus. Écosystème mature pour tout ce dont Scalario a besoin.

**Trade-offs :**
- Gain : architecture modulaire enforçable, TypeScript end-to-end, excellent écosystème ORM/Auth/Queue
- Perte : Node.js single-threaded peut être limité pour des calculs intensifs (compensé par FastAPI pour l'IA)

**Packages clés :**
| Package | Rôle |
|---|---|
| `@nestjs/passport` + `passport-jwt` | Auth JWT multi-tenant |
| `@nestjs/jwt` | JWT access + refresh tokens |
| `@casl/ability` + `@casl/nestjs` | ABAC Layer 3 |
| `typeorm` | ORM PostgreSQL + migrations |
| `pg` + `typeorm` | PostgreSQL avec support JSONB |
| `ioredis` | Client Redis pour cache + sessions |
| `zod` | Validation JSON Schema templates |
| `xstate` | State Machine workflows FSM |
| `bullmq` | Job queues async (sync mutations, notifications) |
| `@nestjs/websockets` | WebSocket Gateway temps réel |
| `@nestjs/swagger` | OpenAPI auto-générée |
| `@nestjs/config` | Configuration par environnement |

### Microservice IA — FastAPI (Python)

**Choix :** FastAPI (Python) — seul parce que LangChain, LlamaIndex, Instructor sont natifs Python

**Rationale :** L'écosystème IA Python est incontournable. FastAPI est le framework Python le plus performant pour des APIs async avec streaming SSE. Il est isolé du backend principal — NestJS le proxie, et un circuit breaker assure que sa panne ne dégrade pas le service principal.

**Trade-offs :**
- Gain : accès à tout l'écosystème IA Python, streaming SSE natif, isolé = scalable indépendamment
- Perte : deuxième langage à maintenir en tant que solo dev, latence réseau interne inter-services

**Packages clés :**
| Package | Rôle |
|---|---|
| `langchain` | Orchestration LLM + Config Agent |
| `llama-index` | RAG indexation + hybrid search |
| `instructor` | Structured outputs (NER) depuis LLM |
| `pydantic` | Validation schemas + structured extraction |
| `pgvector` (Python) | Client pgvector embeddings |
| `anthropic` | Claude API client |
| `mem0` | Mémoire long terme utilisateur |
| `docling` | Parsing PDF/Excel/Word → chunks |
| `sse-starlette` | Server-Sent Events streaming |

### Base de données — PostgreSQL + pgvector

**Choix :** PostgreSQL 16+ avec extension pgvector

**Rationale :** PostgreSQL est le seul SGBD qui combine JSONB natif (config tenant), Row-Level Security (isolation multi-tenant Layer 5), pgvector (RAG), et des performances OLTP pour les opérations ERP. Un seul service couvre tout — données métier + RAG vectoriel + audit log + sync queue.

**Trade-offs :**
- Gain : RLS native = sécurité multi-tenant au niveau DB, pgvector = RAG sans service séparé, JSONB = flexibilité entity store
- Perte : PostgreSQL n'est pas un vector DB spécialisé — pour 1000+ tenants avec des millions de vecteurs, Pinecone ou Weaviate seraient plus rapides. Acceptable Phase 1-2.

### Cache / Sessions — Redis

**Choix :** Redis 7+ (service Docker dédié)

**Rationale :** Redis gère 3 rôles distincts : blacklist refresh tokens révoqués, cache layouts BDUI par `{tenant_id}:{screen_id}:{role}` (TTL 5min), et rate limiting LLM par tenant (Phase 2). La séparation Redis/PostgreSQL est obligatoire pour ne pas mélanger données persistantes et éphémères.

### Storage fichiers — MinIO

**Choix :** MinIO (S3-compatible) — 1 service Docker

**Rationale :** Remplace Supabase Storage. S3-compatible = SDK standard, migration vers AWS S3 ou Cloudflare R2 en 1 ligne de config. Isolation par bucket `{tenant_id}/`. NestJS proxie toutes les opérations — les clients ne touchent jamais MinIO directement.

### LLM — Claude API / Ollama

**Choix :** Claude API (cloud) Phase 1-2, Ollama (local) Phase 3

**Rationale :** Claude API offre la qualité d'extraction NER nécessaire pour la config conversationnelle. Ollama est le fallback pour clients UEMOA sans connexion stable (zones rurales, sites miniers). L'interface `LLMProvider` abstraite dès Phase 1 permet le switch sans modifier la logique.

### Infrastructure — Docker Compose (5 services)

```yaml
# docker-compose.yml
services:
  nestjs:      # API principal — auth, BDUI, modules, workflows
  fastapi:     # Microservice IA — RAG, streaming, Config Agent
  postgresql:  # Données + pgvector + RLS + schema/tenant
  redis:       # Cache config, sessions, rate limiting LLM
  minio:       # Storage fichiers — PDFs, ordonnances, images

# docker-compose.dev.yml (en plus)
  adminer:     # Dashboard DB — remplace Supabase Studio
```

### Développement & Déploiement

| Outil | Rôle |
|---|---|
| GitHub Actions | CI/CD — lint + tests + build + validate-catalogue |
| Docker Compose | Environnement local + production VPS |
| Bun | Runtime Node.js alternatif (faster installs) ou npm |
| Dart pub | Packages Flutter |
| `flutter analyze` | 0 warning imposé en CI |
| ESLint + Prettier | 0 erreur NestJS en CI |
| `quicktype` | JSON Schema → TypeScript interfaces + Dart classes |
| pgAdmin / Adminer | Dev DB management |
| Langfuse | Observabilité LLM (Phase 3 — FR-039) |

---

## Composants Système

### Composant 1 : BDUIEngine (Flutter)

**Rôle :** Orchestrateur central du rendu Flutter. Transforme un JSON schema en widgets Flutter sans aucune logique métier.

**Responsabilités :**
- Parser le JSON schema depuis Drift local ou réponse NestJS
- Déléguer la visibilité des composants au RuleEvaluator
- Résoudre les sources de données
- Instancier les widgets via ComponentRegistry
- Appliquer le layout via LayoutResolver

**Pipeline d'exécution :**
```
JSON (Drift cache) 
  → parse + JSON Schema validation 
  → RuleEvaluator (visible_if)
  → DataSourceResolver (sources → données)
  → ComponentRegistry.build() × N composants
  → LayoutResolver.apply(layout, zones)
  → Widget tree Flutter (zéro if métier)
```

**Interfaces :**
- `BDUIEngine.render(ScreenConfig config, BuildContext ctx) → Widget`
- Entrée : JSON valide contre `screen-config.schema.json`
- Sortie : Widget Flutter avec error boundaries

**Dépendances :** ComponentRegistry, RuleEvaluator, LayoutResolver, Drift (cache local)

**FRs adressés :** FR-001, FR-002, FR-003, FR-004, FR-050, FR-051

---

### Composant 2 : ComponentRegistry (Flutter)

**Rôle :** Registre extensible qui mappe un type string → widget Flutter builder.

**Responsabilités :**
- Maintenir la map `type → ComponentBuilder`
- Résoudre un `ComponentConfig` en widget
- Retourner `UnknownComponent` (jamais crash) pour les types inconnus
- Isoler chaque composant dans un error boundary Flutter

**Interface clé :**
```dart
class ComponentRegistry {
  static final Map<String, ComponentBuilder> _builders = {
    'KPICard':     (config, ctx) => KPICard.fromConfig(config, ctx),
    'DataTable':   (config, ctx) => ERPDataTable.fromConfig(config, ctx),
    'AlertBanner': (config, ctx) => AlertBanner.fromConfig(config, ctx),
    'FAB':         (config, ctx) => ERPFAB.fromConfig(config, ctx),
    'ListTile':    (config, ctx) => ERPListTile.fromConfig(config, ctx),
    'FormSection': (config, ctx) => FormSection.fromConfig(config, ctx),
    'ChartBar':    (config, ctx) => ChartBar.fromConfig(config, ctx),
  };

  static Widget build(ComponentConfig config, BuildContext ctx) {
    final builder = _builders[config.type];
    if (builder == null) return UnknownComponent(config.type);
    return ErrorBoundary(child: builder(config, ctx));
  }
}
```

**Composants initiaux MVP :** KPICard, DataTable, AlertBanner, FAB, ListTile, FormSection, ChartBar

**FRs adressés :** FR-001, FR-050

---

### Composant 3 : RuleEvaluator (Flutter)

**Rôle :** Évaluation des règles `visible_if` déclarées en JSON. Zéro `if` métier dans Flutter.

**Responsabilités :**
- Évaluer les opérateurs AND, OR, role, >, <, ==
- Recevoir le contexte utilisateur (rôles, attributs) depuis le state management
- Retourner `true` si `visible_if == null` (composant toujours visible)
- Exécution < 1ms par composant

**Interface clé :**
```dart
class RuleEvaluator {
  final UserContext userCtx;
  
  bool evaluate(Rule? rule) {
    if (rule == null) return true;
    return switch (rule.operator) {
      'AND'  => rule.children!.every(evaluate),
      'OR'   => rule.children!.any(evaluate),
      'role' => userCtx.roles.contains(rule.value),
      '>'    => resolveField(rule.field!) > rule.value,
      '<'    => resolveField(rule.field!) < rule.value,
      '=='   => resolveField(rule.field!) == rule.value,
      _      => true,
    };
  }
}
```

**Exemple JSON :**
```json
{ "visible_if": { "AND": [
  { "role": ["MANAGER", "DG"] },
  { "field": "montant", "operator": ">", "value": 500000 }
]}}
```

**FRs adressés :** FR-002

---

### Composant 4 : LayoutResolver (Flutter)

**Rôle :** 4 layouts fixes codés une fois. L'IA/le JSON choisit lequel appliquer — elle ne crée jamais de nouveaux layouts.

**Responsabilités :**
- Mapper un layout string vers le widget Layout correspondant
- Adapter les zones selon le breakpoint (mobile/tablet/desktop)
- Fallback `DashboardLayout` pour layouts inconnus

**Layouts disponibles :**
| Layout | Mobile | Tablet | Desktop | Zones |
|---|---|---|---|---|
| `dashboard` | Stack vertical | Grid 2 cols | Grid 3 cols | kpis, main, actions |
| `list` | Liste plein écran | Liste + filtre aside | Liste + filtre + détail | main, filters, detail |
| `form` | Sections empilées | 2 colonnes | 2 colonnes + aside | sections, actions |
| `detail` | Scroll vertical | Tabs | Master/detail split | header, body, actions |

**FRs adressés :** FR-003

---

### Composant 5 : ModuleEngine (NestJS)

**Rôle :** Cœur du backend dynamique. 2 endpoints génériques couvrent 100% des modules de tous les tenants.

**Responsabilités :**
- Résoudre la config JSON du module depuis le catalogue
- Appliquer les filtres RBAC/ABAC sur les données
- Exécuter les actions CRUD + custom déclarées dans le JSON
- Garantir l'idempotence via `client_mutation_id`
- Logger chaque action dans l'Audit Log

**Endpoints :**
```
GET  /api/v1/:tenant/:moduleId/data
  → Charge la config module depuis catalogue
  → Applique RBAC/ABAC/RLS
  → Retourne données + KPIs + stats formatés

POST /api/v1/:tenant/:moduleId/action
  → Header obligatoire : X-Client-Mutation-Id: {uuid}
  → Vérifie idempotence (client_mutation_id en DB, TTL 24h)
  → Résout l'action depuis la config JSON
  → Exécute : create | update | delete | custom
  → Insert audit log
  → Retourne résultat
```

**FRs adressés :** FR-012, FR-059

---

### Composant 6 : BDUIService (NestJS)

**Rôle :** Servir le JSON layout au client Flutter filtré par rôle et contexte.

**Responsabilités :**
- Charger la config screen depuis PostgreSQL ou cache Redis
- Filtrer les composants non autorisés AVANT de retourner le JSON
- Invalider le cache Redis si la config tenant change
- Versionner les layouts avec `schema_version`

**Endpoint :**
```
GET /api/v1/:tenant/layout/:screenId
  Headers: Authorization: Bearer {jwt}
  
  → JWT Guard : extrait tenant_id + roles
  → Vérifie cache Redis : key "{tenant_id}:{screen_id}:{role}"
  → Cache HIT : retourne JSON en < 20ms
  → Cache MISS : 
      charge depuis PostgreSQL
      filtre visible_if pour rôle courant
      stocke dans Redis (TTL 5 min)
      retourne JSON
```

**FRs adressés :** FR-011

---

### Composant 7 : WorkflowEngine (NestJS + XState)

**Rôle :** Validation DAG et exécution des workflows déclarés en JSON.

**Responsabilités :**
- Valider la cohérence DAG (Kahn's algorithm — détection cycles, étapes inaccessibles)
- Générer une XState FSM depuis la définition JSON du workflow
- Valider les transitions d'états (transitions illégales impossibles)
- Exécuter les étapes ordonnées avec conditions évaluées

**Validation DAG (déploiement) :**
```typescript
function validateWorkflow(steps: WorkflowStep[]): ValidationResult {
  const graph = buildDAG(steps);
  if (hasCycle(graph)) throw new Error('Workflow circulaire détecté');
  const sorted = topologicalSort(graph); // Kahn's algorithm
  if (!checkAllStepsReachable(sorted, steps)) {
    throw new Error('Étapes inaccessibles détectées');
  }
  return { valid: true, sorted };
}
```

**États XState (exécution) :**
```typescript
// Généré automatiquement depuis la config JSON workflow
const orderFSM = createMachine({
  states: {
    brouillon:  { on: { SOUMETTRE: 'soumise' }},
    soumise:    { on: { VALIDER: 'validee', REJETER: 'rejetee' }},
    validee:    { on: { LIVRER: 'livree' }},
    livree:     { on: { FACTURER: 'facturee' }},
    facturee:   { type: 'final' },
    rejetee:    { type: 'final' },
  }
});
// Transition illégale (livree → brouillon) → erreur 409
```

**FRs adressés :** FR-018, FR-028

---

### Composant 8 : OfflineSyncEngine (Flutter + Drift)

**Rôle :** Gestion complète de la persistance locale et synchronisation avec le backend.

**Responsabilités :**
- Persister la config JSON tenant dans Drift (chiffrée)
- Enregistrer les mutations offline dans la SyncQueue Drift
- Rejouer les mutations dans l'ordre chronologique à la reconnexion
- Résoudre les conflits via la stratégie déclarée dans le JSON module
- Mettre à jour l'indicateur de statut sync dans l'UI

**Structure SyncQueue (Drift) :**
```dart
class SyncMutation {
  final String mutationId;       // UUID client
  final String moduleId;
  final String action;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  SyncStatus status;             // pending, sending, success, conflict, error
}
```

**Stratégies de résolution de conflits :**
| Stratégie | Comportement |
|---|---|
| `server_wins` (défaut) | Données serveur écrasent le local |
| `client_wins` | Données locales sont envoyées avec force |
| `manual` | Entrée dans conflict queue — interface de résolution |

**FRs adressés :** FR-008, FR-052, FR-056, FR-057, FR-058, FR-059

---

### Composant 9 : SecurityChain (NestJS)

**Rôle :** 5 couches de sécurité en cascade — chaque couche est indépendante.

**Chaîne de sécurité :**
```
Request
  Layer 1 → JwtAuthGuard : vérifie JWT, extrait tenant_id + user_id + roles
  Layer 2 → RbacGuard    : le rôle a-t-il accès à cette route ?
  Layer 3 → AbacGuard    : CASL — (User + Resource + Context) → Decision
  Layer 4 → pgvector     : RAG filtré dept/rôle (Phase 2)
  Layer 5 → PostgreSQL RLS : sécurité niveau DB (dernière ligne de défense)
  → Données retournées (filtrées avant d'atteindre le LLM)
```

**Règle critique IA :** Le LLM est un moteur de traitement, pas un garde de sécurité. Les données sont filtrées AVANT l'appel LLM — le modèle ne reçoit que les données autorisées.

**FRs adressés :** FR-009, FR-010, FR-015, FR-017

---

### Composant 10 : CatalogueService (NestJS)

**Rôle :** Gestion et validation du catalogue JSON — impossible de déployer un JSON invalide.

**Responsabilités :**
- Valider les fichiers JSON contre le Zod schema en CI et à l'API
- Charger et mettre en cache les templates depuis le catalogue
- Versionner les templates (semver)
- Exposer les erreurs de validation lisibles pour les intégrateurs non-développeurs

**Endpoint de validation :**
```
POST /api/v1/admin/templates/validate
  Body: { content: JSON, type: 'domain' | 'module' | 'fusion' }
  → Zod validation complète
  → Retourne : { valid: true } ou { valid: false, errors: [...] }
```

**FRs adressés :** FR-014, FR-020, FR-021, FR-053, FR-054

---

### Composant 11 : AIService (FastAPI — Phase 2)

**Rôle :** Microservice Python pour toutes les opérations IA. Isolé de NestJS.

**Responsabilités :**
- RAG hybride (vecteur + BM25 + reranking) filtré par tenant/rôle
- Config Agent conversationnel (extraction NER avec Instructor)
- Streaming SSE vers NestJS → WebSocket → Flutter
- Mémoire long terme Mem0 par utilisateur
- Ingestion documents Docling (Phase 3)

**Circuit breaker :** Si FastAPI est down, NestJS continue sans IA — les features IA retournent un état dégradé gracieux (pas d'erreur 500).

**FRs adressés :** FR-024, FR-025, FR-026, FR-027, FR-033, FR-035, FR-038

---

## Architecture des Données

### Modèle de données — Entités core

```
tenants (1) ─── users (N)
            ├── screen_configs (N)
            ├── entities (N) ─── workflow_states (1)
            ├── audit_logs (N)
            ├── sync_mutations (N)
            └── embeddings (N)

users (1) ─── refresh_tokens (N)
          └── sync_mutations (N)

entities (1) ─── workflow_states (1)
```

### Schéma PostgreSQL

```sql
-- ================================================================
-- TENANTS
-- ================================================================
CREATE TABLE tenants (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  slug         TEXT UNIQUE NOT NULL,
  config       JSONB NOT NULL DEFAULT '{}',  -- modules activés, rôles, i18n
  schema_name  TEXT,                          -- pour Phase 2 schema-per-tenant
  plan         TEXT NOT NULL DEFAULT 'standard',  -- 'standard' (40-60K FCFA/mois) | 'business' (150-200K FCFA/mois, multi-département)
  is_active    BOOLEAN NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tenants_slug ON tenants(slug);

-- ================================================================
-- USERS
-- ================================================================
CREATE TABLE users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email           TEXT NOT NULL,
  password_hash   TEXT NOT NULL,
  roles           TEXT[] NOT NULL DEFAULT '{}',
  department_id   UUID,
  metadata        JSONB NOT NULL DEFAULT '{}',  -- attributs ABAC
  is_active       BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, email)
);
CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_tenant_isolation ON users
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- ================================================================
-- REFRESH TOKENS
-- ================================================================
CREATE TABLE refresh_tokens (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tenant_id    UUID NOT NULL REFERENCES tenants(id),
  token_hash   TEXT NOT NULL UNIQUE,
  expires_at   TIMESTAMPTZ NOT NULL,
  revoked_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);

-- ================================================================
-- SCREEN CONFIGS (BDUI layouts par tenant)
-- ================================================================
CREATE TABLE screen_configs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id),
  screen_id       TEXT NOT NULL,
  role            TEXT NOT NULL DEFAULT '*',  -- '*' = tous les rôles
  config          JSONB NOT NULL,
  schema_version  TEXT NOT NULL DEFAULT '1.0.0',
  is_active       BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, screen_id, role)
);
CREATE INDEX idx_screen_configs_tenant_screen ON screen_configs(tenant_id, screen_id);

ALTER TABLE screen_configs ENABLE ROW LEVEL SECURITY;
CREATE POLICY screen_configs_tenant ON screen_configs
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- ================================================================
-- ENTITIES (stockage générique JSONB — cœur du ModuleEngine)
-- ================================================================
CREATE TABLE entities (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id),
  module_id       TEXT NOT NULL,      -- 'pos', 'stock', 'fournisseurs'
  entity_type     TEXT NOT NULL,      -- 'vente', 'produit', 'livraison'
  data            JSONB NOT NULL DEFAULT '{}',
  status          TEXT NOT NULL DEFAULT 'active',
  version         INTEGER NOT NULL DEFAULT 1,    -- optimistic locking
  vector_clock    JSONB,                          -- Phase 3 CRDT
  created_by      UUID REFERENCES users(id),
  updated_by      UUID REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes critiques pour performance ModuleEngine
CREATE INDEX idx_entities_tenant_module   ON entities(tenant_id, module_id);
CREATE INDEX idx_entities_tenant_type     ON entities(tenant_id, entity_type);
CREATE INDEX idx_entities_status          ON entities(tenant_id, status);
CREATE INDEX idx_entities_data_gin        ON entities USING gin(data);
CREATE INDEX idx_entities_created_at      ON entities(tenant_id, created_at DESC);

ALTER TABLE entities ENABLE ROW LEVEL SECURITY;
CREATE POLICY entities_tenant ON entities
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- ================================================================
-- WORKFLOW STATES
-- ================================================================
CREATE TABLE workflow_states (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL REFERENCES tenants(id),
  entity_id     UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
  workflow_id   TEXT NOT NULL,
  current_state TEXT NOT NULL,
  history       JSONB[] NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(entity_id, workflow_id)
);
CREATE INDEX idx_workflow_states_entity ON workflow_states(entity_id);

ALTER TABLE workflow_states ENABLE ROW LEVEL SECURITY;
CREATE POLICY workflow_states_tenant ON workflow_states
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- ================================================================
-- AUDIT LOG (insert-only — immuable)
-- ================================================================
CREATE TABLE audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL,
  user_id       UUID NOT NULL,
  action        TEXT NOT NULL,
  module_id     TEXT,
  entity_id     UUID,
  payload_hash  TEXT,               -- hash SHA-256 du payload (pas les données)
  metadata      JSONB NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
  -- Pas de updated_at = insert-only enforçable
);
CREATE INDEX idx_audit_logs_tenant_time ON audit_logs(tenant_id, created_at DESC);
CREATE INDEX idx_audit_logs_user       ON audit_logs(tenant_id, user_id);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_logs_tenant ON audit_logs
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- ================================================================
-- SYNC MUTATIONS (idempotence + conflict resolution)
-- ================================================================
CREATE TABLE sync_mutations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_mutation_id  UUID NOT NULL UNIQUE,    -- clé d'idempotence
  tenant_id           UUID NOT NULL REFERENCES tenants(id),
  user_id             UUID NOT NULL REFERENCES users(id),
  module_id           TEXT NOT NULL,
  action              TEXT NOT NULL,
  payload             JSONB NOT NULL DEFAULT '{}',
  result              JSONB,
  status              TEXT NOT NULL DEFAULT 'pending',  -- pending|success|conflict|error
  conflict_data       JSONB,                            -- données serveur vs client
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at        TIMESTAMPTZ
);
CREATE INDEX idx_sync_mutations_client_id ON sync_mutations(client_mutation_id);
CREATE INDEX idx_sync_mutations_tenant_status ON sync_mutations(tenant_id, status);

-- TTL automatique via pg_cron (24h)
-- DELETE FROM sync_mutations WHERE created_at < now() - interval '24 hours' AND status = 'success';

-- ================================================================
-- EMBEDDINGS (pgvector — RAG Phase 2)
-- ================================================================
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE embeddings (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id),
  entity_id   UUID,
  content     TEXT NOT NULL,
  embedding   vector(1536),         -- dimensions Claude/OpenAI embeddings
  metadata    JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_embeddings_tenant ON embeddings(tenant_id);
CREATE INDEX idx_embeddings_ivfflat ON embeddings USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);  -- IVFFlat pour perfo sur grands datasets

ALTER TABLE embeddings ENABLE ROW LEVEL SECURITY;
CREATE POLICY embeddings_tenant ON embeddings
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);
```

### Design de base de données — Notes clés

**Stockage JSONB pour les entités métier (choix délibéré) :**
Le ModuleEngine ne connaît aucun domaine. La table `entities` stocke toutes les données métier en JSONB — ventes, produits, commandes, patients, chantiers. Le GIN index sur `data` permet des requêtes JSONB efficaces. Ce choix sacrifie la typage statique des données pour la flexibilité absolue du catalogue. En Phase 3, si un module spécifique crée des bottlenecks, une table dédiée peut être ajoutée sans modifier le reste.

**Injection tenant_id via middleware NestJS :**
```typescript
// Dans chaque requête après JWT Guard
await dataSource.query(
  `SET app.current_tenant_id = '${tenantId}'`
);
// Toutes les tables avec RLS filtrent automatiquement
```

**Migration schema-per-tenant (Phase 2) :**
Script de migration sans downtime : créer le schéma dédié → copier les données → activer le nouveau schéma → supprimer les données de shared schema. La RLS reste active comme double protection même en schema-per-tenant.

### Flux de données

**Flux lecture (online) :**
```
Flutter GET /layout/:screenId
  → NestJS BDUIService
  → Redis cache HIT → JSON (< 20ms)
  → Redis cache MISS → PostgreSQL screen_configs
  → filtrage visible_if par rôle
  → Redis cache SET (TTL 5min)
  → JSON filtré → Flutter BDUIEngine
```

**Flux écriture (offline → sync) :**
```
Flutter offline action
  → SyncMutation écrite dans Drift (persist)
  → Connexion rétablie
  → BullMQ job : POST /sync/mutations
  → NestJS SyncEngine : check client_mutation_id
  → Si nouveau : execute action + audit log
  → Si doublon : retourne résultat original (idempotence)
  → Si conflit : stratégie JSON module (server_wins par défaut)
  → Drift sync_queue → status updated
```

---

## Design API

### Architecture API

**Style :** REST avec versioning `/api/v1/`
**Format :** JSON (Content-Type: application/json)
**Auth :** JWT Bearer token (Access: 15min, Refresh: 7 jours avec rotation)
**Versioning :** Path prefix `/api/v1/` — nouvelle version = `/api/v2/` en parallèle
**OpenAPI :** Auto-générée depuis les décorateurs NestJS (Swagger)

### Contrat JSON BDUI — Schema partagé TypeScript/Dart

```typescript
// packages/shared-contracts/src/types.ts
// GÉNÉRÉ par quicktype depuis catalog/schemas/*.json

export interface ComponentConfig {
  type: string;
  id?: string;
  props: Record<string, unknown>;
  visible_if?: Rule | null;
  source?: DataSource;
  validation?: ValidationRule[];
  i18n_key?: string;
}

export interface Rule {
  operator: 'AND' | 'OR' | 'role' | '>' | '<' | '==';
  children?: Rule[];
  field?: string;
  value?: unknown;
}

export interface ScreenConfig {
  screen: string;
  schema_version: string;
  layout: 'dashboard' | 'list' | 'form' | 'detail';
  title?: string;
  i18n_key?: string;
  zones: {
    kpis?: ComponentConfig[];
    main?: ComponentConfig[];
    aside?: ComponentConfig[];
    actions?: ComponentConfig[];
  };
}

export interface WorkflowStep {
  id: string;
  type: 'action' | 'condition' | 'notification' | 'approval';
  next: string | ConditionalNext;
  action?: string;
  params?: Record<string, unknown>;
  visible_if?: Rule;
}

export interface ModuleConfig {
  id: string;
  schema_version: string;
  name: string;
  i18n_key: string;
  icon: string;
  entities: EntityDefinition[];
  screens: ScreenConfig[];
  workflows?: WorkflowDefinition[];
  rbac_roles?: RBACRole[];
  conflict_strategy?: 'server_wins' | 'client_wins' | 'manual';
  abac_rules?: ABACRule[];
}
```

### Endpoints — Liste complète

#### Auth
```
POST /api/v1/auth/login
  Body: { email, password, tenant_slug }
  Returns: { access_token, refresh_token, user: { id, roles, tenant_id } }

POST /api/v1/auth/refresh
  Body: { refresh_token }
  Returns: { access_token, refresh_token }

POST /api/v1/auth/logout
  Headers: Authorization: Bearer {token}
  Body: { refresh_token }
  Action: blacklist refresh_token dans Redis

POST /api/v1/auth/users (admin seulement)
  Headers: Authorization: Bearer {admin_token}
  Body: { email, password, roles[], department_id }
  Returns: { user }
```

#### BDUI — Layouts
```
GET /api/v1/:tenant/layout/:screenId
  Headers: Authorization: Bearer {token}
  Returns: ScreenConfig (JSON filtré par rôle)

GET /api/v1/:tenant/layout/:screenId/bulk?screens=screen1,screen2
  Returns: { screen1: ScreenConfig, screen2: ScreenConfig }
  (premier chargement app — récupère tous les layouts en 1 appel)
```

#### ModuleEngine — Endpoints génériques
```
GET /api/v1/:tenant/:moduleId/data
  Query: ?page=1&limit=50&filters={}&sort=created_at:desc
  Headers: Authorization: Bearer {token}
  Returns: { items: Entity[], total, kpis?: KPIData, meta }

POST /api/v1/:tenant/:moduleId/action
  Headers:
    Authorization: Bearer {token}
    X-Client-Mutation-Id: {uuid}  (obligatoire — idempotence)
  Body: { action: string, payload: Record<string, unknown> }
  Returns: { entity?, result, mutation_id }

GET /api/v1/:tenant/:moduleId/entities/:id
  Returns: Entity complet + workflow_state

DELETE /api/v1/:tenant/:moduleId/entities/:id
  (soft delete — status = 'deleted')
```

#### Tenants
```
POST /api/v1/tenants (ADMIN Scalario seulement)
  Body: { name, slug, plan, initial_config_template? }
  Returns: { tenant, provisioning_time_ms }

GET /api/v1/tenants/:tenantId (OWNER/ADMIN)
  Returns: tenant + config

PATCH /api/v1/tenants/:tenantId/config (OWNER/ADMIN)
  Body: { config: TenantConfig }
  Action: invalide Redis cache layouts du tenant

GET /api/v1/tenants/:tenantId/modules (OWNER/ADMIN)
  Returns: modules actifs + stats utilisation
```

#### Catalogue & Validation
```
POST /api/v1/admin/templates/validate
  Body: { content: JSON, type: 'domain' | 'module' | 'fusion' | 'screen' }
  Returns: { valid: boolean, errors?: ZodError[] }

GET /api/v1/admin/catalogue/domains
  Returns: liste des templates domaines disponibles

GET /api/v1/admin/catalogue/domains/:domainId
  Returns: template complet
```

#### Sync & Offline
```
POST /api/v1/:tenant/sync/mutations
  Body: { mutations: SyncMutation[] }  (envoi batch)
  Returns: { results: SyncResult[] }  (succès/conflit/erreur par mutation)

GET /api/v1/:tenant/sync/conflicts
  Headers: Authorization: Bearer {token}
  Returns: { conflicts: ConflictEntry[] }

POST /api/v1/:tenant/sync/conflicts/:id/resolve
  Body: { resolution: 'client' | 'server', data?: Entity }
  Returns: { resolved: Entity }
```

#### Workflows
```
POST /api/v1/:tenant/:moduleId/entities/:id/workflow/transition
  Body: { event: string, params?: Record<string, unknown> }
  Returns: { current_state, history }

GET /api/v1/:tenant/:moduleId/entities/:id/workflow
  Returns: { current_state, available_transitions, history }
```

#### IA (proxied NestJS → FastAPI, Phase 2)
```
POST /api/v1/:tenant/ai/chat (SSE streaming)
  Body: { message: string, session_id?: string }
  Returns: SSE stream → final: { config_json? }

POST /api/v1/:tenant/ai/search
  Body: { query: string, module_id?: string }
  Returns: { results: RAGResult[], sources }

POST /api/v1/:tenant/ai/import
  Body: FormData { file: xlsx|csv, module_hint? }
  Returns: { config_preview, entities_count }
```

### Authentication & Authorization

**JWT Claims obligatoires :**
```json
{
  "sub": "user-uuid",
  "tenant_id": "tenant-uuid",
  "roles": ["MANAGER"],
  "department_id": "dept-uuid",
  "iat": 1715000000,
  "exp": 1715000900
}
```

**Token d'un tenant A invalide sur les routes du tenant B** — le middleware JWT Guard extrait le `tenant_id` du token et le compare au paramètre `:tenant` de la route. Mismatch = 403.

**Refresh token rotation :** Chaque refresh génère un nouveau couple access + refresh. L'ancien refresh est blacklisté dans Redis avec TTL.

---

## Couverture NFRs

### NFR-001 : Performance — Rendu BDUI

**Requirement :** Screen complet depuis cache Drift < 200ms (cold), < 50ms (hot). Navigation < 100ms.

**Solution architecturale :**
- **Cold (Drift local) :** JSON chargé depuis SQLite local → BDUIEngine pipeline → widget tree. Pas d'appel réseau. SQLite mid-range Android < 50ms, BDUIEngine < 100ms = total < 200ms.
- **Hot (mémoire) :** Riverpod garde le dernier ScreenConfig en mémoire → pas de re-parse → widget rebuild uniquement. < 50ms.
- **Navigation :** `go_router` avec transitions Hero/Slide pré-configurées. Layout déjà en cache mémoire → instantané.
- **RuleEvaluator :** Évaluation < 1ms par composant enforçée par benchmark en CI.

**Validation :** Benchmark automatisé en CI sur émulateur Snapdragon 680. Alert si cold > 200ms.

---

### NFR-002 : Performance — API Backend

**Requirement :** GET p95 < 300ms, POST p95 < 400ms, Layout Redis < 20ms.

**Solution architecturale :**
- **Redis cache :** Layout BDUI servi depuis Redis après premier chargement. Clé `{tenant_id}:{screen_id}:{role}` TTL 5min.
- **Indexes DB :** `idx_entities_tenant_module`, `idx_entities_data_gin` (GIN JSONB) sur toutes les requêtes ModuleEngine fréquentes.
- **Connection pooling :** TypeORM pool (min: 5, max: 20) par service NestJS.
- **BullMQ :** Jobs async pour opérations longues (sync, notifications) — NestJS ne bloque jamais sur un job lourd.
- **Opérations IA :** SSE streaming — jamais de timeout > 2s sans token partiel.

**Validation :** Tests de charge avec k6 (1000 RPS, 50 utilisateurs simultanés par tenant). Dashboard Grafana sur VPS.

---

### NFR-003 : Sécurité — Isolation Multi-tenant

**Requirement :** 5 couches sécurité. LLM ne reçoit que des données filtrées. Token tenant A invalide sur tenant B.

**Solution architecturale (5 couches) :**

| Couche | Technologie | Ce qu'elle bloque |
|---|---|---|
| 1. JWT Guard | NestJS + Passport | Requêtes non-authentifiées |
| 2. RBAC Guard | @nestjs/common + rôles JSON | Routes non autorisées pour ce rôle |
| 3. ABAC CASL | @casl/nestjs | Ressources non autorisées pour ces attributs |
| 4. pgvector filter | LlamaIndex filter | Embeddings d'autres tenants dans le RAG |
| 5. PostgreSQL RLS | `SET app.current_tenant_id` | Données d'autres tenants au niveau DB |

**LLM security :** `FastAPI RAG → pgvector filter(tenant_id) → top_k résultats → LLM`. Le LLM ne voit que les chunks autorisés.

**Test d'intrusion :** Suite de tests automatisés en CI — token tenant A + route tenant B → 403. Requête SQL avec `tenant_id` forgé → RLS bloque.

**Validation :** Tests d'intrusion automatisés (script pytest) exécutés à chaque PR.

---

### NFR-004 : Robustesse — Tolérance aux erreurs BDUI

**Requirement :** JSON invalide jamais crash. Composant inconnu → UnknownComponent. Coverage moteur ≥ 90%.

**Solution architecturale :**
- **Error boundaries Flutter :** Chaque `ComponentRegistry.build()` est wrappé dans un `ErrorBoundary` widget. Exception isolée → fallback UI localisé.
- **Validation bidirectionnelle :** NestJS Zod valide avant stockage DB. Flutter JSON Schema valide avant parsing BDUIEngine.
- **UnknownComponent :** `ComponentRegistry` retourne `UnknownComponent(type)` (jamais null, jamais exception) pour tout type non enregistré.
- **Source de données manquante :** DataSourceResolver retourne un état `DataError` — le composant affiche son état erreur, les autres composants du screen continuent.
- **Coverage enforçé :** `flutter test --coverage` en CI, seuil 90% sur `lib/engine/`.

---

### NFR-005 : Disponibilité

**Requirement :** 99.5% uptime mensuel. Offline continue pendant panne backend.

**Solution architecturale :**
- **Docker restart policies :** `restart: unless-stopped` sur tous les services. Health checks NestJS + PostgreSQL avec seuils d'alerte.
- **Offline-first :** App Flutter charge depuis Drift local au démarrage. Panne NestJS → indicateur "Hors ligne" discret + app entièrement fonctionnelle.
- **PostgreSQL backup :** pg_dump quotidien automatisé via cron Docker → stocké dans MinIO `/backups/`.
- **Redis failure :** NestJS MISS cache → fallback PostgreSQL direct. Redis down ≠ service down.

**RTO/RPO :** RTO < 30min (redémarrage Docker), RPO < 24h (backup quotidien).

---

### NFR-006 : Scalabilité — Multi-tenant

**Requirement :** Phase 1 : 100 tenants actifs. Phase 2 : 1000+ tenants, migration schema-per-tenant sans downtime.

**Solution architecturale :**

**Phase 1 — Shared Schema + RLS :**
- `tenant_id` sur toutes les tables + RLS active. Simple, maintenable.
- 100 tenants × 50 utilisateurs = 5000 utilisateurs simultanés max → testable sur VPS 4 cores / 8GB.
- Provisioning < 30s : insert `tenants`, load template JSON, init RLS context.

**Phase 2 — Schema-per-tenant (migration sans downtime) :**
```sql
-- Étapes migration Phase 2
1. CREATE SCHEMA tenant_{id};
2. CREATE TABLE tenant_{id}.entities ... (identique, sans tenant_id)
3. INSERT INTO tenant_{id}.entities SELECT * FROM public.entities WHERE tenant_id = {id};
4. UPDATE tenants SET schema_name = 'tenant_{id}' WHERE id = {id};
5. NestJS bascule : SET search_path = tenant_{id}
6. DELETE FROM public.entities WHERE tenant_id = {id};
```

**Validation :** Test de charge avec 100 tenants en parallèle avant Phase 1 release.

---

### NFR-007 : Maintenabilité — Zéro logique métier Flutter

**Requirement :** Aucun `if` métier dans Flutter. Tout dans le JSON. Enforçable automatiquement.

**Solution architecturale :**
- **Custom lint rule :** ESLint-like rule Dart via `custom_lint` — détecte les patterns `if (user.role == ...)` dans `lib/` (hors `lib/engine/`). Échec CI si violation.
- **Code review checklist :** Tout nouveau widget doit passer la checklist "pas de logique métier" dans le template PR.
- **Architecture enforcement :** BDUIEngine est la seule entrée pour le rendu — il est impossible d'instancier un KPICard directement avec une condition hardcodée.
- **Guide "comment ajouter un module" :** Documentation dans `catalog/README.md` — checklist sans toucher Flutter.

---

### NFR-008 : Compatibilité — Multi-plateforme

**Requirement :** Android 8+ (API 26), iOS 14+, Web (Chrome 90+, Safari 14+, Firefox 88+). PWA installable.

**Solution architecturale :**
- **Single codebase Flutter :** Breakpoints gérés par LayoutResolver (mobile < 600px, tablet 600-1024px, desktop > 1024px).
- **Drift cross-platform :** Drift mobile (SQLite) + Drift web (IndexedDB via `drift_web`). Même API, même schema, même requêtes.
- **PWA :** `flutter build web --pwa-strategy=offline-first`. Service Worker configuré pour cache des assets Flutter.
- **shadcn_ui :** Composants Flutter compatibles toutes plateformes (pas de platform-specific widgets dans le Design System).

**Validation :** Tests automatisés sur émulateurs Android API 26, iOS 14 Simulator, et Chrome headless en CI.

---

### NFR-009 : Qualité du Code

**Requirement :** `flutter analyze` 0 warning, ESLint 0 erreur, coverage ≥ 80% global / ≥ 90% moteur, CI/CD sur chaque PR.

**Solution architecturale :**
- **CI GitHub Actions** *(voir section CI/CD)*
- **Testing pyramid** *(voir section Testing Strategy)*
- **OpenAPI :** Auto-générée depuis `@ApiOperation()`, `@ApiResponse()` NestJS → importable dans n'importe quel client.

---

### NFR-010 : i18n & Scale Global

**Requirement :** 0 string hardcodée. Multi-devises natif. Compliance et payment adapters pluggables.

**Solution architecturale :**
- **Flutter :** `flutter_localizations` + `intl`. Toutes les strings dans `lib/l10n/app_*.arb`. Custom lint rule detect hardcoded strings.
- **NestJS :** Codes d'erreur uniquement (ex: `ERR_UNAUTHORIZED`, pas "Accès refusé"). i18n des messages = responsabilité du client Flutter.
- **Multi-devises :** Format monétaire dans `tenant.config.currency = 'XOF' | 'USD' | 'EUR' | ...`. Formatage via `intl.NumberFormat.currency`.
- **Payment adapter :**
  ```typescript
  interface PaymentAdapter {
    initiate(amount: number, currency: string, meta: PaymentMeta): Promise<PaymentSession>;
    verify(sessionId: string): Promise<PaymentResult>;
  }
  class WaveAdapter implements PaymentAdapter { ... }
  class OrangeMoneyAdapter implements PaymentAdapter { ... }
  ```
- **Compliance :** `OHADAPlugin implements CompliancePlugin`. Injecté comme module NestJS optionnel. Core ne dépend jamais de OHADA.

---

## Architecture Sécurité

### Authentication — JWT Multi-tenant

```
Login Request
  → Passport LocalStrategy : vérifie email + password + tenant_slug
  → Génère access_token (15min) avec claims: sub, tenant_id, roles[], department_id
  → Génère refresh_token (7 jours) : hash stocké en PostgreSQL
  → Refresh token envoyé en HttpOnly cookie OU header selon le client
  
Refresh Flow
  → Vérifie refresh_token non-révoqué dans PostgreSQL
  → Génère nouveau access_token + nouveau refresh_token (rotation)
  → Blacklist l'ancien refresh_token (hash dans PostgreSQL)
  
Logout
  → Insert refresh_token_hash dans Redis blacklist (TTL = durée restante)
  → Optional : insert dans PostgreSQL revoked_at pour audit
```

**OAuth2 préparé (Phase 2) :** `passport-google-oauth20` ou `passport-azure-ad` peut être ajouté comme strategy sans modifier l'architecture JWT existante.

### Authorization — RBAC + ABAC

**Layer 2 — RBAC Guard (rôles) :**
```typescript
@UseGuards(JwtAuthGuard, RbacGuard)
@Roles('MANAGER', 'OWNER')
@Get(':moduleId/data')
```
Rôles chargés depuis `tenant.config.roles` — pas dans le code NestJS. Nouveau rôle = mise à jour JSON, zéro déploiement.

**Layer 3 — ABAC CASL (attributs) :**
```typescript
// Règle ABAC déclarée dans la config JSON tenant :
// "MANAGER peut voir les factures DE SON DEPT si montant < 500k XOF"
const ability = defineAbility((can) => {
  can('read', 'Invoice', {
    department_id: user.department_id,
    amount: { $lt: 500000 }
  });
});
ForbiddenError.from(ability).throwUnlessCan('read', invoice);
```

**Layer 5 — PostgreSQL RLS :**
```sql
-- Appliqué via middleware NestJS sur chaque requête
SET app.current_tenant_id = '{tenant_id}';
-- Toutes les tables avec RLS filtrent automatiquement
-- Même une requête SQL directe avec tenant_id forgé est bloquée
```

### Chiffrement des données

**En transit :** TLS 1.3 pour toutes les communications externes. HTTPS obligatoire (redirect HTTP → HTTPS au reverse proxy nginx).

**En repos :**
- PostgreSQL : chiffrement filesystem (Linux LUKS ou provider cloud) — pas de chiffrement au niveau colonne Phase 1 (overhead)
- Drift/Isar (mobile) : `flutter_secure_storage` pour les tokens JWT. Config JSON tenant chiffrée via `sqflite_sqlcipher` Phase 2.
- MinIO : server-side encryption configuré

**Secrets management :** Variables d'environnement Docker. Pas de secrets dans le code. Rotation régulière des JWT secrets via `docker secret` en production.

### Bonnes pratiques sécurité

- **Input validation :** Zod sur tous les endpoints NestJS. JSON Schema côté Flutter. Double validation.
- **SQL injection :** TypeORM parameterized queries uniquement. Jamais de template string SQL.
- **XSS :** Flutter Web n'évalue jamais de HTML arbitraire. Les données JSON sont des données, pas du markup.
- **CSRF :** Tokens JWT dans Authorization header (pas de cookies pour les API calls) → pas de CSRF possible.
- **Rate limiting :** `@nestjs/throttler` sur les endpoints auth (5 req/min). Rate limiting LLM par tenant via Redis (configurable).
- **Security headers :** Helmet.js dans NestJS (Content-Security-Policy, X-Frame-Options, etc.)
- **Audit trail :** Chaque action sensible loguée dans `audit_logs` (insert-only). Chaque appel LLM logué avec `query_hash`, `model`, `tokens_used`.

---

## Scalabilité & Performance

### Stratégie de scaling

**Phase 1 — VPS Single Node :**
- Docker Compose sur 1 VPS (4 cores, 8-16GB RAM)
- NestJS : 1 instance (Node.js cluster mode possible avec PM2 si nécessaire)
- PostgreSQL : 1 instance avec connection pooling (pgBouncer si > 100 connexions simultanées)
- Capacité estimée : 100 tenants, 50 utilisateurs simultanés par tenant

**Phase 2 — Scale horizontale ciblée :**
- NestJS peut scaler horizontalement (stateless, Redis pour sessions)
- FastAPI : pod Kubernetes séparé ou service Docker Swarm
- PostgreSQL : Read Replicas pour les requêtes GET lourdes
- Redis Cluster si > 10k connexions simultanées

**Auto-scaling triggers :** CPU > 70% pendant 5min → alert. RAM > 80% → alert. PostgreSQL connexions > 80% pool → alert.

### Optimisation Performance

**Cache multi-couche :**
```
Drift (local Flutter)
  ↓ miss
Redis (NestJS cache)
  ↓ miss
PostgreSQL (source de vérité)
```

**Query optimisation NestJS ModuleEngine :**
- Pagination obligatoire sur tous les `GET data` (défaut : 50, max : 200)
- GIN index sur `entities.data` pour les filtres JSONB fréquents
- Eager loading des workflow_states via JOIN (pas de N+1)
- TypeORM QueryBuilder pour les requêtes complexes (jamais de find avec des relations profondes)

**Lazy loading Flutter :**
- Les screens sont chargés à la demande (pas tout au démarrage)
- Les images sont lazy-loaded via `CachedNetworkImage`
- Les grandes listes utilisent `SliverList.builder` (jamais ListView.builder pour > 100 items)

### Stratégie de cache

| Donnée | Cache | TTL | Invalidation |
|---|---|---|---|
| Layout BDUI | Redis | 5 min | PATCH tenant config |
| Config tenant | Redis | 15 min | PATCH tenant config |
| Données module (liste) | Redis | 30 sec | POST action du module |
| JWT blacklist | Redis | TTL = durée restante token | Auto-expire |
| Rate limit LLM | Redis | 1 min | Auto-expire |
| Screens Flutter | Drift | Permanent | Sync config tenant |
| Données Flutter | Drift | Permanent | Sync mutations |

### Load Balancing

**Phase 1 :** Nginx comme reverse proxy devant NestJS (1 instance). Health check endpoint `GET /health` → 200 si service up.

**Phase 2 :** Nginx upstream avec plusieurs instances NestJS (round-robin). Sticky sessions via Redis si nécessaire (sessions WebSocket).

---

## Fiabilité & Disponibilité

### Haute disponibilité

**Phase 1 :**
- Docker `restart: unless-stopped` sur tous les services
- Health checks dans docker-compose :
  ```yaml
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
  ```
- Si NestJS redémarre : Flutter offline continue, reconnexion auto en background
- Si Redis redémarre : fallback PostgreSQL direct pour layouts (dégradation perfo temporaire)
- Si FastAPI redémarre : circuit breaker NestJS → features IA dégradées gracieusement

**Single points of failure acceptés Phase 1 :**
- PostgreSQL (1 instance) : downtime possible. Mitigé par backup + redémarrage rapide (< 5min).
- VPS lui-même : uptime VPS 99.9% → contribue à target 99.5% global.

### Disaster Recovery

**RPO (Recovery Point Objective) :** < 24h (backup quotidien)
**RTO (Recovery Time Objective) :** < 30min (Docker restart + restore)

**Procédure de restore :**
```bash
# 1. Arrêter les services
docker compose down

# 2. Restore PostgreSQL depuis MinIO backup
docker run --rm -v pgdata:/data minio-client \
  mc cp minio/backups/latest.sql.gz /data/
gunzip /data/latest.sql.gz
psql -f /data/latest.sql

# 3. Redémarrer
docker compose up -d

# 4. Vérifier health checks
docker compose ps
```

### Backup Strategy

**PostgreSQL :**
- pg_dump quotidien à 2h00 UTC via cron job Docker
- Format : SQL compressé gzip
- Destination : MinIO `/backups/pg/YYYY-MM-DD/`
- Rétention : 30 jours
- Test de restore : mensuel (script automatisé)

**MinIO :**
- Fichiers déjà persistés sur volume Docker
- Sauvegarde hebdomadaire vers stockage externe (rsync)

### Monitoring & Alerting

**Métriques à surveiller :**
| Métrique | Seuil Warning | Seuil Critical |
|---|---|---|
| NestJS response time p95 | > 300ms | > 500ms |
| PostgreSQL connexions actives | > 80% pool | > 95% pool |
| Redis mémoire utilisée | > 70% | > 90% |
| Disk usage | > 70% | > 85% |
| CPU NestJS | > 70% 5min | > 90% 5min |

**Logging :**
- NestJS : structured JSON logging (`@nestjs/common` Logger + `pino`)
- PostgreSQL : slow query log (> 100ms)
- FastAPI : structlog JSON
- Centralisation : Docker logs → fichiers + rotation (logrotate)

**Phase 3 :** Langfuse pour LLM observability (tokens, coûts, latences par tenant).

---

## Architecture d'Intégration

### Intégrations internes (NestJS ↔ FastAPI)

**Protocole :** HTTP + SSE (streaming)
```typescript
// NestJS → FastAPI (avec circuit breaker)
@Injectable()
class AIRelayService {
  async streamChat(tenantId: string, message: string): Observable<string> {
    return this.httpService.post(
      `${FASTAPI_URL}/chat`,
      { message, tenant_id: tenantId },
      { responseType: 'stream' }
    ).pipe(
      timeout(30000),
      catchError(() => of({ error: 'AI_SERVICE_UNAVAILABLE' }))
    );
  }
}
```

**NestJS ↔ Redis :**
- `ioredis` client avec reconnect automatique
- Pubsub pour invalidation cache cross-instance (Phase 2)

**NestJS ↔ MinIO :**
- `@aws-sdk/client-s3` (S3-compatible API)
- NestJS proxie TOUTES les opérations (clients ne touchent jamais MinIO directement)
- URLs présignées pour téléchargement direct (performance)

### Intégrations externes

**Claude API :**
```python
# FastAPI avec Instructor
import anthropic
import instructor

client = instructor.from_anthropic(anthropic.Anthropic())

class TenantConfig(BaseModel):
    entities: list[EntityDefinition]
    roles: list[RBACRole]
    workflows: list[WorkflowDefinition]

config = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=4096,
    messages=[{"role": "user", "content": conversation}],
    response_model=TenantConfig,
)
# Jamais de JSON cassé — Instructor retry automatique max 3
```

**Wave (paiement) :** Via `WaveAdapter implements PaymentAdapter`. API Wave → webhook NestJS → module_engine action.

**Ollama (Phase 3) :** `OllamaProvider implements LLMProvider` — switch transparent depuis `ClaudeAPIProvider`.

### Architecture messaging (BullMQ)

**Queues :**
```
sync-mutations    → Processing des mutations offline en batch
notifications     → WebSocket push pour alertes temps réel
ai-indexing       → Indexation embeddings en background (Phase 2)
export-jobs       → Génération de rapports/exports (Phase 2)
```

**Pattern :** Producer (NestJS service) → BullMQ Queue (Redis) → Consumer (NestJS worker). Jobs persistés → survient aux redémarrages.

---

## Architecture de Développement

### Structure Monorepo

```
scalario/
├── apps/
│   └── flutter/                    # Flutter app (mobile + admin web)
│       ├── lib/
│       │   ├── core/
│       │   │   ├── design_system/  # Design tokens, shadcn_ui overrides
│       │   │   └── theme/          # ThemeData Scalario
│       │   ├── engine/             # BDUIEngine, ComponentRegistry, RuleEvaluator, LayoutResolver
│       │   ├── components/         # KPICard, DataTable, AlertBanner, FAB, ListTile, FormSection, ChartBar
│       │   ├── offline/            # Drift schema, SyncQueue, ConflictResolver
│       │   ├── features/
│       │   │   ├── auth/           # Login, token management
│       │   │   ├── home/           # Navigation dynamique depuis JSON
│       │   │   └── admin/          # Routes /admin (OWNER/ADMIN seulement)
│       │   ├── l10n/               # ARB files (fr, en, ...)
│       │   ├── sandbox/            # Dev-only JSON renderer
│       │   └── main.dart
│       ├── assets/
│       │   └── sandbox/            # Sample JSONs pour dev
│       ├── widgetbook/             # Widgetbook app séparée
│       │   └── lib/
│       │       └── main.widgetbook.dart
│       ├── test/
│       │   ├── engine/             # Unit tests moteur (coverage ≥ 90%)
│       │   ├── components/         # Widget tests composants
│       │   └── integration/        # Integration tests E2E
│       └── pubspec.yaml
│
├── backend/
│   └── nestjs/                     # NestJS API principal
│       ├── src/
│       │   ├── auth/               # JWT, Passport, Guards
│       │   ├── bdui/               # BDUIService, ScreenConfig
│       │   ├── module-engine/      # ModuleEngine, actions, data
│       │   ├── workflow/           # WorkflowEngine, XState, DAG
│       │   ├── catalogue/          # Zod validation, template loading
│       │   ├── tenants/            # Multi-tenant provisioning
│       │   ├── security/           # RBAC, ABAC CASL, RLS middleware
│       │   ├── sync/               # SyncEngine, mutations, conflicts
│       │   ├── audit/              # AuditLog service (insert-only)
│       │   ├── storage/            # MinIO proxy (Phase 2)
│       │   ├── ai-relay/           # Proxy FastAPI + circuit breaker
│       │   ├── realtime/           # WebSocket Gateway, notifications
│       │   └── common/             # Interceptors, pipes, decorators
│       ├── test/
│       └── package.json
│
├── services/
│   └── fastapi/                    # AI microservice (Phase 2)
│       ├── app/
│       │   ├── rag/                # RAG hybride, embeddings
│       │   ├── config_agent/       # Conversational config
│       │   ├── ingestion/          # Docling, chunking
│       │   └── memory/             # Mem0
│       └── requirements.txt
│
├── catalog/                        # Le produit — catalogue JSON
│   ├── domains/
│   │   └── retail_fresh_produce.json             # Phase 1 MVP
│   ├── modules/                    # Modules réutilisables
│   ├── fusions/                    # Multi-domaine
│   └── schemas/                    # JSON Schema BDUI (source de vérité)
│       ├── component-config.schema.json
│       ├── screen-config.schema.json
│       ├── module-config.schema.json
│       └── workflow.schema.json
│
├── packages/
│   └── shared-contracts/           # Types auto-générés (quicktype)
│       ├── typescript/             # ComponentConfig, ScreenConfig...
│       └── dart/                   # ComponentConfig, ScreenConfig...
│
├── docker-compose.yml              # 5 services prod
├── docker-compose.dev.yml          # + adminer
├── .github/workflows/
│   ├── ci.yml                      # Lint + Tests + Build
│   └── validate-catalogue.yml      # Zod validation catalogue à chaque PR
└── scripts/
    ├── generate-types.sh           # JSON Schema → TS + Dart
    └── backup-db.sh                # Backup PostgreSQL → MinIO
```

### Module Structure NestJS

Chaque module NestJS suit la même structure :
```
src/module-engine/
├── module-engine.module.ts         # NestJS Module
├── module-engine.service.ts        # Business logic
├── module-engine.controller.ts     # Routes
├── module-engine.guard.ts          # Guards spécifiques si nécessaire
├── dto/
│   ├── get-data.dto.ts             # Zod-validated DTOs
│   └── execute-action.dto.ts
├── interfaces/
│   └── module-config.interface.ts  # Types internes
└── __tests__/
    ├── module-engine.service.spec.ts
    └── module-engine.controller.spec.ts
```

### Testing Strategy

**Pyramide de tests :**

```
         ┌──────────────┐
         │   E2E Tests  │  (5%) — Playwright ou Cypress (Flutter Web)
        ┌┴──────────────┴┐
        │Integration Tests│  (25%) — NestJS supertest, Flutter integration
       ┌┴────────────────┴┐
       │   Widget Tests   │  (20%) — Flutter widget tests
      ┌┴──────────────────┴┐
      │    Unit Tests       │  (50%) — Moteur Flutter + Services NestJS
      └────────────────────┘
```

**Cibles de coverage :**
| Zone | Target | Outil |
|---|---|---|
| BDUIEngine + ComponentRegistry + RuleEvaluator + LayoutResolver | ≥ 90% | `flutter test --coverage` |
| NestJS ModuleEngine + WorkflowEngine | ≥ 85% | Jest coverage |
| NestJS Auth + Security | ≥ 90% | Jest coverage |
| Global Flutter | ≥ 80% | `flutter test --coverage` |
| Global NestJS | ≥ 80% | Jest coverage |

**Widgetbook comme référence de non-régression visuelle :**
- Chaque composant BDUI documenté avec tous ses états
- Snapshot tests sur les WidgetbookUseCases (Goldens Flutter)
- Comparaison screenshot automatique en CI pour détecter les régressions visuelles

### Pipeline CI/CD

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  validate-catalogue:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npx tsx scripts/validate-catalogue.ts
        # Zod validation de tous les JSON dans catalog/
      - run: npm run generate-types
        # quicktype → TypeScript + Dart types

  flutter-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: 'stable' }
      - run: flutter pub get
      - run: flutter analyze --no-fatal-warnings  # 0 error, warnings tolérés
      - run: flutter test --coverage
      - run: lcov --summary coverage/lcov.info    # Échec si < 80%
      - run: flutter build web --no-tree-shake-icons  # Build check

  nestjs-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: pgvector/pgvector:pg16
        env: { POSTGRES_DB: scalario_test, POSTGRES_PASSWORD: test }
      redis:
        image: redis:7-alpine
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1
      - run: cd backend/nestjs && bun install
      - run: cd backend/nestjs && bun run lint    # ESLint 0 error
      - run: cd backend/nestjs && bun test --coverage  # Jest + coverage
      - run: cd backend/nestjs && bun build       # Build check

  security-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run test:intrusion  # Tests isolation multi-tenant
```

---

## Architecture de Déploiement

### Environnements

| Environnement | URL | Configuration | Usage |
|---|---|---|---|
| Development | localhost | docker-compose.dev.yml | Dev local |
| Staging | staging.scalario.io | docker-compose.yml | Test pré-prod |
| Production | app.scalario.io | docker-compose.yml | Clients réels |

**Parité environnements :** Les 3 environnements utilisent exactement le même docker-compose.yml (prod) ou + adminer (dev/staging). Configuration via variables d'environnement uniquement.

### Stratégie de déploiement

**Phase 1 — Rolling Deployment (VPS unique) :**
```bash
# Déploiement sans downtime (Phase 1)
docker compose pull               # Pull nouvelles images
docker compose up -d --no-deps nestjs  # Redémarre NestJS seul
# NestJS : downtime < 5sec (restart rapide)
# PostgreSQL, Redis, MinIO : jamais redémarrés sauf nécessité
```

**Phase 2 — Blue-Green Deployment :**
Quand 2 instances NestJS : deployer la v2 sur port alternatif → tests smoke → switcher nginx upstream → kill v1.

### Infrastructure as Code

```yaml
# docker-compose.yml (production)
version: "3.9"

services:
  nestjs:
    build: ./backend/nestjs
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - JWT_SECRET=${JWT_SECRET}
      - FASTAPI_URL=http://fastapi:8000
      - MINIO_ENDPOINT=minio
    ports:
      - "3000:3000"
    depends_on:
      postgresql:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  fastapi:
    build: ./services/fastapi
    restart: unless-stopped
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - REDIS_URL=${REDIS_URL}
    ports:
      - "8000:8000"
    depends_on:
      - postgresql
      - redis

  postgresql:
    image: pgvector/pgvector:pg16
    restart: unless-stopped
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

  minio:
    image: minio/minio
    restart: unless-stopped
    command: server /data --console-address ":9001"
    volumes:
      - miniodata:/data
    environment:
      - MINIO_ROOT_USER=${MINIO_ROOT_USER}
      - MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}

volumes:
  pgdata:
  redisdata:
  miniodata:

# docker-compose.dev.yml (ajout développement)
services:
  adminer:
    image: adminer
    restart: unless-stopped
    ports:
      - "8080:8080"
```

---

## Traçabilité des Exigences

### Couverture Functional Requirements

| FR | Nom | Composants | Phase |
|---|---|---|---|
| FR-001 | ComponentRegistry | ComponentRegistry (Flutter) | 1 |
| FR-001b | Multi-plateforme Flutter | BDUIEngine + LayoutResolver | 1 |
| FR-002 | RuleEvaluator | RuleEvaluator (Flutter) | 1 |
| FR-003 | LayoutResolver | LayoutResolver (Flutter) | 1 |
| FR-004 | BDUIEngine | BDUIEngine (Flutter) | 1 |
| FR-005 | Design Tokens Flutter | Design System (Flutter) | 1 |
| FR-006 | Sandbox JSON | Sandbox (Flutter dev) | 1 |
| FR-007 | Widgetbook | Widgetbook (Flutter) | 1 |
| FR-008 | Offline-first Mobile | OfflineSyncEngine + Drift | 1 |
| FR-009 | Auth JWT Multi-tenant | SecurityChain (NestJS) | 1 |
| FR-010 | RBAC Guards Dynamiques | SecurityChain + JSON config | 1 |
| FR-011 | BDUIService | BDUIService (NestJS) + Redis | 1 |
| FR-012 | ModuleEngine | ModuleEngine (NestJS) | 1 |
| FR-013 | Multi-tenant Basique | PostgreSQL tenant_id + RLS | 1 |
| FR-014 | Zod Validator | CatalogueService (NestJS) | 1 |
| FR-015 | PostgreSQL RLS | SecurityChain Layer 5 | 1 |
| FR-016 | Redis Sessions / Cache | Redis + NestJS CacheModule | 1 |
| FR-017 | ABAC Basique CASL | SecurityChain Layer 3 | 1 |
| FR-018 | Workflow DAG Engine | WorkflowEngine (NestJS+XState) | 1 |
| FR-019 | Audit Log | AuditService (NestJS) | 1 |
| FR-020 | JSON Schema BDUI | catalog/schemas/ + packages/shared-contracts | 1 |
| FR-021 | Structure Catalogue | catalog/ + CatalogueService | 1 |
| FR-022 | Template retail_fresh_produce.json | catalog/domains/retail_fresh_produce.json | 1 |
| FR-023 | Contraintes Global Scale | i18n Flutter + adapters NestJS | 1 |
| FR-024 | FastAPI Microservice IA | AIService (FastAPI) | 2 |
| FR-025 | RAG Hybride | AIService (FastAPI) + pgvector | 2 |
| FR-026 | Config Conversationnelle | AIService Config Agent | 2 |
| FR-027 | Extraction Structurée NER | Instructor + Pydantic | 2 |
| FR-028 | FSM Auto-généré | WorkflowEngine + XState | 2 |
| FR-029 | Admin Flutter Web | Flutter admin routes + BDUIEngine | 2 |
| FR-030 | BDAPI | ModuleEngine + OpenAPI auto | 2 |
| FR-031 | MinIO Storage | MinIO + NestJS StorageService | 2 |
| FR-032 | Schema-per-tenant | PostgreSQL migration scripts | 2 |
| FR-033 | Mem0 | AIService + Mem0 | 2 |
| FR-034 | Notifications WebSocket | NestJS WebSocket Gateway | 2 |
| FR-035 | AI Excel/CSV Import | AIService + Docling | 2 |
| FR-036 | CRDT Offline Avancé | OfflineSyncEngine + Vector Clocks | 3 |
| FR-037 | Rete Algorithm | SecurityChain ABAC layer | 3 |
| FR-038 | Docling | AIService (FastAPI) | 3 |
| FR-039 | Observabilité Langfuse | AIService + Langfuse | 3 |
| FR-040 | Fine-tuning Local | AIService + fine-tuned model | 3 |
| FR-041 | Ollama LLM Local | AIService + OllamaProvider | 3 |
| FR-042 | Template Builder | Admin Flutter Web + AIService | H2 |
| FR-043 | SDK Intégrateur | API publique + documentation | H2 |
| FR-044 | Marketplace Templates | CatalogueService + review system | H3 |
| FR-045 | Comptabilité OHADA | OHADAPlugin + JSON templates | H2 |
| FR-046 | Module RH | catalog/domains/rh.json | H2 |
| FR-047 | Module CRM | catalog/domains/crm.json | H3 |
| FR-048 | Module Production | catalog/domains/production.json | H3 |
| FR-049 | Canal B2B | Multi-tenant inter-communication | H3 |
| FR-050 | Error Boundaries BDUI | ComponentRegistry ErrorBoundary | 1 |
| FR-051 | Validation formulaires | RuleEvaluator + JSON validation rules | 1 |
| FR-052 | Offline Web | Drift Web (IndexedDB) | 1 |
| FR-053 | Validation JSON Bidirectionnelle | Zod (NestJS) + JSON Schema (Flutter) | 1 |
| FR-054 | Code-gen Contrat Partagé | quicktype + packages/shared-contracts | 1 |
| FR-055 | Tests Coverage Moteur | Jest + flutter test + coverage gates CI | 1 |
| FR-056 | Sync Queue Locale | OfflineSyncEngine + Drift | 1 |
| FR-057 | Conflict Resolution Phase 1 | OfflineSyncEngine + server_wins | 1 |
| FR-058 | Sync Status UI | SyncStatusWidget (Flutter BDUI) | 1 |
| FR-059 | Idempotence Endpoints | SyncEngine + client_mutation_id | 1 |

**Couverture Phase 1 MVP : 30 FRs Must Have + 10 NFRs → 100% couverts**

### Couverture Non-Functional Requirements

| NFR | Nom | Solution | Validation |
|---|---|---|---|
| NFR-001 | Performance BDUI | Drift cache + BDUIEngine pipeline optimisé | Benchmark CI Snapdragon 680 |
| NFR-002 | Performance API | Redis layouts + DB indexes + connection pooling | k6 load test 1000 RPS |
| NFR-003 | Sécurité multi-tenant | 5 couches : JWT+RBAC+ABAC+pgvector+RLS | Tests intrusion automatisés CI |
| NFR-004 | Error boundaries BDUI | Flutter ErrorBoundary + Zod + JSON Schema | Coverage 90%+ + tests erreurs |
| NFR-005 | Disponibilité 99.5% | Docker restart + offline-first + backup quotidien | Uptime monitoring |
| NFR-006 | Scalabilité multi-tenant | Shared schema + RLS Phase 1, schema-per-tenant Phase 2 | Test 100 tenants simultanés |
| NFR-007 | Zéro logique métier Flutter | Custom lint rule + BDUIEngine architecture | Lint rule echec CI si violation |
| NFR-008 | Multi-plateforme | Flutter single codebase + LayoutResolver breakpoints | Tests CI Android/iOS/Web |
| NFR-009 | Qualité code | CI strict + coverage gates + OpenAPI auto | GitHub Actions sur chaque PR |
| NFR-010 | i18n + global scale | flutter_localizations + adapters NestJS | Lint rule 0 string hardcodée |

---

## Trade-offs & Log de Décisions

### Décision 1 : Modular Monolith NestJS vs Microservices

**Choix :** Modular Monolith
**Gain :** Déploiement simple (1 container), pas de distributed tracing, pas de service mesh, maintenable par 1 dev
**Perte :** Scalabilité module par module impossible — tout NestJS scale ensemble
**Rationale :** Phase 1-2 avec < 1000 tenants, 1 dev. Les micro-services ajouteraient 10x la complexité opérationnelle pour un gain de scalabilité prématuré. La structure modulaire NestJS donne les mêmes frontières conceptuelles sans la surcharge.

---

### Décision 2 : JSONB générique pour entities vs tables typées

**Choix :** Table `entities` avec JSONB
**Gain :** ModuleEngine 100% générique, nouveaux modules sans migration DB, flexibilité absolue
**Perte :** Pas de typage statique des données métier, pas de foreign keys inter-entités, requêtes JSONB moins optimales que colonnes typées pour des rapports complexes
**Rationale :** La règle d'or "le backend ne connaît aucun domaine" impose ce choix. Le GIN index sur `data` compense pour les filtres fréquents. Si un module crée des bottlenecks (ex: module comptabilité avec millions d'écritures), une table dédiée peut coexister avec le ModuleEngine — migration ciblée Phase 3.

---

### Décision 3 : Admin en Flutter Web vs React + ShadCN Next.js

**Choix :** Flutter Web (per PRD FR-029)
**Note :** Le PDF de référence (Avril 2026) suggère React + ShadCN + Next.js pour l'admin. Le PRD (Mai 2026, plus récent) tranche pour Flutter Web.
**Gain :** Un seul codebase Flutter, même BDUIEngine dans l'admin (preview BDUI identique par construction), même Design System shadcn_ui Flutter
**Perte :** Flutter Web est moins mature que React pour des interfaces admin complexes (rich text, drag-and-drop avancé). Performance Web Flutter légèrement inférieure à React pour du contenu lourd.
**Rationale :** La prévisibilité du BDUIEngine identical sur mobile ET admin compense largement les limitations Web Flutter. Un solo dev maintient 1 stack au lieu de 2. À réévaluer si l'admin devient une interface publique externe.

---

### Décision 4 : Sync server-wins vs CRDT Phase 1

**Choix :** Server-wins avec conflict queue Phase 1
**Gain :** Simple à implémenter, comportement prévisible, utilisateurs habitués au "serveur a raison"
**Perte :** Perte de données client possible dans des scénarios de conflit légitimes (2 utilisateurs éditent le même produit offline)
**Rationale :** Pour le MVP retail (Blandine, usage mono-utilisateur ou coordination simple), les conflits seront rares. CRDT complet (Vector Clocks) est planifié Phase 3 (FR-036) une fois le core stable. La conflict queue expose les cas ambigus pour résolution manuelle — aucune perte silencieuse.

---

### Décision 5 : Shared schema Phase 1 vs schema-per-tenant dès le départ

**Choix :** Shared schema + RLS Phase 1
**Gain :** Simplicité de démarrage, migrations DB unifiées, provisioning < 30 sec
**Perte :** Performance cross-tenant sur des tables très volumineuses, isolation logique seulement (RLS vs isolation physique)
**Rationale :** Phase 1 = < 100 tenants, données limitées. RLS offre une isolation suffisante et est cryptographiquement imposée par PostgreSQL (Layer 5). La migration Phase 2 est documentée et anticipée dans le schéma (colonne `schema_name` dans tenants).

---

### Décision 6 : PostgreSQL + pgvector vs DB vectorielle dédiée (Pinecone, Weaviate)

**Choix :** PostgreSQL + pgvector
**Gain :** 1 service de moins à maintenir, ABAC filter et RLS natifs sur les embeddings, même DB pour données métier + vecteurs
**Perte :** pgvector moins performant que Pinecone/Weaviate pour > 1M vecteurs par tenant, index IVFFlat requiert calibration
**Rationale :** Phase 1-2 : < 100 tenants × quelques milliers d'embeddings = < 1M vecteurs total. pgvector + IVFFlat suffit. Migration vers Weaviate/Pinecone possible Phase 3 via interface `VectorSearchProvider`.

---

## Questions ouvertes & Risques

| # | Question / Risque | Impact | Mitigation | Deadline |
|---|---|---|---|---|
| R-001 | Flutter Web performance pour admin avec Preview BDUI temps réel — suffisant ? | EPIC-009 | Valider dès Phase 2 avec prototype | M4 |
| R-002 | Drift Web (IndexedDB) : limite 5-10MB par défaut sur navigateur | FR-052 | Utiliser IndexedDB quotas API + avertissement user si proche limite | Phase 1 |
| R-003 | pgvector performance avec > 100 tenants ayant chacun des milliers d'embeddings | Phase 2 RAG | Benchmark avant Phase 2 release, IVFFlat tuning | M4 |
| R-004 | Versionning catalogue : comment gérer upgrade moteur sans casser templates existants ? | EPIC-004 | Semver schema + compatibility matrix + migration guides | Phase 2 |
| R-005 | Bull/BullMQ job queue : comportement si Redis redémarre pendant processing ? | Sync reliability | Jobs persistés dans Redis AOF + retry policy | Phase 1 |
| Q-001 | ~~Revenue share intégrateur Marketplace~~ **✅ Résolu : 60% Scalario / 40% intégrateur sur MRR. Commission marketplace templates : 20% Scalario.** | EPIC-012 | Décidé 2026-05-09 | ✅ |
| Q-002 | LLM local Ollama vs cloud : critères de basculement par client ? | FR-041 | Documenter dans config tenant `llm_provider` | Phase 3 |

---

## Hypothèses & Contraintes

**Hypothèses :**
1. Intégrateur Phase 1 = Carlos — onboarding manuel, Config IA Phase 2
2. Clients Phase 1 ont une connexion mobile périodique (pas forcément stable) — offline-first non-optionnel
3. Flutter Web est suffisant pour l'Admin Phase 2 — validé Phase 1 par prototype
4. PostgreSQL schéma partagé suffit pour < 100 tenants Phase 1
5. Claude API (cloud) acceptable Phase 2 — Ollama upgrade Phase 3
6. VPS unique 4 cores / 8-16GB RAM suffit Phase 1

**Hypothèses critiques à valider (Gates — PRD v1.1) :**
- H1 (Gate 0 J+90) : Blandine utilise l'app quotidiennement et réfère ≥ 1 business
- H2 (Gate 1 M3) : Intégrateur externe autonome en 2 jours de formation
- H3 (Gate 1 M3) : `retail_fresh_produce.json` fonctionne pour 2ème client sans modification
- H4 (Gate 2 M6) : 40-60K FCFA/mois soutenable 12 mois sans relance

**Contraintes non-négociables :**
1. Aucune logique métier dans Flutter — enforçé par lint rule + architecture
2. Aucun endpoint NestJS spécifique à un domaine — enforçé par ModuleEngine générique
3. JSON invalide ne peut jamais être déployé — Zod validation en CI bloquant
4. LLM ne reçoit jamais de données non filtrées — architecture SecurityChain par construction
5. Tout nouveau module = nouveau JSON dans le catalogue, zéro déploiement backend

---

## Considérations futures

**Phase 3+ (Mois 7-9) :**
- CRDT Vector Clocks pour sync offline sans conflit (> 95% des cas automatiques)
- Rete Algorithm ABAC O(1) pour tenants avec > 100 règles ABAC
- Docling ingestion documents existants (migration données client)
- Ollama LLM local pour clients sans connexion stable
- Langfuse observabilité LLM + cost control par tenant

**Phase 2 Must Have (M6-M9 — ajout PRD v1.1) :**
- Canal intégrateur certifié : formation 2 jours, certification 75K FCFA, revenue split 60/40
- Dashboard intégrateur : ses clients, son MRR, ses commissions
- `pharmacie.json` — 2ème template sectoriel

**H2-H3 :**
- Template Builder no-code Flutter Web pour intégrateurs
- Marketplace templates avec review et versionning (20% commission Scalario)
- BDAPI ouvert aux apps tierces (ex: app livraison médicaments → pharmacies Scalario)
- B2B inter-tenants (Gate : 20+ clients même ville)
- Schema-per-tenant en production pour > 500 tenants

**À surveiller :**
- Evolution pgvector performance (nouvelles versions améliorent les index)
- Flutter Web maturité (chaque release améliore les perfs)
- Nouveaux modèles LLM légers pour Ollama local
- Émergence de frameworks CRDT Dart natifs

---

## Approbation & Signature

**Statut de review :**
- [ ] Lead Developer / Architecte (Carlos Simpore)
- [ ] Product Owner (Carlos Simpore)

---

## Historique des révisions

| Version | Date | Auteur | Modifications |
|---|---|---|---|
| 1.0 | 2026-05-09 | Carlos Simpore | Architecture initiale — BDUI Engine + Templates |
| 1.1 | 2026-05-09 | Carlos Simpore | Alignement PRD v1.1 — catégorie Instant Business OS, modèle intégrateur certifié (60/40), pricing Standard/Business dans tenant.plan, retail_fresh_produce.json, EPIC-012 Phase 2 Must Have, hypothèses H1-H4, Q-001 résolu |

---

## Prochaines étapes

### Phase 4 : Sprint Planning & Implémentation

Lancer `/bmad:sprint-planning` pour :
- Décomposer les 7 EPICs Phase 1 en stories détaillées (35-48 stories estimées)
- Estimer la complexité par story
- Planifier les sprints (recommandé : sprints de 2 semaines)
- Commencer l'implémentation story par story avec `/bmad:dev-story`

**Ordre de build recommandé (issu du PDF + dépendances PRD) :**
1. JSON Schema BDUI → contrat TypeScript/Dart généré (FR-020, FR-054)
2. Design System Flutter → shadcn_ui + tokens (FR-005)
3. Widgetbook + 5 composants de base → KPICard, DataTable, AlertBanner, ListTile, FAB (FR-007)
4. BDUIEngine → Registry + RuleEvaluator + LayoutResolver (FR-001 à FR-004)
5. Sandbox JSON → Preuve end-to-end BDUIEngine (FR-006)
6. Backend Foundation → Auth JWT + RBAC + RLS + Redis (FR-009 à FR-017, FR-019)
7. ModuleEngine + BDUIService → 2 endpoints génériques (FR-011, FR-012)
8. Offline & Sync → Drift + SyncQueue + Idempotence (FR-008, FR-052, FR-056 à FR-059)
9. Workflow DAG + XState → Validation + exécution (FR-018)
10. Template retail_fresh_produce.json → Preuve end-to-end complète (FR-022, FR-023)

**Vous disposez maintenant de :**
- PRD complet (59 FRs, 10 NFRs)
- Architecture complète (composants, données, API, sécurité, CI/CD)
- Ordre de build recommandé

L'implémentation peut commencer story par story.

---

*Document créé avec BMAD Method v6 — Phase 3 (Solutioning)*
*Référence technique : `ERP_IA_Architecture_v6.pdf` — Avril 2026*
*Pour continuer : lancer `/bmad:sprint-planning`*

---

## Annexe A — Matrice d'Évaluation Technologique

| Catégorie | Choix retenu | Alternatives considérées | Raison du choix |
|---|---|---|---|
| Frontend mobile | Flutter | React Native, Xamarin | Vrai codebase unique, BDUIEngine cohérent, shadcn_ui disponible |
| Frontend web admin | Flutter Web | React+Next.js | Même codebase, même BDUIEngine, même Design System |
| Backend principal | NestJS | Express.js, Fastify, Hapi | Architecture modulaire, DI intégré, TypeScript natif, écosystème |
| Microservice IA | FastAPI | Node.js + LangChain.js | Écosystème IA Python supérieur (LlamaIndex, Instructor, Docling) |
| Base de données | PostgreSQL + pgvector | MySQL, MongoDB, Supabase | RLS native, JSONB, pgvector, migrations TypeORM |
| Cache | Redis | Memcached, in-memory | Persistance, pub/sub, TTL natif, BullMQ dépend Redis |
| Storage | MinIO | AWS S3, Supabase Storage | Self-hosted, S3-compatible, 1 service Docker, migration triviale |
| ORM | TypeORM | Prisma, Drizzle | Migrations, JSONB support, RLS compatible |
| Auth | Passport.js + @nestjs/jwt | Auth0, Supabase Auth | Full control, multi-tenant custom claims, 0 dépendance externe |
| ABAC | CASL | Casbin, OPA | Intégration NestJS native, DSL TypeScript, performant |
| State Machine | XState | statly, robot | Visualisation, TypeScript natif, génération FSM depuis JSON |
| Job Queue | BullMQ | Agenda, Bull, RabbitMQ | Redis dépendance partagée, retry policy, concurrence configurable |
| LLM | Claude API + Ollama | OpenAI, Gemini | Qualité extraction NER, offline fallback Ollama, adapter pattern |
| RAG | LlamaIndex + pgvector | LangChain+Pinecone | pgvector évite 1 service, ABAC filter natif, hybrid search |
| NER Structuré | Instructor | LangChain parsers | Zero JSON cassé, Pydantic schema, retry automatique |
| Offline Flutter | Drift | Isar, Hive, sqflite | ORM complet, SQL typé, Drift Web = IndexedDB, même API |
| State Flutter | Riverpod | BLoC, GetX, Provider | Compile-time safety, testable, code génération |

---

## Annexe B — Capacity Planning Phase 1

| Ressource | Estimation Phase 1 | Estimation Phase 2 |
|---|---|---|
| Tenants actifs | 1-10 (démo → 5 clients) | 50-100 |
| Utilisateurs simultanés | 5-50 total | 500-2000 |
| Écritures/jour | ~1000 | ~50000 |
| Lectures/jour | ~10000 | ~500000 |
| Embeddings totaux | ~100K | ~5M |
| Stockage DB | < 10GB | < 100GB |
| Stockage MinIO | < 50GB | < 500GB |
| RAM VPS | 8GB | 16-32GB |
| CPU VPS | 4 cores | 8-16 cores |
| Bande passante | ~100GB/mois | ~1TB/mois |

**VPS recommandé Phase 1 :** Hetzner CX41 (4 vCPU, 16GB RAM, 160GB SSD) — ~20€/mois.

---

## Annexe C — Estimation des Coûts Phase 1

| Service | Coût mensuel estimé |
|---|---|
| VPS Hetzner CX41 | ~20€ |
| Claude API (Config Agent Phase 2) | ~30-50€ (usage limité Phase 1) |
| Domaine + SSL | ~5€ |
| GitHub (Actions minutes) | Gratuit (public) ou ~4€ |
| Backup externe (Backblaze B2) | ~2€ |
| **Total Phase 1** | **~60-80€/mois** |

**Revenus cibles Phase 1 :** 40,000 FCFA/mois (Blandine) ≈ ~60€ → équilibre coûts infrastructure dès M1.
