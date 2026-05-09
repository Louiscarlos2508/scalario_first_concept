# Story 16.4 — Inventaire partiel

## Metadata

- **Epic:** Epic 16 — Retail Operations — Gestion Stock Terrain
- **Story ID:** 16-4-partial-inventory
- **Status:** review
- **Priority:** High
- **Depends on:** 16-1 (InventoryRepository créé)

---

## Story

**As a** manager (Moussa),
**I want** to perform a partial inventory count with visual variance signal,
**So that** discrepancies between physical and system stock are identified and corrected (FR35).

---

## Acceptance Criteria

1. **Sélection des produits à compter** — `partial_inventory_screen.dart` :
   - Liste des produits avec checkbox multi-sélection
   - Recherche textuelle pour filtrer
   - Bouton **"Démarrer le comptage"** activé dès qu'au moins 1 produit est sélectionné

2. **Feuille de comptage** — `inventory_count_sheet.dart` :
   - Pour chaque produit sélectionné :
     - Nom + stock système (issu de `GET /inventory/stock?catalogItemId=X&tenantId=Y`)
     - Champ quantité physique comptée (entier ≥ 0)
     - Signal visuel : `AppColors.success` si physique == système, `AppColors.error` si écart
   - Chargement stock système en parallèle (FutureProvider par produit)

3. **Motif global :**
   - Si au moins un produit a un écart → champ motif obligatoire (ex. "Inventaire mensuel mars")
   - Si aucun écart → motif non affiché

4. **Soumission :**
   - Pour chaque produit avec écart → `POST /inventory/adjust` body `{catalogItemId, countedQuantity, reason, tenantId}`
   - Produits sans écart → aucun appel API
   - Résumé final : "X produits ajustés, Y produits sans écart"
   - Snackbar de confirmation globale

5. **Test `test/inventory_partial_count_test.dart`** :
   - Compter 1 produit avec écart → `InventoryMovement.type == 'ADJUSTMENT'` créé
   - Compter 1 produit sans écart → `POST /inventory/adjust` non appelé
   - Widget test : signal vert/rouge présent selon la variance
   - Test motif obligatoire si écart détecté

---

## Tasks/Subtasks

- [x] **Task 1 : Créer `partial_inventory_screen.dart`** — sélection multi-produits
  - [x] Liste + checkbox + recherche
  - [x] Bouton démarrer activé si ≥ 1 sélectionné

- [x] **Task 2 : Créer `inventory_count_sheet.dart`** — feuille de comptage
  - [x] Provider `inventoryStockProvider(catalogItemId, tenantId)` → `GET /inventory/stock`
  - [x] Champ quantité par produit
  - [x] Signal couleur selon variance locale

- [x] **Task 3 : Logique de soumission**
  - [x] Calculer liste des produits avec écart
  - [x] Appel `POST /inventory/adjust` par produit en écart
  - [x] Motif obligatoire si écart

- [x] **Task 4 : Créer `test/inventory_partial_count_test.dart`**
  - [x] Test avec écart → ADJUSTMENT créé
  - [x] Test sans écart → pas d'appel
  - [x] Test signal couleur

- [x] **Task 5 : `flutter test` — zéro régression**

---

## Dev Notes

### Endpoints backend

```http
GET /inventory/stock?catalogItemId=X&tenantId=Y
Response: { catalogItemId, tenantId, currentStock: number, computedAt: string }

POST /inventory/adjust
RBAC: owner, manager
Body: {
  catalogItemId: string,
  countedQuantity: number,
  reason: string,
  tenantId: string
}
Response: {
  adjusted: boolean,
  variance: number,
  movement?: InventoryMovement
}
```

### Logique variance (backend)

```typescript
const variance = data.countedQuantity - currentStock;
// variance > 0 → surplus
// variance < 0 → déficit
// variance == 0 → { adjusted: false }
```

---

## Dev Agent Record

### Implementation Plan

- `PartialInventoryScreen` est un écran deux phases (`_Phase.selection` / `_Phase.counting`) géré par un seul `ConsumerStatefulWidget` — évite la navigation et simplifie le passage d'état.
- Phase sélection : `_SelectionView` stateless avec `CheckboxListTile` par produit, champ recherche (`Key('product_search_field')`), bouton `Key('start_count_button')` désactivé si sélection vide.
- Phase comptage : `_CountingView` stateless paramétré — charge le stock système en parallèle (`getStock()` par produit au `initState` equivalent via `_loadSystemStocks()`).
- Signal variance : `Key('variance_ok_$id')` (vert ✓) / `Key('variance_error_$id')` (rouge ✗) — calculé localement à chaque `onCountChanged`.
- Motif (`Key('count_reason_field')`) : affiché conditionnellement via `hasAnyVariance`, bloque `_canSubmitCount` si vide.
- `adjustStock()` / `getStock()` ajoutés au `InventoryRepository` — injectable `http.Client` pour testabilité.

### Completion Notes

- **100/100 tests pass** (89 existants + 11 nouveaux), zéro régression.
- AC1 ✅ : Checkboxes, recherche textuelle, bouton conditionnel
- AC2 ✅ : Chargement stock parallèle, champs quantité, signals vert/rouge
- AC3 ✅ : Motif conditionnel affiché uniquement si variance ≠ 0
- AC4 ✅ : `adjustStock` appelé uniquement pour les produits avec écart, snackbar résumé
- AC5 ✅ : 11 tests — sélection, filtrage, variance signal, soumission sélective, motif obligatoire, getStock/adjustStock unitaires

---

## File List

| Action | Path |
| ------ | ---- |
| Created | `apps/frontend/lib/features/dashboard/presentation/screens/partial_inventory_screen.dart` |
| Modified | `apps/frontend/lib/features/dashboard/data/repositories/inventory_repository.dart` |
| Created | `apps/frontend/test/inventory_partial_count_test.dart` |

---

## Change Log

| Date | Change |
| ---- | ------ |
| 2026-03-15 | Story créée — inventaire partiel avec signal variance (FR35) |
| 2026-03-15 | Implemented: partial_inventory_screen.dart, repo extensions, 11 tests — 100/100 pass |
