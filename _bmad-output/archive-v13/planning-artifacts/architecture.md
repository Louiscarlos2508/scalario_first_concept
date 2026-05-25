---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: complete
completedAt: '2026-03-31'
inputDocuments:
  - docs/architecture-scalario-2026-03-08.md
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/innovation-strategy-2026-03-29.md
  - _bmad-output/design-thinking-2026-03-29.md
  - apps/backend/prisma/schema.prisma
workflowType: architecture
project_name: scalario
user_name: Carlos-simpore
date: '2026-03-31'
outputDocument: docs/architecture-scalario-2026-03-31.md
---

# Scalario — Architecture Workflow

> Primary output document: `docs/architecture-scalario-2026-03-31.md`
> This file tracks BMAD workflow state.

---

## Project Context Analysis

### Requirements Overview

**Functional Requirements — Architectural Signal:**

111+ FRs across 4 phases (FR1–FR111 + FR-AI-01–05, FR-RBAC-01, FR-TEMPLATE-01–02, FR-MULTISTORE-01, FR-SUPERADMIN-01–06), organized into:

- **Core platform (FR1–FR50, ~60%):** Auth, Tenancy, RBAC, Module Registry, Billing — the universal kernel. Already implemented.
- **Modular extensions (~40%):** Variants, Pricing, Promotions, Purchase Orders, Internal Requests, Batches, Client Orders — off by default, activated per tenant via Module Registry.
- **Platform pivot group (FR-AI-01–05, FR-TEMPLATE-01–02):** Not features — architectural tier additions. Introduce the 4th level (Templates Sectoriels) and the orthogonal AI layer.

**Non-Functional Requirements — Architectural Drivers (ranked):**

| # | NFR | Status |
|---|---|---|
| 1 | Offline-first (NFR14/15/30) | ✅ Implemented |
| 2 | Tenant data isolation (NFR8) | ✅ Implemented |
| 3 | Low-bandwidth sync (NFR3/24–26) | ✅ Implemented |
| 4 | Financial integrity (NFR13/18) | ✅ Implemented |
| 5 | Low-end device performance (NFR1/2/4/6/7) | ✅ Implemented |
| 6 | i18n complete (NFR31) | ⚠️ Discipline only (H1), infrastructure H2 |
| 7 | Payment adapter pattern (NFR33) | ❌ Not yet implemented |
| 8 | Compliance pluggable (NFR32) | ❌ Not yet implemented |
| 9 | API versioned `/api/v1/` (NFR35) | ✅ Implemented |
| 10 | Microservices trajectory (NFR40) | 🔜 Gate at 50+ tenants |

**Scale & Complexity:**

- Domain: Universal SaaS platform (brownfield — active development, first client closing)
- Complexity level: Enterprise
- Solo founder constraint: Every architectural decision must minimize operational overhead
- Central tension: Dead-simple for a 3-person épicerie AND extensible enough for hospitals/mines/coopératives from the same codebase

### Technical Constraints & Dependencies

| Constraint | Architectural impact |
|---|---|
| Solo developer | Modular monolith. No Kafka, no Redis cluster, no worker fleet. |
| UEMOA 2G/3G | Delta sync everywhere. Batch sizes < 500KB. Offline = primary UX. |
| Low-end Android tablets | <150MB RAM. Isar over SQLite. No heavy Flutter packages. |
| Flutter single binary | SDUI + Template config for N business types. No per-client builds. |
| Self-hosted Supabase | Docker Compose. Operator = Carlos. No Supabase Cloud. |
| Blandine demo < 1 month | Architecture debt work is parallel, never blocking the demo. |

### Cross-Cutting Concerns Identified

| Concern | Scope |
|---|---|
| Tenant isolation | Every DB model, every API endpoint, every Isar collection |
| Offline/sync | Every mutation (outbox), every read (local-first), every UI (sync indicator) |
| RBAC | Every API endpoint, every Flutter screen (module guard), every AI action |
| i18n | Every user-facing string in Flutter + NestJS error responses |
| AI-invocable actions | Every Level 2 shared module must declare AiActionsManifest |
| Payment adapter | Any code that calls a payment provider |
| Compliance plugin | Transaction creation, session closure, fiscal reporting |
| Module guard | Every Level 2 module endpoint — checks tenant activation |

---

## Stack Validation (Step 3)

Stack confirmed as-is — no replacement decisions required:

| Layer | Choice | Rationale |
|---|---|---|
| Flutter | Keep | Single binary, Riverpod 2.x, Isar offline-first — already invested |
| NestJS | Keep | Modular DynamicModule architecture maps perfectly to 4-tier model |
| Prisma | Keep | Multi-schema `kernel`/`shared`/`retail` + `ai` (H2) fits tier structure |
| Self-hosted Supabase | Keep | Auth + RLS + Realtime — no cloud vendor lock-in, Docker Compose |
| PostgreSQL | Keep | TIMESTAMPTZ(6), DECIMAL(10,2), multi-schema — no alternative needed |

---

## Core Architectural Decisions (Step 4)

Three open decisions resolved:

| Decision | Choice | Rationale |
|---|---|---|
| NestJS ↔ Python AI service communication | HTTP REST (localhost:8001) | Simplest for solo dev, no message broker overhead, easy to debug |
| Default AI model | Claude Sonnet 4.6 | Speed/cost balance for real-time chat and action invocation |
| Config Wizard AI model | Claude Opus 4.6 | Higher reasoning for one-time complex configuration generation |
| Wave integration | Webhook primary + polling fallback | Resilience without persistent connection infrastructure |

---

## Implementation Patterns & Consistency Rules (Step 5)

### Database Naming

- Prisma models: `PascalCase` → PostgreSQL tables: `snake_case` via `@@map`
- All models carry `tenantId String` + `createdAt DateTime @default(now())` + `updatedAt DateTime @updatedAt`
- Money: `DECIMAL(10,2)` stored as `Decimal` in Prisma, serialized as `string` in JSON responses (never float)
- Timestamps: `TIMESTAMPTZ(6)` in DB, ISO 8601 strings in API, `DateTime` UTC in Flutter

### API Conventions

- All endpoints: `/api/v1/{resource}` — kebab-case plural
- Query params: `camelCase` (e.g. `?tenantId=`, `?since=`, `?page=`, `?limit=`)
- Standard response envelope: `{ data: T }` (single) / `{ data: T[], meta: { page, limit, total } }` (list)
- Error shape: `{ statusCode, message: { key: 'error.domain.code', params: {} } }`
- Delta sync param: `?since=ISO8601` on every list endpoint that supports offline sync

### NestJS File & Naming Conventions

- Files: `kebab-case.type.ts` (e.g. `catalog.service.ts`, `tenant.guard.ts`)
- Classes: `PascalCase + Module/Service/Controller/Guard/Dto/Event` suffix
- One controller per sub-concern (no mega-controllers)
- Business logic in services only — controllers are thin routing layer
- Guards run in order: `AuthGuard → TenantGuard → BillingGuard → ModuleGuard → RolesGuard`

### Flutter / Riverpod Conventions

- Files: `snake_case.dart` — one class per file
- Widgets: `PascalCase`, providers: `camelCase + Provider` suffix
- `.autoDispose` on all providers unless explicitly justified (e.g. cart state)
- Never call `ref.read()` inside `build()` — use `ref.watch()` or `ref.listen()`
- Mutations: widget → repository → Isar outbox → SyncEngine background isolate → API
- Never call API directly from a widget or provider

### Event Bus Conventions

- Event names: `domain.action` dot notation (e.g. `catalog.item.updated`, `pos.session.closed`)
- All domain events extend `DomainEvent` base class with `tenantId`, `timestamp`, `aiRelevant: bool`
- `aiRelevant: true` events are forwarded to AI service via internal webhook (H2)

### Outbox Pattern

1. Write mutation to Isar (optimistic local state)
2. Push to `outbox` Isar collection
3. SyncEngine (background isolate) picks up, POSTs to `/api/v1/{resource}`
4. On 200: mark outbox item `synced`, delete local entry
5. On conflict: apply LWW (last-write-wins by `updatedAt`) or surface to user

### i18n Discipline (effective 2026-03-31)

- No new hardcoded user-facing strings in Flutter after this date
- All strings must use `context.l10n.keyName` (flutter_localizations / gen-l10n)
- NestJS error responses must return `{ key: 'error.domain.code', params: {} }` — never raw English strings
- Existing violations are tolerated in H1 — tracked as i18n debt

### 10 Mandatory Rules for AI Agents Working on This Codebase

1. Never write `tenantId` directly into queries — always extract from `@TenantId()` decorator or Isar context
2. Never call a payment provider directly — always go through `PaymentAdapter` interface
3. Never hardcode user-facing strings after 2026-03-31
4. Never add a new Level 2 shared module without an `AiActionsManifest` declaration
5. Never bypass the guard chain (`AuthGuard → TenantGuard → BillingGuard → ModuleGuard → RolesGuard`)
6. Never write mutations from a Flutter widget — always through repository → outbox
7. Never call the AI microservice directly from a Flutter widget — always through `AiChatRepository`
8. Never add code to `retail/` (Level 3) that isn't retail-specific — shared logic belongs in `shared/`
9. Always use `@map` and `@@map` in Prisma to maintain `snake_case` PostgreSQL tables
10. Never put billing/tenant-management logic in Level 2 modules — that lives in `kernel/`


---

## Structure du Projet & Frontières (Step 6)

### Arborescence complète

```
scalario/                                    ← Monorepo racine
├── apps/
│   ├── backend/                             ← NestJS API (Tier 1–3)
│   │   ├── prisma/
│   │   │   ├── schema.prisma                ← Source de vérité DB (kernel/shared/retail + ai H2)
│   │   │   ├── migrations/                  ← Une migration = une PR
│   │   │   ├── seed.ts
│   │   │   ├── seed-retail.ts               ← Seeds Blandine (épicerie)
│   │   │   └── seed-superadmin.ts
│   │   ├── src/
│   │   │   ├── main.ts
│   │   │   ├── app.module.ts
│   │   │   ├── core/                        ← Infrastructure cross-cutting pure
│   │   │   │   ├── guards/auth/             ← AuthGuard (Supabase JWT)
│   │   │   │   ├── guards/tenant/           ← TenantGuard (x-tenant-id header)
│   │   │   │   └── services/supabase/       ← SupabaseService (client admin)
│   │   │   ├── kernel/                      ← Tier 1 — Kernel universel
│   │   │   │   ├── kernel.module.ts
│   │   │   │   ├── auth/
│   │   │   │   ├── tenancy/
│   │   │   │   ├── rbac/                    ← RolesGuard, PermissionService
│   │   │   │   ├── modules/                 ← ModuleRegistryService, ModuleGuard
│   │   │   │   ├── billing/                 ← BillingGuard
│   │   │   │   ├── events/                  ← EventBusService, DomainEvent types
│   │   │   │   ├── sdui/                    ← SduiService + layouts/*.json
│   │   │   │   │   └── layouts/
│   │   │   │   │       ├── retail.dashboard.json
│   │   │   │   │       ├── retail.pos.json
│   │   │   │   │       └── [NEW-H1] sector-template.*.json
│   │   │   │   ├── audit/
│   │   │   │   └── [NEW-H1] templates/      ← SectorTemplateService + Controller
│   │   │   │       ├── sector-template.module.ts
│   │   │   │       ├── sector-template.service.ts
│   │   │   │       └── dto/apply-template.dto.ts
│   │   │   ├── shared/                      ← Tier 2 — Modules partagés activables
│   │   │   │   ├── catalog/
│   │   │   │   │   ├── variants/
│   │   │   │   │   ├── price-levels/
│   │   │   │   │   ├── serials/
│   │   │   │   │   ├── price-history/
│   │   │   │   │   └── [NEW-H1] catalog.ai-actions.ts
│   │   │   │   ├── inventory/
│   │   │   │   │   └── [NEW-H1] inventory.ai-actions.ts
│   │   │   │   ├── contacts/
│   │   │   │   │   └── [NEW-H1] contacts.ai-actions.ts
│   │   │   │   ├── payments/
│   │   │   │   │   ├── payments.module.ts
│   │   │   │   │   ├── payments.service.ts
│   │   │   │   │   ├── [NEW-H1] payment-adapter.interface.ts
│   │   │   │   │   ├── [NEW-H1] adapters/cash.adapter.ts
│   │   │   │   │   └── [NEW-H1] adapters/wave.adapter.ts
│   │   │   │   ├── promotions/
│   │   │   │   ├── purchase-orders/
│   │   │   │   │   └── [NEW-H1] purchase-orders.ai-actions.ts
│   │   │   │   ├── batches/
│   │   │   │   ├── client-orders/
│   │   │   │   ├── internal-requests/
│   │   │   │   ├── notifications/
│   │   │   │   └── [NEW-H1] ai-actions/     ← Registre centralisé AiActions
│   │   │   │       ├── ai-actions.module.ts
│   │   │   │       ├── ai-actions-registry.service.ts
│   │   │   │       └── ai-actions.interface.ts
│   │   │   ├── retail/                      ← Tier 3 — Module fonctionnel Retail
│   │   │   │   ├── retail.module.ts
│   │   │   │   ├── retail.controller.ts
│   │   │   │   ├── retail-sale.service.ts
│   │   │   │   ├── retail-session.controller.ts
│   │   │   │   ├── retail-orchestration.service.ts
│   │   │   │   └── expense.service.ts
│   │   │   ├── pos/
│   │   │   ├── organization/
│   │   │   ├── reporting/
│   │   │   ├── tenant/
│   │   │   ├── migration/
│   │   │   └── admin/                       ← SuperAdmin (Carlos only)
│   │   │       ├── guards/super-admin.guard.ts
│   │   │       ├── tenants/
│   │   │       ├── users/
│   │   │       ├── modules/
│   │   │       ├── billing/
│   │   │       ├── business-type/
│   │   │       └── monitoring/
│   │   └── test/
│   │       ├── unit/
│   │       ├── integration/
│   │       └── e2e/
│   │
│   ├── frontend/                            ← Flutter (Android tablet first)
│   │   ├── lib/
│   │   │   ├── app/
│   │   │   │   └── sdui_registry_setup.dart
│   │   │   ├── core/
│   │   │   │   ├── auth/                    ← AuthRepository, AuthState, UserProfile
│   │   │   │   ├── constants/               ← api_constants.dart
│   │   │   │   ├── models/                  ← SyncMetadata, SyncStatus
│   │   │   │   ├── providers/               ← ActiveModulesProvider, PaymentMethodsProvider
│   │   │   │   ├── sdui/                    ← SduiRenderer, SduiWidgetRegistry
│   │   │   │   ├── services/
│   │   │   │   │   ├── sync_service.dart    ← SyncEngine (background isolate)
│   │   │   │   │   ├── isar_service.dart
│   │   │   │   │   ├── realtime_service.dart
│   │   │   │   │   └── sync_adapters/       ← Un adapter par domaine
│   │   │   │   ├── theme/
│   │   │   │   ├── utils/                   ← ConflictResolution (LWW)
│   │   │   │   └── widgets/
│   │   │   └── features/
│   │   │       ├── auth/
│   │   │       ├── admin/
│   │   │       │   ├── data/models/
│   │   │       │   ├── data/services/
│   │   │       │   └── presentation/
│   │   │       ├── retail/
│   │   │       │   ├── pos/
│   │   │       │   │   ├── data/models/     ← Isar: Product, CartItem, Order…
│   │   │       │   │   ├── data/repositories/
│   │   │       │   │   ├── data/services/
│   │   │       │   │   └── presentation/
│   │   │       │   │       ├── providers/
│   │   │       │   │       └── screens/
│   │   │       │   └── backoffice/
│   │   │       │       └── presentation/
│   │   │       └── [NEW-H2] ai/             ← Panel IA dédié
│   │   │           ├── data/
│   │   │           │   ├── models/ai_conversation.dart
│   │   │           │   ├── models/ai_action_chip.dart
│   │   │           │   └── repositories/ai_chat_repository.dart
│   │   │           └── presentation/
│   │   │               ├── providers/ai_providers.dart
│   │   │               ├── screens/ai_panel_screen.dart
│   │   │               └── widgets/ai_command_bar.dart
│   │   ├── assets/
│   │   └── pubspec.yaml
│   │
│   └── [NEW-H2] ai-service/                 ← Python/FastAPI microservice IA
│       ├── main.py                          ← FastAPI, port 8001 (localhost only)
│       ├── routers/chat.py
│       ├── routers/actions.py               ← Function calling
│       ├── services/claude_service.py       ← Anthropic SDK, Sonnet 4.6 default
│       ├── services/action_registry.py
│       ├── services/tenant_context.py
│       ├── models/chat.py
│       ├── models/action.py
│       ├── requirements.txt
│       └── Dockerfile
│
├── docs/
│   ├── architecture-scalario-2026-03-08.md  ← v1.6 (archivée)
│   └── architecture-scalario-2026-03-31.md  ← v2.0 (source de vérité active)
└── .github/
    └── workflows/                           ← CI/CD (GitHub Actions + Fastlane H2)
```

### Frontières Architecturales

**Flux d'appels autorisés :**

| Appelant | Cible | Canal | Auth |
|---|---|---|---|
| Flutter app | NestJS `/api/v1/` | HTTPS REST | Supabase JWT + `x-tenant-id` |
| NestJS | Python AI service | HTTP REST `localhost:8001` | Internal only |
| NestJS | Supabase | Supabase Admin SDK | Service role key |
| Flutter app | Supabase Realtime | WebSocket | Supabase JWT |
| Flutter app | Python AI service | **JAMAIS direct** | N/A |

**Règles de dépendance inter-couches :**

| Règle | Direction |
|---|---|
| `kernel/` ne dépend de rien au-dessus de lui | ↓ seulement |
| `shared/` ne dépend pas de `retail/` | ↓ seulement |
| `retail/` peut importer depuis `kernel/` et `shared/` | ↓ autorisé |
| Widget Flutter ne touche jamais directement l'API | Toujours via repository → outbox |
| Panel IA séparé des écrans module | Écran dédié, jamais injecté |

**Isolation tenant :**

| Couche | Mécanisme |
|---|---|
| PostgreSQL | `tenant_id` sur chaque table + Supabase RLS |
| NestJS | `@TenantId()` decorator extrait du JWT |
| Isar (Flutter) | `tenantId` filtré dans chaque query |
| Python AI | `tenant_id` propagé depuis NestJS sur chaque appel |

### Mapping FR → Répertoires

| FR / Epic | Backend | Frontend |
|---|---|---|
| FR1–FR20 Auth, Tenancy, RBAC | `src/kernel/` | `lib/core/auth/` |
| FR21–FR30 Module Registry | `src/kernel/modules/` | `lib/core/providers/active_modules_provider.dart` |
| FR31–FR50 Billing, SuperAdmin | `src/admin/billing/` | `lib/features/admin/` |
| FR51–FR70 Catalog, Inventory | `src/shared/catalog/`, `src/shared/inventory/` | `lib/features/retail/pos/data/` |
| FR71–FR87 POS, Sessions | `src/pos/`, `src/retail/` | `lib/features/retail/pos/presentation/` |
| FR88–FR95 Purchase Orders | `src/shared/purchase-orders/` | `lib/features/retail/backoffice/` |
| FR96–FR111 Batches, Variants | `src/shared/batches/`, `src/shared/promotions/` | `lib/features/retail/` |
| FR-AI-01–05 | `src/shared/ai-actions/` [H1] + `apps/ai-service/` [H2] | `lib/features/ai/` [H2] |
| FR-TEMPLATE-01–02 | `src/kernel/templates/` [H1] | `lib/core/sdui/` |
| NFR33 Payment adapter | `src/shared/payments/adapters/` [H1] | `lib/core/providers/payment_methods_provider.dart` |
| NFR32 Compliance plugin | `src/shared/compliance/` [H2] | N/A |


---

## Validation de l'Architecture (Step 7)

### Cohérence des décisions

| Décision A | Décision B | Compatibilité |
|---|---|---|
| Offline-first (Isar + outbox) | Delta sync `?since=` | Compatible — même protocole |
| Python microservice séparé | NestJS gère tout le DB access | Compatible — découplage intentionnel |
| SDUI Epic 10 | SectorTemplate layout config | Compatible — templates pointent vers LayoutDefinition |
| PaymentAdapter H1 | Wave integration H1 | Compatible — interface avant implémentation |
| AiActionsManifest H1 | Python microservice H2 | Compatible — registre avant service |
| Role.tenantId nullable H1 | Custom roles H2 | Compatible — migration sans données impactées |
| Single Flutter binary | SDUI + Template config | Compatible — fondation du flywheel |

Guard chain cohérent dans tout le document : `AuthGuard → TenantGuard → BillingGuard → ModuleGuard → RolesGuard`.

### Couverture des exigences

Tous les FRs (FR1–FR111, FR-AI-01–05, FR-TEMPLATE-01–02, FR-RBAC-01, FR-MULTISTORE-01, FR-SUPERADMIN-01–06) et tous les NFRs (NFR1–NFR40) sont couverts avec un mapping explicite vers les répertoires et horizons (H1/H2/H3).

### Gaps identifiés

**Gap 1 (important) — Ambiguïté `tenant/` vs `tenants/`**
Règle à appliquer immédiatement : tout nouvel endpoint tenant-facing va dans `src/tenant/`. Le répertoire `src/tenants/` est déprécié — aucun nouveau fichier.

**Gap 2 (mineur) — Endpoint webhook Wave**
`POST /api/v1/payments/wave/webhook` absent du catalogue §5.5. À documenter lors de l'implémentation de WaveAdapter.

**Gap 3 (dépendance livraison) — Epic 10 et SectorTemplate**
Le champ `layoutCode` sur SectorTemplate est nullable. La SectorTemplate H1 peut être seedée avec `layoutCode = null`. La complétion d'Epic 10 débloque le champ — pas un gap architectural.

### Checklist de complétude

- [x] Contexte projet analysé (brownfield, UEMOA, solo founder, Blandine)
- [x] Complexité et contraintes techniques identifiées
- [x] Préoccupations transverses mappées (8 concerns)
- [x] 10 ADRs documentés avec contexte + décision + conséquences
- [x] Stack technique validé (aucun remplacement requis)
- [x] 3 décisions ouvertes résolues (HTTP REST AI, Sonnet/Opus, Wave webhook+polling)
- [x] Décisions irréversibles lockées (§10.4)
- [x] Décisions différables documentées (§10.5)
- [x] Conventions de nommage DB / API / NestJS / Flutter
- [x] Guard chain spécifié et ordonné
- [x] Flux outbox spécifié étape par étape
- [x] 10 règles impératives pour agents IA
- [x] Arborescence complète basée sur code réel
- [x] Frontières inter-couches définies
- [x] Mapping FR → répertoires complet

### Statut final

**PRÊT POUR IMPLÉMENTATION — Niveau de confiance : Élevé**

Points forts : document aligné sur code existant, interfaces H1 anticipent les besoins H2, règle AI séparée des écrans simplifie Flutter, isolation tenant garantie sans audit supplémentaire.

