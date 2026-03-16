# Story 16.5 — Hub Inventaire (navigation onglets)

## Metadata

- **Epic:** Epic 16 — Retail Operations — Gestion Stock Terrain
- **Story ID:** 16-5-inventory-navigation
- **Status:** review
- **Priority:** High
- **Depends on:** 16-1, 16-2, 16-3, 16-4 (formulaires créés)

---

## Story

**As a** manager (Moussa),
**I want** a single tabbed Inventory screen to access all stock operations,
**So that** I can switch between Réceptions, Transferts, Pertes, and Inventaire from one place (FR36).

---

## Acceptance Criteria

1. **Écran hub** — `inventory_screen.dart` (remplace le placeholder actuel) :
   - `DefaultTabController` avec 5 onglets : **Produits · Réceptions · Transferts · Pertes · Inventaire**
   - `TabBar` avec labels français et icônes cohérentes (Material Icons)
   - `TabBarView` : chaque onglet affiche le widget correspondant

2. **Onglet Produits :**
   - Liste des produits du catalogue avec stock actuel (`GET /inventory/stock`)
   - Recherche textuelle en temps réel
   - Indicateur stock faible : badge rouge si stock < seuil (seuil = 5 par défaut)

3. **Onglet Réceptions :**
   - `delivery_form.dart` (story 16-1) en haut
   - Liste des 20 derniers mouvements de type `DELIVERY` : `GET /inventory/movements?type=DELIVERY&limit=20&tenantId=`

4. **Onglet Transferts :**
   - `transfer_out_form.dart` (story 16-2) accessible via bouton FAB ou en haut
   - `transfer_pending_screen.dart` (story 16-2) intégré — liste des transferts en attente
   - Liste des 20 derniers mouvements TRANSFER_OUT/TRANSFER_IN

5. **Onglet Pertes :**
   - `loss_declaration_form.dart` (story 16-3) intégré
   - Liste des 20 derniers mouvements de type `LOSS`

6. **Onglet Inventaire :**
   - `partial_inventory_screen.dart` (story 16-4) intégré
   - Historique des 20 derniers ADJUSTMENT

7. **Raccourci dashboard → onglet Réceptions :**
   - La card "Stock faible" sur le dashboard navigue vers `InventoryScreen` avec `initialIndex: 1` (onglet Réceptions)
   - Paramètre optionnel `initialIndex` sur `InventoryScreen`

8. **Test `test/inventory_navigation_test.dart`** :
   - Widget test : TabBar présent avec 5 onglets aux labels corrects
   - Tap onglet "Pertes" → `loss_declaration_form` visible
   - Test `initialIndex: 1` → onglet Réceptions actif par défaut

---

## Tasks/Subtasks

- [ ] **Task 1 : Créer `inventory_screen.dart`** — hub tabbed
  - [ ] `DefaultTabController(length: 5)`
  - [ ] `TabBar` avec 5 onglets labellisés en français
  - [ ] `TabBarView` pointant vers les widgets des stories 16-1 à 16-4
  - [ ] Paramètre optionnel `initialIndex`

- [ ] **Task 2 : Onglet Produits**
  - [ ] Provider `inventoryProductListProvider` → catalogue + stock actuel
  - [ ] Badge stock faible (stock < 5)
  - [ ] Recherche textuelle

- [ ] **Task 3 : Intégrer les formulaires dans les onglets**
  - [ ] Réceptions : `DeliveryForm` + liste 20 derniers DELIVERY
  - [ ] Transferts : FAB → `TransferOutForm` + `TransferPendingScreen`
  - [ ] Pertes : `LossDeclarationForm` + liste 20 derniers LOSS
  - [ ] Inventaire : `PartialInventoryScreen` + liste 20 derniers ADJUSTMENT

- [ ] **Task 4 : Raccourci dashboard**
  - [ ] Modifier la card "Stock faible" dans `dashboard_screen.dart`
  - [ ] Navigation → `InventoryScreen(initialIndex: 1)`

- [ ] **Task 5 : Créer `test/inventory_navigation_test.dart`**
  - [ ] Test 5 onglets présents
  - [ ] Test navigation par tap
  - [ ] Test `initialIndex`

- [ ] **Task 6 : `flutter test` — zéro régression**

---

## Dev Notes

### Structure de l'écran

```dart
class InventoryScreen extends ConsumerWidget {
  final int initialIndex;
  const InventoryScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventaire'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Produits'),
              Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Réceptions'),
              Tab(icon: Icon(Icons.swap_horiz_outlined), text: 'Transferts'),
              Tab(icon: Icon(Icons.remove_circle_outline), text: 'Pertes'),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Inventaire'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProductsTab(),
            _ReceptionsTab(),
            _TransfersTab(),
            _LossTab(),
            _InventoryCountTab(),
          ],
        ),
      ),
    );
  }
}
```

### Provider liste mouvements par type

```dart
final recentMovementsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, type) async {
    final tenantId = ref.watch(activeTenantProvider);
    final response = await http.get(
      Uri.parse('$baseUrl/inventory/movements?type=$type&limit=20&tenantId=$tenantId'),
      headers: {'Content-Type': 'application/json'},
    );
    // parse + return
  },
);
```

### Raccourci dashboard

```dart
// dashboard_screen.dart — card "Stock faible"
onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const InventoryScreen(initialIndex: 1),
  ),
),
```

### Intégration dans DashboardShell

`InventoryScreen` est déjà l'écran de l'onglet "Inventaire" dans `DashboardShell` (index 1). Remplacer le widget placeholder actuel par `InventoryScreen()`.

---

## File List

| Action | Path |
| ------ | ---- |
| Modified | `apps/frontend/lib/features/dashboard/presentation/screens/inventory_screen.dart` |
| Modified | `apps/frontend/lib/features/dashboard/presentation/widgets/kpi_card_grid.dart` |
| Modified | `apps/frontend/lib/features/pos/presentation/providers/pos_providers.dart` |
| Created | `apps/frontend/test/inventory_navigation_test.dart` |

---

## Dev Agent Record

### Completion Notes

- **105/105 tests pass** (100 existants + 5 nouveaux), zéro régression.
- AC1 ✅ : `DefaultTabController(length: 5, initialIndex: initialIndex)`, TabBar scrollable avec 5 onglets
- AC2 ✅ : Onglet Produits conserve le DataTable existant avec badge stock faible
- AC3–6 ✅ : Formulaires 16-1 à 16-4 intégrés dans les onglets Réceptions/Transferts/Pertes/Inventaire
- AC7 ✅ : Card "Stock faible" → `Navigator.push` vers `InventoryScreen(initialIndex: 1)` via `InkWell.onTap`
- AC8 ✅ : 5 tests — TabBar 5 onglets, tap Pertes/Réceptions/Transferts, `initialIndex: 1`
- `inventoryRepositoryProvider` ajouté dans `pos_providers.dart` — injectable dans les tests

---

## Change Log

| Date | Change |
| ---- | ------ |
| 2026-03-15 | Story créée — hub inventaire 5 onglets navigation (FR36) |
| 2026-03-15 | Implemented: 5-tab InventoryScreen hub, inventoryRepositoryProvider, dashboard shortcut, 5 tests — 105/105 pass |
