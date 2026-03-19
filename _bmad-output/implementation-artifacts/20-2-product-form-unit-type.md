# Story 20.2 — Frontend : ProductFormDialog supporte unitType

## Metadata

- **Epic:** Epic 20 — Vente au poids + unités configurables
- **Story ID:** 20-2-product-form-unit-type
- **Status:** done
- **Priority:** High
- **Depends on:** 20-1 (champs backend + endpoint PATCH disponibles)

---

## Story

**As an** owner,
**I want** the product form to let me configure unit type, unit label, and unit price,
**So that** I can set up weight/volume articles for accurate POS pricing (FR76, FR78).

---

## Acceptance Criteria

### AC1 — Dropdown unitType

**Given** `ProductFormDialog` est ouvert (création ou édition)
**When** l'utilisateur voit le formulaire
**Then** un dropdown "Type d'unité" est présent avec 4 options :
- Pièce (`piece`) — sélectionné par défaut
- Poids (`weight`)
- Volume (`volume`)
- Longueur (`length`)

### AC2 — Champ label unité (conditionnel)

**Given** `unitType != 'piece'` est sélectionné
**When** le formulaire se met à jour
**Then** un champ texte "Label unité" apparaît (ex: "kg", "g", "L", "m")
**And** ce champ est obligatoire si `unitType != 'piece'`
**And** si `unitType == 'piece'`, le champ est masqué et sa valeur est ignorée

### AC3 — Affichage prix adapté

**Given** `unitType != 'piece'`
**When** le champ prix est affiché
**Then** son label affiche "Prix par [label unité]" (ex: "Prix par kg")
**And** si `unitType == 'piece'`, le label reste "Prix" (comportement actuel)

### AC4 — Champ facteur de conversion (optionnel)

**Given** `unitType != 'piece'`
**When** l'utilisateur développe la section "Paramètres avancés"
**Then** un champ "Facteur de conversion (optionnel)" est disponible
**And** son helper text indique "Ex: 0.5 si 1 sachet 500g = 0.5 kg stock"
**And** le champ accepte uniquement des valeurs numériques décimales > 0

### AC5 — Sauvegarde et pré-remplissage

**Given** un article avec `unitType = 'weight'` et `pricePerUnit = 1500` est édité
**When** `ProductFormDialog` s'ouvre en mode édition
**Then** le dropdown affiche "Poids", le label unité affiche la valeur persistée, le prix affiche `1500`

### AC6 — Appel API

**Given** le formulaire est soumis avec `unitType = 'weight'`, `pricePerUnit = 1500`, `conversionRate = null`
**When** `POST /api/v1/catalog/items` ou `PATCH` est appelé
**Then** le body inclut `{"unitType": "weight", "pricePerUnit": 1500, "conversionRate": null}`

### AC7 — Test widget

**Given** le widget test de `ProductFormDialog`
**When** `unitType` est changé à `'weight'`
**Then** le champ "Label unité" devient visible et obligatoire
**And** le label du champ prix change en "Prix par [label]"

---

## Tasks/Subtasks

- [ ] **Task 1 : Modèle Product Dart**
  - [ ] Ajouter dans `product.dart` : `unitType String`, `pricePerUnit double?`, `conversionRate double?`
  - [ ] Mettre à jour `fromJson()` : `json['unitType'] ?? json['unit_type'] ?? 'piece'`
  - [ ] Mettre à jour `toJson()` pour inclure les nouveaux champs
  - [ ] Régénérer `product.g.dart` si nécessaire (Isar schema version bump)

- [ ] **Task 2 : ProductFormDialog — dropdown unitType**
  - [ ] Ajouter `DropdownButtonFormField<String>` avec les 4 options
  - [ ] Lier à `_selectedUnitType` (state local)
  - [ ] Pré-remplir depuis `widget.product?.unitType ?? 'piece'`

- [ ] **Task 3 : ProductFormDialog — champ label unité conditionnel**
  - [ ] Afficher `TextFormField` "Label unité" si `_selectedUnitType != 'piece'`
  - [ ] Validation : requis si `unitType != 'piece'`
  - [ ] Masquer et ignorer la valeur si `unitType == 'piece'`

- [ ] **Task 4 : ProductFormDialog — prix adaptatif**
  - [ ] Changer le label du champ prix dynamiquement : `"Prix${_selectedUnitType != 'piece' ? ' par $_unitLabel' : ''}"`

- [ ] **Task 5 : ProductFormDialog — section "Paramètres avancés"**
  - [ ] Ajouter `ExpansionTile` "Paramètres avancés" visible si `unitType != 'piece'`
  - [ ] Champ `conversionRate` (TextFormField numérique, optionnel, validator > 0)
  - [ ] Helper text explicatif

- [ ] **Task 6 : CatalogRepository — sérialisation**
  - [ ] Inclure `unitType`, `pricePerUnit`, `conversionRate` dans `createItem()` et `updateItem()`
  - [ ] Désérialiser ces champs dans `fromJson()` / réponse API

- [ ] **Task 7 : Test widget**
  - [ ] Test : changer dropdown à 'weight' → label unité visible + obligatoire
  - [ ] Test : label prix adaptatif
  - [ ] Test : soumission → payload contient les 3 champs

---

## Files to Create/Modify

**Modified files:**
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `unitType`, `pricePerUnit`, `conversionRate`
- `apps/frontend/lib/features/retail/pos/data/models/product.g.dart` — régénérer
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — dropdown + champs conditionnels
- `apps/frontend/lib/features/shared/catalog/data/repositories/catalog_repository.dart` — sérialisation nouveaux champs
