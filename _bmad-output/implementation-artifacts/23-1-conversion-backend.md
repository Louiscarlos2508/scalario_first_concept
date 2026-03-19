# Story 23.1 — Backend : parentItemId + conversionRate + logique REPACKAGING

## Metadata

- **Epic:** Epic 23 — Conversion unités vrac → détail
- **Story ID:** 23-1-conversion-backend
- **Status:** ready-for-dev
- **Priority:** High
- **Depends on:** Epic 20 (unitType + conversionRate sur CatalogItem), Epic 5 (mouvements de stock)

---

## Story

**As a** backend developer,
**I want** parent-child article relationships persisted and the POS sale endpoint to automatically decrement parent stock when a child article is sold,
**So that** bulk → retail unit stock tracking is automated and fully traced (FR83).

---

## Acceptance Criteria

### AC1 — Migration parentItemId + conversionRate

**Given** les champs `parentItemId` et `conversionRate` sont définis pour `CatalogItem`
**When** le développeur applique la migration Prisma
**Then** `parentItemId String? @map("parent_item_id") @db.Uuid` est présent sur `catalog_items`
**And** `conversionRate Decimal? @map("conversion_rate") @db.Decimal(10, 4)` est présent (peut déjà exister depuis Epic 20)
**And** les deux champs sont nullable — absence = article autonome sans relation parent

### AC2 — Validation relation parent-enfant

**Given** `PATCH /api/v1/catalog/:id` est appelé avec `{ "parentItemId": "uuid", "conversionRate": 0.02 }`
**When** le service valide la relation
**Then** le parent référencé doit appartenir au même tenant — sinon erreur 400
**And** pas de référence circulaire tolérée (A → B → A) — le service vérifie 1 niveau
**And** profondeur max = 1 : un article enfant ne peut pas lui-même avoir des enfants
**And** `conversionRate` doit être > 0 et ≤ 1 pour les sous-unités

### AC3 — Décrémentation stock parent à la vente

**Given** un article enfant avec `parentItemId` et `conversionRate` est vendu au POS
**When** `POST /api/v1/transactions` traite la vente
**Then** le stock de l'article enfant n'est PAS décrémenté (l'enfant n'a pas de stock propre)
**And** le stock du parent est décrémenté de `quantity × conversionRate`
**And** un `InventoryMovement` de type `REPACKAGING` est créé avec `catalogItemId` = parent, `quantity` = -(quantity × conversionRate), `referenceId` = transactionId

### AC4 — Endpoint GET articles enfants d'un parent

**Given** `GET /api/v1/catalog/:id/children` est appelé
**When** le backend répond
**Then** la réponse liste tous les articles dont `parentItemId` = `:id` pour le tenant courant
**And** chaque entrée inclut `id`, `name`, `unitType`, `pricePerUnit`, `conversionRate`

### AC5 — Avertissement stock parent insuffisant

**Given** la vente d'un article enfant décrémenterait le stock parent en dessous de 0
**When** la transaction est traitée
**Then** le backend renvoie un avertissement `{ warning: "PARENT_STOCK_LOW", parentItemName: string, parentStockAfter: number }` dans la réponse (non bloquant — la vente passe quand même)
**And** le stock parent peut devenir négatif (comportement identique aux articles ordinaires)

---

## Tasks/Subtasks

- [ ] **Task 1 : Migration parentItemId**
  - [ ] Ajouter `parentItemId String? @map("parent_item_id") @db.Uuid` sur `CatalogItem`
  - [ ] Relation self-referencing : `parent CatalogItem? @relation("ParentChild", fields: [parentItemId], references: [id])`
  - [ ] Générer migration

- [ ] **Task 2 : Validation parent-enfant dans CatalogService**
  - [ ] Vérifier `parent.tenantId == item.tenantId`
  - [ ] Vérifier que le parent n'a pas lui-même un `parentItemId` (profondeur max 1)
  - [ ] Vérifier absence de circularité
  - [ ] Valider `conversionRate > 0 && conversionRate <= 1`

- [ ] **Task 3 : Endpoint GET /:id/children**
  - [ ] Dans `catalog.controller.ts` : `@Get(':id/children')`
  - [ ] Query `WHERE parentItemId = :id AND tenantId = tenant`

- [ ] **Task 4 : TransactionsService — décrémentation parent**
  - [ ] Lors du traitement d'une vente, pour chaque item avec `parentItemId`
  - [ ] Décrémentation parent : `quantity × conversionRate`
  - [ ] Créer `InventoryMovement` type `REPACKAGING`
  - [ ] Inclure warning si stock parent < 0 après décrément

- [ ] **Task 5 : Type REPACKAGING dans InventoryMovement**
  - [ ] Ajouter `REPACKAGING` à la liste des types de mouvements acceptés

---

## Files to Modify

- `apps/backend/prisma/schema.prisma` — ajouter `parentItemId`, relation self-referencing sur `CatalogItem`
- `apps/backend/src/shared/catalog/catalog.service.ts` — validation parent-enfant + endpoint children
- `apps/backend/src/shared/catalog/catalog.controller.ts` — `GET /:id/children`
- `apps/backend/src/shared/transactions/transactions.service.ts` — décrémentation parent + InventoryMovement REPACKAGING

## Dev Notes

- Si l'article enfant a aussi son propre `conversionRate` (FR78 sans `parentItemId`), les deux logiques coexistent
- Le type `REPACKAGING` est ajouté à l'enum commentaire de `InventoryMovement`
