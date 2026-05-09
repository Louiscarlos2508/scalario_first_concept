# Story 20.1 — Backend : Migration Prisma unitType + pricePerUnit + conversionRate

## Metadata

- **Epic:** Epic 20 — Vente au poids + unités configurables
- **Story ID:** 20-1-unit-type-backend
- **Status:** done
- **Priority:** High
- **Depends on:** Epics 1–9 (backend catalog opérationnel)

---

## Story

**As an** owner,
**I want** each catalog item to have a configurable unit type, unit price, and stock conversion factor,
**So that** the system can price and track weight/volume/length articles correctly (FR76, FR78).

---

## Acceptance Criteria

### AC1 — Migration Prisma

**Given** the current `CatalogItem` table has no `unit_type`, `price_per_unit`, or `conversion_rate` columns
**When** the Prisma migration runs
**Then** the following columns are added to `shared.catalog_items`:
- `unit_type VARCHAR NOT NULL DEFAULT 'piece'` — valeurs acceptées : `piece | weight | volume | length`
- `price_per_unit NUMERIC(10,2) NULL` — prix par unité native (optionnel, null = même valeur que `price`)
- `conversion_rate NUMERIC(10,4) NULL` — facteur de conversion unité de vente → unité de stock
**And** toutes les lignes existantes ont `unit_type = 'piece'`, `price_per_unit = NULL`, `conversion_rate = NULL`
**And** aucune donnée existante n'est perdue

### AC2 — DTO & validation

**Given** `POST /api/v1/catalog/items` ou `PATCH /api/v1/catalog/items/:id`
**When** le body inclut `unitType`, `pricePerUnit`, `conversionRate`
**Then** les champs sont validés :
- `unitType` : enum strict `['piece', 'weight', 'volume', 'length']`, défaut `'piece'`
- `pricePerUnit` : Decimal ≥ 0, optionnel
- `conversionRate` : Decimal > 0, optionnel
**And** une valeur `unitType` invalide retourne HTTP 400 avec message d'erreur lisible

### AC3 — Réponse GET catalog

**Given** `GET /api/v1/catalog/items`
**When** la réponse est sérialisée
**Then** chaque item inclut `unitType`, `pricePerUnit`, `conversionRate` (null si non définis)
**And** la sync delta (`?since=`) inclut aussi ces champs

### AC4 — Décrémentation stock avec conversionRate

**Given** un article avec `conversionRate = 0.5` (ex: 1 sachet 500g = 0.5 unité stock)
**When** une vente de quantité `2.0` est enregistrée
**Then** le `InventoryMovement.quantity` créé est `2.0 × 0.5 = 1.0` (dans l'unité de stock)
**And** si `conversionRate` est null, la décrémentation est `quantity` sans transformation

### AC5 — Tests backend

**Given** `catalog.service.spec.ts`
**When** les tests unitaires sont exécutés
**Then** :
- Créer un item avec `unitType: 'weight'` → champ persisté correctement
- Créer avec `unitType: 'invalid'` → erreur de validation
- Décrémentation avec `conversionRate: 0.5`, quantité `3` → stock réduit de `1.5`
- Décrémentation sans `conversionRate` → stock réduit de `3` (comportement inchangé)

---

## Tasks/Subtasks

- [x] **Task 1 : Migration Prisma**
  - [x] Ajouter à `CatalogItem` dans `schema.prisma` : `unitType String @default("piece") @map("unit_type")`, `pricePerUnit Decimal? @map("price_per_unit") @db.Decimal(10, 2)`, `conversionRate Decimal? @map("conversion_rate") @db.Decimal(10, 4)`
  - [x] Générer la migration : `npx prisma migrate dev --name add_unit_type_to_catalog_items` (via `db push` — shadow DB incompatibility)
  - [x] Vérifier que les données existantes ont `unit_type = 'piece'` par défaut

- [x] **Task 2 : DTO & validation**
  - [x] Créer `apps/backend/src/shared/catalog/dto/create-catalog-item.dto.ts` avec `unitType` (enum), `pricePerUnit` (optionnel), `conversionRate` (optionnel)
  - [x] Créer `apps/backend/src/shared/catalog/dto/update-catalog-item.dto.ts` (PartialType de Create)
  - [x] Utiliser `class-validator` : `@IsIn(['piece', 'weight', 'volume', 'length'])`, `@IsOptional()`, `@IsNumber()`

- [x] **Task 3 : CatalogService — accepter + persister les nouveaux champs**
  - [x] Mettre à jour `createItem()` pour accepter `unitType`, `pricePerUnit`, `conversionRate`
  - [x] Ajouter méthode `updateItem()` (PATCH) dans le service
  - [x] Mettre à jour `getItems()` pour inclure `unitType`, `pricePerUnit`, `conversionRate` dans la réponse

- [x] **Task 4 : CatalogController — endpoint PATCH**
  - [x] Ajouter `PATCH /catalog/items/:id` avec `@Roles('owner')`
  - [x] Injecter les nouveaux champs depuis le DTO validé

- [x] **Task 5 : Logique conversionRate dans InventoryService**
  - [x] Lors de la création d'un `InventoryMovement` de type `SALE`, appliquer `quantity × conversionRate` si `conversionRate != null`
  - [x] Si `conversionRate` est null, comportement inchangé

- [x] **Task 6 : Tests unitaires**
  - [x] Ajouter dans `catalog.service.spec.ts` :
    - Test createItem avec `unitType: 'weight'` → champ persisté
    - Test createItem avec `unitType: 'invalid'` → erreur 400
    - Test décrémentation avec `conversionRate: 0.5`, qty 3 → stock réduit de 1.5
    - Test décrémentation sans `conversionRate` → stock réduit de 3

---

## Files to Create/Modify

**New files:**
- `apps/backend/src/shared/catalog/dto/create-catalog-item.dto.ts`
- `apps/backend/src/shared/catalog/dto/update-catalog-item.dto.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_unit_type_to_catalog_items/migration.sql`

**Modified files:**
- `apps/backend/prisma/schema.prisma` — ajouter `unitType`, `pricePerUnit`, `conversionRate` sur `CatalogItem`
- `apps/backend/src/shared/catalog/catalog.service.ts` — logique conversionRate + updateItem()
- `apps/backend/src/shared/catalog/catalog.controller.ts` — accepter nouveaux champs + PATCH endpoint
- `apps/backend/src/shared/catalog/catalog.service.spec.ts` — 4 nouveaux tests
