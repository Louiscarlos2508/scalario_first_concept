# Story 20.3 — Frontend : POS vente au poids

## Metadata

- **Epic:** Epic 20 — Vente au poids + unités configurables
- **Story ID:** 20-3-pos-vente-au-poids
- **Status:** done
- **Priority:** High
- **Depends on:** 20-1 (backend), 20-2 (modèle Product enrichi)

---

## Story

**As a** commercial (Fatou),
**I want** the POS to show a quantity input when I add a weight/volume article,
**So that** I can sell 1.5 kg of tomatoes and get the correct total automatically (FR77).

---

## Acceptance Criteria

### AC1 — Déclenchement saisie quantité

**Given** la grille POS affiche un article avec `unitType = 'weight'` (ou `volume`, `length`)
**When** l'utilisateur tape sur la carte produit
**Then** un dialog "Saisir la quantité" apparaît immédiatement (avant ajout au panier)
**And** le dialog affiche : nom du produit, champ numérique en virgule flottante, label unité (ex: "kg"), prix unitaire (ex: "1 500 F/kg")
**And** la validation est immédiate : toute valeur > 0 est acceptée

### AC2 — Calcul total automatique

**Given** l'utilisateur saisit `1.5` dans le dialog quantité d'un article à `1 500 F/kg`
**When** il confirme
**Then** l'article est ajouté au panier avec quantité `1.5`, total ligne = `2 250 F` (arrondi 5 FCFA)
**And** le total panier est mis à jour immédiatement

### AC3 — Affichage panier

**Given** un article au poids est dans le panier
**When** le panneau panier (`CartPanel`) affiche la ligne
**Then** la quantité s'affiche avec l'unité native : "1.5 kg" (pas "1.5 pièce(s)")
**And** le prix ligne affiche "2 250 F"

### AC4 — Article pièce inchangé

**Given** un article avec `unitType = 'piece'`
**When** l'utilisateur tape sur la carte produit
**Then** le comportement existant est préservé (ajout direct, quantité entière, pas de dialog)

### AC5 — Reçu adapté

**Given** une vente contenant un article au poids est finalisée
**When** `ReceiptDialog` s'affiche
**Then** chaque ligne article au poids affiche : `[nom] — [quantité] [unité] × [prix/unité] = [total ligne]`
**And** les articles pièce affichent le format actuel inchangé

### AC6 — Transaction enregistrée

**Given** la vente est soumise au backend
**When** `itemsJson` est sérialisé dans la `Transaction`
**Then** chaque item au poids contient : `{"catalogItemId", "quantity": 1.5, "unitType": "weight", "unitLabel": "kg", "pricePerUnit": 1500, "lineTotal": 2250}`

### AC7 — Test widget

**Given** le widget test du `QuantityInputDialog`
**When** l'utilisateur entre `2.3` et confirme
**Then** le `CartNotifier` reçoit l'article avec `quantity = 2.3`
**And** le total calculé = `pricePerUnit × 2.3` arrondi au plus proche multiple de 5

---

## Tasks/Subtasks

- [ ] **Task 1 : QuantityInputDialog — nouveau widget**
  - [ ] Créer `apps/frontend/lib/features/retail/pos/presentation/widgets/quantity_input_dialog.dart`
  - [ ] Champ numérique décimal, validation > 0
  - [ ] Afficher : nom produit, label unité, prix/unité, prévisualisation total en temps réel
  - [ ] Boutons "Annuler" et "Confirmer"
  - [ ] Retourner la quantité saisie (double) via `Navigator.pop(quantity)`

- [ ] **Task 2 : ProductGrid — détecter unitType et ouvrir dialog**
  - [ ] Dans `product_grid.dart`, au tap sur une carte : si `product.unitType != 'piece'`, ouvrir `QuantityInputDialog`
  - [ ] Après confirmation, appeler `cartNotifier.addProductWithQuantity(product, quantity)`
  - [ ] Si `unitType == 'piece'`, comportement actuel inchangé

- [ ] **Task 3 : CartNotifier — gérer quantité flottante**
  - [ ] Dans `cart_notifier.dart`, ajouter méthode `addProductWithQuantity(Product, double quantity)`
  - [ ] Calculer `lineTotal = (pricePerUnit ?? price) × quantity` arrondi multiple de 5 FCFA
  - [ ] Permettre `CartItem.quantity` de type double (au lieu de int si applicable)

- [ ] **Task 4 : CartPanel — affichage unité native**
  - [ ] Dans la ligne panier, afficher `"${quantity} ${unitLabel ?? 'pièce(s)'}"`
  - [ ] Si `unitType == 'piece'`, afficher format actuel

- [ ] **Task 5 : ReceiptDialog — format ligne poids**
  - [ ] Pour chaque item avec `unitType != 'piece'`, format : `[nom] — [qty] [unitLabel] × [pricePerUnit] F = [lineTotal] F`
  - [ ] Pour les articles `piece`, format actuel inchangé

- [ ] **Task 6 : CheckoutController — sérialisation itemsJson**
  - [ ] Inclure `unitType`, `unitLabel`, `pricePerUnit`, `lineTotal` dans `itemsJson` pour chaque ligne

- [ ] **Task 7 : Test widget**
  - [ ] Créer `apps/frontend/test/features/pos/quantity_input_dialog_test.dart`
  - [ ] Test : entrée 2.3 → CartNotifier reçoit quantity = 2.3
  - [ ] Test : total = pricePerUnit × qty arrondi multiple de 5

---

## Files to Create/Modify

**New files:**
- `apps/frontend/lib/features/retail/pos/presentation/widgets/quantity_input_dialog.dart`
- `apps/frontend/test/features/pos/quantity_input_dialog_test.dart`

**Modified files:**
- `apps/frontend/lib/features/retail/pos/presentation/widgets/product_grid.dart` — détecter unitType + ouvrir dialog
- `apps/frontend/lib/features/retail/pos/presentation/state/cart_notifier.dart` — quantité flottante
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — affichage unité native
- `apps/frontend/lib/features/retail/pos/presentation/widgets/receipt_dialog.dart` — format ligne poids
- `apps/frontend/lib/features/retail/pos/presentation/state/checkout_controller.dart` — sérialisation itemsJson
