# Story 16.1 — Réception livraison fournisseur

## Metadata
- **Epic:** Epic 16 — Retail Operations — Gestion Stock Terrain
- **Story ID:** 16-1-supplier-delivery-reception
- **Status:** review
- **Priority:** High
- **Depends on:** Epic 15 done (DashboardShell stable), Epic 5 backend (endpoint opérationnel)

---

## Story

**As a** manager (Moussa),
**I want** to record a supplier delivery with received quantities,
**So that** stock is credited immediately and variances are traced (FR29, FR30).

---

## Acceptance Criteria

1. **Formulaire réception** — `delivery_form.dart` :
   - Sélection du produit depuis le catalogue (recherche textuelle, affiche nom + stock actuel)
   - Champ quantité reçue (entier > 0, obligatoire)
   - Champ notes/variance (optionnel, ex. "3 caisses abîmées")
   - Bouton **"Valider la réception"** (Fitts ≥ 48dp)

2. **Appel API :**
   - Submit → `POST /inventory/movements` body `{type: "DELIVERY", catalogItemId: product.remoteId, quantity, reason?, tenantId}`
   - Succès → snackbar "Réception enregistrée" + formulaire réinitialisé
   - Erreur réseau/API → snackbar rouge `AppColors.error` + message d'erreur

3. **UX :**
   - Loading indicator pendant l'appel API
   - Bouton désactivé pendant l'envoi (évite double-soumission)
   - Quantité pré-focalisée au clavier à l'ouverture du formulaire

4. **Test `test/inventory_delivery_test.dart`** :
   - Widget test : formulaire présent, bouton submit trouvé
   - Stub API mock → submit crée une entrée avec `type == 'DELIVERY'`
   - Validation : quantité vide → bouton désactivé / erreur inline

---

## Tasks/Subtasks

- [x] **Task 1 : Créer `delivery_form.dart`** (widget stateful + ConsumerWidget)
  - [x] Champ recherche produit → `FutureProvider` sur `GET /inventory/movements` ou catalogue
  - [x] Champ quantité (TextFormField, keyboardType numeric)
  - [x] Champ notes optionnel
  - [x] Submit handler avec `POST /inventory/movements`

- [x] **Task 2 : Créer `InventoryRepository.createMovement()`**
  - [x] Appel HTTP `POST /inventory/movements`
  - [x] Gestion erreurs (timeout, 4xx, 5xx)

- [x] **Task 3 : Créer `test/inventory_delivery_test.dart`**
  - [x] Widget test formulaire
  - [x] Test submit avec mock API

- [x] **Task 4 : Intégration dans l'onglet Réceptions** (préparer — intégration finale en 16-5)

- [x] **Task 5 : `flutter test` — zéro régression**

---

## Dev Notes

### Endpoint backend

```
POST /inventory/movements
RBAC: owner, manager
Body: {
  type: "DELIVERY",
  catalogItemId: string,   // product.remoteId
  quantity: number,        // entier positif
  reason?: string | null,  // notes optionnelles
  tenantId: string
}
Response: InventoryMovement { id, type, quantity, ... }
```

### Sélection produit

Réutiliser `paginatedProductListProvider` (déjà en place dans `pos_providers.dart`). Le champ recherche filtre la liste. `product.remoteId` est l'identifiant backend attendu par l'API.

### Modèle de réponse backend

```json
{
  "id": "uuid",
  "catalogItemId": "uuid",
  "quantity": "10",
  "type": "DELIVERY",
  "reason": null,
  "tenantId": "tenant-1",
  "createdAt": "2026-03-15T10:00:00Z"
}
```

### Constante base URL

```dart
// Utiliser la même constante que pos_providers.dart
const baseUrl = 'http://127.0.0.1:3000';
```

### Pattern HTTP existant

Voir `ProductRepository.adjustStock()` et `stockHistoryProvider` dans `pos_providers.dart` pour le pattern d'appel HTTP avec `http.post` + headers JSON.

---

## Dev Agent Record

### Implementation Plan

- `InventoryRepository` créé avec `httpClient` injectable pour testabilité (pattern `MockClient` de `package:http/testing.dart`).
- `DeliveryForm` est un `ConsumerStatefulWidget` qui:
  - Utilise `Autocomplete<Product>` avec `paginatedProductListProvider` pour la sélection du produit
  - Filtre les suggestions en temps réel par nom
  - Garde `_canSubmit` calculé localement (produit sélectionné + quantité > 0 + non en cours d'envoi)
  - Utilise `autofocus: true` sur le champ quantité (AC3 - quantité pré-focalisée)
  - Affiche un `CircularProgressIndicator` inline dans le bouton pendant l'envoi
  - Réinitialise tous les champs après succès
- Tests: 6 tests (4 widget + 2 unit), `pump() + pump(50ms)` au lieu de `pumpAndSettle()` pour éviter le timeout du stream `_StubSyncService`.
- Task 4 (intégration onglet Réceptions) : `DeliveryForm` est prêt à être importé — intégration réelle prévue en story 16-5.

### Completion Notes

- **71/71 tests pass** (65 existants + 6 nouveaux), zéro régression.
- AC1 ✅ : Autocomplete produit + champ quantité obligatoire + notes optionnel + bouton 48dp
- AC2 ✅ : POST /inventory/movements avec type DELIVERY, snackbar succès/erreur, reset formulaire
- AC3 ✅ : Loading spinner, bouton désactivé pendant envoi, autofocus quantité
- AC4 ✅ : 6 tests couvrant formulaire, validation, submit mock, erreur API

---

## File List

| Action | Path |
|--------|------|
| Created | `apps/frontend/lib/features/dashboard/presentation/widgets/inventory/delivery_form.dart` |
| Created | `apps/frontend/lib/features/dashboard/data/repositories/inventory_repository.dart` |
| Created | `apps/frontend/test/inventory_delivery_test.dart` |

---

## Change Log

| Date       | Change                                                                                       |
|------------|----------------------------------------------------------------------------------------------|
| 2026-03-15 | Story créée — réception livraison fournisseur (FR29-FR30)                                    |
| 2026-03-15 | Implemented: delivery_form.dart, InventoryRepository.createMovement(), 6 tests — 71/71 pass  |
