# Story 17.4 — Frontend : Ajout produit depuis le backoffice catalogue

## Metadata
- **Epic:** Epic 17 — Dépenses & Bénéfice
- **Story ID:** 17-4-add-product-backoffice
- **Status:** review
- **Priority:** Medium
- **Depends on:** Epic 10 (SDUI), Epic 14 (design system)

---

## Story

**As a** store owner in the backoffice,
**I want** to add a new product to the catalog directly from the backoffice,
**So that** I don't need to use a separate admin interface.

---

## Acceptance Criteria

1. **Formulaire d'ajout** (FAB "+" sur `CatalogScreen`) :
   - Nom (texte, obligatoire)
   - Prix (numérique, obligatoire)
   - Catégorie (dropdown, liste des catégories du tenant via `categoriesProvider`)
   - Barcode (texte, optionnel)
   - Quantité initiale en stock (numérique, défaut 0)

2. **Validation locale** :
   - Nom ou Prix absent → champ souligné en rouge, submit bloqué

3. **Submit valide** :
   - `POST /catalog/items` → crée le `CatalogItem`
   - Si quantité initiale > 0 → `POST /inventory/movements` body `{ type: "DELIVERY", catalogItemId, quantity }` (backend créé Story 5)
   - Snackbar "Produit ajouté", liste catalogue rafraîchie

4. **Gestion d'erreurs** :
   - Erreur réseau → snackbar rouge avec message d'erreur

---

## Structure fichiers

```
lib/features/retail/catalog/
  data/
    repositories/catalog_repository.dart      ← new
  presentation/
    providers/catalog_providers.dart          ← new
    screens/catalog_screen.dart               ← new (FAB "+")
    widgets/product_form_dialog.dart          ← updated (submitToCatalog flag + keys)
```

---

## Tasks/Subtasks

- [x] **Task 1 : `ProductFormDialog`**
  - [x] Formulaire avec tous les champs
  - [x] Validation locale (Nom + Prix obligatoires)
  - [x] Dropdown catégories depuis `categoriesProvider`

- [x] **Task 2 : `CatalogScreen` — FAB**
  - [x] Ajouter FAB "+" qui ouvre `ProductFormDialog`

- [x] **Task 3 : Submit**
  - [x] `POST /catalog/items` via `CatalogRepository`
  - [x] Si `initialStock > 0` → `POST /inventory/movements` (DELIVERY)
  - [x] `ref.invalidate(catalogProvider)` après succès

- [x] **Task 4 : Tests**
  - [x] Widget test : formulaire présent, validation Nom + Prix obligatoires
  - [x] Submit valide → `CatalogRepository.createItem()` appelé avec les bons paramètres
  - [x] Quantité > 0 → `InventoryRepository.createMovement(type: "DELIVERY")` appelé
  - [x] Erreur réseau → snackbar rouge affiché

---

## Dev Notes

- `ProductFormDialog` extended with `submitToCatalog` flag (default `false`). When `true`, the dialog calls `CatalogRepository.createItem()` + `InventoryRepository.createMovement()` directly. When `false`, existing POS/inventory behavior (pop with Product data) is preserved — backward compatible.
- `CatalogScreen` replaces `CategoriesScreen` in the backoffice nav ("Catégories" → "Catalogue"). `CategoriesScreen` remains accessible via an AppBar icon in `CatalogScreen`.
- `catalogProvider` is a `FutureProvider<List<Map<String, dynamic>>>` (no local model needed — raw API maps for simplicity).
- `CatalogRepository` follows the same constructor-injection pattern (`http.Client?` + `String? Function()? tokenGetter`) for test isolation.

---

## Dev Agent Record

### Implementation Plan
- Task 1: Added `submitToCatalog` flag, widget keys (`product_name_field`, `product_price_field`, `product_stock_field`, `product_barcode_field`, `product_category_field`, `product_submit_button`), and `_submitToCatalogApi()` async path to `ProductFormDialog`.
- Task 2: Created `CatalogScreen` with FAB (`catalog_fab`), empty state (`catalog_empty_state`), item list (`catalog_item_{id}`).
- Task 3: `CatalogRepository.createItem()` + `InventoryRepository.createMovement(DELIVERY)` in submit path, `ref.invalidate(catalogProvider)` on success.
- Task 4: 9 tests in `catalog_screen_test.dart` covering all ACs.
- Navigation: replaced `CategoriesScreen` at index 2 with `CatalogScreen` ("Catalogue"). No new nav item — count stays at 8.

### Completion Notes
- All 4 tasks complete and validated.
- 144/144 flutter tests pass (9 new tests added, zero regressions).
- Backward compatibility: `ProductFormDialog(submitToCatalog: false)` still works for `InventoryScreen` product editing.

---

## File List

- `apps/frontend/lib/features/retail/catalog/data/repositories/catalog_repository.dart` — new
- `apps/frontend/lib/features/retail/catalog/presentation/providers/catalog_providers.dart` — new
- `apps/frontend/lib/features/retail/catalog/presentation/screens/catalog_screen.dart` — new
- `apps/frontend/lib/features/retail/catalog/presentation/widgets/product_form_dialog.dart` — updated (`submitToCatalog` flag, widget keys, `_submitToCatalogApi()`)
- `apps/frontend/lib/features/retail/backoffice/presentation/widgets/dashboard_shell.dart` — updated: "Catégories" → "Catalogue" nav label + icon
- `apps/frontend/lib/features/retail/backoffice/presentation/screens/dashboard_screen.dart` — updated: `CategoriesScreen` → `CatalogScreen`
- `apps/frontend/test/catalog_screen_test.dart` — new, 9 tests

---

## Change Log

- 2026-03-16 — Story 17-4 implemented. CatalogRepository, catalog_providers, CatalogScreen, ProductFormDialog updated with submitToCatalog flag. 9 new tests. 144/144 pass.
