# Story 25.1 — Backend : ProductVariant + endpoints CRUD

## Metadata

- **Epic:** Epic 25 — Variantes, multi-tarifs & promotions
- **Story ID:** 25-1-variant-backend
- **Status:** ready-for-dev
- **Priority:** High
- **Depends on:** Epics 1–9, Epic 2 (CatalogItem)

---

## Story

**As a** backend developer,
**I want** a `ProductVariant` model with its own price, stock and attributes, linked to a parent `CatalogItem`,
**So that** articles can have multiple sellable variants (size S/M/L, color blue/red) with independent inventory (FR89).

---

## Acceptance Criteria

### AC1 — Migration ProductVariant

**Given** le modèle `ProductVariant` est défini dans l'architecture v1.1
**When** la migration est appliquée
**Then** la table `prod_variants` existe dans le schema `shared` avec : `id`, `catalog_item_id`, `tenant_id`, `sku`, `barcode`, `price`, `stock_quantity`, `attributes` (Json), `is_active`, `created_at`, `updated_at`
**And** `catalog_items.has_variants` est un booléen permettant de savoir si l'article parent a des variantes actives
**And** un index existe sur `(tenant_id, catalog_item_id)`

### AC2 — CRUD variantes

**Given** `POST /api/v1/catalog/:id/variants` est appelé avec `{ sku, price, stockQuantity, attributes: { taille: "M", couleur: "Bleu" } }`
**When** la requête est validée
**Then** une variante est créée liée à l'article parent du tenant
**And** `CatalogItem.hasVariants` est mis à `true` automatiquement si c'est la première variante active
**And** `GET /api/v1/catalog/:id/variants` retourne toutes les variantes actives de l'article
**And** `PATCH /api/v1/catalog/:id/variants/:variantId` permet de modifier prix, stock, attributs
**And** `DELETE /api/v1/catalog/:id/variants/:variantId` désactive la variante (`isActive = false`)

### AC3 — Stock agrégé sur l'article parent

**Given** un article parent a 3 variantes avec des stocks respectifs de 10, 5, 8
**When** `GET /api/v1/catalog/:id` est appelé
**Then** la réponse inclut `totalStockQuantity: 23` (somme des `stockQuantity` des variantes actives)
**And** le stock de l'article parent lui-même n'est pas utilisé quand `hasVariants = true`

### AC4 — Lookup par barcode de variante

**Given** le caissier scanne un barcode de variante
**When** `GET /api/v1/catalog/barcode/:barcode` est appelé
**Then** si le barcode correspond à une variante, la réponse inclut l'article parent ET la variante correspondante (`matchedVariant: { id, attributes, price, stockQuantity }`)
**And** le flux POS sélectionne automatiquement la variante sans étape manuelle

### AC5 — Décrémentation stock variante à la vente

**Given** une variante est vendue au POS
**When** la transaction est traitée
**Then** `stockQuantity` de la variante spécifique est décrémenté (pas celui du parent)
**And** un `InventoryMovement` de type `SALE` est créé avec `catalogItemId` = parent et `variantId` = variante

---

## Tasks/Subtasks

- [ ] **Task 1 : Migration ProductVariant**
  - [ ] Modèle `ProductVariant` dans `schema.prisma` (schema `shared`)
  - [ ] Ajouter `hasVariants Boolean @default(false)` sur `CatalogItem`
  - [ ] Ajouter `variantId String? @map("variant_id") @db.Uuid` à `InventoryMovement`
  - [ ] Générer migration

- [ ] **Task 2 : VariantsService + Controller**
  - [ ] Créer `variants.service.ts`, `variants.controller.ts`
  - [ ] CRUD : `createVariant()`, `getVariants()`, `updateVariant()`, `deleteVariant()`
  - [ ] Mise à jour automatique `hasVariants` sur le parent

- [ ] **Task 3 : Stock agrégé**
  - [ ] Dans `catalog.service.ts` → `getItem(:id)` : calculer `totalStockQuantity = SUM(variants.stockQuantity)` si `hasVariants`

- [ ] **Task 4 : Barcode lookup variante**
  - [ ] Dans `catalog.service.ts` → `getByBarcode(:barcode)` : chercher d'abord en variante, inclure `matchedVariant`

- [ ] **Task 5 : Décrémentation variante dans TransactionsService**
  - [ ] Si `variantId` fourni dans la transaction item : décrémenter `variant.stockQuantity`
  - [ ] Créer `InventoryMovement` avec `variantId`

---

## Files to Create

- `apps/backend/src/shared/catalog/variants/variants.service.ts`
- `apps/backend/src/shared/catalog/variants/variants.controller.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — modèle `ProductVariant`, `hasVariants` sur `CatalogItem`, `variantId` sur `InventoryMovement`
- `apps/backend/src/shared/catalog/catalog.service.ts` — `totalStockQuantity` agrégé + barcode lookup
- `apps/backend/src/shared/transactions/transactions.service.ts` — décrémenter stock variante

## Dev Notes

- Ajouter `variantId String? @map("variant_id") @db.Uuid` à `InventoryMovement` pour tracer les mouvements par variante
- Les attributs `{ taille, couleur }` sont libres (Json) — pas d'enum fixe côté backend
