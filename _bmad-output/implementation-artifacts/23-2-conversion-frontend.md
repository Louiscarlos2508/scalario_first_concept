# Story 23.2 — Frontend : Formulaire conversion dans ProductFormDialog

## Metadata

- **Epic:** Epic 23 — Conversion unités vrac → détail
- **Story ID:** 23-2-conversion-frontend
- **Status:** ready-for-dev
- **Priority:** High
- **Depends on:** 23-1 (endpoints parentItemId + PATCH disponibles)

---

## Story

**As a** owner or manager,
**I want** to link a child article to a parent bulk article and configure the conversion factor from the product form,
**So that** I can set up bulk → retail splits without leaving the admin UI (FR83).

---

## Acceptance Criteria

### AC1 — Section "Reconditionnement" dans ProductFormDialog

**Given** l'utilisateur ouvre `ProductFormDialog` pour créer ou éditer un article
**When** le formulaire s'affiche
**Then** une section optionnelle "Reconditionnement" est visible, avec un toggle "Cet article est un détail d'un article vrac"
**And** si le toggle est OFF, les champs de relation sont masqués
**And** si le toggle est ON, deux champs apparaissent : "Article parent" (autocomplete) et "Facteur de conversion" (nombre décimal > 0)

### AC2 — Autocomplete article parent

**Given** l'utilisateur saisit du texte dans le champ "Article parent"
**When** l'autocomplete se déclenche (≥ 2 caractères)
**Then** la liste propose les articles du tenant qui ne sont pas eux-mêmes des articles enfants (pas de `parentItemId` défini)
**And** l'article en cours d'édition est exclu de la liste (pas d'auto-référence)
**And** chaque résultat affiche : nom, unitType, stock actuel

### AC3 — Affichage du facteur de conversion

**Given** l'utilisateur a sélectionné un article parent et saisi un facteur de conversion (ex: 0.02)
**When** le facteur est confirmé
**Then** un texte d'aide s'affiche sous le champ : "Vendre 1 [label enfant] décrémente [facteur] [unitLabel parent]"
**And** si le facteur est invalide (≤ 0 ou > 1), une erreur de validation s'affiche

### AC4 — Sauvegarde

**Given** l'utilisateur soumet le formulaire avec parentItemId + conversionRate
**When** `PATCH /api/v1/catalog/:id` est appelé
**Then** `parentItemId` et `conversionRate` sont inclus dans le payload
**And** le modèle `Product` Dart est mis à jour avec ces champs

### AC5 — Fiche parent — liste des articles enfants

**Given** l'utilisateur ouvre la fiche d'un article parent (via le catalogue)
**When** la fiche s'affiche
**Then** une section "Articles détail liés" liste les articles enfants avec leur facteur de conversion
**And** chaque enfant est cliquable pour ouvrir son `ProductFormDialog`

---

## Tasks/Subtasks

- [ ] **Task 1 : Modèle Product Dart — parentItemId + conversionRate**
  - [ ] Ajouter `String? parentItemId` et `double? conversionRate` dans `product.dart`
  - [ ] Mettre à jour `fromJson()` et `toJson()`

- [ ] **Task 2 : ProductFormDialog — section Reconditionnement**
  - [ ] Toggle "Cet article est un détail d'un article vrac"
  - [ ] Champ autocomplete "Article parent" (visible si toggle ON)
  - [ ] Champ "Facteur de conversion" (visible si toggle ON, validator > 0 && <= 1)
  - [ ] Texte d'aide dynamique

- [ ] **Task 3 : Autocomplete article parent**
  - [ ] Filtrer les articles du tenant sans `parentItemId` (ni l'article courant)
  - [ ] Peut réutiliser `catalogSearchProvider` avec filtre `hasNoParent=true`

- [ ] **Task 4 : Fiche article — liste enfants**
  - [ ] Appeler `GET /api/v1/catalog/:id/children` pour charger les enfants
  - [ ] Afficher section "Articles détail liés" si children non vide
  - [ ] Tap enfant → ouvrir `ProductFormDialog` en mode édition

- [ ] **Task 5 : CatalogRepository — PATCH avec nouveaux champs**
  - [ ] Inclure `parentItemId`, `conversionRate` dans `updateItem()`

---

## Files to Modify

- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `parentItemId`, `conversionRate`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — section Reconditionnement
- `apps/frontend/lib/features/shared/catalog/data/repositories/catalog_repository.dart` — PATCH avec nouveaux champs
