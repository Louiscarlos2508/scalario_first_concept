# Story 26.5 — Dynamic Pricing with Price History (FR96)

## Metadata

- **Epic:** Epic 26 — Traçabilité Articles & Configurations Métier
- **Story ID:** 26-5-dynamic-pricing
- **Status:** done
- **Priority:** Medium
- **Depends on:** Epic 2 (CatalogItem), Epic 6 (POS)

---

## Story

**As a** retailer selling commodities with fluctuating prices (gold, fuel, raw materials),
**I want** articles flagged as dynamic-priced to maintain a full price history,
**So that** the POS always uses the current price and I can audit past pricing decisions (FR96).

---

## Acceptance Criteria

### AC1 — Champ dynamicPricing + modèle PriceHistory

**Given** le modèle `CatalogItem` existe dans schema.prisma
**When** la migration est appliquée
**Then** le champ `dynamicPricing Boolean @default(false) @map("dynamic_pricing")` est présent sur `catalog_items`
**And** le modèle `PriceHistory` existe dans le schema `shared` avec :
  - `id String @id @default(uuid()) @db.Uuid`
  - `catalogItemId String @map("catalog_item_id") @db.Uuid`
  - `price Decimal @db.Decimal(12, 2)`
  - `effectiveFrom DateTime @map("effective_from") @db.Timestamptz(6)`
  - `reason String?`
  - `tenantId String @map("tenant_id") @db.Uuid`
  - `createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)`
  - Relation : `catalogItem CatalogItem @relation(fields: [catalogItemId], references: [id])`
**And** un index `@@index([catalogItemId, effectiveFrom])` et `@@index([tenantId])` sont présents
**And** `@@map("price_history")` et `@@schema("shared")` sont appliqués

### AC2 — Enregistrement automatique dans PriceHistory lors d'une mise à jour de prix

**Given** un article a `dynamicPricing = true`
**When** son prix est modifié via `PATCH /api/v1/catalog/:id` avec `{ price: 5500 }`
**Then** un `PriceHistory` est créé automatiquement :
  - `price = 5500`
  - `effectiveFrom = now()`
  - `reason = dto.reason` (optionnel, depuis le payload)
  - `tenantId` du tenant courant
**And** le prix actuel de `CatalogItem.price` est mis à jour normalement
**And** pour les articles sans `dynamicPricing`, aucune entrée `PriceHistory` n'est créée

### AC3 — Endpoint GET historique des prix

**Given** `GET /api/v1/catalog/:id/price-history` est appelé
**When** l'article a des entrées dans `PriceHistory`
**Then** la liste est retournée triée par `effectiveFrom DESC` avec : `price`, `effectiveFrom`, `reason`
**And** si l'article n'a pas `dynamicPricing = true`, retourner `[]` (tableau vide)

### AC4 — POS utilise toujours le prix courant de CatalogItem

**Given** un article dynamicPricing a son prix mis à jour quotidiennement
**When** il est ajouté au panier POS
**Then** le prix utilisé est `CatalogItem.price` — aucun calcul supplémentaire côté POS
**And** le prix est récupéré lors de la dernière sync delta du catalogue (comportement existant)

### AC5 — Vue historique des prix dans le backoffice

**Given** l'owner ouvre la fiche d'un article avec `dynamicPricing = true`
**When** il ouvre l'onglet "Historique des prix"
**Then** la liste des `PriceHistory` est affichée : date effective, prix, motif
**And** un graphique linéaire simple (`LineChart` de `fl_chart`) montre l'évolution du prix dans le temps
**And** si moins de 2 points de données, le graphique est remplacé par un message "Pas encore assez de données"
**And** si l'article n'a pas `dynamicPricing = true`, l'onglet est masqué

### AC6 — Champ reason dans la modification de prix + toggle dans ProductFormDialog

**Given** l'owner modifie le prix d'un article `dynamicPricing = true` dans `ProductFormDialog`
**When** le champ prix est modifié
**Then** un champ optionnel "Motif de la modification" apparaît
**And** la valeur est transmise via `PATCH /api/v1/catalog/:id` comme `{ price: N, reason: "..." }`
**And** le toggle "Prix dynamique" active/désactive `dynamicPricing` sur l'article

---

## Tasks / Subtasks

- [ ] **Task 1 — Migration Prisma** (AC1)
  - [ ] Ajouter `dynamicPricing Boolean @default(false) @map("dynamic_pricing")` sur `CatalogItem`
  - [ ] Créer modèle `PriceHistory` complet dans `schema.prisma`
  - [ ] Générer la migration SQL

- [ ] **Task 2 — PriceHistoryService backend** (AC2 + AC3)
  - [ ] Créer `apps/backend/src/shared/catalog/price-history/price-history.service.ts`
    - `recordPrice(tenantId, catalogItemId, price, reason?)` — crée une entrée `PriceHistory`
    - `getPriceHistory(tenantId, catalogItemId)` — retourne triée par `effectiveFrom DESC`
  - [ ] Dans `CatalogService.updateCatalogItem()` :
    - Si `dto.price` est fourni ET `catalogItem.dynamicPricing == true` → appeler `priceHistoryService.recordPrice()`
  - [ ] Créer `GET /catalog/:id/price-history` dans `CatalogController`
  - [ ] Ajouter `reason?: string` dans `UpdateCatalogItemDto`
  - [ ] Enregistrer `PriceHistoryService` dans `CatalogModule`

- [ ] **Task 3 — Provider et modèle Dart PriceHistory** (AC5)
  - [ ] Créer `apps/frontend/lib/features/shared/catalog/data/models/price_history.dart`
    - `PriceHistory { String id, Decimal price, DateTime effectiveFrom, String? reason }`
  - [ ] Créer `apps/frontend/lib/features/shared/catalog/presentation/providers/price_history_provider.dart`
    - `priceHistoryProvider(catalogItemId)` → `FutureProvider<List<PriceHistory>>`
    - Appel `GET /api/v1/catalog/:id/price-history`

- [ ] **Task 4 — Onglet Historique des prix** (AC5)
  - [ ] Créer `apps/frontend/lib/features/shared/catalog/presentation/widgets/price_history_tab.dart`
    - Liste des entrées PriceHistory (prix, date, motif)
    - Graphique `LineChart` de `fl_chart` (déjà utilisé dans dashboard — réutiliser le pattern)
    - Message "Pas assez de données" si < 2 points
  - [ ] Intégrer l'onglet dans la fiche article (`CatalogScreen`), conditionnel sur `dynamicPricing`

- [ ] **Task 5 — Toggle + champ reason dans ProductFormDialog** (AC6)
  - [ ] Ajouter `SwitchListTile` "Prix dynamique"
  - [ ] Si `dynamicPricing = true` et prix modifié → afficher `TextFormField` optionnel "Motif de la modification"
  - [ ] Envoyer `PATCH /api/v1/catalog/:id` avec `{ dynamicPricing: true/false }` ou `{ price: N, reason: "..." }`

---

## Files to Create

- `apps/backend/src/shared/catalog/price-history/price-history.service.ts`
- `apps/backend/prisma/migrations/YYYYMMDD_add_price_history/migration.sql`
- `apps/frontend/lib/features/shared/catalog/data/models/price_history.dart`
- `apps/frontend/lib/features/shared/catalog/presentation/providers/price_history_provider.dart`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/price_history_tab.dart`

## Files to Modify

- `apps/backend/prisma/schema.prisma` — `PriceHistory` model + `dynamicPricing` sur `CatalogItem`
- `apps/backend/src/shared/catalog/catalog.service.ts` — hook PriceHistory sur update prix
- `apps/backend/src/shared/catalog/catalog.controller.ts` — endpoint `GET /catalog/:id/price-history`
- `apps/backend/src/shared/catalog/catalog.module.ts` — enregistrer `PriceHistoryService`
- `apps/backend/src/shared/catalog/dto/update-catalog-item.dto.ts` — ajouter `reason?: string`
- `apps/frontend/lib/features/shared/catalog/presentation/screens/catalog_screen.dart` — onglet Historique des prix
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — toggle dynamicPricing + champ reason

---

## Dev Notes

### Architecture Reference

- `PriceHistory` est défini dans `docs/architecture-scalario-2026-03-08.md` v1.2 (shared schema)
- `dynamicPricing` est un champ `Boolean @default(false)` sur `CatalogItem` — optionnel par défaut
- Le hook de création PriceHistory est dans `CatalogService.updateCatalogItem()` — intercepter uniquement si `price` change ET `dynamicPricing = true`

### LineChart Pattern

- `fl_chart` est déjà utilisé dans le dashboard (widgets SDUI) — réutiliser le pattern existant
- Chercher `LineChart` ou `fl_chart` dans `apps/frontend/lib/` pour localiser l'usage actuel
- Données : `List<FlSpot>` où x = index chronologique, y = prix

### Catalog Update Hook

```typescript
// Dans catalog.service.ts updateCatalogItem()
if (dto.price !== undefined && existingItem.dynamicPricing) {
  await this.priceHistoryService.recordPrice(tenantId, id, dto.price, dto.reason);
}
```

### POS Impact

- Aucun changement POS requis — le POS utilise déjà `CatalogItem.price` issu de la dernière sync
- La mise à jour de prix est une opération backoffice (synchrone, online)
- La sync delta propagera le nouveau prix au POS offline

### Offline

- `PriceHistory` n'est pas syncronisé vers le client (trop volumineux) — c'est une donnée backoffice uniquement
- L'onglet "Historique des prix" requiert une connexion active

### References

- [Source: docs/architecture-scalario-2026-03-08.md — PriceHistory model, CatalogItem.dynamicPricing]
- [Source: _bmad-output/planning-artifacts/prd.md — FR96]
- [Source: _bmad-output/planning-artifacts/epics.md — Story 26-5]
- [Source: apps/frontend/lib/core/sdui/ — fl_chart LineChart pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
