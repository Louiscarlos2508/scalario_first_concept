# Story 22.1 — Backend : minStockLevel sur CatalogItem + endpoint alertes

## Metadata

- **Epic:** Epic 22 — Alertes stock bas + notifications
- **Story ID:** 22-1-min-stock-level-backend
- **Status:** done
- **Priority:** High
- **Depends on:** Epics 1–9, Epic 5 (mouvements de stock)

---

## Story

**As a** backend developer,
**I want** a low-stock alert evaluation triggered after every stock-decrementing movement, surfaced via a dedicated endpoint,
**So that** the backoffice can display real-time low-stock signals (FR81, FR82).

---

## Acceptance Criteria

### AC1 — Champ minStockLevel sur CatalogItem

**Given** la migration Prisma pour `minStockLevel` sur `CatalogItem` est définie
**When** le développeur vérifie `schema.prisma`
**Then** si le champ n'est pas encore appliqué, une migration `add_min_stock_level_to_catalog_items` est générée et appliquée
**And** le champ est `Decimal?` nullable — absence = pas d'alerte pour cet article

### AC2 — Endpoint PATCH minStockLevel

**Given** `PATCH /api/v1/catalog/:id` est appelé avec `{ "minStockLevel": 5 }`
**When** la requête est validée
**Then** le champ `minStockLevel` est mis à jour pour l'article du tenant
**And** la réponse renvoie l'article mis à jour avec `minStockLevel`
**And** l'endpoint est protégé par `TenantGuard` et `RolesGuard(['owner', 'manager'])`

### AC3 — Évaluation post-mouvement de stock

**Given** un `InventoryMovement` de type `SALE`, `LOSS`, `TRANSFER_OUT`, ou `ADJUSTMENT` (quantité négative) est créé
**When** l'`InventoryService` traite le mouvement
**Then** pour chaque `catalogItemId` concerné, si `stockQuantity ≤ minStockLevel` et `minStockLevel IS NOT NULL`
**And** une entrée `StockAlert` est upserted (ou un événement `LowStockDetected` est émis sur l'Event Bus)
**And** si `stockQuantity > minStockLevel`, aucune alerte n'est créée / l'alerte existante est résolue automatiquement

### AC4 — Endpoint GET alertes actives

**Given** `GET /api/v1/stock-alerts` est appelé
**When** le backend répond
**Then** la réponse renvoie la liste des articles dont `stockQuantity ≤ minStockLevel` pour le tenant courant
**And** chaque entrée inclut : `catalogItemId`, `itemName`, `stockQuantity`, `minStockLevel`, `deficit` (minStockLevel − stockQuantity)
**And** les résultats sont triés par `deficit` décroissant (articles les plus critiques en premier)
**And** l'endpoint supporte `?limit=` et `?offset=` pour la pagination

### AC5 — Endpoint GET count alertes actives

**Given** `GET /api/v1/stock-alerts/count` est appelé
**When** le backend répond
**Then** la réponse renvoie `{ criticalCount: number }` — nombre d'articles sous seuil pour le tenant
**And** l'endpoint est protégé par `TenantGuard` et `RolesGuard(['owner', 'manager'])`

---

## Tasks/Subtasks

- [ ] **Task 1 : Migration Prisma minStockLevel**
  - [ ] Vérifier si `minStockLevel` existe déjà sur `CatalogItem` dans `schema.prisma`
  - [ ] Si absent : ajouter `minStockLevel Decimal? @map("min_stock_level") @db.Decimal(10, 2)`
  - [ ] Générer migration si nécessaire

- [ ] **Task 2 : Module StockAlerts**
  - [ ] Créer `stock-alerts.module.ts`, `stock-alerts.service.ts`, `stock-alerts.controller.ts`
  - [ ] `getAlerts(tenantId, {limit, offset})` : query `WHERE retail_products.stock_quantity <= catalog_items.min_stock_level`
  - [ ] `getAlertsCount(tenantId)` : count du même filtre

- [ ] **Task 3 : Évaluation post-mouvement**
  - [ ] Dans `inventory.service.ts`, après mouvement SALE/LOSS/TRANSFER_OUT/ADJUSTMENT décrémentant
  - [ ] Émettre `LowStockDetected { tenantId, catalogItemId, itemName, stockQuantity, minStockLevel }` via EventBus
  - [ ] Ou: appel direct `StockAlertsService.evaluate(catalogItemId, tenantId)`

- [ ] **Task 4 : DTO**
  - [ ] `StockAlertDto` : `catalogItemId, itemName, stockQuantity, minStockLevel, deficit`

- [ ] **Task 5 : Enregistrement**
  - [ ] Importer `StockAlertsModule` dans `AppModule`

---

## Files to Create

- `apps/backend/src/shared/stock-alerts/stock-alerts.module.ts`
- `apps/backend/src/shared/stock-alerts/stock-alerts.service.ts`
- `apps/backend/src/shared/stock-alerts/stock-alerts.controller.ts`
- `apps/backend/src/shared/stock-alerts/dto/stock-alert.dto.ts`

## Files to Modify

- `apps/backend/src/shared/inventory/inventory.service.ts` — émettre `LowStockDetected`
- `apps/backend/prisma/schema.prisma` — vérifier/appliquer `minStockLevel` sur `CatalogItem`

## Dev Notes

- Pas de table `StockAlert` dédiée si on préfère une vue calculée — acceptable en MVP (query `WHERE stockQuantity <= minStockLevel`)
- L'évaluation peut être synchrone (dans la transaction) ou via Event Bus (`LowStockDetected`) — privilégier Event Bus pour découplage
