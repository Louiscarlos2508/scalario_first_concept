# Story 23.3 — Frontend : POS vente du produit enfant (décrémente stock parent)

## Metadata

- **Epic:** Epic 23 — Conversion unités vrac → détail
- **Story ID:** 23-3-pos-vente-enfant
- **Status:** done
- **Priority:** High
- **Depends on:** 23-1 (décrémentation parent backend), 23-2 (modèle Product enrichi)

---

## Story

**As a** cashier,
**I want** to sell child articles (sachets, portions) at the POS with automatic parent stock tracking and a clear warning when parent stock is low,
**So that** bulk consumption is tracked without manual intervention (FR83).

---

## Acceptance Criteria

### AC1 — Vente article enfant au POS — flux normal

**Given** un article enfant (avec `parentItemId`) est ajouté au panier
**When** la transaction est validée
**Then** la vente se complète normalement — aucune différence visible pour le caissier
**And** le backend décrémente le stock du parent (Story 23-1 AC3)
**And** le reçu affiche l'article enfant vendu (nom, quantité, prix) sans mention du parent

### AC2 — Alerte stock parent faible

**Given** la transaction renvoie `warning: "PARENT_STOCK_LOW"` dans la réponse
**When** la transaction est confirmée
**Then** une snackbar orange apparaît après validation : "Stock faible : [nomParent] — [stockAfter] [unitLabel] restant(s)"
**And** la snackbar est non bloquante (ne nécessite pas d'action) et disparaît après 4 secondes
**And** la vente n'est PAS annulée — la snackbar est informationnelle uniquement

### AC3 — Grille POS — badge "VRAC" sur article parent

**Given** un article a des enfants liés (`hasChildren = true`)
**When** la grille POS s'affiche
**Then** un badge discret "VRAC" apparaît sur la card de l'article parent
**And** les articles enfants n'ont pas ce badge

### AC4 — Stock parent local mis à jour après vente

**Given** une vente d'article enfant est synchronisée
**When** la sync retour met à jour les stocks locaux
**Then** le stock local du parent (dans Isar) est décrémenté de `quantity × conversionRate`
**And** si le stock parent passe sous `minStockLevel`, l'alerte stock bas (Epic 22) se déclenche

---

## Tasks/Subtasks

- [ ] **Task 1 : CheckoutController — lire `warning` de la réponse**
  - [ ] Après POST transaction, vérifier si réponse contient `warning: "PARENT_STOCK_LOW"`
  - [ ] Si présent, émettre event ou retourner le warning dans le state

- [ ] **Task 2 : CartPanel — snackbar alerte parent**
  - [ ] Écouter le state du checkout pour les warnings
  - [ ] Afficher snackbar orange : "Stock faible : [nomParent] — [stockAfter] restant(s)"
  - [ ] Auto-dismiss après 4 secondes

- [ ] **Task 3 : Grille POS — badge VRAC**
  - [ ] Dans `product_grid.dart`, si `product.hasChildren == true` (ou `parentItemId != null` sur l'article)
  - [ ] Afficher chip texte "VRAC" en discret sur la card

- [ ] **Task 4 : Sync locale stock parent**
  - [ ] Après vente d'article enfant, décrémenter Isar stock parent de `quantity × conversionRate`
  - [ ] Peut se faire dans le `CatalogRepository` après sync delta

---

## Files to Modify

- `apps/frontend/lib/features/retail/pos/presentation/state/checkout_controller.dart` — lire `warning` de la réponse
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — snackbar alerte parent
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_grid.dart` — badge VRAC

## Dev Notes

- Le `cartNotifier` doit lire `parentItemId` pour informer l'UI post-validation
- La logique de décrémentation parent est entièrement backend — le frontend ne calcule pas, il affiche le warning du backend
- Le badge "VRAC" sur la card parent est optionnel MVP — peut être un simple chip texte
