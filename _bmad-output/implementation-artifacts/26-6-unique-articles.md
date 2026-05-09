# Story 26.6 — Unique Articles / Consignment Goods (FR97)

## Metadata

- **Epic:** Epic 26 — Traçabilité Articles & Configurations Métier
- **Story ID:** 26-6-unique-articles
- **Status:** done
- **Priority:** Medium
- **Depends on:** Epic 2 (CatalogItem), Epic 4 (Transactions), Epic 5 (Inventory/Stock movements)

---

## Story

**As a** retailer handling consignment goods, antiques, or one-off items,
**I want** certain articles to be marked as unique with a stock cap of 1,
**So that** they disappear from the active catalog after sale and I can duplicate them to create similar listings (FR97).

---

## Acceptance Criteria

### AC1 — Champ isUnique sur CatalogItem

**Given** le modèle `CatalogItem` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `isUnique Boolean @default(false) @map("is_unique")` est présent sur `catalog_items`
**And** la valeur par défaut est `false` — tous les articles existants ne sont pas affectés

### AC2 — Stock plafonné à 1 pour les articles uniques

**Given** un article a `isUnique = true`
**When** une réception fournisseur, un ajustement de stock ou tout mouvement entrant tente de mettre `stockQuantity > 1`
**Then** le backend retourne `400 Bad Request` avec le message : `"Un article unique ne peut avoir un stock supérieur à 1"`
**And** le mouvement de stock est rejeté
**And** le frontend affiche ce message d'erreur clairement (SnackBar ou AlertDialog)

### AC3 — Archivage automatique après vente

**Given** un article unique (`isUnique = true`) est vendu et son stock passe à 0
**When** la transaction est finalisée par `TransactionsService`
**Then** `CatalogItem.isActive` est automatiquement mis à `false`
**And** l'article n'apparaît plus dans la grille POS ni dans le catalogue actif (filtre `isActive = true` déjà en place)
**And** il reste accessible dans les transactions historiques
**And** il peut être retrouvé via la recherche avec filtre "articles archivés" dans le backoffice

### AC4 — Duplication depuis le backoffice

**Given** l'owner consulte la fiche d'un article unique (actif ou archivé)
**When** il clique "Dupliquer cet article"
**Then** `POST /api/v1/catalog/:id/duplicate` est appelé
**And** un nouvel article est créé avec les mêmes données (nom, prix, catégorie, `isUnique = true`) mais :
  - `stockQuantity = 0`
  - `isActive = true`
  - Nouveau `id` généré
**And** l'owner est redirigé vers la fiche du nouvel article pour compléter les détails

### AC5 — Badge visuel "UNIQUE" dans la grille POS et le catalogue

**Given** un article a `isUnique = true` et `isActive = true`
**When** il s'affiche dans la grille POS (`ProductGrid`) ou dans le catalogue backoffice
**Then** un badge "UNIQUE" (ou icône distinctive) est visible sur la carte de l'article
**And** pour le POS, le badge apparaît dans le coin supérieur droit de la carte (cohérent avec le badge "PROMO" existant)

### AC6 — Toggle isUnique dans ProductFormDialog

**Given** l'owner crée ou édite un article dans `ProductFormDialog`
**When** il active le toggle "Article unique (dépôt-vente)"
**Then** `isUnique` est mis à `true` via `PATCH /api/v1/catalog/:id` ou dans le payload de création
**And** le champ stock est automatiquement plafonné à 1 dans l'UI (max = 1 validé)
**And** un texte d'avertissement s'affiche : "Cet article sera automatiquement archivé après la vente"

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration isUnique** (AC1)
  - [ ] Ajouter `isUnique Boolean @default(false) @map("is_unique")` sur `CatalogItem` dans `schema.prisma`
  - [ ] Générer la migration SQL

- [ ] **Task 2 — Contrainte stock ≤ 1 dans InventoryService** (AC2)
  - [ ] Dans `InventoryService`, pour tout mouvement entrant (`RECEPTION`, `ADJUSTMENT_IN`, `TRANSFER_IN`) :
    - Si `catalogItem.isUnique == true` ET `newStockQuantity > 1` → lever `BadRequestException`
  - [ ] Vérifier aussi dans `CatalogService.updateCatalogItem()` si `stockQuantity` est mis à jour directement

- [ ] **Task 3 — Archivage automatique dans TransactionsService** (AC3)
  - [ ] Dans `TransactionsService`, après décrémentation du stock à la vente :
    - Si `catalogItem.isUnique == true` ET `newStock == 0` → `catalogService.updateCatalogItem(id, { isActive: false })`
  - [ ] La désactivation se fait dans la même transaction DB que la vente (via Prisma `$transaction`)

- [ ] **Task 4 — Endpoint duplication** (AC4)
  - [ ] Ajouter `POST /api/v1/catalog/:id/duplicate` dans `CatalogController`
  - [ ] Dans `CatalogService.duplicateCatalogItem(id, tenantId)` :
    - Charger l'article source
    - Créer un nouvel article avec les mêmes champs sauf `id`, `stockQuantity = 0`, `isActive = true`
    - Retourner le nouvel article

- [ ] **Task 5 — Badge UNIQUE dans le frontend** (AC5)
  - [ ] Dans `ProductGrid` (POS), ajouter un badge "UNIQUE" sur les cards ayant `product.isUnique == true`
    - Pattern similaire au badge "PROMO" existant — Stack avec Positioned
  - [ ] Dans le catalogue backoffice, ajouter un indicateur similaire sur les tuiles d'article unique

- [ ] **Task 6 — Toggle isUnique + duplication dans ProductFormDialog** (AC6)
  - [ ] Ajouter `SwitchListTile` "Article unique (dépôt-vente)"
  - [ ] Si activé, forcer `stockQuantity` max à 1 dans le formulaire
  - [ ] Ajouter bouton "Dupliquer" sur la fiche article (visible pour tous les articles `isUnique`, actifs ou archivés)
  - [ ] Appel `POST /api/v1/catalog/:id/duplicate` → naviguer vers la fiche du nouvel article

---

## Files to Create

- `apps/backend/prisma/migrations/YYYYMMDD_add_is_unique/migration.sql`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — `isUnique` sur `CatalogItem`
- `apps/backend/src/shared/catalog/catalog.service.ts` — `duplicateCatalogItem()` + validation stock dans update
- `apps/backend/src/shared/catalog/catalog.controller.ts` — endpoint `POST /catalog/:id/duplicate`
- `apps/backend/src/shared/inventory/inventory.service.ts` — validation stock ≤ 1 pour articles uniques
- `apps/backend/src/shared/transactions/transactions.service.ts` — archivage auto après vente (`isActive = false`)
- `apps/frontend/lib/features/retail/pos/presentation/widgets/product_grid.dart` — badge UNIQUE
- `apps/frontend/lib/features/shared/catalog/presentation/screens/catalog_screen.dart` — badge UNIQUE + bouton Dupliquer
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — toggle isUnique + validation stock

---

## Dev Notes

### Architecture Reference

- `isUnique` est un `Boolean @default(false)` sur `CatalogItem` — défini dans `docs/architecture-scalario-2026-03-08.md` v1.2
- Désactivé par défaut — aucune migration de données requise pour les articles existants

### Archivage atomique

- L'archivage (`isActive = false`) doit se faire **dans la même transaction Prisma** que la vente, pour garantir l'atomicité
- Utiliser `prisma.$transaction([...])` ou le pattern `tx` déjà utilisé dans `TransactionsService`

### Duplication

```typescript
// CatalogService.duplicateCatalogItem()
const source = await prisma.catalogItem.findUniqueOrThrow({ where: { id } });
const duplicate = await prisma.catalogItem.create({
  data: {
    ...source,
    id: undefined,           // auto-généré
    stockQuantity: 0,
    isActive: true,
    createdAt: undefined,    // auto-généré
    updatedAt: undefined,
  },
});
return duplicate;
```
- Ne pas copier `id`, `createdAt`, `updatedAt`, `stockQuantity`

### Badge UNIQUE dans le POS

- Le badge "PROMO" est déjà implémenté dans `product_grid.dart` (story 25-7) — réutiliser le pattern Stack/Positioned
- Couleur suggérée : violet ou gris foncé pour distinguer de "PROMO" (vert)

### Articles archivés dans le backoffice

- Le filtre `isActive = true` est déjà en place sur `GET /api/v1/catalog`
- Ajouter un filtre optionnel `?includeArchived=true` pour permettre la consultation des articles archivés
- L'UI peut avoir un toggle "Afficher les archivés" dans la barre de filtres du catalogue

### Offline

- La désactivation automatique (`isActive = false`) est une opération backend synchrone
- En mode offline, la vente est enregistrée dans l'outbox — la désactivation se fera lors de la sync
- Temporairement, l'article peut rester visible au POS offline jusqu'à la sync (comportement acceptable)

### References

- [Source: docs/architecture-scalario-2026-03-08.md — CatalogItem.isUnique]
- [Source: _bmad-output/planning-artifacts/prd.md — FR97]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 26-6]
- [Source: apps/frontend/lib/features/retail/pos/presentation/widgets/product_grid.dart — badge pattern (PROMO)]
- [Source: apps/backend/src/shared/transactions/transactions.service.ts — stock decrement pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `isUnique` was already in schema.prisma (from 26-1) and CatalogItem model — no migration needed
- Stock cap validation added in `InventoryService.createMovement()` for DELIVERY, TRANSFER_IN, and positive ADJUSTMENT movements
- Auto-archive (isActive = false) added in `InventoryService.handleTransactionCreated()` in the SALE branch after FIFO depletion
- `duplicateCatalogItem()` copies all Epic 26 fields but clears barcode (avoids unique constraint), parentItemId, and hasVariants
- UNIQUE badge: purple `Container` at top-left in `product_grid.dart` (mutually exclusive with VRAC in practice); inline `Row` badge in `_CatalogItemTile` title
- "Dupliquer" available in both the catalog ⋮ menu (for isUnique items) and the `ProductFormDialog` (edit mode button)
- Stock initial validator limits to max 1 when `_isUnique` is checked in `ProductFormDialog`

### File List

- `apps/backend/src/shared/inventory/inventory.service.ts` — AC2 stock cap + AC3 auto-archive
- `apps/backend/src/shared/catalog/catalog.service.ts` — AC4 `duplicateCatalogItem()` + `isUnique` in createItem
- `apps/backend/src/shared/catalog/catalog.controller.ts` — AC4 `POST /items/:id/duplicate`
- `apps/frontend/lib/features/shared/catalog/data/repositories/catalog_repository.dart` — `isUnique` param + `duplicateItem()`
- `apps/frontend/lib/features/retail/pos/presentation/widgets/product_grid.dart` — AC5 UNIQUE badge
- `apps/frontend/lib/features/shared/catalog/presentation/screens/catalog_screen.dart` — AC5 badge + AC4 Dupliquer menu
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — AC6 isUnique toggle + stock validator + Dupliquer button
