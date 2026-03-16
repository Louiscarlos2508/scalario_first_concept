# Story 15.3 — UI French Labels — POS

## Metadata
- **Epic:** Epic 15 — SDUI Dashboard & UI Polish
- **Story ID:** 15-3-ui-french-labels-pos
- **Status:** review
- **Priority:** High
- **Depends on:** aucun (parallélisable avec 15-4)

---

## Story

**As a** cashier using Scalario POS,
**I want** all POS labels and buttons to be in French with FCFA currency,
**So that** the interface matches the language and currency of West African merchants (design system: "Français d'abord").

---

## Acceptance Criteria

1. **Checkout button** — `cart_panel.dart`: "Checkout" / "CHECKOUT" → **"ENCAISSER"**. The button is the largest element on screen (Loi de Fitts — primary action bottom-right of cart panel).

2. **Session labels** — `session_guard.dart`, `session_report_dialog.dart`, `pos_screen.dart`:
   - "Open Session" / "No active session" → **"Ouvrir la caisse"** / **"Aucune session active"**
   - "Opening Balance" → **"Fond de caisse"**
   - "Close Session" → **"Fermer la session"**
   - "Session Report" → **"Rapport de caisse"**
   - "Variance" → **"Écart"**

3. **Cart labels** — `cart_panel.dart`:
   - "Cart" / "Your cart is empty" → **"Panier"** / **"Panier vide"**
   - "Total:" → **"Total :"**
   - "Cash" → **"Espèces"**
   - "Change:" / "Change due:" → **"Monnaie rendue :"**
   - "Pay" → **"Payer"**
   - "Discount" → **"Remise"**
   - "Remove" → **"Supprimer"**

4. **Product grid labels** — `product_grid.dart`:
   - "Products" / "Search products..." → **"Produits"** / **"Rechercher..."**
   - "All" (category tab) → **"Tout"**
   - "Out of stock" → **"Rupture de stock"**
   - "Add to cart" (tooltip) → **"Ajouter au panier"**

5. **Customer labels** — `customer_selection_dialog.dart`:
   - "Select Customer" → **"Choisir un client"**
   - "Search customers..." → **"Rechercher un client..."**
   - "No customer" → **"Aucun client"**
   - "Cash sale" → **"Vente comptant"**

6. **Other dialogs** — `discount_dialog.dart`, `receipt_dialog.dart`, `parked_carts_dialog.dart`:
   - "Apply Discount" → **"Appliquer une remise"**
   - "Receipt" → **"Reçu"**
   - "Print" → **"Imprimer"**
   - "Parked Carts" → **"Ventes en attente"**
   - "Park" → **"Mettre en attente"**
   - "Resume" → **"Reprendre"**

7. **Sync indicator** — `sync_status_indicator.dart`:
   - "Syncing..." → **"Synchronisation..."**
   - "Synced" → **"Synchronisé"**
   - "Offline" → **"Hors ligne"**
   - "Sync error" → **"Erreur de sync"**

8. **Currency** — All occurrences of `\$`, `'\$'`, `USD`, `' $'` in POS widget files replaced by **`FCFA`**. Format: `1 500 FCFA` (space separator, no decimals for FCFA — 5-franc rounding already handled by backend).

9. **No regression** — All existing tests pass. `pos_screen_test.dart` updated to match new French labels where assertions check label text.

---

## Tasks/Subtasks

- [x] **Task 1: Translate `cart_panel.dart`**
  - [x] All labels per AC3 + FCFA currency

- [x] **Task 2: Translate `product_grid.dart`**
  - [x] All labels per AC4

- [x] **Task 3: Translate `session_guard.dart` and `session_report_dialog.dart`**
  - [x] All labels per AC2

- [x] **Task 4: Translate `customer_selection_dialog.dart`**
  - [x] All labels per AC5

- [x] **Task 5: Translate `discount_dialog.dart`, `receipt_dialog.dart`, `parked_carts_dialog.dart`**
  - [x] All labels per AC6

- [x] **Task 6: Translate `sync_status_indicator.dart`**
  - [x] All labels per AC7

- [x] **Task 7: Update `pos_screen_test.dart`** — update text assertions to French

- [x] **Task 8: Run `flutter test` — zero errors/regressions**

---

## Dev Notes

### File Inventory (all files to modify)

```
apps/frontend/lib/features/pos/presentation/widgets/cart_panel.dart
apps/frontend/lib/features/pos/presentation/widgets/product_grid.dart
apps/frontend/lib/features/pos/presentation/widgets/session_guard.dart (if labels exist)
apps/frontend/lib/features/pos/presentation/widgets/session_report_dialog.dart
apps/frontend/lib/features/pos/presentation/widgets/customer_selection_dialog.dart
apps/frontend/lib/features/pos/presentation/widgets/discount_dialog.dart
apps/frontend/lib/features/pos/presentation/widgets/receipt_dialog.dart
apps/frontend/lib/features/pos/presentation/widgets/parked_carts_dialog.dart
apps/frontend/lib/features/pos/presentation/widgets/sync_status_indicator.dart
apps/frontend/test/pos_screen_test.dart                                    ← assertions update
```

### Currency Format

Use `intl` package (already in pubspec.yaml):
```dart
// FCFA — no decimals, space separator
NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(amount)
// → "1 500 FCFA"
```

### Design System Constraint

Per `docs/design-system.md`:
- "ENCAISSER" button = largest element on screen, bottom-right of cart panel (Loi de Fitts)
- Labels must be concise — Loi de Miller: max 3-4 words per label
- All error/feedback messages in French (AC7 sync indicator)

---

## Dev Agent Record

### Implementation Plan

Added `_fcfa()` helper (top-level in each file needing currency) using `NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)`. Translated all labels file-by-file per AC:

1. `cart_panel.dart` — Title "Panier", "ENCAISSER", "Total :", "ATTENTE", "Annuler/Enregistrer/Confirmer", "Vente réussie !", all FCFA amounts. "Mode :" payment selector.
2. `product_grid.dart` — "Tout" category chip, "Aucun produit trouvé.", price FCFA, "Stock en magasins :".
3. `session_guard.dart` — "Ouvrir la caisse", "Fond de caisse" field label.
4. `session_report_dialog.dart` — "Rapport de caisse (Z-Report)", "Écart", "Fond de caisse", all FCFA amounts, "Retour/Confirmer la fermeture".
5. `customer_selection_dialog.dart` — "Choisir un client", "Rechercher un client...", "Aucun client trouvé.", FCFA balances, "NOUVEAU CLIENT", "Régler la dette".
6. `discount_dialog.dart` — "Remise :", "Montant", "FCFA" radio label, "Annuler/Appliquer", French snackbar errors.
7. `receipt_dialog.dart` — "Reçu", "N° commande :", "TOTAL :", FCFA amounts, "Merci pour votre achat !", "Fermer/Imprimer".
8. `parked_carts_dialog.dart` — "Ventes en attente", "Aucune vente en attente", FCFA subtotals, "Sans nom".
9. `sync_status_indicator.dart` — "Synchronisé", "Synchronisation...", "Erreur de sync", "Hors ligne", "Reconnexion...".
10. `pos_screen_test.dart` — Updated assertions to use `textContaining('100')`/`textContaining('200')` for FCFA prices, `'Total :'` for label, `findsWidgets` for FCFA presence.

### Completion Notes

All 8 tasks complete. 63/63 tests pass. Zero regressions.

---

## File List

| Action | Path |
|--------|------|
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/cart_panel.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/product_grid.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/session_guard.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/session_report_dialog.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/customer_selection_dialog.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/discount_dialog.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/receipt_dialog.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/parked_carts_dialog.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/widgets/sync_status_indicator.dart` |
| Modified | `apps/frontend/test/pos_screen_test.dart` |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story created — French labels and FCFA currency for all POS widgets |
| 2026-03-15 | Implementation complete — 9 POS widgets translated to French + FCFA, 63/63 tests green |
