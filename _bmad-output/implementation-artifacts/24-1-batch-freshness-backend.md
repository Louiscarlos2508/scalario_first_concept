# Story 24.1 — Backend : ProductBatch + expiryDays + endpoints expiring

## Metadata

- **Epic:** Epic 24 — Fraîcheur + code couleur priorité vente
- **Story ID:** 24-1-batch-freshness-backend
- **Status:** done
- **Priority:** High
- **Depends on:** Epics 1–9, Epic 21 (réception fournisseur)

---

## Story

**As a** backend developer,
**I want** a `ProductBatch` model tracking freshness per reception lot, and endpoints to query expiring articles,
**So that** the system can drive color-coded freshness indicators and the "Fraîcheur" tab (FR84, FR85).

---

## Acceptance Criteria

### AC1 — Migration expiryDays + shrinkageTolerance sur CatalogItem

**Given** les champs sont définis dans l'architecture v1.1
**When** la migration est appliquée
**Then** `expiryDays Int? @map("expiry_days")` est présent sur `catalog_items`
**And** `shrinkageTolerance Decimal? @map("shrinkage_tolerance") @db.Decimal(5, 2)` est présent
**And** les deux sont nullable — absence = fraîcheur non trackée pour cet article

### AC2 — Migration ProductBatch

**Given** le modèle `ProductBatch` est défini dans l'architecture v1.1
**When** la migration est appliquée
**Then** la table `prod_batches` existe dans le schema `shared` avec les colonnes : `id`, `catalog_item_id`, `tenant_id`, `received_at`, `expires_at`, `initial_qty`, `remaining_qty`, `batch_ref`, `is_depleted`, `created_at`
**And** un index existe sur `(tenant_id, expires_at)` pour les requêtes de tri par expiration

### AC3 — Création automatique ProductBatch à la réception

**Given** une réception fournisseur est enregistrée
**When** l'article reçu a `expiryDays != null`
**Then** un `ProductBatch` est créé avec : `receivedAt = now()`, `expiresAt = now() + expiryDays days`, `initialQty = receivedQuantity`, `remainingQty = receivedQuantity`
**And** si `expiryDays = null`, aucun batch n'est créé (article non tracé)

### AC4 — Dépletion FIFO des batches à la vente

**Given** un article avec des batches actifs est vendu au POS
**When** la transaction est traitée
**Then** le batch avec la date `expiresAt` la plus ancienne est consommé en premier (FIFO)
**And** `remainingQty` est décrémenté de la quantité vendue
**And** si `remainingQty ≤ 0`, le batch est marqué `isDepleted = true`
**And** si la vente dépasse le `remainingQty` d'un batch, le surplus est prélevé sur le batch suivant (cascade)

### AC5 — Endpoint GET articles expirant

**Given** `GET /api/v1/batches/expiring?days=7` est appelé
**When** le backend répond
**Then** la réponse liste les batches dont `expiresAt ≤ now() + 7 days` et `isDepleted = false` pour le tenant
**And** chaque entrée inclut : `batchId`, `catalogItemId`, `itemName`, `expiresAt`, `remainingQty`, `freshnessPercent`
**And** les résultats sont triés par `expiresAt` croissant (plus urgents en premier)
**And** `GET /api/v1/batches/expiring/count` renvoie `{ urgentCount: number }` (batches avec `freshnessPercent < 50%`)

### AC6 — Tolérance rétrécissement sur mouvements LOSS

**Given** un mouvement de stock de type `LOSS` est enregistré pour un article avec `shrinkageTolerance`
**When** la quantité perdue est ≤ `shrinkageTolerance %` du stock total
**Then** le mouvement est enregistré avec `reason: "NATURAL_VARIANCE"`
**And** ce mouvement n'apparaît pas dans les KPIs de pertes du dashboard

---

## Tasks/Subtasks

- [x] **Task 1 : Migration CatalogItem — expiryDays + shrinkageTolerance**
  - [x] Ajouter `expiryDays Int? @map("expiry_days")` sur `CatalogItem`
  - [x] Ajouter `shrinkageTolerance Decimal? @map("shrinkage_tolerance") @db.Decimal(5, 2)`
  - [x] Générer migration

- [x] **Task 2 : Migration ProductBatch**
  - [x] Créer modèle `ProductBatch` dans `schema.prisma` (schema `shared`)
  - [x] Index sur `(tenantId, expiresAt)`
  - [x] Générer migration

- [x] **Task 3 : BatchesModule**
  - [x] Créer `batches.module.ts`, `batches.service.ts`, `batches.controller.ts`
  - [x] `getBatchesExpiring(tenantId, days)` : query + calcul `freshnessPercent`
  - [x] `getExpiringCount(tenantId)` : urgentCount (freshnessPercent < 50%)

- [x] **Task 4 : Création batch à la réception**
  - [x] Dans `inventory.service.ts` (ou `purchase-orders.service.ts`), après création mouvement `DELIVERY`
  - [x] Si `catalogItem.expiryDays != null`, créer `ProductBatch`

- [x] **Task 5 : Dépletion FIFO à la vente**
  - [x] Dans `transactions.service.ts`, pour chaque item vendu avec batches actifs
  - [x] Trier batches par `expiresAt` ASC, décrémenter FIFO
  - [x] Marquer `isDepleted = true` si `remainingQty <= 0`

- [x] **Task 6 : Tolérance LOSS**
  - [x] Dans `inventory.service.ts`, si type `LOSS` et quantity <= `shrinkageTolerance %` : `reason = "NATURAL_VARIANCE"`

---

## Files to Create

- `apps/backend/src/shared/batches/batches.module.ts`
- `apps/backend/src/shared/batches/batches.service.ts`
- `apps/backend/src/shared/batches/batches.controller.ts`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — `expiryDays`, `shrinkageTolerance` sur `CatalogItem` + modèle `ProductBatch`
- `apps/backend/src/shared/inventory/inventory.service.ts` — créer batch à la réception + dépletion FIFO

## Dev Notes

- La dépletion FIFO est optionnelle en MVP — acceptable de décrémenter le stock global sans tracker le batch précis ; tracker le batch est la v2
- `freshnessPercent = (expiresAt − now) / expiryDays × 100` (en jours)
