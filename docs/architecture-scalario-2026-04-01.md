# Architecture Document — Scalario Platform

**Author:** Carlos-simpore
**Date:** 2026-04-01
**Version:** 2.0
**Status:** Draft — Architecture Cible
**Précédente version:** `docs/architecture-scalario-2026-03-08.md` (v1.5)

**Revision History:**
| Version | Date | Changes |
|:---|:---|:---|
| 2.0 | 2026-04-01 | Vision universelle. 4 tiers. Flutter restructuré. RBAC data-driven. AI section dédiée. Python microservice H2. Payment/Compliance adapters. |
| 2.1 | 2026-04-01 | Section 3 : plan d'extinction du concept "vertical" comme frontière architecturale (H1 pragmatisme → H2 shell générique → H3 vertical = métadonnée uniquement). |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Overview — 4 Niveaux](#2-architecture-overview--4-niveaux)
3. [Flutter File Structure](#3-flutter-file-structure)
4. [Backend Architecture](#4-backend-architecture)
5. [Data Models — RBAC & Templates](#5-data-models--rbac--templates)
6. [AI Architecture](#6-ai-architecture)
7. [Flywheel — Modules Core → Templates Sectoriels](#7-flywheel--modules-core--templates-sectoriels)
8. [Migration Path — v1.5 → v2.0](#8-migration-path--v15--v20)
9. [ADRs](#9-adrs)
10. [What to Build When — H1/H2/H3](#10-what-to-build-when--h1h2h3)

---

## 1. Executive Summary

### Ce qui change vs v1.5

| Dimension | V1.5 | V2.0 |
|:---|:---|:---|
| Vision | ERP Retail vertical UEMOA | Plateforme de gestion universelle — beachhead UEMOA Retail |
| Architecture tiers | 3 : Kernel → Shared → Vertical Retail | 4 : Kernel → Shared Services → Modules Fonctionnels → Templates Sectoriels |
| Flutter structure | `features/retail/` + `features/shared/` | `features/retail/` + `features/modules/` + `features/templates/` (H2) |
| RBAC | `roleScreenAccess` JSON statique dans `BusinessTypeDefinition` | Table `RoleScreenPolicy` data-driven, migration progressive |
| AI | Mentionné dans la roadmap, non architecturé | Section dédiée `AIAssistantScreen`, Python FastAPI via proxy NestJS (H2) |
| Payments | `paymentMethods` JSON sur `Tenant`, non structuré | `IPaymentAdapter` — Wave/OM/Moov = adapters pluggables |
| Compliance | OHADA implicite | `ICompliancePlugin` — OHADA = plugin, pas code core |
| Templates sectoriels | `BusinessTypeDefinition` avec JSON | `SectorTemplate` comme entité propre (H2) |
| Nouvelles verticales seed | `retail` uniquement | `retail` (11 types) + `distribution` (3) + `restauration` (2) + `services` (1) |

### Ce qui ne change pas

- **Stack technologique** : Flutter + NestJS + Prisma (multi-schema) + Supabase self-hosted + Isar. Aucun driver de changement.
- **Offline-first** : driver architectural #1 absolu. Aucune décision ne compromet l'opération sans connectivité.
- **Modular Monolith NestJS** : 3 clients actifs, fondateur solo, zéro driver de scaling indépendant. Pas de microservices avant 200+ tenants actifs.
- **Kernel schema existant** : `Tenant`, `Role`, `Permission`, `RolePermission`, `Module`, `TenantModule`, `OrganizationMember`, `AuditLog`, `PlanDefinition`, `BillingEvent` — tous compatibles v2.0 sans migration destructive.
- **Logique métier Flutter** : tout le code dans `features/shared/` reste intact. Le rename est l'unique changement structurel H1.

### Problèmes réels à résoudre (factuels)

| Problème | Pourquoi c'est un problème maintenant | Priorité |
|:---|:---|:---|
| `roleScreenAccess` JSON dans `BusinessTypeDefinition` est partagé entre tous les tenants du même businessType | Aucun tenant ne peut avoir des droits différents d'un autre "épicerie". Bloque la personnalisation client. | **H1 sprint final** |
| Pas d'interface `IPaymentAdapter` — si Wave est intégré directement, Orange Money = refactoring POS complet | Wave API H2 + Orange Money = 2 providers à coût séparé si pas d'interface | **H1 fondation** |
| Pas d'interface `ICompliancePlugin` — si OHADA est hardcodé dans les services de transactions/rapports | Expansion Côte d'Ivoire H2 = modifier le kernel pour TVA | **H1 fondation** |
| `features/shared/` contient des modules métier — nom trompeur pour tout contributeur futur | Aucun impact fonctionnel, confusion de navigation uniquement | **H1 rename** |

---

## 2. Architecture Overview — 4 Niveaux

### Les 4 tiers

```
┌────────────────────────────────────────────────────────────────────────┐
│  TIER 4 — SECTORAL TEMPLATES (H2+)                                     │
│  Configuration pure — aucun code Flutter, aucun module NestJS dédié    │
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │
│  │  SectorTmpl  │  │  SectorTmpl  │  │  SectorTmpl  │   ...           │
│  │  epicerie    │  │  pharmacie   │  │  restaurant  │                  │
│  │ modules[]    │  │ modules[]    │  │ modules[]    │                  │
│  │ roles{}      │  │ roles{}      │  │ roles{}      │                  │
│  │ vocabulary{} │  │ vocabulary{} │  │ vocabulary{} │                  │
│  └──────────────┘  └──────────────┘  └──────────────┘                 │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │ compose from
┌──────────────────────────────▼─────────────────────────────────────────┐
│  TIER 3 — FUNCTIONAL MODULES (H1 → H3)                                  │
│                                                                          │
│  catalog · inventory · pos · cash_session · contacts · reports          │
│  expenses · freshness · purchase_orders · reservations · client_orders  │
│  returns · promotions · billing · internal_requests · stock_alerts      │
│                                                                          │
│  [H2+] work_order · appointment · table_management · kitchen_display    │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │ depends on
┌──────────────────────────────▼─────────────────────────────────────────┐
│  TIER 2 — SHARED SERVICES (H1 foundations)                              │
│                                                                          │
│  payments (IPaymentAdapter) · notifications · compliance (ICompliancePlugin)│
│  sync_engine · audit · i18n · sdui_engine                               │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │ built on
┌──────────────────────────────▼─────────────────────────────────────────┐
│  TIER 1 — KERNEL (stable après H1 — ne toucher qu'en dernier recours)  │
│                                                                          │
│  auth · tenancy · rbac · module_registry · event_bus                   │
│  plan_enforcer · billing_kernel                                          │
└────────────────────────────────────────────────────────────────────────┘
```

### Stack complète — vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     FLUTTER CLIENT (Offline-First)                       │
│                                                                          │
│  core/                features/                                          │
│  ├── auth/             ├── auth/      → LoginScreen, SplashScreen        │
│  ├── sdui/             ├── retail/    → DashboardShell, PosScreen        │
│  ├── services/         ├── modules/   → catalog, inventory, freshness…   │
│  ├── theme/            ├── templates/ → [H2] SectorTemplate configs      │
│  └── widgets/          ├── admin/     → Superadmin (Carlos uniquement)   │
│                         └── ai/       → [H2] AIAssistantScreen           │
│                                                                          │
│  Isar (WAL) ←→ SyncEngine (background isolate) ←→ Supabase Realtime     │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ HTTPS /api/v1/
┌────────────────────────────────▼────────────────────────────────────────┐
│               NestJS BACKEND (Modular Monolith)                          │
│                                                                          │
│  AuthGuard → TenantGuard → RolesGuard → Controllers                     │
│                                                                          │
│  kernel/    auth · tenancy · rbac · module_registry · event_bus          │
│  shared/    payments(adapter) · notifications · compliance(plugin) · sync│
│  modules/   catalog · inventory · pos · sessions · contacts · reports    │
│             expenses · freshness · purchases · reservations · orders…    │
│                                                                          │
│  [H2] ai/   AIModule (proxy → Python FastAPI interne)                   │
│                                                                          │
│  Prisma → kernel schema | shared schema | retail schema                  │
└──────────────────────┬─────────────────────┬───────────────────────────┘
                       │                     │ [H2] HTTP interne
         ┌─────────────▼──────────┐  ┌───────▼──────────────────────────┐
         │  SUPABASE (Self-Hosted)│  │  PYTHON FastAPI (H2+)             │
         │  PostgreSQL (RLS)      │  │  LLM integration                  │
         │  Auth (JWT)            │  │  GenUI (SDUI JSON) generation     │
         │  Realtime (WS)         │  │  AI-invocable action dispatcher   │
         │  Storage               │  │  Internal Docker network uniquement│
         └────────────────────────┘  └──────────────────────────────────┘
```

---

## 3. Flutter File Structure

### Décision : Option B modifiée (un rename + un namespace vide)

**Pourquoi pas Option C** (features/kernel/ + features/modules/ + features/templates/) : `core/` joue déjà le rôle de kernel Flutter. Créer `features/kernel/` serait une duplication du rôle de `core/`. Option C déplace ~50 fichiers pour un gain de clarté minimal.

**Pourquoi pas Option A simple** (garder tel quel, juste documenter) : `features/shared/` nommant des modules métier complets crée une confusion durable. Un rename résout ça définitivement.

**Ce qui change :**

```
features/shared/   →   features/modules/     (rename, contenu identique)
                        features/templates/   (nouveau dossier vide — namespace H2)
                        features/ai/          (nouveau dossier vide — H2)
```

### Structure cible

```
apps/frontend/lib/
├── app/
│   └── sdui_registry_setup.dart
├── core/                            ← INCHANGÉ. Kernel Flutter.
│   ├── auth/                        ← AuthRepository, AuthState, UserProfile
│   ├── constants/
│   ├── models/
│   ├── providers/                   ← ActiveModulesProvider, PaymentMethodsProvider
│   ├── sdui/                        ← SduiLayout, SduiRenderer, SduiWidgetRegistry
│   ├── services/                    ← Barcode, DeviceIdentity, Isar, Realtime,
│   │                                   Receipt, Sync + 5 adapters
│   ├── settings/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── admin/                       ← INCHANGÉ. Panel superadmin Carlos.
│   ├── auth/                        ← INCHANGÉ. LoginScreen.
│   ├── retail/                      ← INCHANGÉ. Shell du vertical Retail.
│   │   ├── backoffice/              │  DashboardScreen, DashboardShell
│   │   └── pos/                     │  PosScreen, CartPanel, widgets POS
│   │
│   ├── modules/                     ← RENOMMÉ depuis features/shared/
│   │   │                               Contenu identique. Un find/replace suffit.
│   │   ├── billing/
│   │   ├── business_type/
│   │   ├── catalog/
│   │   ├── client_orders/
│   │   ├── contacts/
│   │   ├── expenses/
│   │   ├── freshness/
│   │   ├── inventory/
│   │   ├── notifications/
│   │   ├── promotions/
│   │   ├── purchase_orders/
│   │   ├── reports/
│   │   ├── reservations/
│   │   ├── returns/
│   │   └── stock_alerts/
│   │
│   ├── templates/                   ← NOUVEAU (vide en H1, peuplé en H2)
│   │   └── .gitkeep                 ← Namespace réservé. Aucun code H1.
│   │                                   H2 : retail_epicerie/, pharmacie/, etc.
│   │                                   Chaque sous-dossier = SectorTemplate data class
│   │                                   + config JSON. Aucun écran Flutter dédié.
│   │
│   └── ai/                          ← NOUVEAU (vide en H1, implémenté en H2)
│       └── .gitkeep
│
└── main.dart
```

### Blast radius du rename

- **Fichiers touchés :** tous les `import '…/features/shared/…'` → `import '…/features/modules/…'`
- **Logique changée :** aucune
- **Tests cassés :** aucun
- **Durée :** 1 commande IDE rename + 15 min de vérification

### Plan d'extinction du concept "vertical"

`features/retail/` existe aujourd'hui parce que c'est le seul secteur implémenté. C'est du pragmatisme, pas de l'architecture. Le "vertical" comme frontière de code doit disparaître — remplacé par des SectorTemplates + un shell générique.

#### H1 — Conserver features/retail/ tel quel

`features/retail/` contient deux choses :

- `backoffice/` → DashboardShell (navigation principale de l'app)
- `pos/` → PosScreen + CartPanel

Le DashboardShell n'est pas intrinsèquement "retail" — il affiche les tabs selon les modules actifs et le rôle. Il est nommé retail parce qu'il a été conçu dans ce contexte. C'est acceptable en H1 car c'est le seul secteur.

#### H2 — Extraction du shell générique (trigger : arrivée d'un 2e secteur)

```
Avant (H1) :
  features/retail/backoffice/DashboardShell   ← shell couplé au retail

Après (H2) :
  features/shell/DashboardShell               ← shell générique, piloté par SectorTemplate
  features/retail/                            ← vide ou supprimé
```

Le shell générique lit le `SectorTemplate` actif pour savoir :

- quelles tabs afficher
- quel rôle accède à quoi
- quel vocabulaire utiliser (labels, termes métier)

Il n'y aura pas de `features/restaurant/` ni de `features/artisan/`. Ces secteurs n'ont pas de shell dédié — ils utilisent le shell générique configuré par leur SectorTemplate.

#### H3 — features/retail/ disparaît

Tous les secteurs passent par le shell générique. Zéro code Flutter par secteur. `features/retail/` est supprimé.

#### Le champ `vertical` dans la DB change de rôle

```
Avant : discriminateur architectural → branche le code vers le "module retail"
Après : tag de filtrage → groupe les SectorTemplates, segmente les analytics
```

`Tenant.vertical` et `BusinessTypeDefinition.vertical` restent en base mais ne pilotent plus aucune branche de code après H2. Leur valeur est informationnelle, pas comportementale.

---

## 4. Backend Architecture

### 4.1 Structure NestJS — organisation des modules

```
src/
├── kernel/
│   ├── auth/                 ← AuthGuard, @CurrentUser(), validation JWT Supabase
│   ├── tenancy/              ← TenantGuard, @CurrentTenant(), lifecycle tenant
│   ├── rbac/
│   │   ├── roles.guard.ts    ← @Roles() decorator enforcement
│   │   ├── permission.service.ts
│   │   └── role-screen-policy/ ← [NEW H1] RoleScreenPolicy data-driven
│   ├── module-registry/      ← ModuleRegistry, activation TenantModule
│   ├── event-bus/            ← NestJS EventEmitter2 (interne uniquement)
│   ├── plan-enforcer/        ← Interface H1 ; middleware activé en H2
│   └── billing/              ← BillingKernelModule
│
├── shared/
│   ├── payments/             ← [NOUVEAU H1] IPaymentAdapter + adapters
│   │   ├── interfaces/
│   │   │   └── payment-adapter.interface.ts
│   │   ├── adapters/
│   │   │   ├── cash.adapter.ts
│   │   │   └── manual-mobile-money.adapter.ts    ← V1 : saisie manuelle
│   │   │   └── wave.adapter.ts                   ← [H2] API Wave
│   │   │   └── orange-money.adapter.ts           ← [H2] API Orange Money
│   │   └── payment.service.ts                    ← Utilise le registry d'adapters
│   │
│   ├── compliance/           ← [NOUVEAU H1] ICompliancePlugin + plugins
│   │   ├── interfaces/
│   │   │   └── compliance-plugin.interface.ts
│   │   └── plugins/
│   │       └── ohada.plugin.ts
│   │       └── tva-ci.plugin.ts                  ← [H2] Côte d'Ivoire
│   │
│   ├── notifications/        ← NotificationService (push + in_app)
│   │   └── adapters/
│   │       └── whatsapp.adapter.ts               ← [H2] WhatsApp Business API
│   │
│   ├── sync/                 ← Delta sync endpoints, résolution de conflits
│   ├── audit/                ← AuditLogService
│   └── i18n/                 ← TranslationService — zéro string hardcodée
│
├── modules/                  ← Modules métier existants (inchangés)
│   ├── catalog/
│   ├── inventory/
│   ├── pos/
│   ├── cash-session/
│   ├── contacts/
│   ├── reports/
│   ├── expenses/
│   ├── freshness/
│   ├── purchase-orders/
│   ├── reservations/
│   ├── client-orders/
│   ├── returns/
│   ├── promotions/
│   └── internal-requests/
│
└── ai/                       ← [H2] Proxy module uniquement
    ├── ai.controller.ts      ← Routes /api/v1/ai/*
    └── ai-proxy.service.ts   ← Forward vers Python FastAPI (réseau interne)
```

### 4.2 Payment Adapter Pattern

**Interfaces à définir en H1 — implémentation minimale H1, adapters réels H2 :**

```typescript
// src/shared/payments/interfaces/payment-adapter.interface.ts

export interface PaymentInitResult {
  intentId: string;
  status: 'pending' | 'completed' | 'failed';
  providerRef?: string;
}

export interface IPaymentAdapter {
  readonly provider: string; // 'CASH' | 'MOBILE_MONEY' | 'WAVE' | 'ORANGE_MONEY'

  initiate(params: {
    amount: number;
    tenantId: string;
    ref: string;
  }): Promise<PaymentInitResult>;

  verify(intentId: string): Promise<'completed' | 'pending' | 'failed'>;
}
```

**H1 :** `CashAdapter` (toujours `completed`) + `ManualMobileMoneyadapter` (complété par l'opérateur manuellement). Aucun appel API externe.

**H2 :** `WaveAdapter` + `OrangeMoneyAdapter` branchés sur ce même registre. Le code POS ne change pas.

**Règle :** Aucune mention de `'wave'` ou `'orange_money'` dans la logique métier POS/transactions. Uniquement dans les adapters.

### 4.3 Compliance Plugin Pattern

```typescript
// src/shared/compliance/interfaces/compliance-plugin.interface.ts

export interface ICompliancePlugin {
  readonly jurisdiction: string; // 'OHADA' | 'TVA_CI' | 'CNSS_KE'

  validateTransaction(tx: Transaction): { valid: boolean; errors: string[] };
  generateFiscalEntry(tx: Transaction): FiscalEntry;
  exportPeriodReport(tenantId: string, from: Date, to: Date): Promise<Buffer>;
}
```

**H1 :** `OhadaPlugin` implémenté (plan de comptes, écritures de ventes, export FEC).
**H2 :** `TvaCiPlugin` (TVA Côte d'Ivoire) — branché sans toucher le kernel.

### 4.4 AI Proxy Module (H2)

**Architecture de la séparation NestJS / Python :**

```
Flutter
  └─ HTTPS → NestJS /api/v1/ai/*
                └─ AuthGuard → TenantGuard résout le tenant
                └─ AIProxyService.forward(request, tenantId)
                     └─ HTTP interne → Python FastAPI :8001 (Docker network)
                          ← retourne { text, genui_layout, actions[] }
                └─ NestJS retourne la réponse à Flutter
```

**Pourquoi NestJS proxy et non API Gateway direct :**
- Flutter a une seule base URL. Pas de logique de routing côté client.
- L'auth et l'isolation tenant sont résolues dans NestJS avant que Python reçoive quoi que ce soit.
- Python est sur le réseau Docker interne uniquement — non exposé sur internet.
- Si Python est down, NestJS retourne 503 pour les routes `/ai/*` uniquement. Les routes métier sont inaffectées.

**Migration future vers API Gateway :** Justifiée si Python a besoin de timeouts différents (streaming LLM > 30s) et que Flutter doit les gérer indépendamment. Pas de trigger prévisible en H2.

---

## 5. Data Models — RBAC Dynamique + Templates Sectoriels

### 5.1 RBAC Migration — roleScreenAccess → RoleScreenPolicy

**État actuel (v1.5) :**

```
BusinessTypeDefinition.roleScreenAccess: Json
Valeur exemple :
{
  "commercial": ["pos", "losses", "stock_view", "transfers", "daily_sales"],
  "cashier":    ["pos"]
}
```

**Problème concret :** Ce JSON est partagé par tous les tenants du même `businessType`. Un tenant `epicerie_A` ne peut pas avoir des droits commerciaux différents d'un tenant `epicerie_B`. Toute modification impacte tous les clients du même type.

**État cible (v2.0) :**

```prisma
// NOUVELLE table — migration additive, non cassante
model RoleScreenPolicy {
  id         String  @id @default(uuid()) @db.Uuid
  tenantId   String  @map("tenant_id") @db.Uuid
  roleId     String  @map("role_id") @db.Uuid
  screenCode String  @map("screen_code")
  granted    Boolean @default(true)

  tenant     Tenant  @relation(fields: [tenantId], references: [id])
  role       Role    @relation(fields: [roleId], references: [id])

  @@unique([tenantId, roleId, screenCode])
  @@index([tenantId, roleId])
  @@map("role_screen_policies")
  @@schema("kernel")
}
```

**Migration en 3 étapes — aucun client cassé :**

```
Étape 1 — H1 sprint final (additive)
  Créer table RoleScreenPolicy.
  Pour chaque tenant existant :
    Lire BusinessTypeDefinition.roleScreenAccess de son businessType.
    Créer les RoleScreenPolicy correspondantes (tenant_id + role_id + screen_code).
  Backend : lire RoleScreenPolicy en priorité, fallback sur roleScreenAccess JSON si vide.
  Flutter : aucun changement (lit depuis cache Isar, même format).

Étape 2 — H2 début
  Backend ne lit plus le JSON fallback pour les tenants migrés.
  API admin pour modifier les policies d'un tenant individuel.

Étape 3 — H2 mi
  roleScreenAccess déprécié dans BusinessTypeDefinition.
  Supprimé en H3 une fois tous les tenants migrés.
```

### 5.2 Templates Sectoriels — Évolution de BusinessTypeDefinition

**État actuel :** `BusinessTypeDefinition` contient à la fois la définition du type (code, name, icon), la configuration par défaut (defaultFlags, visibleSections), les labels (roleLabels, transferLabels), les droits (roleScreenAccess) et le type de document (documentType).

**Ce que doit devenir un Template Sectoriel :**
Un Template = bundle de configuration complet pour déployer un nouveau secteur sans code Flutter. Il définit : quels modules activer, quels rôles créer, quel vocabulaire métier utiliser, quels workflows activer, quel flow d'onboarding présenter.

**Plan H1 — extension additive de BusinessTypeDefinition :**

```prisma
// 2 nouveaux champs — migration non cassante
model BusinessTypeDefinition {
  // ... tous les champs existants inchangés ...

  // H1 : configuration des workflows par défaut pour ce type
  // Ex: {"cashSession": {"requiresReconciliation": true}}
  workflowConfig   Json @default("{}") @map("workflow_config")

  // H1 : vocabulaire i18n propre à ce type de commerce
  // Ex: {"transfer": "Transfert magasin", "session": "Caisse"}
  i18nVocabulary   Json @default("{}") @map("i18n_vocabulary")
}
```

**Plan H2 — SectorTemplate comme entité propre :**

```prisma
model SectorTemplate {
  id              String   @id @default(uuid()) @db.Uuid
  code            String   @unique  // 'retail_epicerie' | 'pharmacie' | 'restaurant'
  name            String
  vertical        String   // 'retail' | 'artisan' | 'restaurant' | 'services'

  // Modules activés par défaut (codes correspondant à Module.code)
  // Ex: ["catalog","inventory","pos","cash_session","freshness"]
  defaultModules  String[] @map("default_modules")

  // Définition des rôles par défaut avec leurs screens et permissions
  defaultRoles    Json     @default("{}") @map("default_roles")

  // Configuration des workflows spécifiques au secteur
  workflowConfig  Json     @default("{}") @map("workflow_config")

  // Vocabulaire métier du secteur (labels UI, termes métier)
  vocabulary      Json     @default("{}") @map("vocabulary")

  // Étapes de l'onboarding wizard (H2 — AI Config Wizard)
  onboardingFlow  Json     @default("[]") @map("onboarding_flow")

  isActive        Boolean  @default(true) @map("is_active")
  createdAt       DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  businessTypes   BusinessTypeDefinition[]

  @@map("sector_templates")
  @@schema("kernel")
}

// Ajout FK nullable sur BusinessTypeDefinition (migration non cassante)
model BusinessTypeDefinition {
  // ... tous les champs existants ...
  templateId String?        @map("template_id") @db.Uuid
  template   SectorTemplate? @relation(fields: [templateId], references: [id])
}
```

**Gate pour la migration H1 → H2 :** Dès qu'un intégrateur configure un secteur nouveau via l'interface (et non plus via seed.ts), `SectorTemplate` devient nécessaire. Avant ce moment, l'extension H1 suffit.

---

## 6. AI Architecture

### 6.1 Règle absolue

L'AI n'est jamais injectée sur les écrans modules existants. Pas de bouton "Demander à l'IA" sur `PosScreen`. Pas de popover sur `InventoryScreen`. Pas d'action chip dans les formulaires.

**L'AI a son espace propre. Les screens ont le leur.**

Raisons :
- Les screens doivent fonctionner offline. L'AI ne peut pas.
- Un screen qui dépend de l'AI pour ses actions critiques dégrade l'UX offline.
- L'utilisateur qui cherche l'AI sait où aller (section dédiée). L'utilisateur qui cherche le stock ne voit pas l'AI.

### 6.2 AIAssistantScreen — Navigation conditionnelle

```
AppShell Navigation (DashboardShell)
├── Accueil (Dashboard SDUI)       — toujours visible
├── POS                            — si module actif + rôle
├── Stock                          — si module actif + rôle
├── Achats                         — si module actif + rôle
├── ... autres modules ...
└── Assistant (icône AI)           — visible SEULEMENT si :
                                     • connectivité active
                                     • module AI activé pour le tenant
                                     CACHÉ (pas grisé) si offline
```

La différence entre "caché" et "grisé" est importante : un item grisé suggère que la feature devrait être accessible. Un item absent ne crée aucune attente. Offline = absent.

### 6.3 Structure de l'écran

```
AIAssistantScreen (route /assistant)
├── AppBar
│   ├── Titre : "Assistant"
│   └── ContextChip : module actuel (ex: "Stock")
│
├── ChatThread (scrollable)
│   ├── UserMessage
│   └── AIResponse
│       ├── TextContent
│       └── GenUISlot                  ← Réutilise SduiRenderer existant
│           ├── action_chip_list       ← Nouveau widget SDUI à enregistrer
│           ├── kpi_card_grid          ← Widget SDUI existant
│           └── line_chart             ← Widget SDUI existant
│
├── OfflineBanner                      ← Affiché si connexion perdue en cours de session
│                                         Persistent, non dismissible
│
└── InputBar
    ├── TextField                      ← Désactivé si offline
    └── SendButton
```

**Réutilisation du SduiRenderer :** Le GenUI généré par Python retourne du JSON SDUI-compatible. Le `SduiRenderer` existant le rend sans nouveau renderer custom. L'AI est promptée/formée sur le vocabulaire SDUI existant.

**Nouveau widget SDUI à enregistrer** (unique ajout à `sdui_registry_setup.dart`) :
```dart
registry.register('action_chip_list', (data) => AIActionChipList(data: data));
```

### 6.4 AISessionContext Provider

```dart
// core/providers/ai_session_context_provider.dart

@riverpod
AISessionContext aiSessionContext(AISessionContextRef ref) {
  return AISessionContext(
    currentModule: ref.watch(activeModuleProvider),
    currentScreen: ref.watch(currentScreenProvider),
    userRole: ref.watch(currentUserRoleProvider),
    tenantId: ref.watch(currentTenantProvider).id,
    // Métriques légères — pour que l'AI ait le contexte sans requête supplémentaire
    todayTransactionCount: ref.watch(todayTransactionCountProvider),
  );
}
```

Ce contexte est passé en JSON avec chaque message envoyé à l'AI. L'AI sait sur quel écran l'utilisateur se trouve, son rôle, et le volume de transactions du jour — sans que l'utilisateur ait besoin de préciser.

### 6.5 Actions AI-Invocables par Module

Chaque module NestJS expose les actions que l'AI peut déclencher. Ces actions sont des fonctions de service ordinaires, décorées pour le registre AI.

**Pattern :**
```typescript
// src/modules/inventory/inventory.ai-actions.ts

@Injectable()
export class InventoryAIActions {

  constructor(private readonly inventoryService: InventoryService) {}

  // L'AI peut appeler cette action via function calling
  async getLowStockItems(tenantId: string, threshold?: number) {
    return this.inventoryService.getLowStockItems(tenantId, threshold ?? 5);
  }

  async createReplenishmentSuggestion(tenantId: string) {
    return this.inventoryService.computeReplenishmentSuggestions(tenantId);
  }
}
```

Python reçoit la liste des actions disponibles filtrées par :
- Modules actifs du tenant
- Rôle de l'utilisateur (un `cashier` ne peut pas créer des commandes fournisseurs via l'AI non plus)

L'AI ne contourne jamais les permissions RBAC.

### 6.6 Offline — Règle simple

| État | Comportement |
|:---|:---|
| Connecté + module AI actif | Navigation item visible. Assistant opérationnel. |
| Connecté + module AI inactif | Navigation item absent. |
| Offline | Navigation item absent. Zéro dégradation des autres écrans. |
| Connexion perdue en session AI | `OfflineBanner` apparaît. `InputBar` désactivé. Historique chat conservé en mémoire session. |

**Pas de cache AI offline en H2.** Les action chips précalculées (Top 20 queries offline) sont une optimisation H3, justifiée seulement à partir de ~1000 requêtes AI/tenant/mois.

---

## 7. Flywheel — Modules Core → Templates Sectoriels

### Principe

```
Un Module Core universel (work_order, appointment, table_management)
  → combiné dans N SectorTemplates (configuration pure, zéro Flutter dédié)
    → déverrouille N nouveaux secteurs immédiatement
      → chaque nouveau client = données = AI plus précise
        → AI Config Wizard configure plus vite
          → plus de clients = financement du Module Core suivant
```

### Règle de priorisation

**Construire le Module Core qui déverrouille le plus de Templates Sectoriels.**

### Cartographie Modules Core → Secteurs

| Module Core | Business types déverrouillés | Priorité |
|:---|:---|:---|
| `catalog` + `inventory` + `pos` + `cash_session` | Retail (11 types), Services (encaissement), Bar/Restaurant (caisse) | **H1 — Déjà construit** |
| `freshness` + Taux de Frotte | Épicerie, Restauration cuisine, Marché de produits frais | **H1 — En cours** |
| `work_order` + `bill_of_materials` | `tailleur`, `menuisier`, `forgeron`, `cordonnier`, `imprimeur`, `artisan_general` | H2 priorité 1 |
| `appointment` | `salon_coiffure`, `lavage_auto`, `cyber_cafe`, `photographe`, `services_general` | H2 |
| `table_management` + `kitchen_display` | `restaurant`, `fast_food`, `bar`, `traiteur` | H2 |
| `hr_payroll` + `attendance` | Enterprise (tous secteurs), ONG, Santé | H3 |
| `accounting_ohada` | Enterprise, Cabinet comptable | H3 |

### Règle d'intégrité

**Un Template Sectoriel ne doit jamais toucher le kernel.** Si configurer un template pharmacie nécessite de modifier `auth/`, `tenancy/` ou `rbac/` — c'est un échec d'architecture.

Flux valide : `SectorTemplate` configure des `FunctionalModules` qui s'appuient sur des `SharedServices` qui utilisent le `Kernel`.

---

## 8. Migration Path — v1.5 → v2.0

**Principe : aucun client cassé, aucune feature retirée, aucune interruption de service.**

### Phase 0 — Préparation immédiate (avant démo Blandine)

Ces actions sont non-cassantes et doivent être faites en premier. Elles débloquent tout le reste.

| Action | Type | Risque |
|:---|:---|:---|
| Rename `features/shared/` → `features/modules/` + find/replace imports | Flutter refactoring | Nul |
| Créer `features/templates/` + `features/ai/` (dossiers vides) | Structure | Nul |
| Définir `IPaymentAdapter` interface (sans implémenter Wave) | NestJS interface | Nul |
| Migrer `CashAdapter` + `ManualMobileMoney` depuis logique POS actuelle | NestJS adapter | Faible |
| Définir `ICompliancePlugin` interface + `OhadaPlugin` | NestJS interface + plugin | Faible |
| Ajouter `workflowConfig` + `i18nVocabulary` à `BusinessTypeDefinition` | Migration Prisma additive | Nul |
| Créer table `RoleScreenPolicy` (migration additive) | Migration Prisma additive | Nul |
| Seed `RoleScreenPolicy` depuis `roleScreenAccess` pour les 3 clients existants | Script de seed | Faible |

### Phase 1 — Après démo Blandine (H2 début, Q2 2026)

| Action | Prérequis | Risque |
|:---|:---|:---|
| Backend lit `RoleScreenPolicy` en priorité (fallback JSON si vide) | Seed Phase 0 OK | Faible |
| Wave adapter + Orange Money adapter | `IPaymentAdapter` Phase 0 | Faible |
| WhatsApp Business API adapter dans `NotificationService` | Architecture notifications | Faible |
| Gestion utilisateurs côté client (09.1/09.2) — scénario actuellement superadmin-only | Aucun | Moyen |
| Python FastAPI microservice (Docker, réseau interne) | Docker Compose | Moyen |
| NestJS `AIModule` proxy | Python service up | Moyen |
| `AIAssistantScreen` Flutter | NestJS AI proxy + `features/ai/` namespace | Moyen |

### Phase 2 — H2 mi (Q3 2026)

| Action | Prérequis |
|:---|:---|
| `SectorTemplate` modèle Prisma + migration | Aucun |
| Script de migration `BusinessTypeDefinition` → `SectorTemplate` | Modèle créé |
| AI Excel/CSV Import catalogue (FR-AI-03) | Python service |
| AI Natural Language Config produits (FR-AI-04) | Python service |
| `UsageLimitsMiddleware` (plan enforcer) | `PlanDefinition.limits` déjà en DB |

### Phase 3 — H2 fin / H3 (Q4 2026+)

| Action | Prérequis |
|:---|:---|
| AI Config Wizard Universel (FR-AI-05) | Python service + `SectorTemplate` |
| Supprimer fallback JSON `roleScreenAccess` (tous clients sur `RoleScreenPolicy`) | Migration H2 complète |
| Déprécier `roleScreenAccess` dans `BusinessTypeDefinition` | Étape précédente |
| Scalario Connect, Enterprise, Marketplace | Gates business (voir section 10) |

---

## 9. ADRs

### ADR-001 : Modular Monolith NestJS maintenu

**Décision :** NestJS reste un monolithe modulaire. Pas d'extraction en microservices avant H3.

**Contexte :** Fondateur solo, 3 clients actifs, aucune contrainte de scaling indépendant identifiée.

**Raisons :**
- Complexité opérationnelle microservices injustifiable pour ~30 tenants actifs
- NestJS `DynamicModule` donne l'isolation de module sans coût de déploiement
- Les boundaries de modules sont encore en cours de stabilisation

**Exception unique :** Python FastAPI en H2. Raison spécifique : l'écosystème LLM (LangChain, LlamaIndex, vector stores) est Python-natif. Maintenir un wrapper TypeScript serait une friction permanente. C'est un service isolé par périmètre fonctionnel (AI uniquement), pas une extraction architecturale générale.

**Trigger de révision :** 200+ tenants actifs avec besoins de scaling indépendant mesurés.

---

### ADR-002 : Flutter features/shared/ → features/modules/

**Décision :** Renommer le dossier `features/shared/` en `features/modules/`.

**Contexte :** `features/shared/` contient des modules métier complets (catalog, inventory, freshness, reports…). Le nom "shared" est trompeur : il ne désigne pas des composants partagés (UI widgets, utils) mais des modules fonctionnels autonomes.

**Impact :** Pur renommage. Logique inchangée. Aucun test cassé. Un find/replace sur les imports suffit.

**Bénéfice :** La structure Flutter reflète les 4 tiers de l'architecture. `core/` = kernel, `features/modules/` = modules fonctionnels, `features/retail/` = shell vertical.

---

### ADR-003 : Payment Adapter Pattern dès H1

**Décision :** Toute logique de paiement passe par `IPaymentAdapter`. Aucun provider hardcodé dans la logique métier POS ou sessions.

**Contexte :** Blandine utilise Mobile Money (Orange Money/Wave) en mode manuel. L'API Wave sera intégrée en H2. Orange Money et Moov sont présents en UEMOA.

**Impact si ignoré :** Chaque nouveau payment provider nécessite de modifier la logique POS, les sessions, et les réconciliations. Avec 3 providers potentiels, le coût est multiplié par 3.

**H1 scope :** Définir `IPaymentAdapter`, implémenter `CashAdapter` + `ManualMobileMoney`. Zéro appel API externe. L'interface coûte 2h en H1, économise 2 semaines en H2.

---

### ADR-004 : Compliance Pluggable Framework dès H1

**Décision :** Toute logique fiscale et sociale passe par `ICompliancePlugin`. OHADA = plugin, pas code core.

**Contexte :** Expansion H2 vers Côte d'Ivoire (TVA DGI-CI) et potentiellement Kenya (CNSS) est dans la roadmap.

**Impact si ignoré :** Si les règles OHADA sont intégrées dans les services de transactions ou de rapports, ajouter la TVA ivoirienne nécessite de modifier le kernel.

**H1 scope :** Définir `ICompliancePlugin`, implémenter `OhadaPlugin`. L'interface coûte 2h en H1.

---

### ADR-005 : RBAC Data-Driven — Migration Progressive Non-Cassante

**Décision :** Migrer `roleScreenAccess` JSON statique vers table `RoleScreenPolicy` en 3 étapes sans interruption de service pour les clients existants.

**Contexte :** Le JSON actuel dans `BusinessTypeDefinition` est partagé par tous les tenants du même type. Aucune personnalisation par tenant n'est possible sans modifier le seed global.

**Migration :** Additive (nouvelle table), seed automatique depuis l'existant, fallback JSON maintenu pendant la transition. Aucun client ne voit de changement.

---

### ADR-006 : AI = Section Dédiée, Jamais sur les Écrans Modules

**Décision :** Aucun élément UI relatif à l'AI n'est injecté sur les écrans modules (PosScreen, InventoryScreen, ReportsScreen, etc.). L'AI vit uniquement dans `AIAssistantScreen`.

**Raisons :**
- Les écrans modules sont offline-first. L'AI requiert une connexion. Mélanger les deux crée des états ambigus et des erreurs inattendues offline.
- Un screen prévisible et déterministe a plus de valeur pour un opérateur en production que des suggestions AI intermittentes.
- L'utilisateur peut ignorer l'AI section complètement sans dégradation d'expérience.

**Conséquence :** L'AI doit être assez utile dans sa section pour que les utilisateurs viennent naturellement. Si personne n'utilise `AIAssistantScreen`, c'est un signal produit, pas un problème d'architecture.

---

### ADR-007 : NestJS Proxy vers Python FastAPI (H2)

**Décision :** Flutter parle à NestJS uniquement. NestJS proxie `/api/v1/ai/*` vers Python FastAPI sur le réseau Docker interne.

**Alternative rejetée :** API Gateway Nginx avec routing direct Flutter → Python. Rejetée car l'authentification et l'isolation tenant (resolved dans NestJS) devraient être dupliquées dans Python, créant deux points d'enforcement de la sécurité.

**Avantages du proxy :**
- URL unique pour Flutter (pas de gestion de deux base URLs)
- Auth et `tenantId` résolus une fois dans NestJS, injectés dans chaque requête proxiée
- Python non exposé sur internet — surface d'attaque réduite
- Si Python est down : 503 sur `/ai/*` uniquement, zéro impact sur les routes métier

**Trigger de migration vers API Gateway :** Si les appels LLM dépassent 30s et que Flutter a besoin de gérer les timeouts indépendamment (streaming). Non prévisible en H2.

---

### ADR-008 : SduiRenderer Réutilisé pour GenUI AI

**Décision :** Le GenUI généré par l'AI retourne du JSON SDUI-compatible. Flutter utilise le `SduiRenderer` existant pour le rendre.

**Contexte :** `SduiRenderer` est déjà en production pour le dashboard. Les widgets `kpi_card_grid`, `line_chart`, `product_grid` sont enregistrés et testés.

**Bénéfice :** Pas de second renderer à maintenir. Les widgets SDUI existants sont immédiatement disponibles pour les réponses AI. Le seul ajout est le widget `action_chip_list` spécifique aux actions AI-invocables.

**Contrainte :** Python doit être prompté/formé sur le vocabulaire SDUI. Les widgets non enregistrés dans `SduiWidgetRegistry` ne peuvent pas être générés par l'AI.

---

### ADR-009 : SectorTemplate en H2, Pas en H1

**Décision :** Ne pas créer l'entité `SectorTemplate` en H1. Ajouter `workflowConfig` et `i18nVocabulary` comme champs JSON à `BusinessTypeDefinition` pour les besoins H1.

**Raison du report :** En H1, aucun intégrateur ne configure de secteur nouveau. `SectorTemplate` n'a pas d'utilisateur concret. Le coût de la migration est réel, le bénéfice est théorique. Les champs JSON ajoutés en H1 donnent toute la flexibilité nécessaire sans modèle supplémentaire.

**Gate pour H2 :** Dès qu'un intégrateur configure un secteur nouveau via une interface (pas via seed.ts), `SectorTemplate` devient justifié et la migration est faite en une journée (script automatique depuis les champs JSON existants).

---

### ADR-010 : Supabase Self-Hosted Maintenu

**Décision :** Garder Supabase self-hosted sur Docker Compose. Pas de migration vers Supabase Cloud.

**Raisons :**
- Contrôle total des données clients (requis pour conformité OHADA et certifications futures)
- Pas de vendor lock-in
- Coût prévisible à l'échelle (pas de surprise de pricing à 1000 tenants)
- Docker Compose simplifie l'administration solo

**Charge opérationnelle :** Backups automatisés PostgreSQL obligatoires dès H1. Fenêtre de maintenance acceptable : 1–2h maximum par mois.

---

## 10. What to Build When — H1/H2/H3

### H1 — Avant démo Blandine (mi-avril 2026)

#### Fondations non-négociables

Ces 4 fondations sont mentionnées dans le PRD comme "H1 non-négociables". Les implémenter maintenant évite un refactoring coûteux en H2. Ce ne sont pas des features — ce sont des contraintes d'implémentation.

| Fondation | Règle | Coût si différé |
|:---|:---|:---|
| **i18n complet** | Zéro string UI hardcodée. Toutes les labels passent par le système de traduction. | Rétrofit sur 50+ écrans = 1–2 semaines |
| **REST API /api/v1/** | Toutes les routes sous `/api/v1/`. Aucune route sans préfixe de version. | Clients Flutter hardcodent les paths — impossible de versionner |
| **Payment Adapter** | `IPaymentAdapter` défini. Wave/OM = adapters, pas intégrations directes. | Chaque provider = refactoring POS + sessions |
| **Compliance Pluggable** | `ICompliancePlugin` défini. OHADA = plugin. | TVA Côte d'Ivoire H2 = modifier kernel |

#### Features critiques démo Blandine

| Feature | Fichiers concernés | Statut actuel |
|:---|:---|:---|
| Flow fermeture caisse step-by-step (01.1–01.3) | `session_report_dialog.dart`, `session_notifier.dart` | ⚠️ Partiel — logique présente, UX éclatée dans dialogs |
| PIN identification vendeur (04.1) | Nouveau `employee_select_screen.dart` | ❌ À créer |
| Centre alertes unifié (02.2) | Unifier `stock_alerts_screen.dart` + `freshness_screen.dart` + `notification_bell.dart` | ⚠️ Partiel |
| Taux de Frotte sur réception (10.1) | `receive_purchase_order_sheet.dart` — vérifier `shrinkageTolerance` appliqué | ⚠️ À vérifier |

#### Refactoring structurel

| Action | Durée estimée |
|:---|:---|
| Rename `features/shared/` → `features/modules/` + find/replace | 1h |
| Créer `features/templates/` + `features/ai/` (vides) | 5 min |
| Migration Prisma : `workflowConfig` + `i18nVocabulary` sur `BusinessTypeDefinition` | 1h |
| Migration Prisma : table `RoleScreenPolicy` + seed depuis `roleScreenAccess` | 3h |

---

### H2 — Post-démo, 12 mois (Q2–Q4 2026)

#### H2 début (Mois 1–3)

| Composant | Prérequis | Justification |
|:---|:---|:---|
| Backend lit `RoleScreenPolicy` + fallback JSON | Seed H1 | RBAC data-driven opérationnel |
| Wave adapter (si API disponible) | `IPaymentAdapter` H1 | 1 journée d'implémentation avec l'interface en place |
| Orange Money adapter | `IPaymentAdapter` H1 | Idem |
| WhatsApp Business API (résumé quotidien Blandine) | `NotificationService` | Feature promise à Blandine |
| Gestion utilisateurs côté client (09.1/09.2) | Aucun | Actuellement superadmin-only — bloque la scalabilité |

#### H2 mi (Mois 3–6)

| Composant | Prérequis | Justification |
|:---|:---|:---|
| Python FastAPI (Docker Compose) | Docker Compose existant | Prérequis pour toutes les features AI |
| NestJS `AIModule` proxy | Python service up | Bridge NestJS ↔ Python |
| `AIAssistantScreen` Flutter | NestJS AI proxy | Section dédiée — offline-conditional |
| AI Excel/CSV Import catalogue (FR-AI-03) | Python service | Onboarding catalogue 3h → 10 min |
| AI Natural Language Config produits (FR-AI-04) | Python service | Vrac→sachet, multi-unités par langage naturel |
| `SectorTemplate` modèle + migration | Trigger : premier intégrateur | Activé uniquement si un intégrateur configure un secteur |

#### H2 fin (Mois 6–12)

| Composant | Prérequis |
|:---|:---|
| AI Config Wizard Universel (FR-AI-05) | Python service + `SectorTemplate` |
| `UsageLimitsMiddleware` (plan enforcer) | `PlanDefinition.limits` déjà en DB depuis H1 |
| Freemium Starter self-service | AI Config Wizard opérationnel |
| Programme Ambassadeurs | `referred_by` déjà en DB — activer logique métier |
| Module `work_order` + `bill_of_materials` (artisan) | `SectorTemplate` |

---

### H3 — Expansion (12–36 mois, 2027+)

| Composant | Gate d'entrée |
|:---|:---|
| Scalario Connect (B2B inter-tenants) | 20+ clients dans la même ville |
| Scalario Enterprise (multi-départements) | 3+ clients PME multi-entités |
| Template Marketplace / SDK tiers | 50+ clients actifs + documentation SDK |
| Conformité fiscale automatique (TVA DGI) | `OhadaPlugin` prouvé + partenariat expert-comptable |
| White-label / OEM (banques, telecoms) | PMF validé + 30+ clients actifs |
| AI réseau cross-tenants (données agrégées anonymisées) | 50–100 clients actifs + opt-in consentement explicite |
| AI action chips offline précalculées (Top 20) | AI individuelle H2 prouvée + analyse usage réel (~1000 req/tenant/mois) |
| Suppression de `roleScreenAccess` dans `BusinessTypeDefinition` | Tous les tenants sur `RoleScreenPolicy` |

---

### Ce qui peut être différé sans risque

| Décision | Peut attendre | Raison |
|:---|:---|:---|
| Migration vers API Gateway Nginx (routing Flutter → Python) | H3 | NestJS proxy suffit. Aucun timeout différentiel en H2. |
| Suppression du fallback JSON `roleScreenAccess` | H3 | Le champ reste en DB, le fallback ne coûte rien en performance. |
| Flutter web / desktop builds | H3+ | Android + iOS couvrent 100% du marché UEMOA. Web = demo enterprise, pas production. |
| Extraction NestJS vers microservices | Jamais avant 200+ tenants actifs | Aucun driver de scaling mesurable. |
