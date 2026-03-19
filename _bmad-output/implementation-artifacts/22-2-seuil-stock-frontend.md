# Story 22.2 — Frontend : Configuration seuil dans ProductFormDialog + badge catalogue

## Metadata

- **Epic:** Epic 22 — Alertes stock bas + notifications
- **Story ID:** 22-2-seuil-stock-frontend
- **Status:** ready-for-dev
- **Priority:** High
- **Depends on:** 22-1 (endpoint PATCH minStockLevel disponible)

---

## Story

**As a** owner or manager,
**I want** to set a minimum stock threshold on each product and see a visual badge when that threshold is breached,
**So that** I can identify at-risk articles at a glance in the catalog (FR81, FR82).

---

## Acceptance Criteria

### AC1 — Champ minStockLevel dans ProductFormDialog

**Given** l'utilisateur ouvre `ProductFormDialog` pour créer ou éditer un article
**When** le formulaire s'affiche
**Then** un champ optionnel "Seuil stock bas" (type: nombre décimal, label: "Alerte si stock ≤") est visible
**And** si le champ est vide, aucune alerte ne sera générée pour cet article (placeholder : "Désactivé")
**And** le champ accepte des valeurs décimales (ex. 2.5 pour articles au poids)

### AC2 — Sauvegarde du seuil

**Given** l'utilisateur saisit `5` dans le champ "Seuil stock bas" et soumet le formulaire
**When** l'appel `PATCH /api/v1/catalog/:id` est exécuté
**Then** `minStockLevel: 5` est inclus dans le payload
**And** la réponse est reflétée dans le modèle `Product` local (Isar mis à jour)
**And** un message de confirmation "Seuil enregistré" apparaît en snackbar

### AC3 — Badge rouge sur article sous seuil dans la grille catalogue

**Given** un article a `stockQuantity ≤ minStockLevel` (et `minStockLevel != null`)
**When** la grille catalogue s'affiche
**Then** une icône d'alerte (triangle orange ou badge rouge) apparaît sur la card de l'article
**And** le tooltip ou sous-label indique "Stock critique : X restants" (X = stockQuantity)
**And** les articles sans seuil configuré n'affichent aucun badge

### AC4 — Offline

**Given** l'appareil est hors ligne
**When** l'utilisateur ouvre le catalogue
**Then** les badges de stock bas sont calculés localement depuis le modèle Isar (stockQuantity vs minStockLevel)
**And** aucun appel réseau n'est requis pour afficher les badges

---

## Tasks/Subtasks

- [ ] **Task 1 : Modèle Product Dart — minStockLevel**
  - [ ] Vérifier si `minStockLevel` existe déjà dans `product.dart`
  - [ ] Si absent : ajouter `double? minStockLevel` avec `fromJson` robuste
  - [ ] Mettre à jour `toJson()`

- [ ] **Task 2 : ProductFormDialog — champ seuil**
  - [ ] Ajouter `TextFormField` "Alerte si stock ≤" (optionnel, décimal)
  - [ ] Placeholder "Désactivé" si vide
  - [ ] Inclure `minStockLevel` dans le payload PATCH

- [ ] **Task 3 : Badge alerte sur product_grid.dart**
  - [ ] Condition : `product.minStockLevel != null && product.stockQuantity <= product.minStockLevel`
  - [ ] Afficher icône triangle orange (Icons.warning_amber_rounded) sur la card
  - [ ] Tooltip "Stock critique : ${product.stockQuantity} restants"

- [ ] **Task 4 : CatalogRepository — PATCH minStockLevel**
  - [ ] Inclure `minStockLevel` dans le payload `updateItem()`
  - [ ] Mettre à jour l'entrée Isar locale après réponse

---

## Files to Modify

- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `minStockLevel` (si absent)
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — champ seuil
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_grid.dart` — badge alerte
- `apps/frontend/lib/features/shared/catalog/data/repositories/catalog_repository.dart` — PATCH minStockLevel

## Dev Notes

- La logique de badge est pure (pas de provider supplémentaire) : `product.minStockLevel != null && product.stockQuantity <= product.minStockLevel`
- Calculé localement depuis Isar → fonctionne offline sans appel réseau
