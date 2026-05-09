# Story 16.6 — Inventaire offline-first & sync

## Metadata
- **Epic:** Epic 16 — Retail Operations — Gestion Stock Terrain
- **Story ID:** 16-6-inventory-offline-sync
- **Status:** review
- **Priority:** High
- **Depends on:** 16-1, 16-2, 16-3, 16-4, 16-5 (tous les formulaires et la navigation)

---

## Story

**As a** manager (Moussa) working in an area with intermittent connectivity,
**I want** stock operations to be saved locally when offline and synced automatically when back online,
**So that** I never lose a delivery, transfer, or loss declaration due to network issues.

---

## Acceptance Criteria

1. **Modèle Isar `InventoryMovementLocal`** — `inventory_movement_local.dart` :
   - Champs : `id` (auto-incrémenté), `remoteId` (String?), `type` (String), `catalogItemId` (String), `quantity` (int), `reason` (String?), `referenceId` (String?), `tenantId` (String), `createdAt` (DateTime), `syncStatus` (String : `pending` | `synced` | `failed`), `errorMessage` (String?)
   - Annoté `@collection` Isar
   - `.g.dart` généré via `dart run build_runner build`

2. **`InventoryRepository` (mis à jour)** :
   - `saveLocal(InventoryMovementLocal)` → écriture Isar
   - `getPendingMovements()` → liste des mouvements en `pending`
   - `markSynced(int id, String remoteId)` → `syncStatus = 'synced'`
   - `markFailed(int id, String error)` → `syncStatus = 'failed'`
   - `getMovements({String? type, int limit = 20})` → lecture Isar locale (pas d'appel réseau)

3. **Formulaires offline-first (stories 16-1 à 16-4 mis à jour)** :
   - Tous les formulaires (`delivery_form`, `transfer_out_form`, `loss_declaration_form`, `partial_inventory_screen`) sauvegardent d'abord en local (`saveLocal`) avant d'appeler l'API
   - Si réseau disponible → appel API immédiat → `markSynced` ou `markFailed` selon réponse
   - Si réseau indisponible → sauvegarde locale uniquement, snackbar "Sauvegardé localement — sera synchronisé"

4. **SyncService — adapter inventaire** :
   - `InventorySyncAdapter` implémentant l'interface `SyncAdapter` existante (Epic 8)
   - `sync()` : récupère les `pending`, appelle l'API correspondante selon `type`, met à jour le statut
   - Enregistré dans `SyncService` à l'initialisation (dans `app.module.ts` ou `main.dart`)

5. **Badge outbox** :
   - `inventoryOutboxCountProvider` → nombre de mouvements en `pending`
   - Badge visible sur l'onglet "Inventaire" dans `DashboardShell` si count > 0
   - `AppColors.warning` pour le badge

6. **Test `test/inventory_offline_sync_test.dart`** :
   - Sauvegarder un mouvement hors ligne → `syncStatus == 'pending'`
   - Déclencher sync → `syncStatus == 'synced'` + `remoteId` non null
   - Simuler erreur réseau → `syncStatus == 'failed'` + `errorMessage` non null
   - Badge count = 0 quand aucun pending

---

## Tasks/Subtasks

- [ ] **Task 1 : Créer `inventory_movement_local.dart`** — modèle Isar
  - [ ] Définir la collection avec tous les champs
  - [ ] Lancer `dart run build_runner build` pour générer `.g.dart`

- [ ] **Task 2 : Mettre à jour `InventoryRepository`**
  - [ ] Ajouter `saveLocal`, `getPendingMovements`, `markSynced`, `markFailed`, `getMovements`
  - [ ] Injecter instance Isar (via `ref.watch(isarProvider)`)

- [ ] **Task 3 : Mettre à jour les 4 formulaires en offline-first**
  - [ ] `delivery_form.dart` → saveLocal avant POST
  - [ ] `transfer_out_form.dart` → saveLocal avant POST
  - [ ] `loss_declaration_form.dart` → saveLocal avant POST
  - [ ] `partial_inventory_screen.dart` → saveLocal avant POST /inventory/adjust

- [ ] **Task 4 : Créer `InventorySyncAdapter`**
  - [ ] Implémenter interface `SyncAdapter` (voir Epic 8 `delta_sync_service.dart`)
  - [ ] Logique de dispatch selon `movement.type`
  - [ ] Enregistrement dans `SyncService`

- [ ] **Task 5 : Badge outbox**
  - [ ] `inventoryOutboxCountProvider` → stream Isar sur count pending
  - [ ] Badge dans `DashboardShell` onglet Inventaire

- [ ] **Task 6 : Créer `test/inventory_offline_sync_test.dart`**
  - [ ] Test offline save → pending
  - [ ] Test sync → synced
  - [ ] Test erreur → failed

- [ ] **Task 7 : `flutter test` — zéro régression**

---

## Dev Notes

### Modèle Isar

```dart
// apps/frontend/lib/features/dashboard/data/models/inventory_movement_local.dart
import 'package:isar/isar.dart';

part 'inventory_movement_local.g.dart';

@collection
class InventoryMovementLocal {
  Id id = Isar.autoIncrement;
  String? remoteId;
  late String type;          // DELIVERY, TRANSFER_OUT, TRANSFER_IN, LOSS, ADJUSTMENT
  late String catalogItemId;
  late int quantity;
  String? reason;
  String? referenceId;       // pour TRANSFER_OUT/IN
  late String tenantId;
  late DateTime createdAt;
  @Index()
  late String syncStatus;    // 'pending' | 'synced' | 'failed'
  String? errorMessage;
}
```

### Pattern offline-first dans les formulaires

```dart
// Exemple dans delivery_form.dart
Future<void> _submit() async {
  final movement = InventoryMovementLocal()
    ..type = 'DELIVERY'
    ..catalogItemId = selectedProduct!.remoteId
    ..quantity = int.parse(quantityController.text)
    ..reason = notesController.text.isEmpty ? null : notesController.text
    ..tenantId = tenantId
    ..createdAt = DateTime.now()
    ..syncStatus = 'pending';

  // 1. Sauvegarde locale immédiate
  await ref.read(inventoryRepositoryProvider).saveLocal(movement);

  // 2. Tenter l'appel réseau
  try {
    final result = await ref.read(inventoryRepositoryProvider).createMovement(
      type: 'DELIVERY',
      catalogItemId: selectedProduct!.remoteId,
      quantity: int.parse(quantityController.text),
      reason: movement.reason,
      tenantId: tenantId,
    );
    await ref.read(inventoryRepositoryProvider).markSynced(movement.id, result['id']);
    // snackbar succès
  } on SocketException {
    // snackbar "Sauvegardé localement"
  } catch (e) {
    await ref.read(inventoryRepositoryProvider).markFailed(movement.id, e.toString());
    // snackbar erreur
  }
}
```

### Interface SyncAdapter (Epic 8)

```dart
// Voir apps/frontend/lib/core/sync/sync_adapter.dart
abstract class SyncAdapter {
  Future<void> sync();
}
```

`InventorySyncAdapter` implémente cette interface et est enregistré dans `SyncService.adapters`.

### Isar provider existant

```dart
// Réutiliser isarProvider de pos_providers.dart ou core/providers/isar_provider.dart
// Ajouter InventoryMovementLocal à la liste des collections Isar ouvertes
await Isar.open([
  ...,
  InventoryMovementLocalSchema,  // ← ajouter ici
]);
```

### Badge outbox

```dart
final inventoryOutboxCountProvider = StreamProvider<int>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) return Stream.value(0);
  return isar.inventoryMovementLocals
    .where()
    .syncStatusEqualTo('pending')
    .count()
    .asStream();
});
```

---

## File List

| Action | Path |
|--------|------|
| Created | `apps/frontend/lib/features/dashboard/data/models/inventory_movement_local.dart` |
| Created | `apps/frontend/lib/features/dashboard/data/models/inventory_movement_local.g.dart` |
| Modified | `apps/frontend/lib/features/dashboard/data/repositories/inventory_repository.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/widgets/inventory/delivery_form.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/widgets/inventory/transfer_out_form.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/widgets/inventory/loss_declaration_form.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/partial_inventory_screen.dart` |
| Created | `apps/frontend/lib/core/sync/inventory_sync_adapter.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/widgets/dashboard_shell.dart` |
| Created | `apps/frontend/test/inventory_offline_sync_test.dart` |

---

## Dev Agent Record

### Implementation Summary (2026-03-15)

**Tasks completed:**
- Task 1: `InventoryMovementLocal` Isar `@collection` with `@Index()` on `type` and `syncStatus`; `build_runner` generated `.g.dart`
- Task 2: Added `saveLocal`, `getPendingMovements`, `markSynced`, `markFailed`, `getMovements` to `InventoryRepository`; methods are no-ops when `isarService` is null (backwards-compatible with existing unit tests)
- Task 3: All 4 forms updated to offline-first outbox pattern — `saveLocal` before API call, `markSynced` on success, `SocketException` → "Sauvegardé localement" snackbar, `markFailed` on other errors
- Task 4: `InventorySyncAdapter` implementing `SyncAdapter` (push-only outbox)
- Task 5: `inventoryOutboxCountProvider` + `Badge` on Inventaire tab (index 1) in `DashboardShell` for both `NavigationRail` and `BottomNavigationBar`
- Task 6: `test/inventory_offline_sync_test.dart` — 9 tests with `_FakeInventoryRepository` (in-memory)
- Task 7: `flutter test` — 114/114 passed, zero regressions

**Key deviation from spec:** `inventoryOutboxCountProvider` implemented as polling `StreamProvider<int>` (10s interval) rather than Isar reactive stream — avoids Isar isolate complexities in tests and keeps the provider testable via `overrideWith`.

## Change Log

| Date | Change |
|------|--------|
| 2026-03-15 | Story créée — inventaire offline-first, Isar model, SyncAdapter, badge outbox |
| 2026-03-15 | Implementation complete — 114/114 tests passing, status → review |
