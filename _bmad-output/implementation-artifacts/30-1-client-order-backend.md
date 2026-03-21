# Story 30.1 — Backend — ClientOrder + ClientOrderLine, migration, endpoints CRUD (FR107, FR108)

## Metadata

- **Epic:** Epic 30 — Commandes Clients & Labels Rôle
- **Story ID:** 30-1-client-order-backend
- **Status:** review
- **Priority:** High
- **Phase:** 2a
- **Depends on:** Epic 1 (Kernel + RBAC), Epic 2 (catalog), Epic 3 (contacts), Epic 4 (transactions), Epic 5 (inventory/StockMovement)

---

## Story

**As a** commercial or manager,
**I want** a `ClientOrder` and `ClientOrderLine` backend with CRUD endpoints, automatic order numbering (CO-XXXX), stock validation at confirmation, and StockMovement RESERVATION on confirmation,
**So that** client orders can be created, tracked, and confirmed with stock integrity guarantees (FR107, FR108).

---

## Acceptance Criteria

### AC1 — Migration Prisma client_orders + client_order_lines

**Given** le fichier `schema.prisma` est mis à jour avec les modèles `ClientOrder` et `ClientOrderLine`
**When** la migration est appliquée
**Then** les tables `client_orders` et `client_order_lines` existent dans le schéma `shared` avec les colonnes : `id`, `order_number` (unique), `tenant_id`, `customer_id`, `status` (default `draft`), `deposit_amount` (nullable), `deposit_paid_at` (nullable), `notes` (nullable), `created_by`, `prepared_by` (nullable), `delivered_by` (nullable), `created_at`, `delivered_at` (nullable)
**And** `client_order_lines` : `id`, `client_order_id`, `catalog_item_id`, `variant_id` (nullable), `quantity`, `unit_price`, `delivered_qty` (default 0)

### AC2 — POST /api/v1/client-orders — création en draft

**Given** un utilisateur authentifié envoie `POST /api/v1/client-orders` avec `{ customerId, lines: [{catalogItemId, variantId?, quantity, unitPrice}], notes?, depositAmount? }`
**When** la requête est valide
**Then** une commande est créée en statut `draft` avec un `orderNumber` au format `CO-XXXX` (4 chiffres minimum, séquence par tenant)
**And** les lignes sont créées avec `deliveredQty = 0`
**And** la commande créée est retournée en `201 Created` avec ses lignes
**When** `customerId` est absent ou invalide
**Then** la réponse est `400 Bad Request`

### AC3 — GET /api/v1/client-orders — liste filtrée

**Given** un utilisateur appelle `GET /api/v1/client-orders`
**When** les filtres optionnels `status`, `customerId`, `dateFrom`, `dateTo` sont passés en query params
**Then** la liste des commandes du tenant est retournée filtrée et triée par `createdAt DESC`
**And** les commandes d'autres tenants ne sont jamais retournées

### AC4 — GET /api/v1/client-orders/:id — détail

**Given** un utilisateur appelle `GET /api/v1/client-orders/:id`
**When** la commande appartient au tenant courant
**Then** la commande complète avec ses lignes est retournée en `200 OK`
**When** la commande n'appartient pas au tenant courant
**Then** la réponse est `404 Not Found`

### AC5 — PATCH /api/v1/client-orders/:id — modification draft

**Given** un utilisateur envoie `PATCH /api/v1/client-orders/:id`
**When** la commande est en statut `draft`
**Then** les champs `notes`, `depositAmount`, et les lignes peuvent être mis à jour
**When** la commande n'est pas en statut `draft`
**Then** la réponse est `422 Unprocessable Entity` : `"Seules les commandes en statut draft peuvent être modifiées"`

### AC6 — POST /api/v1/client-orders/:id/confirm — validation stock + RESERVATION

**Given** un manager ou owner appelle `POST /api/v1/client-orders/:id/confirm` sur une commande `draft`
**When** le stock disponible est suffisant pour toutes les lignes
**Then** le statut passe à `confirmed`
**And** un `StockMovement` de type `RESERVATION` est créé par ligne (quantité réservée, référence `clientOrderId`)
**When** le stock est insuffisant pour au moins une ligne
**Then** la réponse est `422 Unprocessable Entity` : `"Stock insuffisant pour : [nom article]"`
**And** aucun mouvement de stock n'est créé

### AC7 — POST /api/v1/client-orders/:id/cancel — annulation

**Given** un manager ou owner appelle `POST /api/v1/client-orders/:id/cancel`
**When** la commande est en statut `draft` ou `confirmed`
**Then** le statut passe à `cancelled`
**And** si la commande était `confirmed`, les `StockMovement RESERVATION` liés sont annulés via un mouvement inverse `RESERVATION_RELEASE`

### AC8 — GET /api/v1/client-orders/kpis — agrégats dashboard

**Given** un utilisateur appelle `GET /api/v1/client-orders/kpis`
**When** la requête est authentifiée
**Then** la réponse est `200 OK` avec `{ inProgressCount: number, pendingRevenue: number }` pour les statuts actifs (`confirmed`, `in-progress`, `ready`)

---

## Tasks / Subtasks

- [x] **Task 1 — Migration Prisma** (AC1)
  - [x] Ajouter les modèles `ClientOrder` et `ClientOrderLine` dans `schema.prisma` (@@schema("shared"))
  - [x] Vérifier que le type `RESERVATION` existe dans l'enum des types de `StockMovement` — ajouter `RESERVATION` et `RESERVATION_RELEASE` si absents
  - [x] Générer et vérifier la migration SQL

- [x] **Task 2 — ClientOrderModule NestJS** (AC2–AC8)
  - [x] Créer `client-order.module.ts`, `client-order.controller.ts`, `client-order.service.ts`
  - [x] Créer `create-client-order.dto.ts` et `update-client-order.dto.ts`
  - [x] Importer `ClientOrderModule` dans `app.module.ts`

- [x] **Task 3 — Numérotation automatique CO-XXXX** (AC2)
  - [x] Implémenter la logique : `SELECT MAX(order_number) WHERE tenantId = ?`, parser, incrémenter, formatter `CO-${String(n+1).padStart(4, '0')}`
  - [x] Gérer le cas premier ordre du tenant (`CO-0001`)

- [x] **Task 4 — CRUD endpoints** (AC2, AC3, AC4, AC5)
  - [x] `POST /client-orders` — créer commande draft avec lignes
  - [x] `GET /client-orders` — liste avec filtres status/customerId/dateFrom/dateTo
  - [x] `GET /client-orders/:id` — détail avec lignes
  - [x] `PATCH /client-orders/:id` — modification si draft

- [x] **Task 5 — Endpoint confirm + validation stock** (AC6)
  - [x] `POST /client-orders/:id/confirm` — vérifier stock disponible par ligne
  - [x] Créer `StockMovement RESERVATION` par ligne si stock OK
  - [x] Retourner 422 avec message explicite si stock insuffisant

- [x] **Task 6 — Endpoint cancel** (AC7)
  - [x] `POST /client-orders/:id/cancel` — transition vers `cancelled`
  - [x] Si `confirmed`, créer mouvements `RESERVATION_RELEASE` pour annuler les réservations

- [x] **Task 7 — Endpoint kpis** (AC8)
  - [x] `GET /client-orders/kpis` — déclarer AVANT `/:id` dans le contrôleur pour éviter conflit routing NestJS
  - [x] Agréger `inProgressCount` et `pendingRevenue` sur les statuts actifs

- [x] **Task 8 — Tests unitaires** (AC2–AC8)
  - [x] Tests service : création, confirmation (stock OK / insuffisant), annulation, kpis
  - [x] Mocks PrismaService

---

## Files to Create

- `apps/backend/prisma/migrations/YYYYMMDD_add_client_orders/migration.sql`
- `apps/backend/src/shared/client-orders/client-order.module.ts`
- `apps/backend/src/shared/client-orders/client-order.controller.ts`
- `apps/backend/src/shared/client-orders/client-order.service.ts`
- `apps/backend/src/shared/client-orders/dto/create-client-order.dto.ts`
- `apps/backend/src/shared/client-orders/dto/update-client-order.dto.ts`
- `apps/backend/src/shared/client-orders/client-order.service.spec.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — modèles `ClientOrder`, `ClientOrderLine` ; types `RESERVATION` / `RESERVATION_RELEASE` dans enum StockMovement
- `apps/backend/src/app.module.ts` — importer `ClientOrderModule`

---

## Dev Notes

### orderNumber — séquence par tenant

```typescript
// Récupérer le dernier numéro du tenant
const last = await this.prisma.clientOrder.findFirst({
  where: { tenantId },
  orderBy: { orderNumber: 'desc' },
  select: { orderNumber: true },
});
const lastN = last ? parseInt(last.orderNumber.replace('CO-', ''), 10) : 0;
const orderNumber = `CO-${String(lastN + 1).padStart(4, '0')}`;
```

### Routing NestJS — kpis avant /:id

L'endpoint `/kpis` doit être déclaré avant `/:id` dans le contrôleur, sinon NestJS interprète `kpis` comme un paramètre d'id :

```typescript
@Get('kpis')      // ← en premier
async getKpis(...) {}

@Get(':id')       // ← en second
async findOne(...) {}
```

### Type RESERVATION dans StockMovement

Vérifier dans `schema.prisma` si le type de mouvement est un enum ou une String libre. Si enum, ajouter `RESERVATION` et `RESERVATION_RELEASE`. Si String libre, utiliser ces valeurs directement sans migration supplémentaire.

### Rôles autorisés

- Tous les rôles peuvent lire (GET)
- `confirm` et `cancel` : `@Roles('owner', 'manager')`
- `create` et `update` : `@Roles('owner', 'manager', 'commercial')`

---

## References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 30-1]
- [Source: _bmad-output/planning-artifacts/prd.md — FR107, FR108]
- [Source: docs/architecture-scalario-2026-03-08.md — Section 4.2.13 ClientOrder, Section 5.2 Prisma models ClientOrder/ClientOrderLine]

---

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-6

### Debug Log References
- Pre-existing test failures in purchase-orders.service.spec.ts and retail-session.controller.spec.ts confirmed not caused by this story

### Completion Notes List
- Implemented ClientOrder + ClientOrderLine Prisma models in shared schema
- CO-XXXX auto-numbering via findFirst+parse+increment pattern (race-condition acceptable for MVP)
- RESERVATION/RESERVATION_RELEASE inventory movements for stock locking at confirm/cancel
- Stock validation: physical stock - active reservations per line (separate aggregation, no getCurrentStock modification needed)
- /kpis declared before /:id in controller to avoid NestJS route collision
- 13/13 unit tests pass; 2 pre-existing failures in other suites confirmed not regressions

### File List
- apps/backend/prisma/migrations/20260320050000_add_client_orders/migration.sql
- apps/backend/prisma/schema.prisma (modified — ClientOrder, ClientOrderLine models + RESERVATION types in comment)
- apps/backend/src/shared/client-orders/client-orders.module.ts
- apps/backend/src/shared/client-orders/client-orders.controller.ts
- apps/backend/src/shared/client-orders/client-orders.service.ts
- apps/backend/src/shared/client-orders/dto/create-client-order.dto.ts
- apps/backend/src/shared/client-orders/client-orders.service.spec.ts
- apps/backend/src/app.module.ts (modified — ClientOrdersModule registered)
