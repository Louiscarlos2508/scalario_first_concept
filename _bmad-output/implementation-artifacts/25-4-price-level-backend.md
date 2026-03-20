# Story 25.4 — Backend : PriceLevel + endpoints multi-tarifs

## Metadata

- **Epic:** Epic 25 — Variantes, multi-tarifs & promotions
- **Story ID:** 25-4-price-level-backend
- **Status:** done
- **Priority:** High
- **Depends on:** Epics 1–9, Epic 3 (contacts/contactType)

---

## Story

**As a** backend developer,
**I want** a `PriceLevel` model and price resolution logic that automatically selects the correct price per transaction context,
**So that** wholesale, loyalty, and promotional prices apply without manual cashier intervention (FR90).

---

## Acceptance Criteria

### AC1 — Migration PriceLevel

**Given** le modèle `PriceLevel` est défini dans l'architecture v1.1
**When** la migration est appliquée
**Then** la table `price_levels` existe dans le schema `shared` avec : `id`, `catalog_item_id`, `tenant_id`, `level_code`, `label`, `price`, `min_qty` (nullable), `customer_types` (String[] nullable), `is_active`, `created_at`
**And** un index existe sur `(tenant_id, catalog_item_id)`

### AC2 — CRUD price levels

**Given** `POST /api/v1/catalog/:id/price-levels` est appelé avec `{ levelCode: "GROS", label: "Prix gros", price: 4500, minQty: 10 }`
**When** la requête est validée
**Then** un niveau de prix est créé pour l'article du tenant
**And** `GET /api/v1/catalog/:id/price-levels` retourne tous les niveaux actifs
**And** `PATCH` et `DELETE` (soft) sont disponibles

### AC3 — Résolution automatique du prix à la vente

**Given** une transaction inclut un article avec des niveaux de prix configurés
**When** la transaction est traitée
**Then** le service évalue dans l'ordre : (1) `minQty` — si `quantity >= minQty`, le niveau s'applique ; (2) `customerTypes` — si le contact a un `contactType` dans `customerTypes`, le niveau s'applique
**And** si plusieurs niveaux sont éligibles, le plus avantageux (prix le plus bas) est sélectionné
**And** si aucun niveau n'est éligible, le prix par défaut de l'article est utilisé
**And** la réponse transaction inclut `appliedPriceLevel: { levelCode, label }` par ligne de vente

### AC4 — Permission price_override

**Given** un cashier avec la permission `price_override` sélectionne manuellement un niveau de prix
**When** `POST /api/v1/transactions` est appelé avec `{ items: [{ ..., forcedPriceLevelCode: "GROS" }] }`
**Then** le niveau forcé est appliqué sans vérification des conditions `minQty`/`customerTypes`
**And** si l'utilisateur n'a pas `price_override`, une erreur 403 est renvoyée si `forcedPriceLevelCode` est présent

---

## Tasks/Subtasks

- [ ] **Task 1 : Migration PriceLevel**
  - [ ] Modèle `PriceLevel` dans `schema.prisma` (schema `shared`)
  - [ ] Champs : `id, catalogItemId, tenantId, levelCode, label, price, minQty?, customerTypes?, isActive, createdAt`
  - [ ] Générer migration

- [ ] **Task 2 : PriceLevelsService + Controller**
  - [ ] Créer `price-levels.service.ts`, `price-levels.controller.ts`
  - [ ] CRUD : `createPriceLevel()`, `getPriceLevels()`, `updatePriceLevel()`, `deletePriceLevel()`

- [ ] **Task 3 : Moteur résolution prix dans TransactionsService**
  - [ ] Méthode `resolvePriceLevel(catalogItemId, quantity, contactId, tenantId)` → retourne `PriceLevel | null`
  - [ ] Priorité : niveau le plus avantageux (prix min) parmi les éligibles
  - [ ] Fallback : `CatalogItem.price` (RETAIL)
  - [ ] Inclure `appliedPriceLevel` dans la réponse

- [ ] **Task 4 : Permission price_override**
  - [ ] Vérifier `user.permissions.includes('price_override')` si `forcedPriceLevelCode` présent
  - [ ] Erreur 403 si permission absente

---

## Files to Create

- `apps/backend/src/shared/catalog/price-levels/price-levels.service.ts`
- `apps/backend/src/shared/catalog/price-levels/price-levels.controller.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — modèle `PriceLevel`
- `apps/backend/src/shared/transactions/transactions.service.ts` — résolution prix + `forcedPriceLevelCode`

## Dev Notes

- `contactType` sur le modèle `Contact` est déjà en place (Epic 3)
- Le niveau "RETAIL" (défaut) n'a pas besoin d'être stocké en `PriceLevel` — c'est le prix `CatalogItem.price`
