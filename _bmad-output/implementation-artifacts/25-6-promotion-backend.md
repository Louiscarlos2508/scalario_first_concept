# Story 25.6 — Backend : Promotion + endpoints CRUD + moteur d'éligibilité

## Metadata

- **Epic:** Epic 25 — Variantes, multi-tarifs & promotions
- **Story ID:** 25-6-promotion-backend
- **Status:** ready-for-dev
- **Priority:** High
- **Depends on:** Epics 1–9, Epic 2 (CatalogItem + Category)

---

## Story

**As a** backend developer,
**I want** a `Promotion` model with a promotion engine that evaluates eligibility at POS cart time,
**So that** discounts apply automatically and the best promotion wins per article (FR91).

---

## Acceptance Criteria

### AC1 — Migration Promotion

**Given** le modèle `Promotion` est défini dans l'architecture v1.1
**When** la migration est appliquée
**Then** la table `promotions` existe dans le schema `shared` avec : `id`, `tenant_id`, `type` (`PERCENT` | `BUY_N_GET_M` | `CROSSED_PRICE`), `scope` (`ITEM` | `CATEGORY`), `scope_id`, `value` (Json), `start_date`, `end_date`, `status` (`active` | `inactive`), `conflict_rule` (`BEST` | `FIRST`), `created_at`
**And** un index existe sur `(tenant_id, status, start_date, end_date)`

### AC2 — CRUD promotions

**Given** `POST /api/v1/promotions` est appelé avec un payload typé PERCENT
**When** la requête est validée
**Then** une promotion est créée avec `status: active` et les dates configurées
**And** `GET /api/v1/promotions` liste les promotions avec filtre `?status=active&type=PERCENT`
**And** `PATCH /api/v1/promotions/:id` permet de modifier le statut, les dates, ou les paramètres
**And** `DELETE /api/v1/promotions/:id` soft-delete la promotion

### AC3 — Moteur d'éligibilité à la vente

**Given** une transaction inclut un article éligible à une ou plusieurs promotions actives
**When** la transaction est traitée
**Then** le moteur évalue toutes les promotions actives dont `start_date <= now <= end_date` et dont `scope` couvre l'article (par `catalogItemId` ou `categoryId`)
**And** pour `PERCENT` : le discount = `price × value.percent / 100`
**And** pour `BUY_N_GET_M` : si `quantity >= value.buyN`, `value.getMQty` articles offerts (ligne séparée prix 0)
**And** pour `CROSSED_PRICE` : le prix affiché = `value.newPrice`, le prix original est tracé
**And** si plusieurs promotions sont éligibles et `conflict_rule = BEST`, la promotion avec le discount le plus élevé est sélectionnée
**And** la réponse transaction inclut par ligne : `appliedPromotion: { id, type, originalPrice, discountedPrice }`

### AC4 — Endpoint GET promotions actives pour un article

**Given** `GET /api/v1/promotions/active?catalogItemId=:id` est appelé
**When** le backend répond
**Then** la réponse liste toutes les promotions actives couvrant cet article, avec leur type et valeur calculée

---

## Tasks/Subtasks

- [ ] **Task 1 : Migration Promotion**
  - [ ] Modèle `Promotion` dans `schema.prisma` (schema `shared`)
  - [ ] Champs : `id, tenantId, type, scope, scopeId, value Json, startDate, endDate, status, conflictRule, createdAt`
  - [ ] Générer migration

- [ ] **Task 2 : PromotionsModule**
  - [ ] Créer `promotions.module.ts`, `promotions.service.ts`, `promotions.controller.ts`
  - [ ] CRUD : `createPromotion()`, `listPromotions()`, `updatePromotion()`, `deletePromotion()`

- [ ] **Task 3 : PromotionEngineService**
  - [ ] Créer `promotion-engine.service.ts`
  - [ ] `evaluate(catalogItemId, categoryId, quantity, tenantId)` → retourne la promotion applicable
  - [ ] Logique PERCENT, BUY_N_GET_M, CROSSED_PRICE
  - [ ] Résolution conflits : BEST (prix le plus bas) ou FIRST (première active)

- [ ] **Task 4 : Intégration dans TransactionsService**
  - [ ] Appeler `PromotionEngineService.evaluate()` avant calcul total
  - [ ] Inclure `appliedPromotion` dans la réponse par ligne

- [ ] **Task 5 : Endpoint GET promotions actives pour un article**
  - [ ] `GET /promotions/active?catalogItemId=:id`

---

## Files to Create

- `apps/backend/src/shared/promotions/promotions.module.ts`
- `apps/backend/src/shared/promotions/promotions.service.ts`
- `apps/backend/src/shared/promotions/promotions.controller.ts`
- `apps/backend/src/shared/promotions/promotion-engine.service.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — modèle `Promotion`
- `apps/backend/src/shared/transactions/transactions.service.ts` — appeler `PromotionEngineService`

## Dev Notes

- `value` est un Json flexible pour éviter d'avoir une table par type de promotion
- Exemple PERCENT : `{ "percent": 20 }` ; BUY_N_GET_M : `{ "buyN": 3, "getM": 1, "freeItemId": null }` ; CROSSED_PRICE : `{ "originalPrice": 5000, "newPrice": 3500 }`
