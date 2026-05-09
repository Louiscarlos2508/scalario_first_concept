# Story 20.4 — Tests bout en bout + sync produits au poids

## Metadata

- **Epic:** Epic 20 — Vente au poids + unités configurables
- **Story ID:** 20-4-tests-sync-poids
- **Status:** done
- **Priority:** High
- **Depends on:** 20-1, 20-2, 20-3 (toutes les stories Epic 20 complétées)

---

## Story

**As a** developer,
**I want** weight products to sync correctly and receipts to display correct units end-to-end,
**So that** the feature is validated from backend to frontend (FR76, FR77, FR78).

---

## Acceptance Criteria

### AC1 — Sync delta produits au poids

**Given** un article avec `unitType = 'weight'` et `pricePerUnit = 1500` existe sur le backend
**When** `CatalogRepository.syncProducts()` exécute un pull delta
**Then** le `Product` local reçu a `unitType = 'weight'`, `pricePerUnit = 1500.0`
**And** l'article est stocké dans Isar avec ces valeurs sans troncation ni perte de précision

### AC2 — Robustesse sync — champs absents

**Given** le backend retourne un article sans `unitType` (ancienne donnée avant migration)
**When** `Product.fromJson()` parse la réponse
**Then** `unitType` prend la valeur par défaut `'piece'`
**And** aucune exception n'est levée

### AC3 — Reçu affiché correctement

**Given** un reçu contenant une ligne "Tomates — 1.5 kg × 1 500 F/kg = 2 250 F"
**When** `ReceiptDialog` est rendu en test widget
**Then** le texte "1.5 kg" apparaît dans le widget
**And** le texte "2 250" apparaît dans le widget
**And** aucun texte "pièce(s)" ou "1 pcs" n'apparaît pour cette ligne

### AC4 — Calcul arrondi FCFA

**Given** un article à `1 333 F/kg`
**When** la quantité `0.75 kg` est saisie → total brut = `999.75 F`
**Then** le total affiché et enregistré = `1 000 F` (arrondi au plus proche multiple de 5)

### AC5 — conversionRate appliqué correctement

**Given** un article "Sachet farine" avec `conversionRate = 0.5` (1 sachet = 0.5 kg de stock)
**When** une vente de `3 sachets` est synchronisée avec le backend
**Then** le `InventoryMovement.quantity` créé par le backend est `1.5` (3 × 0.5)
**And** le stock de l'article diminue de `1.5`

### AC6 — Test d'intégration backend (NestJS)

**Given** `catalog.service.spec.ts`
**When** les tests d'intégration sont exécutés
**Then** :
- Migration appliquée → colonnes présentes avec bonnes valeurs par défaut
- Create item `unitType: 'volume'` → GET retourne `unitType: 'volume'`
- Sync delta `?since=T` → articles modifiés incluent `unitType` et `pricePerUnit`

---

## Tasks/Subtasks

- [ ] **Task 1 : Product.fromJson() robuste**
  - [ ] Dans `product.dart`, utiliser `json['unitType'] ?? json['unit_type'] ?? 'piece'` pour compatibilité snake_case/camelCase
  - [ ] `pricePerUnit` : `(json['pricePerUnit'] ?? json['price_per_unit'])?.toDouble()`
  - [ ] `conversionRate` : `(json['conversionRate'] ?? json['conversion_rate'])?.toDouble()`
  - [ ] Vérifier qu'aucune exception n'est levée si les champs sont absents

- [ ] **Task 2 : Tests intégration backend**
  - [ ] Dans `catalog.service.spec.ts`, ajouter :
    - Test : createItem `unitType: 'volume'` → getItems retourne `unitType: 'volume'`
    - Test : sync delta `?since=T` → articles incluent `unitType` + `pricePerUnit`
    - Test : conversionRate 0.5 + qty 3 → InventoryMovement.quantity = 1.5

- [ ] **Task 3 : Test widget ReceiptDialog poids**
  - [ ] Créer `apps/frontend/test/features/pos/receipt_dialog_weight_test.dart`
  - [ ] Rendre `ReceiptDialog` avec un item weight (1.5 kg, 1500 F/kg, total 2250 F)
  - [ ] Vérifier : texte "1.5 kg" présent
  - [ ] Vérifier : texte "2 250" présent
  - [ ] Vérifier : pas de "pièce(s)" pour cet item

- [ ] **Task 4 : Test arrondi FCFA**
  - [ ] Dans `quantity_input_dialog_test.dart` ou test unitaire séparé
  - [ ] `1 333 × 0.75 = 999.75` → arrondi à `1 000`
  - [ ] `1 500 × 1.5 = 2 250` → pas d'arrondi nécessaire (déjà multiple de 5)
  - [ ] `1 100 × 0.3 = 330` → résultat = `330` (déjà multiple de 5)

- [ ] **Task 5 : Isar schema version bump**
  - [ ] Si `unitType` est ajouté comme champ indexé dans Isar, bumper `@Collection(inheritance: false)` schemaVersion ou annoter le champ

- [ ] **Task 6 : Run tests complets**
  - [ ] `flutter test` — zéro régression
  - [ ] `npm run test` dans `apps/backend` — zéro régression

---

## Files to Create/Modify

**New files:**
- `apps/frontend/test/features/pos/receipt_dialog_weight_test.dart`

**Modified files:**
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — fromJson robuste
- `apps/backend/src/shared/catalog/catalog.service.spec.ts` — tests migration + sync

## Dev Notes

- `Product.fromJson()` doit utiliser `json['unitType'] ?? json['unit_type'] ?? 'piece'` pour la compatibilité snake_case/camelCase
- Isar schema version bump nécessaire si `unitType` est ajouté comme champ indexé
- L'arrondi FCFA : `(rawTotal / 5).round() * 5`
