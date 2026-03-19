# Story 25.3 — Frontend : POS sélection variante à la vente

## Metadata

- **Epic:** Epic 25 — Variantes, multi-tarifs & promotions
- **Story ID:** 25-3-pos-variant-selection
- **Status:** ready-for-dev
- **Priority:** High
- **Depends on:** 25-1 (backend), 25-2 (modèle ProductVariant)

---

## Story

**As a** cashier,
**I want** a variant selector to appear automatically when I tap an article with variants,
**So that** I can sell the exact variant the customer wants without leaving the POS screen (FR89).

---

## Acceptance Criteria

### AC1 — Sélecteur de variante au tap

**Given** un article avec `hasVariants = true` est tappé dans la grille POS
**When** la grille détecte le tap
**Then** une bottom sheet `VariantSelectorSheet` s'ouvre avec la liste des variantes actives
**And** chaque variante affiche ses attributs (ex: "Taille M — Bleu"), son prix et son stock
**And** les variantes en rupture de stock (`stockQuantity = 0`) sont grisées mais visibles

### AC2 — Ajout au panier avec variante

**Given** le caissier sélectionne une variante
**When** il confirme
**Then** la variante est ajoutée au panier avec son prix propre (pas le prix parent)
**And** la ligne panier affiche : nom article + attributs variante (ex: "T-Shirt — Taille M, Bleu")
**And** le reçu affiche également les attributs de la variante

### AC3 — Scan barcode variante

**Given** le caissier scanne un barcode de variante
**When** la grille POS reçoit le barcode
**Then** la variante est directement ajoutée au panier sans passer par le sélecteur
**And** si le barcode correspond à l'article parent (pas une variante), le sélecteur s'ouvre normalement

### AC4 — Offline

**Given** l'appareil est hors ligne
**When** le sélecteur de variantes s'ouvre
**Then** les variantes sont chargées depuis Isar (synchronisées lors de la dernière connexion)
**And** le stock affiché est le stock local (peut être décalé — acceptable offline)

---

## Tasks/Subtasks

- [ ] **Task 1 : VariantSelectorSheet**
  - [ ] Créer `apps/frontend/lib/features/retail/pos/presentation/widgets/variant_selector_sheet.dart`
  - [ ] Liste des variantes actives : attributs, prix, stock
  - [ ] Variantes en rupture grisées mais visibles
  - [ ] Tap variante → retourner la variante sélectionnée via `Navigator.pop(variant)`

- [ ] **Task 2 : ProductGrid — détecter hasVariants**
  - [ ] Si `product.hasVariants == true`, ouvrir `VariantSelectorSheet` au tap
  - [ ] Si `unitType != 'piece'`, ouvrir `QuantityInputDialog` après sélection variante
  - [ ] Si `hasVariants == false`, comportement actuel

- [ ] **Task 3 : CartNotifier — addProductWithVariant**
  - [ ] Méthode `addProductWithVariant(product, variant, [quantity])` dans `cart_notifier.dart`
  - [ ] Prix de la ligne = `variant.price` (pas `product.price`)
  - [ ] Label panier : `"${product.name} — ${variant.attributesLabel}"`

- [ ] **Task 4 : CheckoutController — variantId dans itemsJson**
  - [ ] Inclure `variantId` dans `itemsJson` pour chaque ligne avec variante

- [ ] **Task 5 : CartPanel — afficher attributs variante**
  - [ ] Sur la ligne panier, afficher attributs sous le nom (ex: "Taille M, Bleu")

- [ ] **Task 6 : ReceiptDialog — afficher attributs variante**
  - [ ] Chaque ligne avec variante affiche les attributs dans le reçu

- [ ] **Task 7 : Scan barcode variante**
  - [ ] Si lookup barcode retourne `matchedVariant`, ajouter directement sans sélecteur

---

## Files to Create

- `apps/frontend/lib/features/retail/pos/presentation/widgets/variant_selector_sheet.dart`

## Files to Modify

- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_grid.dart` — détecter `hasVariants` + ouvrir sélecteur
- `apps/frontend/lib/features/retail/pos/presentation/state/checkout_controller.dart` — addToCart avec variantId
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — attributs variante
- `apps/frontend/lib/features/retail/pos/presentation/state/cart_notifier.dart` — addProductWithVariant
