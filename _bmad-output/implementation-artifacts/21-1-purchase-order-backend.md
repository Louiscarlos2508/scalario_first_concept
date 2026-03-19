# Story 21.1 — Backend : Modèles PurchaseOrder + endpoints CRUD

## Metadata

- **Epic:** Epic 21 — Commandes fournisseurs + réception liée
- **Story ID:** 21-1-purchase-order-backend
- **Status:** done
- **Priority:** High
- **Depends on:** Epics 1–9, Epic 3 (contacts fournisseurs), Epic 16 (hub inventaire)

---

## Story

**As a** manager (Moussa),
**I want** a purchase order API to create, update, and track supplier orders,
**So that** expected deliveries are documented and reception variances are traceable (FR79, FR80).

---

## Acceptance Criteria

### AC1 — Migration Prisma

**Given** les tables `purchase_orders` et `purchase_order_lines` sont absentes du schéma `shared`
**When** la migration Prisma s'exécute
**Then** les tables sont créées avec :
- `purchase_orders` : `id, supplier_id (UUID → contacts.id), status, expected_date, notes, tenant_id, created_by, created_at, updated_at`
- `purchase_order_lines` : `id, purchase_order_id, catalog_item_id, expected_quantity, received_quantity (null), quality_notes (null), created_at`
**And** aucune donnée existante n'est affectée

### AC2 — CRUD commandes

**Given** un manager authentifié avec rôle owner ou manager
**When** `POST /api/v1/purchase-orders` est appelé avec `{supplierId, lines: [{catalogItemId, expectedQuantity}], expectedDate?, notes?}`
**Then** une `PurchaseOrder` est créée avec `status = 'draft'` et ses lignes associées
**And** la réponse inclut l'objet complet avec lignes

**Given** `GET /api/v1/purchase-orders` est appelé
**When** des filtres sont passés (`?status=confirmed&supplierId=uuid&from=date&to=date`)
**Then** seules les commandes correspondant aux filtres sont retournées, triées par `created_at` DESC
**And** chaque commande inclut : `id, status, expectedDate, supplierName, lineCount, tenantId`

**Given** `GET /api/v1/purchase-orders/:id` est appelé
**When** la commande existe pour le tenant courant
**Then** la réponse inclut l'objet complet avec `lines[]` (chaque ligne : catalogItemId, itemName, expectedQuantity, receivedQuantity, qualityNotes)

**Given** `PATCH /api/v1/purchase-orders/:id` est appelé avec `{status: 'confirmed'}`
**When** la transition de statut est valide (ex: draft → confirmed)
**Then** le statut est mis à jour et la réponse inclut l'objet mis à jour
**And** une transition invalide (ex: received → draft) retourne HTTP 422 avec message d'erreur

### AC3 — Endpoint réception

**Given** `POST /api/v1/purchase-orders/:id/receive` est appelé avec `{lines: [{purchaseOrderLineId, receivedQuantity, qualityNotes?}]}`
**When** la commande est en statut `confirmed` ou `partially_received`
**Then** pour chaque ligne : `receivedQuantity` est enregistrée, `qualityNotes` sauvegardée
**And** le système calcule la variance = `receivedQuantity - expectedQuantity` pour chaque ligne
**And** si toutes les lignes sont reçues → statut passe à `received`
**And** si certaines lignes sont partiellement reçues → statut passe à `partially_received`
**And** pour chaque ligne reçue : un `InventoryMovement` de type `DELIVERY` est créé avec `quantity = receivedQuantity`, `referenceId = purchaseOrderId`
**And** l'événement `DeliveryReceived` est émis (payload : lignes reçues, tenantId)

### AC4 — Réception sans commande associée

**Given** `POST /api/v1/inventory/movements` est appelé avec `{type: 'DELIVERY', catalogItemId, quantity}`
**When** aucun `purchaseOrderId` n'est fourni
**Then** le mouvement est créé normalement (comportement inchangé — Epic 16 Story 16.1)

### AC5 — Tests backend

**Given** `purchase-orders.service.spec.ts`
**When** les tests sont exécutés
**Then** :
- Créer une PO avec 2 lignes → 2 `PurchaseOrderLine` créées avec `receivedQuantity = null`
- Transition valide `draft → confirmed` → OK ; transition invalide `received → draft` → erreur 422
- Réception complète (toutes lignes reçues) → statut = `received`, `InventoryMovement` créés
- Réception partielle → statut = `partially_received`
- Variance = reçu − commandé, calculée correctement pour chaque ligne

---

## Tasks/Subtasks

- [ ] **Task 1 : Migration Prisma**
  - [ ] Ajouter modèles `PurchaseOrder` et `PurchaseOrderLine` dans `schema.prisma`
  - [ ] Statuts valides : `draft | confirmed | partially_received | received | cancelled`
  - [ ] Relation `PurchaseOrder ↔ Contact (supplier_id)` et `PurchaseOrderLine ↔ CatalogItem`
  - [ ] Générer migration : `npx prisma migrate dev --name add_purchase_orders`

- [ ] **Task 2 : Module + Service + Controller**
  - [ ] Créer `purchase-orders.module.ts`, `purchase-orders.service.ts`, `purchase-orders.controller.ts`
  - [ ] Implémenter `createPurchaseOrder()`, `listPurchaseOrders()`, `getPurchaseOrder()`, `updateStatus()`
  - [ ] Implémenter `receivePurchaseOrder()` avec calcul variance + création InventoryMovements
  - [ ] Émettre `DeliveryReceived` via EventBus

- [ ] **Task 3 : DTOs**
  - [ ] `create-purchase-order.dto.ts` : `supplierId`, `lines[]`, `expectedDate?`, `notes?`
  - [ ] `receive-purchase-order.dto.ts` : `lines[]` avec `purchaseOrderLineId`, `receivedQuantity`, `qualityNotes?`
  - [ ] Validation `class-validator` sur tous les champs

- [ ] **Task 4 : Guards + permissions**
  - [ ] `TenantGuard` + `@Roles('owner', 'manager')` sur tous les endpoints
  - [ ] Endpoint `GET /stats` : count POs `confirmed` + `partially_received`

- [ ] **Task 5 : Enregistrement dans app.module.ts**
  - [ ] Importer `PurchaseOrdersModule` dans `AppModule`

- [ ] **Task 6 : Tests unitaires**
  - [ ] Créer `purchase-orders.service.spec.ts` avec les 5 scénarios AC5

---

## Files to Create

- `apps/backend/src/shared/purchase-orders/purchase-orders.module.ts`
- `apps/backend/src/shared/purchase-orders/purchase-orders.controller.ts`
- `apps/backend/src/shared/purchase-orders/purchase-orders.service.ts`
- `apps/backend/src/shared/purchase-orders/dto/create-purchase-order.dto.ts`
- `apps/backend/src/shared/purchase-orders/dto/receive-purchase-order.dto.ts`
- `apps/backend/src/shared/purchase-orders/purchase-orders.service.spec.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_purchase_orders/migration.sql`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — ajouter `PurchaseOrder`, `PurchaseOrderLine`
- `apps/backend/src/app.module.ts` — importer `PurchaseOrdersModule`
