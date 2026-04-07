# System Architecture: Scalario Retail — Phase 1

**Date:** 2026-04-06
**Architecte:** Carlos Simporé
**Version:** 1.0
**Type de projet:** Application mobile & desktop de gestion de boutique retail
**Niveau projet:** Level 3
**Statut:** Draft

---

## Document Overview

Ce document définit l'architecture système de Scalario Retail Phase 1. Il couvre uniquement le produit codé en dur — aucune référence aux phases futures (UI Engine, SDUI, config no-code, AI).

**Documents liés :**
- PRD : `docs/prd-scalario-retail-2026-04-06.md`
- Brief Phase 1 : `_bmad-output/phase1-brief.md`

---

## Executive Summary

Scalario Retail Phase 1 est une application offline-first de gestion de boutique retail. L'architecture repose sur deux piliers :

1. **Client Flutter** avec base locale Isar — toutes les opérations fonctionnent sans Internet
2. **Backend NestJS** avec PostgreSQL (Supabase) — source de vérité serveur, sync bidirectionnelle

Le pattern dominant est **Offline-First Sync** : chaque écriture se fait d'abord en local, puis est synchronisée vers le serveur via une queue d'opérations. Le backend est un **monolithe modulaire NestJS** — simple à déployer, suffisant pour le volume Phase 1.

---

## Architectural Drivers

Ces NFRs structurent les décisions architecturales :

### Driver 1: Offline-First + Zéro Perte (NFR-001, NFR-003, NFR-004)

**Impact :** Chaque entité a un cycle de vie local → queue → sync → résolution de conflits. C'est le pattern central de l'application.

**Décisions :**
- Isar comme base locale avec schéma miroir du serveur
- Queue de sync persistante (opérations CRUD horodatées)
- Stratégie de conflits par type d'entité (LWW pour données maîtres, merge additif pour mouvements)
- Toute opération < 500ms en local

### Driver 2: Appareils Milieu de Gamme (NFR-002)

**Impact :** Contrainte les choix de libs, impose lazy loading et pagination locale.

**Décisions :**
- Pas de libs lourdes (pas de gRPC)
- Pagination des listes (produits, ventes, mouvements)
- Images compressées et chargées à la demande
- APK < 50MB, mémoire runtime < 150MB

### Driver 3: Sécurité Multi-Rôles (NFR-006, NFR-007, NFR-008)

**Impact :** Double vérification client + serveur pour chaque action.

**Décisions :**
- Supabase Auth pour JWT + refresh tokens
- Isar avec chiffrement natif
- Permissions vérifiées côté Flutter (UI masquée) ET côté NestJS (guards)
- Row Level Security PostgreSQL comme filet supplémentaire

### Driver 4: Multi-Plateforme (NFR-012, NFR-015)

**Impact :** Un seul codebase Flutter pour Android, iOS, Desktop.

**Décisions :**
- Responsive layout avec breakpoints (mobile / tablette / desktop)
- Navigation adaptative : BottomNavigationBar (mobile) vs NavigationRail/Drawer (desktop)
- Pas de plugins platform-specific critiques

### Driver 5: API REST Standard (NFR-013)

**Impact :** Contrat clair entre client et serveur.

**Décisions :**
- REST avec versioning /api/v1/
- OpenAPI/Swagger auto-généré
- JSON partout, codes HTTP standards

---

## System Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT (Flutter)                       │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │    UI     │  │  State   │  │  Local   │  │  Sync   │ │
│  │  Layer    │←→│  Mgmt    │←→│  Data    │←→│ Engine  │ │
│  │ (Screens) │  │ (Riverpod│  │  (Isar) │  │         │ │
│  └──────────┘  └──────────┘  └──────────┘  └────┬────┘ │
│                                                   │      │
└───────────────────────────────────────────────────┼──────┘
                                                    │
                                          HTTPS / REST API
                                                    │
┌───────────────────────────────────────────────────┼──────┐
│                   BACKEND (NestJS)                 │      │
│                                                    │      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────┴───┐ │
│  │   Auth   │  │ Business │  │  Sync    │  │   API   │ │
│  │  Guard   │←→│  Modules │←→│  Module  │←→│ Gateway │ │
│  │          │  │          │  │          │  │         │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
│                       │                                   │
│                  ┌────┴────┐                              │
│                  │   ORM   │                              │
│                  │(Prisma) │                              │
│                  └────┬────┘                              │
│                       │                                   │
└───────────────────────┼───────────────────────────────────┘
                        │
              ┌─────────┴─────────┐
              │    PostgreSQL     │
              │   (Supabase)     │
              │                   │
              │  + Supabase Auth  │
              │  + Storage (imgs) │
              └───────────────────┘
                        │
              ┌─────────┴─────────┐
              │   Firebase (FCM)  │
              │   Push Notifs     │
              └───────────────────┘
```

### Architectural Pattern

**Pattern :** Monolithe modulaire NestJS + Client offline-first Flutter

**Rationale :**
- **Monolithe modulaire** (pas microservices) : un seul déployable, séparation logique par modules NestJS. Suffisant pour < 100 boutiques Phase 1. Évite la complexité distribuée.
- **Offline-first** : le client est autonome. Le backend est un "luxury" pour la sync et les notifications push. L'app marche à 100% sans serveur.

---

## Technology Stack

### Frontend (Client)

**Choix :** Flutter 3.x + Dart

**Rationale :** Cross-platform natif (Android, iOS, Windows, macOS) avec un seul codebase. Performance native, hot reload, écosystème mature. Déjà choisi dans le brief.

**Libs clés :**
| Lib | Usage |
|-----|-------|
| `flutter_riverpod` | State management — réactif, testable, pas de boilerplate |
| `isar` + `isar_flutter_libs` | Base locale embarquée — offline-first, rapide, schema-driven |
| `supabase_flutter` | Backend integration + auth |
| `go_router` | Navigation déclarative, deep linking |
| `fl_chart` | Graphiques simples pour rapports |
| `intl` | Formatage dates, nombres, devise FCFA |
| `connectivity_plus` | Détection état réseau |
| `esc_pos_utils_plus` + `print_bluetooth_thermal` | Impression thermique Bluetooth (ESC/POS) |
| `pdf` + `printing` | Génération factures PDF, partage |
| `mobile_scanner` | Scan code-barres |
| `image_picker` | Photos produits |

**Trade-offs :**
- (+) Un seul codebase pour 4 plateformes
- (+) Performance native, pas de WebView
- (-) Isar : NoSQL-like, moins de requêtes relationnelles complexes que SQL
- (-) Desktop Flutter moins mature que mobile

### Backend

**Choix :** NestJS (Node.js / TypeScript)

**Rationale :** Framework structuré (modules, guards, pipes), TypeScript partagé avec l'écosystème, bon écosystème de libs, facile à déployer.

**Libs clés :**
| Lib | Usage |
|-----|-------|
| `@nestjs/swagger` | Documentation API auto-générée |
| `prisma` | ORM type-safe, migrations, introspection |
| `@nestjs/passport` + `passport-jwt` | Auth JWT |
| `class-validator` + `class-transformer` | Validation DTO |
| `firebase-admin` | Envoi push notifications |
| `@nestjs/schedule` | Tâches planifiées (résumé quotidien) |

**Trade-offs :**
- (+) Structure claire, modulaire, testable
- (+) TypeScript = typage fort
- (-) Node.js single-threaded — OK pour le volume Phase 1
- (-) Prisma génère du code, overhead si schéma très large

### Database

**Choix :** PostgreSQL via Supabase

**Rationale :** Supabase fournit PostgreSQL managé + Auth + Storage + Row Level Security. Réduit l'infra à gérer pour un solo founder.

**Trade-offs :**
- (+) Auth intégrée (Supabase Auth), storage pour images
- (+) RLS comme couche de sécurité supplémentaire
- (+) Hébergé, pas d'infra à maintenir
- (-) Dépendance à Supabase (mitigé : PostgreSQL standard, migrable)

### Infrastructure

**Choix :** Supabase (DB + Auth + Storage) + Railway ou Fly.io (NestJS)

**Rationale :** Déploiement simple, pas de Docker/K8s à gérer. Railway pour le NestJS car déploiement Git push, scaling vertical facile.

**Environnements :**
- `development` : local (PostgreSQL Docker + NestJS local)
- `staging` : Supabase staging project + Railway staging
- `production` : Supabase prod + Railway prod

### Third-Party Services

| Service | Usage | Coût Phase 1 |
|---------|-------|---------------|
| Supabase | DB + Auth + Storage | Free tier (500MB DB, 1GB storage) |
| Railway | Hébergement NestJS | ~$5/mois |
| Firebase (FCM) | Push notifications | Gratuit |
| GitHub | Repo + CI (Actions) | Free tier |

**Coût total Phase 1 : ~$5-10/mois**

### Development & Deployment

| Outil | Usage |
|-------|-------|
| Git + GitHub | Version control, code review |
| GitHub Actions | CI/CD — tests, lint, build, deploy |
| Flutter test + Mockito | Tests unitaires et widget tests |
| Jest | Tests backend NestJS |
| Fastlane | Build et distribution mobile (APK/IPA) |

---

## System Components

### Component 1: UI Layer (Flutter)

**Purpose :** Affichage et interaction utilisateur

**Responsibilities :**
- Écrans (POS, Stock, Caisse, Rapports, etc.)
- Navigation adaptative (mobile vs desktop)
- Formulaires avec validation locale
- Affichage permissions (masquer les écrans non autorisés)

**FRs Addressed :** Tous (UI pour chaque FR)

### Component 2: State Management (Riverpod)

**Purpose :** Gestion de l'état applicatif réactif

**Responsibilities :**
- Providers par domaine (products, sales, stock, cash, orders)
- Transformation des données locales pour l'affichage
- Gestion du state de sync (online/offline, syncing, error)

**FRs Addressed :** Transversal

### Component 3: Local Data Layer (Isar)

**Purpose :** Stockage local offline, source de vérité côté client

**Responsibilities :**
- CRUD sur toutes les entités locales via schemas Isar
- Requêtes indexées et liens entre collections
- Chiffrement natif Isar
- Schémas versionnés avec migration

**FRs Addressed :** FR-031 (offline), FR-006-032 (toutes les entités)

### Component 4: Sync Engine (Flutter)

**Purpose :** Synchronisation bidirectionnelle client ↔ serveur

**Responsibilities :**
- Queue persistante d'opérations locales (pending sync)
- Détection de connexion réseau
- Push des changements locaux vers le serveur
- Pull des changements serveur vers le client
- Résolution de conflits
- Retry avec backoff exponentiel

**FRs Addressed :** FR-031, FR-032

**Architecture interne :**
```
┌──────────────┐
│  Operation   │  Chaque écriture locale crée une SyncOperation
│    Queue     │  {id, entity, entityId, operation, payload, timestamp, status}
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Sync        │  Au retour connexion :
│  Scheduler   │  1. Push toutes les ops pending (FIFO)
│              │  2. Pull les changements serveur depuis lastSyncTimestamp
└──────┬───────┘  3. Résoudre les conflits
       │
       ▼
┌──────────────┐
│  Conflict    │  Stratégie par entité :
│  Resolver    │  - Product, Supplier, User → Last-Write-Wins (updatedAt)
│              │  - StockMovement, Sale, Expense → Additive (jamais de conflit)
└──────────────┘  - CashSession → Device-owner wins
```

### Component 5: API Gateway (NestJS)

**Purpose :** Point d'entrée unique pour toutes les requêtes client

**Responsibilities :**
- Routing vers les modules métier
- Authentification JWT (Guard global)
- Validation des DTOs (Pipes)
- Rate limiting basique
- Versioning API (/api/v1/)

**FRs Addressed :** FR-029 (auth), transversal

### Component 6: Business Modules (NestJS)

**Purpose :** Logique métier côté serveur

**Modules :**
| Module | Responsabilité | FRs |
|--------|---------------|-----|
| `ProductModule` | CRUD produits, variantes, conversions, frotte | FR-006, FR-007, FR-011, FR-012, FR-013 |
| `StockModule` | Mouvements stock, alertes, fraîcheur, inventaire | FR-008, FR-009, FR-010, FR-014, FR-015, FR-016, FR-034 |
| `SaleModule` | Ventes détail + gros, historique, factures | FR-001, FR-002, FR-003, FR-004, FR-005, FR-035 |
| `CashModule` | Sessions caisse, réconciliation | FR-017, FR-018 |
| `ExpenseModule` | Dépenses boutique | FR-019 |
| `OrderModule` | Commandes internes, workflow validation | FR-020, FR-021, FR-022 |
| `ReportModule` | Rapports CA, stock, pertes | FR-024, FR-025, FR-026 |
| `NotificationModule` | Push notifications, résumé quotidien | FR-022, FR-023 |
| `ClientModule` | CRM clients, historique achats, crédit | FR-037, FR-038 |
| `SupplierModule` | CRUD fournisseurs, historique achats | FR-027, FR-028 |
| `AuthModule` | Auth, rôles, permissions | FR-029, FR-030 |
| `SyncModule` | Réception/envoi des changements sync | FR-031, FR-032 |
| `ShopModule` | Configuration boutique, onboarding | Transversal |

### Component 7: Sync Module (NestJS)

**Purpose :** Gestion de la synchronisation côté serveur

**Responsibilities :**
- Recevoir les opérations batch du client
- Appliquer les changements en base serveur
- Retourner les changements serveur depuis un timestamp donné
- Gérer les conflits côté serveur si nécessaire
- Maintenir un changelog par boutique

**Endpoints :**
- `POST /api/v1/sync/push` — client envoie ses opérations pending
- `GET /api/v1/sync/pull?since={timestamp}` — client récupère les changements serveur

### Component 8: Notification Service

**Purpose :** Envoi de notifications push via FCM

**Responsibilities :**
- Enregistrement des device tokens
- Envoi notifications événementielles (commande en attente)
- Envoi résumé quotidien (cron job)
- Gestion des échecs de livraison

**FRs Addressed :** FR-022, FR-023

### Component 9: Backoffice Super Admin (Web)

**Purpose :** Interface interne pour opérer la plateforme Scalario (réservée au fondateur)

**Responsibilities :**
- Création de tenant (nouvelle boutique)
- Activation / suspension de tenant
- Reset password utilisateur
- Consultation des logs de synchronisation par tenant

**FRs Addressed :** FR-033

---

## Data Architecture

### Data Model

```
Shop
├── id (UUID)
├── name
├── businessType (FRESH_PRODUCE | BEVERAGES | COSMETICS)
├── currency (FCFA)
├── createdAt, updatedAt

User
├── id (UUID)
├── shopId → Shop
├── email
├── passwordHash (Supabase Auth)
├── name
├── role (OWNER | MANAGER | SELLER)
├── permissions (JSON — overrides par toggle)
├── deviceToken (FCM)
├── createdAt, updatedAt

Product
├── id (UUID)
├── shopId → Shop
├── name
├── category
├── unitBase (kg, unité, litre...)
├── priceRetail (FCFA)
├── priceWholesale (FCFA, nullable)
├── wholesaleUnit (carton, sac, nullable)
├── wholesaleFactor (int, ex: 12)
├── isPerishable (bool)
├── frotteRate (decimal %, default 0)
├── shelfLifeDays (int, nullable)
├── lowStockThreshold (decimal)
├── imageUrl (nullable)
├── isActive (bool)
├── createdAt, updatedAt

ProductVariant
├── id (UUID)
├── productId → Product
├── name (ex: "500ml", "1L")
├── priceRetail
├── priceWholesale (nullable)
├── currentStock
├── createdAt, updatedAt

UnitConversion
├── id (UUID)
├── productId → Product
├── sourceUnit (ex: "sac 5kg")
├── derivedUnit (ex: "sachet 100g")
├── factor (ex: 50)
├── derivedPrice (FCFA)
├── createdAt, updatedAt

StockMovement
├── id (UUID)
├── shopId → Shop
├── productId → Product
├── variantId → ProductVariant (nullable)
├── type (IN | OUT | ADJUSTMENT | FROTTE_LOSS)
├── quantity (decimal, signé)
├── reason (nullable — obligatoire si ADJUSTMENT)
├── referenceType (SALE | SUPPLY | MANUAL | CONVERSION)
├── referenceId (UUID, nullable)
├── userId → User
├── createdAt

Sale
├── id (UUID)
├── shopId → Shop
├── userId → User (vendeur)
├── clientId → Client (nullable — lié si vente associée à un client)
├── cashSessionId → CashSession (nullable)
├── saleType (RETAIL | WHOLESALE)
├── paymentMethod (CASH | WAVE | ORANGE_MONEY | CREDIT)
├── totalAmount (FCFA)
├── createdAt

SaleItem
├── id (UUID)
├── saleId → Sale
├── productId → Product
├── variantId → ProductVariant (nullable)
├── conversionId → UnitConversion (nullable)
├── quantity (decimal)
├── unitPrice (FCFA)
├── lineTotal (FCFA)

CashSession
├── id (UUID)
├── shopId → Shop
├── openedBy → User
├── closedBy → User (nullable)
├── openingAmount (FCFA)
├── closingAmountDeclared (FCFA, nullable)
├── closingAmountTheoretical (FCFA, calculé)
├── discrepancy (FCFA, calculé)
├── salesBreakdown (JSON — par mode de paiement)
├── status (OPEN | CLOSED)
├── openedAt, closedAt

Expense
├── id (UUID)
├── shopId → Shop
├── userId → User
├── amount (FCFA)
├── category (RENT | TRANSPORT | SUPPLIES | SALARY | OTHER)
├── customCategory (nullable)
├── description
├── date
├── createdAt, updatedAt

InternalOrder
├── id (UUID)
├── shopId → Shop
├── createdBy → User
├── supplierId → Supplier (nullable)
├── status (PENDING | MANAGER_APPROVED | OWNER_APPROVED | REJECTED | CANCELLED)
├── rejectionReason (nullable)
├── createdAt, updatedAt

InternalOrderItem
├── id (UUID)
├── orderId → InternalOrder
├── productId → Product
├── quantity (decimal)
├── estimatedCost (FCFA, nullable)

OrderApproval
├── id (UUID)
├── orderId → InternalOrder
├── userId → User
├── action (APPROVE | REJECT)
├── comment (nullable)
├── createdAt

Supplier
├── id (UUID)
├── shopId → Shop
├── name
├── phone (nullable)
├── address (nullable)
├── notes (nullable)
├── createdAt, updatedAt

Supply
├── id (UUID)
├── shopId → Shop
├── supplierId → Supplier (nullable)
├── userId → User
├── totalCost (FCFA)
├── createdAt

SupplyItem
├── id (UUID)
├── supplyId → Supply
├── productId → Product
├── quantity (decimal)
├── unitCost (FCFA)

Client
├── id (UUID)
├── shopId → Shop
├── name
├── phone (nullable)
├── notes (nullable)
├── creditBalance (FCFA, calculé — total dû)
├── createdAt, updatedAt

CreditPayment
├── id (UUID)
├── shopId → Shop
├── clientId → Client
├── saleId → Sale (nullable — le paiement peut couvrir plusieurs ventes)
├── amount (FCFA)
├── receivedBy → User
├── notes (nullable)
├── createdAt

Invoice
├── id (UUID)
├── shopId → Shop
├── saleId → Sale
├── invoiceNumber (string, séquentiel ex: "FAC-2026-0001")
├── totalAmount (FCFA)
├── paymentMethod (CASH | WAVE | ORANGE_MONEY)
├── createdAt

Inventory
├── id (UUID)
├── shopId → Shop
├── conductedBy → User
├── validatedBy → User (nullable)
├── status (IN_PROGRESS | COMPLETED | VALIDATED)
├── totalProducts (int)
├── productsWithDiscrepancy (int)
├── totalDiscrepancyValue (FCFA)
├── notes (nullable)
├── createdAt, completedAt

InventoryItem
├── id (UUID)
├── inventoryId → Inventory
├── productId → Product
├── variantId → ProductVariant (nullable)
├── theoreticalQuantity (decimal)
├── actualQuantity (decimal)
├── discrepancy (decimal, calculé)
├── discrepancyValue (FCFA, calculé)

SyncOperation (local Isar uniquement)
├── id (auto-increment)
├── entity (string — "product", "sale", etc.)
├── entityId (UUID)
├── operation (CREATE | UPDATE | DELETE)
├── payload (JSON)
├── timestamp (DateTime)
├── status (PENDING | SYNCED | FAILED)
├── retryCount (int)

Notification (local)
├── id (UUID)
├── type (ORDER_PENDING | LOW_STOCK | DAILY_SUMMARY)
├── title
├── body
├── data (JSON)
├── isRead (bool)
├── createdAt
```

### Database Design

**PostgreSQL (Supabase) :**
- Toutes les entités ci-dessus sauf SyncOperation et Notification (locales uniquement)
- UUID comme clé primaire partout (compatible sync multi-device)
- `shopId` sur chaque table pour isolation des données par boutique
- Row Level Security (RLS) activée : un utilisateur ne voit que les données de sa boutique

**Indexes critiques :**
```sql
-- Recherche produit rapide
CREATE INDEX idx_product_shop_name ON product(shop_id, name);
CREATE INDEX idx_product_shop_category ON product(shop_id, category);

-- Historique ventes par date
CREATE INDEX idx_sale_shop_created ON sale(shop_id, created_at DESC);

-- Mouvements stock par produit
CREATE INDEX idx_stock_movement_product ON stock_movement(product_id, created_at DESC);

-- Sync : changements depuis timestamp
CREATE INDEX idx_product_updated ON product(shop_id, updated_at);
CREATE INDEX idx_sale_updated ON sale(shop_id, created_at);
-- (idem pour chaque entité synchronisée)
```

**Isar (local) :**

- Collections miroir des entités serveur + SyncOperation + Notification
- Indexes Isar sur les champs de recherche pour performance locale
- Collection `SyncMetadata` pour stocker le `lastSyncTimestamp`
- Schémas versionnés avec migration Isar

### Data Flow

```
ÉCRITURE (ex: nouvelle vente) :
1. UI → Riverpod provider → Repository
2. Repository écrit dans Isar (vente + stock movements) en transaction Isar
3. Repository crée une SyncOperation(PENDING) dans la même transaction
4. UI mise à jour instantanément (< 500ms)
5. Si online → SyncEngine push immédiatement
6. Si offline → SyncOperation reste en queue

LECTURE :
1. UI → Riverpod provider → Repository
2. Repository lit depuis Isar (toujours local, jamais API directe)
3. Données toujours disponibles offline

SYNC (au retour connexion) :
1. SyncEngine détecte connexion (connectivity_plus)
2. PUSH : POST /api/v1/sync/push avec toutes les SyncOperation(PENDING)
3. Backend applique les ops, retourne les IDs confirmés + conflits
4. Client marque les ops comme SYNCED
5. PULL : GET /api/v1/sync/pull?since=lastSyncTimestamp
6. Client applique les changements serveur dans Isar
7. Client met à jour lastSyncTimestamp
```

---

## API Design

### API Architecture

- **Style :** REST
- **Versioning :** URL path (`/api/v1/`)
- **Auth :** JWT Bearer token (Supabase Auth)
- **Format :** JSON
- **Pagination :** Cursor-based (`?cursor=xxx&limit=50`)
- **Erreurs :** Format standard `{ error: string, message: string, statusCode: number }`

### Endpoints

#### Auth
```
POST   /api/v1/auth/register          — Inscription (crée shop + owner)
POST   /api/v1/auth/login             — Connexion (retourne JWT)
POST   /api/v1/auth/refresh           — Refresh token
POST   /api/v1/auth/forgot-password   — Demande reset mot de passe
POST   /api/v1/auth/reset-password    — Reset mot de passe
```

#### Shop & Users
```
GET    /api/v1/shop                   — Détails de la boutique
PATCH  /api/v1/shop                   — Modifier boutique
POST   /api/v1/shop/users             — Inviter un utilisateur (gérant/vendeur)
GET    /api/v1/shop/users             — Liste des utilisateurs de la boutique
PATCH  /api/v1/shop/users/:id         — Modifier rôle/permissions
DELETE /api/v1/shop/users/:id         — Supprimer un utilisateur
```

#### Products
```
GET    /api/v1/products               — Liste produits (paginé, filtrable)
POST   /api/v1/products               — Créer produit
GET    /api/v1/products/:id           — Détail produit
PATCH  /api/v1/products/:id           — Modifier produit
DELETE /api/v1/products/:id           — Supprimer produit (soft delete)
```

#### Product Variants
```
GET    /api/v1/products/:id/variants  — Liste variantes
POST   /api/v1/products/:id/variants  — Créer variante
PATCH  /api/v1/variants/:id           — Modifier variante
DELETE /api/v1/variants/:id           — Supprimer variante
```

#### Unit Conversions
```
GET    /api/v1/products/:id/conversions  — Liste conversions
POST   /api/v1/products/:id/conversions  — Créer conversion
PATCH  /api/v1/conversions/:id           — Modifier conversion
DELETE /api/v1/conversions/:id           — Supprimer conversion
```

#### Stock
```
GET    /api/v1/stock                  — État stock actuel (paginé)
GET    /api/v1/stock/movements        — Historique mouvements (filtrable)
POST   /api/v1/stock/adjustment       — Ajustement manuel
GET    /api/v1/stock/alerts           — Produits en stock bas
```

#### Sales
```
POST   /api/v1/sales                  — Créer vente
GET    /api/v1/sales                  — Historique ventes (paginé, filtrable)
GET    /api/v1/sales/:id              — Détail vente
```

#### Cash Sessions
```
POST   /api/v1/cash/open              — Ouvrir caisse
POST   /api/v1/cash/close             — Fermer caisse
GET    /api/v1/cash/current           — Session caisse active
GET    /api/v1/cash/history           — Historique sessions
```

#### Expenses
```
POST   /api/v1/expenses               — Créer dépense
GET    /api/v1/expenses               — Liste dépenses (filtrable)
PATCH  /api/v1/expenses/:id           — Modifier dépense
DELETE /api/v1/expenses/:id           — Supprimer dépense
```

#### Internal Orders
```
POST   /api/v1/orders                 — Créer commande
GET    /api/v1/orders                 — Liste commandes (filtrable par statut)
GET    /api/v1/orders/:id             — Détail commande
POST   /api/v1/orders/:id/approve     — Approuver commande
POST   /api/v1/orders/:id/reject      — Rejeter commande (body: reason)
POST   /api/v1/orders/:id/cancel      — Annuler commande (créateur uniquement)
```

#### Suppliers
```
GET    /api/v1/suppliers              — Liste fournisseurs
POST   /api/v1/suppliers              — Créer fournisseur
PATCH  /api/v1/suppliers/:id          — Modifier fournisseur
DELETE /api/v1/suppliers/:id          — Supprimer fournisseur
```

#### Supplies (Approvisionnements)
```
POST   /api/v1/supplies               — Enregistrer approvisionnement
GET    /api/v1/supplies               — Historique approvisionnements
GET    /api/v1/supplies/:id           — Détail approvisionnement
```

#### Clients (CRM)
```
GET    /api/v1/clients               — Liste clients (paginé, recherche nom/téléphone)
POST   /api/v1/clients               — Créer client
GET    /api/v1/clients/:id           — Détail client (fiche + solde crédit)
PATCH  /api/v1/clients/:id           — Modifier client
GET    /api/v1/clients/:id/purchases — Historique achats du client
GET    /api/v1/clients/:id/credits   — Historique crédits et paiements
POST   /api/v1/clients/:id/pay       — Enregistrer un paiement crédit
GET    /api/v1/clients/debtors       — Liste clients avec crédit en cours
```

#### Invoices (Factures)
```
GET    /api/v1/invoices               — Liste factures (paginé, filtrable)
GET    /api/v1/invoices/:id           — Détail facture
GET    /api/v1/invoices/:id/pdf       — Télécharger facture en PDF
```

#### Inventories
```
POST   /api/v1/inventories            — Lancer un inventaire
GET    /api/v1/inventories            — Historique inventaires
GET    /api/v1/inventories/:id        — Détail inventaire (items + écarts)
PATCH  /api/v1/inventories/:id        — Ajouter/modifier items comptés
POST   /api/v1/inventories/:id/validate — Valider l'inventaire (gérant/patron)
```

#### Reports
```
GET    /api/v1/reports/revenue        — CA (journalier, par période)
GET    /api/v1/reports/stock           — État stock + mouvements
GET    /api/v1/reports/losses          — Pertes (frotte, expirations)
```

#### Sync
```
POST   /api/v1/sync/push              — Client envoie ses opérations
GET    /api/v1/sync/pull?since={ts}   — Client récupère les changements serveur
```

#### Notifications
```
POST   /api/v1/notifications/register — Enregistrer device token FCM
GET    /api/v1/notifications           — Liste notifications (in-app)
PATCH  /api/v1/notifications/:id/read — Marquer comme lu
```

### Authentication & Authorization

**Flow d'authentification :**
```
1. POST /auth/register → Supabase crée le user, retourne JWT + refresh
2. POST /auth/login → Supabase vérifie, retourne JWT + refresh
3. Client stocke les tokens en secure storage (Flutter)
4. Chaque requête API inclut: Authorization: Bearer <jwt>
5. NestJS JwtGuard valide le token, extrait userId + shopId
6. RolesGuard vérifie le rôle + permissions pour l'endpoint
```

**Permissions par rôle (défaut) :**

| Permission | Owner | Manager | Seller |
|-----------|-------|---------|--------|
| POS (vente) | oui | oui | oui |
| Voir prix d'achat | oui | oui | non |
| Modifier prix | oui | oui | non |
| Stock (lecture) | oui | oui | oui |
| Stock (écriture) | oui | oui | non |
| Caisse | oui | oui | non |
| Dépenses | oui | oui | non |
| Commandes (créer) | oui | oui | oui |
| Commandes (approuver) | oui | oui | non |
| CRM clients (lecture) | oui | oui | oui |
| CRM clients (écriture) | oui | oui | non |
| Vente à crédit | oui (toggle) | oui | oui (si activé) |
| Paiement crédit | oui | oui | non |
| Rapports | oui | oui | non |
| Gestion utilisateurs | oui | non | non |
| Configuration boutique | oui | non | non |

Le propriétaire peut toggle on/off chaque permission par utilisateur.

---

## Non-Functional Requirements Coverage

### NFR-001: Performance offline

**Requirement :** Toute opération < 500ms offline

**Solution :**
- Isar exécute les requêtes via indexes natifs — exécution rapide, pas de parsing SQL
- Indexes sur les champs de recherche (nom produit, date vente, catégorie)
- Pagination locale (50 items par page, LIMIT/OFFSET natif SQL)
- Isolates Isar pour les requêtes lourdes (pas de blocage main thread)

**Validation :** Benchmark Flutter integration tests sur device 2GB RAM

---

### NFR-002: Support appareils milieu de gamme

**Requirement :** Fluide sur 2GB RAM, APK < 50MB, mémoire < 150MB

**Solution :**
- Isar : empreinte mémoire faible, base fichier unique
- Images produits : compression JPEG 80%, max 500KB, chargement lazy
- Pas de lib lourde (pas de ML, pas de WebView)
- Tree-shaking Dart, code splitting Flutter

**Validation :** Profiling sur Redmi 9A (2GB RAM, Android 10)

---

### NFR-003: Zéro perte de données

**Requirement :** 100% des transactions offline retrouvées après sync

**Solution :**
- Écriture Isar transactionnelle (ACID)
- SyncOperation persistée en même temps que la donnée (même transaction Isar)
- Status PENDING → SYNCED uniquement après confirmation serveur (HTTP 200)
- En cas d'échec sync : retry avec backoff exponentiel (1s, 2s, 4s, 8s... max 5min)
- SyncOperation jamais supprimée tant que pas SYNCED

**Validation :** Test : 100 ventes offline, kill app, relancer, sync, vérifier 100 côté serveur

---

### NFR-004: Résolution de conflits sync

**Requirement :** Conflits résolus automatiquement, sans intervention utilisateur

**Solution :**

| Type d'entité | Stratégie | Justification |
|--------------|-----------|---------------|
| Product, Supplier, User, Shop | Last-Write-Wins (comparaison `updatedAt`) | Données maîtres, le dernier qui modifie a raison |
| Sale, SaleItem, Expense | Pas de conflit possible | Données immutables, créées une seule fois |
| StockMovement | Merge additif | Les mouvements sont des événements, on les additionne |
| CashSession | Device-owner wins | Une seule caisse active, le device qui l'a ouverte la ferme |
| InternalOrder | Statut le plus avancé gagne | PENDING < APPROVED < REJECTED |

**Validation :** Tests d'intégration simulant des modifications concurrentes sur 2 devices

---

### NFR-005: Disponibilité backend 99%

**Requirement :** Uptime ≥ 99%

**Solution :**
- Supabase : SLA 99.9% sur plan Pro
- Railway : auto-restart, health checks
- L'app fonctionne à 100% offline pendant les pannes

**Validation :** Monitoring uptime (UptimeRobot ou équivalent gratuit)

---

### NFR-006: Authentification sécurisée

**Requirement :** JWT avec sessions expirables

**Solution :**
- Supabase Auth gère les JWT (access token 1h, refresh token 7j)
- Refresh automatique via Dio interceptor côté Flutter
- Invalidation : Supabase permet de révoquer les refresh tokens
- Tokens stockés en `flutter_secure_storage` (Keychain iOS, Keystore Android)

---

### NFR-007: Chiffrement données locales

**Requirement :** Base locale chiffrée

**Solution :**
- Isar avec chiffrement natif (AES-256)
- Clé de chiffrement générée au premier lancement, stockée en `flutter_secure_storage`
- Sur device rooté, la clé est protégée par le Keystore hardware

---

### NFR-008: Isolation des permissions

**Requirement :** Vendeurs limités, double vérification client+serveur

**Solution :**
- **Client :** Riverpod `PermissionProvider` contrôle la visibilité des écrans et actions
- **Serveur :** NestJS `@Roles()` decorator + `RolesGuard` sur chaque endpoint
- **DB :** Row Level Security PostgreSQL — filtre par shopId

---

### NFR-009: Interface accessible

**Requirement :** Gros boutons, navigation simple

**Solution :**
- Design system avec `minTapTarget: 48dp`
- Bottom nav (mobile) avec 4-5 items max, labels texte
- Navigation rail (desktop/tablette) avec icônes + labels
- Pas de gestes complexes pour actions critiques
- Confirmation dialog pour actions destructives

---

### NFR-010: Langue française

**Requirement :** Tout en français, FCFA

**Solution :**
- Fichier de strings centralisé (pas de i18n framework, juste une classe de constantes)
- Formatage : `intl` package avec locale `fr_FR`
- Devise FCFA : pas de décimales (montants entiers)

---

### NFR-011: Onboarding rapide

**Requirement :** Setup < 5 min

**Solution :**
- Wizard 4 étapes : 1. Créer compte → 2. Nommer boutique + type business → 3. Ajouter premier produit → 4. Prêt
- Catégories prédéfinies par type de business (fruits/légumes pour FRESH_PRODUCE, etc.)
- Skip possible sur l'étape produit

---

### NFR-012: Multi-plateforme

**Requirement :** Android + iOS + Desktop

**Solution :**
- Flutter unique codebase
- Plugins compatibles toutes plateformes (Isar, Dio, go_router)
- Conditional imports pour les rares cas platform-specific (secure storage, file paths)

---

### NFR-013: API REST standard

**Requirement :** REST, versioning, Swagger

**Solution :**
- NestJS avec `@nestjs/swagger` → Swagger UI auto-généré à `/api/docs`
- Versioning URL `/api/v1/`
- DTOs validés avec `class-validator`

---

### NFR-014: Couverture de tests 70%

**Requirement :** Tests sur logique métier critique

**Solution :**
- **Flutter :** unit tests (calcul prix frotte, conversions, stock) + widget tests (POS flow)
- **NestJS :** unit tests (services) + e2e tests (endpoints avec DB test)
- **Sync :** integration tests (offline → online → verify data)
- CI : `flutter test --coverage` + `jest --coverage` dans GitHub Actions

---

### NFR-015: Interface responsive

**Requirement :** Adaptatif mobile/tablette/desktop

**Solution :**
- 3 breakpoints : mobile (< 600dp), tablette (600-1024dp), desktop (> 1024dp)
- `LayoutBuilder` pour adapter les écrans
- Mobile : bottom nav, single column, full-screen modals
- Desktop : sidebar nav, master-detail, dialogs

---

## Security Architecture

### Authentication

- **Méthode :** Supabase Auth (email/password) → JWT
- **Access token :** 1 heure, auto-refresh
- **Refresh token :** 7 jours, stocké en secure storage
- **Réinitialisation :** Email via Supabase (magic link ou code)

### Authorization

- **Modèle :** RBAC statique (3 rôles) + toggles par utilisateur
- **Enforcement :** Triple couche
  1. Flutter UI : masquage des écrans/actions non autorisés
  2. NestJS Guards : `@Roles('OWNER', 'MANAGER')` sur les endpoints
  3. PostgreSQL RLS : `shop_id = auth.jwt().shop_id`

### Data Encryption

- **En transit :** HTTPS/TLS 1.2+ (Supabase + Railway forcent HTTPS)
- **Au repos (serveur) :** Supabase chiffre PostgreSQL par défaut (AES-256)
- **Au repos (client) :** Isar chiffrement natif AES-256, clé dans secure storage hardware

### Security Best Practices

- Validation input : `class-validator` côté NestJS, validation formulaire côté Flutter
- SQL injection : Prisma (requêtes paramétrées, pas de raw SQL)
- Rate limiting : `@nestjs/throttler` (ex : 100 req/min par IP)
- CORS : restreint aux domaines autorisés
- Pas de données sensibles dans les logs (mot de passe, tokens)
- Headers sécurité : Helmet middleware NestJS

---

## Scalability & Performance

### Scaling Strategy (Phase 1)

**Phase 1 = scaling vertical uniquement.** Volume attendu :
- < 100 boutiques
- < 1 000 ventes/jour total
- < 10 000 produits par boutique

**Supabase :** Free tier → Pro tier si besoin (8GB DB, 100K auth users)
**Railway :** Single instance NestJS, vertical scaling (512MB → 2GB RAM)

Pas de load balancer, pas de replicas, pas de cache Redis — overkill pour Phase 1.

### Performance Optimization

- **Client :** Isar indexes, pagination, lazy image loading
- **Serveur :** Prisma query optimization, indexes PostgreSQL
- **Sync :** Batch push (toutes les ops en une requête), delta pull (seulement les changements)
- **Rapports :** Calculs agrégés côté serveur avec requêtes SQL optimisées

### Caching Strategy

- **Pas de cache serveur en Phase 1** — les requêtes ne sont pas assez fréquentes
- **Client :** Isar EST le cache — toutes les lectures sont locales
- Si besoin futur : Redis pour les rapports agrégés

---

## Reliability & Availability

### High Availability

- **L'app est HA by design** grâce à l'offline-first
- Backend down → l'app continue à fonctionner normalement
- Sync reprend automatiquement quand le backend revient

### Disaster Recovery

- **RPO :** 0 (données locales sur le device + sync vers serveur)
- **RTO :** N/A côté client (toujours disponible), < 1h côté serveur (redéploiement Railway)
- **Backups :** Supabase daily automated backups (plan Pro)

### Monitoring & Alerting

| Outil | Usage | Coût |
|-------|-------|------|
| Supabase Dashboard | Métriques DB, auth, storage | Inclus |
| Railway Logs | Logs NestJS, métriques runtime | Inclus |
| Sentry (Flutter + NestJS) | Crash reporting, error tracking | Free tier |
| UptimeRobot | Monitoring uptime endpoint /health | Gratuit |

**Alertes :**
- Sentry : notification email sur crash ou error spike
- UptimeRobot : notification si /health ne répond plus

---

## Development Architecture

### Code Organization

**Flutter (client) :**
```
lib/
├── main.dart
├── app.dart                    # MaterialApp, routing, theme
├── core/
│   ├── constants/              # Couleurs, strings FR, config
│   ├── theme/                  # ThemeData, responsive breakpoints
│   ├── utils/                  # Helpers (formatage FCFA, dates)
│   ├── network/                # Dio client, interceptors
│   └── sync/                   # SyncEngine, ConflictResolver, SyncQueue
├── data/
│   ├── database/               # Isar tables, DAOs, database class
│   ├── repositories/           # Abstraction CRUD (local + remote)
│   └── datasources/
│       ├── local/              # Isar DAOs
│       └── remote/             # API datasources (Dio)
├── domain/
│   ├── entities/               # Business entities (pures, sans Isar)
│   └── usecases/               # Logique métier (CalcFrottePrice, etc.)
├── presentation/
│   ├── providers/              # Riverpod providers par domaine
│   ├── screens/
│   │   ├── auth/               # Login, Register, ForgotPassword
│   │   ├── onboarding/         # Setup wizard
│   │   ├── dashboard/          # Home, résumé
│   │   ├── pos/                # POS, panier, checkout
│   │   ├── products/           # Catalogue, détail, variantes
│   │   ├── stock/              # Stock, mouvements, alertes
│   │   ├── cash/               # Caisse, ouverture, fermeture
│   │   ├── expenses/           # Dépenses
│   │   ├── orders/             # Commandes internes
│   │   ├── reports/            # Rapports CA, stock, pertes
│   │   ├── suppliers/          # Fournisseurs
│   │   ├── inventory/          # Inventaire physique, écarts
│   │   ├── invoices/           # Factures, PDF, impression
│   │   ├── clients/            # CRM clients, historique, crédits
│   │   ├── settings/           # Config boutique, utilisateurs
│   │   └── notifications/      # Liste notifications
│   └── widgets/                # Composants réutilisables
└── test/
    ├── unit/                   # Tests logique métier
    ├── widget/                 # Tests widgets
    └── integration/            # Tests sync, flows complets
```

**NestJS (backend) :**
```
src/
├── main.ts
├── app.module.ts
├── common/
│   ├── guards/                 # JwtGuard, RolesGuard
│   ├── decorators/             # @Roles(), @CurrentUser()
│   ├── filters/                # Exception filters
│   ├── pipes/                  # Validation pipe
│   └── interceptors/           # Logging, transform
├── modules/
│   ├── auth/                   # AuthModule (Supabase JWT validation)
│   ├── shop/                   # ShopModule (CRUD boutique + users)
│   ├── product/                # ProductModule (CRUD + variantes + conversions)
│   ├── stock/                  # StockModule (mouvements, alertes)
│   ├── sale/                   # SaleModule (ventes détail + gros)
│   ├── cash/                   # CashModule (sessions caisse)
│   ├── expense/                # ExpenseModule
│   ├── order/                  # OrderModule (commandes + workflow)
│   ├── report/                 # ReportModule (agrégations SQL)
│   ├── client/                 # ClientModule (CRM + crédits)
│   ├── supplier/               # SupplierModule
│   ├── notification/           # NotificationModule (FCM)
│   └── sync/                   # SyncModule (push/pull)
├── prisma/
│   ├── schema.prisma           # Schéma DB
│   └── migrations/             # Migrations auto-générées
└── test/
    ├── unit/
    └── e2e/
```

### Testing Strategy

| Type | Outil | Cible | Coverage |
|------|-------|-------|----------|
| Unit (Flutter) | `flutter_test` | Usecases, calculs (frotte, conversions, stock) | > 80% |
| Widget (Flutter) | `flutter_test` | Écrans POS, formulaires | > 60% |
| Integration (Flutter) | `integration_test` | Sync offline→online, flow vente complet | Scénarios clés |
| Unit (NestJS) | Jest | Services, guards, pipes | > 70% |
| E2E (NestJS) | Jest + Supertest | Endpoints API avec DB test | Scénarios clés |

### CI/CD Pipeline

```
GitHub Actions :

PR → main :
  1. flutter analyze (lint)
  2. flutter test --coverage
  3. cd backend && npm test -- --coverage
  4. Reject si coverage < 70% sur logique métier

Merge → main :
  1. Tests (idem ci-dessus)
  2. flutter build apk --release
  3. flutter build ios --release (si signing configuré)
  4. Deploy backend → Railway (auto-deploy depuis main)
  5. Upload APK → Firebase App Distribution (testeurs)
```

---

## Deployment Architecture

### Environments

| Env | DB | Backend | Client | Usage |
|-----|-----|---------|--------|-------|
| `dev` | PostgreSQL local (Docker) | NestJS local (port 3000) | Flutter debug | Développement |
| `staging` | Supabase staging project | Railway staging | APK debug | Tests pré-release |
| `prod` | Supabase prod | Railway prod | APK/IPA release | Production |

### Deployment Strategy

- **Backend :** Git push → Railway auto-deploy (zero-downtime, rolling restart)
- **Mobile :** Build CI → Firebase App Distribution (testeurs) → Play Store (production)
- **Desktop :** Build CI → GitHub Releases (DMG, EXE)

---

## Requirements Traceability

### Functional Requirements Coverage

| FR ID | FR Name | Components Client | Components Serveur |
|-------|---------|-------------------|-------------------|
| FR-001 | Vente détail | POS Screen, SaleProvider, SaleRepo | SaleModule |
| FR-002 | Mode paiement | POS Screen (sélection) | SaleModule (enum) |
| FR-003 | Historique ventes | SalesHistory Screen, SaleProvider | SaleModule (GET /sales) |
| FR-004 | Vente gros | POS Screen (toggle), SaleProvider | SaleModule |
| FR-005 | Unités gros conversion | ProductProvider, POS calcul | ProductModule |
| FR-006 | CRUD produits | Products Screen, ProductProvider | ProductModule |
| FR-007 | Variantes | ProductDetail Screen | ProductModule (variants) |
| FR-008 | Suivi stock | Stock Screen, StockProvider | StockModule |
| FR-009 | Alertes stock | StockAlerts widget, StockProvider | StockModule (alerts) |
| FR-010 | Approvisionnement | Supply Screen, SupplyProvider | StockModule + SupplierModule |
| FR-011 | Config frotte | ProductForm, ProductProvider | ProductModule (frotteRate) |
| FR-012 | Calcul prix frotte | CalcFrottePriceUsecase | ProductModule |
| FR-013 | Conversion vrac→sachet | ConversionConfig Screen | ProductModule (conversions) |
| FR-014 | Déduction stock conversion | SaleProvider (calcul), StockProvider | StockModule |
| FR-015 | Code couleur fraîcheur | FreshnessIndicator widget | StockModule |
| FR-016 | Alerte priorité vente | Dashboard, POS highlight | StockModule |
| FR-017 | Ouverture caisse | Cash Screen, CashProvider | CashModule |
| FR-018 | Fermeture caisse | CashClose Screen, CashProvider | CashModule |
| FR-019 | Dépenses | Expenses Screen, ExpenseProvider | ExpenseModule |
| FR-020 | Création commande | OrderCreate Screen, OrderProvider | OrderModule |
| FR-021 | Validation commande | OrderDetail Screen, OrderProvider | OrderModule (approve/reject) |
| FR-022 | Notification commande | NotificationProvider, FCM | NotificationModule |
| FR-023 | Résumé quotidien | FCM push, DailySummary Screen | NotificationModule (cron) |
| FR-024 | Rapport CA | RevenueReport Screen, ReportProvider | ReportModule |
| FR-025 | Rapport stock | StockReport Screen, ReportProvider | ReportModule |
| FR-026 | Rapport pertes | LossReport Screen, ReportProvider | ReportModule |
| FR-027 | CRUD fournisseurs | Suppliers Screen, SupplierProvider | SupplierModule |
| FR-028 | Historique achats | SupplierDetail Screen | SupplierModule |
| FR-029 | Auth | Auth Screens, AuthProvider | AuthModule |
| FR-030 | Rôles permissions | PermissionProvider, Settings | AuthModule (guards) |
| FR-031 | Offline | Isar, SyncEngine | N/A (client-side) |
| FR-032 | Sync auto | SyncEngine, SyncQueue | SyncModule |
| FR-033 | Backoffice Super Admin | N/A | AdminModule (web) |
| FR-034 | Inventaire hebdo | Inventory Screen, InventoryProvider | StockModule |
| FR-035 | Factures | InvoiceProvider, PDF generation | SaleModule (invoices) |
| FR-036 | Impression thermique | Bluetooth print service (ESC/POS) | N/A (client-side) |
| FR-037 | CRM clients | Clients Screen, ClientProvider | ClientModule |
| FR-038 | Vente à crédit | POS (mode crédit), CreditProvider | ClientModule (credits) |

**Couverture : 38/38 FRs (100%)**

### Non-Functional Requirements Coverage

| NFR ID | NFR Name | Solution | Validation |
|--------|----------|----------|------------|
| NFR-001 | Performance offline | Isar indexes, pagination | Benchmark < 500ms sur device test |
| NFR-002 | Milieu de gamme | Lazy loading, compression images | Profiling Redmi 9A |
| NFR-003 | Zéro perte | Transaction Isar ACID + SyncQueue persistante | Test 100 ventes offline→sync |
| NFR-004 | Conflits sync | LWW / Merge additif par entité | Tests concurrence 2 devices |
| NFR-005 | Uptime 99% | Supabase + Railway managed | UptimeRobot monitoring |
| NFR-006 | Auth JWT | Supabase Auth, secure storage | Tests auth flow |
| NFR-007 | Chiffrement local | Isar chiffrement natif AES-256, clé en keystore | Vérification device rooté |
| NFR-008 | Isolation permissions | Guards NestJS + RLS + UI masquée | Test vendeur→endpoint admin |
| NFR-009 | Interface accessible | 48dp min, labels, nav simple | Revue UX testeurs |
| NFR-010 | Français | Strings centralisées, intl fr_FR | Revue exhaustive |
| NFR-011 | Onboarding < 5min | Wizard 4 étapes | Test chronométré |
| NFR-012 | Multi-plateforme | Flutter cross-platform | Build + test sur 4 plateformes |
| NFR-013 | API REST | NestJS + Swagger | Documentation auto-générée |
| NFR-014 | Tests 70% | Jest + flutter_test, CI gate | Coverage CI |
| NFR-015 | Responsive | 3 breakpoints, LayoutBuilder | Test 3 tailles écran |

**Couverture : 15/15 NFRs (100%)**

---

## Trade-offs & Decision Log

### Decision 1: Monolithe NestJS vs Microservices

**Choix :** Monolithe modulaire
**Gain :** Simplicité de déploiement, pas de coordination distribuée, un seul repo
**Perte :** Scaling indépendant des modules impossible
**Justification :** < 100 boutiques Phase 1 → overkill de faire des microservices. Modules NestJS bien séparés permettent une migration future si besoin.

### Decision 2: Isar vs Drift (SQLite)

**Choix :** Isar
**Gain :** Performance native, chiffrement intégré, code generation type-safe, empreinte mémoire faible
**Perte :** Pas de SQL relationnel complet (liens entre collections au lieu de jointures SQL)
**Justification :** Le volume par boutique est modeste (< 10K produits). Les liens Isar suffisent pour les relations. Les rapports complexes sont calculés côté serveur (PostgreSQL). Performance et chiffrement natif l'emportent.

### Decision 3: Supabase Auth vs Auth custom NestJS

**Choix :** Supabase Auth
**Gain :** Zéro code auth à maintenir, JWT standards, reset password, RLS intégré
**Perte :** Dépendance Supabase, moins de contrôle
**Justification :** Solo founder — chaque heure de code auth en moins = une heure de produit en plus. Migrable vers Auth0 ou custom si besoin.

### Decision 4: Sync push/pull custom vs lib (PowerSync, Brick)

**Choix :** Sync custom
**Gain :** Contrôle total sur la résolution de conflits, pas de dépendance externe lourde
**Perte :** Plus de code à écrire et maintenir
**Justification :** Les stratégies de conflits sont spécifiques au domaine (LWW pour produits, additif pour stock). Une lib générique imposerait des compromis. Le mécanisme est simple (queue + push + pull + resolve).

### Decision 5: Riverpod vs Bloc

**Choix :** Riverpod
**Gain :** Moins de boilerplate, compile-time safety, autodispose, testable
**Perte :** Moins de documentation/exemples que Bloc
**Justification :** Riverpod est plus moderne, plus concis, et le pattern provider-based s'aligne bien avec la structure Repository. Meilleure DX pour solo dev.

---

## Open Issues & Risks

| # | Risque | Impact | Mitigation |
|---|--------|--------|------------|
| 1 | Isar performance sur très gros volumes | Faible — < 10K produits/boutique | Indexes, pagination, requêtes optimisées |
| 2 | Sync conflits non anticipés | Haut — corruption de données | Tests exhaustifs des scénarios de conflit, logs de résolution |
| 3 | Supabase free tier limité | Faible — upgrade à $25/mois | Monitoring usage, upgrade préventif si > 80% quota |
| 4 | FCM non fiable en Afrique | Moyen — notifications manquées | Notifications in-app comme fallback, résumé visible au dashboard |
| 5 | Desktop Flutter moins mature | Faible — UX dégradée | Mobile = priorité, desktop = best-effort Phase 1 |

---

## Assumptions & Constraints

1. Volume modeste : < 100 boutiques, < 10 000 produits/boutique, < 1 000 ventes/jour/boutique
2. Connexion Internet disponible au moins 1x/jour pour sync
3. Un seul device actif par vendeur à la fois (pas de multi-session simultanée)
4. Multi-tenant : isolation par tenantId, chaque boutique est un tenant
5. FCFA uniquement, pas de décimales
6. Pas de migration de données existantes (les boutiques partent de zéro)
7. Solo founder = cycle de dev itératif, pas d'équipe à coordonner

---

## Approval & Sign-off

**Review Status:**
- [ ] Product Owner (Carlos Simporé)

---

## Revision History

| Version | Date | Auteur | Changements |
|---------|------|--------|-------------|
| 1.0 | 2026-04-06 | Carlos Simporé | Architecture initiale Phase 1 |
| 1.1 | 2026-04-06 | Carlos Simporé | Ajout FR-034 inventaire, FR-035 factures, FR-036 impression thermique |
| 1.2 | 2026-04-06 | Carlos Simporé | FR-037 CRM clients, FR-038 vente à crédit, Client/CreditPayment entities, ClientModule, permissions crédit, traceability 38/38 FRs |

---

## Next Steps

Lancer `/sprint-planning` pour :
- Décomposer les 8 epics en user stories détaillées
- Estimer la complexité de chaque story
- Planifier les sprints d'implémentation

Documentation complète Phase 1 :
- Brief Phase 1
- PRD (32 FRs, 15 NFRs, 8 Epics)
- Architecture (ce document)

---

**Ce document a été créé avec la méthode BMAD v6 — Phase 3 (Solutioning)**

---

## Appendix A: Technology Evaluation

| Critère | Isar | Hive | Drift (SQLite) |
|---------|------|------|----------------|
| Performance | Excellent | Bon | Excellent |
| Chiffrement | Natif (AES-256) | Non | SQLCipher |
| Flutter-native | Oui | Oui | Oui |
| Relations | Links entre collections | Non | SQL complet (jointures, FK) |
| Requêtes | Index-based, rapides | Très limitées | SQL natif |
| Schema | Code generation, type-safe | Manuelles | Code generation, type-safe |
| Maintenance | Active | Active | Active, mature |
| **Verdict** | **Choisi** — performant, natif, chiffrement intégré | Écarté — limité | Alternative valide si SQL requis |

| Critère | Riverpod | Bloc | GetX |
|---------|----------|------|------|
| Boilerplate | Faible | Élevé | Très faible |
| Testabilité | Excellente | Excellente | Faible |
| Type safety | Compile-time | Runtime | Runtime |
| Maturité | Stable | Très mature | Stable |
| **Verdict** | **Choisi** — meilleure DX solo dev | Alternative valide | Écarté |

---

## Appendix B: Capacity Planning

| Métrique | Phase 1 (3 boutiques) | Phase 1 (100 boutiques) |
|----------|-----------------------|-------------------------|
| Produits total serveur | ~500 | ~50 000 |
| Ventes/jour total | ~50 | ~5 000 |
| Stockage DB | ~10 MB | ~1 GB |
| Stockage images | ~50 MB | ~5 GB |
| Requêtes API/jour | ~500 | ~50 000 |
| **Verdict** | Free tier Supabase OK | Pro tier Supabase nécessaire |

---

## Appendix C: Cost Estimation

| Poste | Phase 1 (3 testeurs) | Phase 1 (100 boutiques) |
|-------|---------------------|------------------------|
| Supabase | $0 (free tier) | $25/mois (Pro) |
| Railway (NestJS) | $5/mois | $10-20/mois |
| Firebase (FCM) | $0 | $0 |
| Sentry | $0 (free tier) | $0 (free tier) |
| Domain + SSL | ~$10/an | ~$10/an |
| **Total mensuel** | **~$5** | **~$35-45** |
