# Story 25.5 — Frontend : Configuration prix par niveau + POS override

## Metadata

- **Epic:** Epic 25 — Variantes, multi-tarifs & promotions
- **Story ID:** 25-5-price-level-frontend
- **Status:** done
- **Priority:** High
- **Depends on:** 25-4 (endpoints price-levels disponibles)

---

## Story

**As a** owner,
**I want** to configure price levels per article from the product form, and cashiers with permission to manually select a price level at the POS,
**So that** wholesale and loyalty pricing is managed centrally and applied consistently (FR90).

---

## Acceptance Criteria

### AC1 — Section "Prix par niveau" dans ProductFormDialog

**Given** l'utilisateur édite un article
**When** le formulaire s'affiche
**Then** une section "Tarification" liste les niveaux de prix actifs du tenant (ex: "Gros", "Fidélité")
**And** chaque niveau affiche un champ prix + champ "Quantité min" (optionnel) + champ "Types client" (multiselect optionnel)
**And** les niveaux du tenant sont configurables depuis les paramètres tenant ("Gérer les niveaux de prix")

### AC2 — Configuration des niveaux disponibles par tenant

**Given** l'owner ouvre `TenantSettingsScreen` section "Tarification"
**When** il crée un niveau "Grossiste" avec le code "GROS"
**Then** ce niveau apparaît dans tous les `ProductFormDialog` du tenant
**And** le tenant peut avoir entre 1 et N niveaux (pas de limite fixe)

### AC3 — Affichage du niveau appliqué dans le panier POS

**Given** un article est ajouté au panier et un niveau de prix est appliqué automatiquement
**When** la ligne panier s'affiche
**Then** un chip discret indique le niveau appliqué (ex: chip "GROS" en bleu sous le prix)
**And** si le prix par défaut (RETAIL) est appliqué, aucun chip n'est affiché

### AC4 — Override manuel par le caissier autorisé

**Given** un caissier avec la permission `price_override` appuie longuement sur une ligne du panier
**When** le menu contextuel s'ouvre
**Then** une option "Changer le niveau de prix" est visible
**And** une bottom sheet liste les niveaux disponibles pour cet article
**And** la sélection met à jour le prix de la ligne et affiche le chip du niveau sélectionné
**And** pour un caissier sans `price_override`, l'option "Changer le niveau de prix" est masquée

---

## Tasks/Subtasks

- [ ] **Task 1 : Modèle PriceLevel Dart**
  - [ ] `price_level.dart` : `id, levelCode, label, price, minQty?, customerTypes?`
  - [ ] `fromJson()` + `toJson()`

- [ ] **Task 2 : ProductFormDialog — section Tarification**
  - [ ] Charger niveaux disponibles du tenant via provider
  - [ ] Pour chaque niveau : champ prix, champ qty min, multiselect types client
  - [ ] Submit → `POST /api/v1/catalog/:id/price-levels`

- [ ] **Task 3 : TenantSettingsScreen — gestion niveaux**
  - [ ] Section "Tarification" dans les paramètres tenant
  - [ ] Créer/renommer/supprimer les codes de niveau disponibles

- [ ] **Task 4 : CartPanel — chip niveau appliqué**
  - [ ] Si `appliedPriceLevel` dans la réponse backend, afficher chip `levelCode` sous le prix
  - [ ] Pas de chip si niveau RETAIL (défaut)

- [ ] **Task 5 : Override manuel**
  - [ ] Long press ligne panier → menu contextuel (si `price_override`)
  - [ ] Bottom sheet : liste niveaux disponibles pour l'article
  - [ ] Sélection → re-calculer prix ligne + `forcedPriceLevelCode` dans le payload transaction

---

## Files to Modify

- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_form_dialog.dart` — section Tarification
- `apps/frontend/lib/features/retail/pos/presentation/widgets/cart_panel.dart` — chip niveau + menu override
- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — ajouter `priceLevels`
