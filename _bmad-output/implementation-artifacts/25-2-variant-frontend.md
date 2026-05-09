# Story 25.2 — Frontend : Gestion variantes dans le catalogue (attributs configurables)

## Metadata

- **Epic:** Epic 25 — Variantes, multi-tarifs & promotions
- **Story ID:** 25-2-variant-frontend
- **Status:** done
- **Priority:** High
- **Depends on:** 25-1 (endpoints variantes disponibles)

---

## Story

**As a** owner or manager,
**I want** to define variants for an article with tenant-configurable attribute labels, directly from the product sheet,
**So that** I can manage different sizes, colors, or grades without creating separate catalog entries (FR89).

---

## Acceptance Criteria

### AC1 — Toggle "Cet article a des variantes" dans ProductFormDialog

**Given** l'utilisateur édite un article dans `ProductFormDialog`
**When** il active le toggle "Cet article a des variantes"
**Then** une section "Variantes" apparaît avec un bouton "Ajouter une variante"
**And** un avertissement s'affiche : "Le prix et le stock de l'article seront gérés par variante"
**And** si des variantes existent déjà, elles sont listées sous forme de chips éditables

### AC2 — Formulaire de création de variante

**Given** l'utilisateur clique "Ajouter une variante"
**When** la bottom sheet s'ouvre
**Then** il peut saisir : SKU (optionnel), barcode (optionnel), prix (requis), stock initial (requis), et 1 à N attributs libres (ex: `Taille = XL`)
**And** les labels d'attributs proposés en autocomplete sont ceux définis dans les paramètres tenant
**And** le tenant peut créer de nouveaux labels d'attributs à la volée depuis ce formulaire

### AC3 — Vue liste variantes dans la fiche article

**Given** un article a des variantes
**When** sa fiche s'affiche dans le catalogue
**Then** un tableau récapitulatif liste les variantes avec : attributs, SKU, prix, stock
**And** chaque ligne est cliquable pour éditer la variante
**And** un agrégat "Stock total : X" est affiché en en-tête

### AC4 — Gestion attributs tenant depuis les paramètres

**Given** l'owner ouvre les paramètres catalogue
**When** la section "Attributs variantes" s'affiche
**Then** il peut créer/renommer/supprimer les labels d'attributs disponibles (ex: "Pointure", "Parfum")
**And** ces labels sont synchronisés sur tous les appareils

---

## Tasks/Subtasks

- [ ] **Task 1 : Modèle ProductVariant Dart**
  - [ ] Créer `apps/frontend/lib/features/shared/catalog/data/models/product_variant.dart`
  - [ ] Champs : `id, catalogItemId, sku, barcode, price, stockQuantity, attributes Map<String, String>, isActive`
  - [ ] `fromJson()` et `toJson()`

- [ ] **Task 2 : Modèle Product — hasVariants + variants**
  - [ ] Ajouter `bool hasVariants`, `List<ProductVariant> variants` dans `product.dart`
  - [ ] Mettre à jour `fromJson()`

- [ ] **Task 3 : ProductFormDialog — toggle + section variantes**
  - [ ] Toggle "Cet article a des variantes"
  - [ ] Liste des variantes existantes (chips éditables)
  - [ ] Bouton "Ajouter une variante" → ouvre `VariantFormSheet`
  - [ ] Avertissement si toggle activé

- [ ] **Task 4 : VariantFormSheet**
  - [ ] Créer `variant_form_sheet.dart`
  - [ ] Champs : SKU, barcode, prix, stock, attributs libres
  - [ ] Autocomplete labels d'attributs depuis settings tenant
  - [ ] Submit → `POST /api/v1/catalog/:id/variants`

- [ ] **Task 5 : Fiche article — liste variantes**
  - [ ] Tableau récapitulatif dans la fiche article
  - [ ] Agrégat "Stock total"
  - [ ] Tap ligne → ouvre `VariantFormSheet` en mode édition

---

## Files to Create

- `apps/frontend/lib/features/shared/catalog/presentation/widgets/variant_form_sheet.dart`
- `apps/frontend/lib/features/shared/catalog/data/models/product_variant.dart`

## Files to Modify

- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — section variantes
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — `hasVariants`, `variants`
