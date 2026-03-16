# Story 16.2 — Transfert stock magasin → rayon

## Metadata

- **Epic:** Epic 16 — Retail Operations — Gestion Stock Terrain
- **Story ID:** 16-2-stock-transfer
- **Status:** review
- **Priority:** High
- **Depends on:** 16-1 (InventoryRepository créé)

---

## Story

**As a** manager (Moussa) and a commercial (Fatou),
**I want** to declare a stock transfer out and confirm reception with chain-of-custody,
**So that** the double-validation pattern traces variance automatically (FR31, FR32, FR33).

---

## Acceptance Criteria

1. **Formulaire déclaration sortie (gestionnaire/owner)** — `transfer_out_form.dart` :
   - Sélection produit + quantité déclarée (entier > 0)
   - Notes optionnelles
   - Submit → `POST /inventory/movements` body `{type: "TRANSFER_OUT", catalogItemId, quantity, reason?, tenantId}`
   - Réponse contient `referenceId` (UUID) — stocké en `StateProvider<String?>` pour la confirmation

2. **Écran en attente de confirmation** — `transfer_pending_screen.dart` :
   - Affiche : produit, quantité déclarée, referenceId tronqué, date/heure
   - Bouton **"Confirmer la réception"** visible au récepteur
   - Liste des transferts en attente : `GET /inventory/movements?tenantId=&referenceId=`

3. **Formulaire confirmation (récepteur — owner/manager/commercial)** — `transfer_confirm_form.dart` :
   - Champ quantité effectivement reçue (pré-rempli = quantité déclarée)
   - Submit → `POST /inventory/movements/confirm` body `{referenceId, catalogItemId, quantity, tenantId}`
   - Succès → affiche la variance calculée (quantité déclarée − quantité reçue)

4. **Variance affichée :**
   - Variance = 0 → label vert `AppColors.success` "Aucun écart"
   - Variance ≠ 0 → label rouge `AppColors.error` "Écart : +X / −X unités"

5. **Test `test/inventory_transfer_test.dart`** :
   - TRANSFER_OUT créé → referenceId non-null dans la réponse
   - TRANSFER_IN confirmé avec variance → `reason` contient "Variance: 2"
   - Widget test : formulaires présents et soumissibles

---

## Tasks/Subtasks

- [x] **Task 1 : Créer `transfer_out_form.dart`**
  - [x] Formulaire + appel `POST /inventory/movements` type TRANSFER_OUT
  - [x] Stocker `referenceId` dans `transferPendingReferenceIdProvider`

- [x] **Task 2 : Créer `transfer_pending_screen.dart`**
  - [x] Provider `pendingTransfersProvider` → `GET /inventory/movements` filtré TRANSFER_OUT sans TRANSFER_IN correspondant
  - [x] Card par transfert en attente avec bouton confirmer

- [x] **Task 3 : Créer `transfer_confirm_form.dart`**
  - [x] Formulaire confirmation + appel `POST /inventory/movements/confirm`
  - [x] Affichage variance après succès

- [x] **Task 4 : Créer `test/inventory_transfer_test.dart`**
  - [x] Test flux TRANSFER_OUT + confirm
  - [x] Test variance

- [x] **Task 5 : `flutter test` — zéro régression**

---

## Dev Notes

### Endpoints backend

```http
POST /inventory/movements
RBAC: owner, manager
Body: { type: "TRANSFER_OUT", catalogItemId, quantity, reason?, tenantId }
Response: { id, type, quantity, referenceId, ... }  ← referenceId = UUID généré côté backend

POST /inventory/movements/confirm
RBAC: owner, manager, commercial
Body: { referenceId: string, catalogItemId?: string, quantity: number, tenantId: string }
Response: { id, type: "TRANSFER_IN", quantity, reason: "Variance: X" | null, ... }
```

### Chain-of-custody pattern

1. Moussa (manager) déclare TRANSFER_OUT → backend génère `referenceId`
2. `referenceId` est l'identifiant liant les deux movements
3. Fatou (commercial) confirme avec le même `referenceId` → backend calcule `variance = sentQty - receivedQty`
4. Si variance ≠ 0 → `TRANSFER_IN.reason = "Variance: {variance}"`

### Transferts en attente

Un transfert est "en attente" si un TRANSFER_OUT existe avec `referenceId` mais sans TRANSFER_IN correspondant. Requête :

```http
GET /inventory/movements?tenantId=X&referenceId=Y
```

Filtrer côté Flutter : si les résultats contiennent uniquement TRANSFER_OUT (pas de TRANSFER_IN) → en attente.

### StateProvider pour referenceId

```dart
final transferPendingReferenceIdProvider = StateProvider<String?>((ref) => null);
```

---

## Dev Agent Record

### Implementation Plan

- `InventoryRepository` étendu avec `getPendingTransfers()` et `confirmTransfer()`.
- `transferPendingReferenceIdProvider` défini dans `transfer_out_form.dart` (exported, accessible aux widgets consommateurs).
- `TransferPendingScreen` est un `ConsumerStatefulWidget` qui charge les transferts en attente au `initState()` et propose un `AlertDialog` de confirmation inline.
- `TransferConfirmForm` reçoit `declaredQuantity` pour pré-remplir le champ et calcule la variance client-side après confirmation pour l'affichage immédiat (sans second appel API).
- Variance affichée via `_VarianceResult` — `Key('variance_label_zero')` / `Key('variance_label_nonzero')` pour testabilité.

### Completion Notes

- **82/82 tests pass** (71 existants + 11 nouveaux), zéro régression.
- AC1 ✅ : TransferOutForm — autocomplete produit, quantité, referenceId stocké
- AC2 ✅ : TransferPendingScreen — liste TRANSFER_OUT, bouton confirmer par référence, état vide
- AC3 ✅ : TransferConfirmForm — pré-rempli, POST confirm, variance affichée
- AC4 ✅ : Labels verts/rouges avec Keys testables
- AC5 ✅ : 11 tests (3 TransferOut + 2 Pending + 4 Confirm + 2 Repository)

---

## File List

| Action | Path |
| ------ | ---- |
| Created | `apps/frontend/lib/features/dashboard/presentation/widgets/inventory/transfer_out_form.dart` |
| Created | `apps/frontend/lib/features/dashboard/presentation/widgets/inventory/transfer_pending_screen.dart` |
| Created | `apps/frontend/lib/features/dashboard/presentation/widgets/inventory/transfer_confirm_form.dart` |
| Modified | `apps/frontend/lib/features/dashboard/data/repositories/inventory_repository.dart` |
| Created | `apps/frontend/test/inventory_transfer_test.dart` |

---

## Change Log

| Date       | Change                                                                                                  |
|------------|---------------------------------------------------------------------------------------------------------|
| 2026-03-15 | Story créée — transfert stock double validation chain-of-custody (FR31-FR33)                            |
| 2026-03-15 | Implemented: 3 widgets + repo extensions + 11 tests — 82/82 pass                                       |
