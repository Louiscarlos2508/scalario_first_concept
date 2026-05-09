# Story 16.3 — Déclaration de pertes

## Metadata

- **Epic:** Epic 16 — Retail Operations — Gestion Stock Terrain
- **Story ID:** 16-3-stock-loss-declaration
- **Status:** review
- **Priority:** High
- **Depends on:** 16-1 (InventoryRepository créé)

---

## Story

**As a** manager using the backoffice,
**I want** to declare a stock loss with a mandatory reason,
**So that** shrinkage is traced and attributed to the right cause (FR34).

---

## Acceptance Criteria

1. **Formulaire déclaration** — `loss_declaration_form.dart` :
   - Sélection produit (recherche)
   - Champ quantité perdue (entier > 0, obligatoire)
   - Dropdown motif obligatoire : **Casse · Péremption · Vol · Frotte · Autre**
   - Si "Autre" sélectionné → champ texte libre obligatoire (précision)
   - Bouton **"Déclarer la perte"** désactivé si formulaire invalide

2. **Validation frontend :**
   - Motif non sélectionné → message d'erreur inline rouge "Motif obligatoire"
   - Quantité ≤ 0 ou vide → "Quantité invalide"
   - "Autre" sans précision → "Veuillez préciser le motif"
   - Aucun appel API si validation échoue

3. **Appel API :**
   - Submit valide → `POST /inventory/movements` body `{type: "LOSS", catalogItemId, quantity, reason: motifLabel, tenantId}`
   - Pour "Autre" → `reason = "Autre : {précision}"`
   - Succès → snackbar "Perte déclarée" + formulaire réinitialisé
   - Erreur 400 (reason manquant backend) → snackbar rouge avec message

4. **Test `test/inventory_loss_test.dart`** :
   - Submit sans motif → pas d'appel API + message d'erreur visible
   - Submit avec motif "Casse" + quantité 3 → `InventoryMovement.type == 'LOSS'`, `reason == 'Casse'`
   - Submit "Autre" sans précision → erreur frontend
   - Widget test : 5 options du dropdown présentes

---

## Tasks/Subtasks

- [x] **Task 1 : Créer `loss_declaration_form.dart`**
  - [x] Sélection produit (réutiliser pattern delivery_form)
  - [x] Champ quantité
  - [x] Dropdown motif avec 5 options + champ conditionnel "Autre"
  - [x] Validation formulaire inline

- [x] **Task 2 : Ajouter `InventoryRepository.createLoss()` (ou réutiliser `createMovement()`)**
  - [x] Corps spécifique : type LOSS, reason obligatoire
  - [x] Gestion erreur 400 si reason absent (double sécurité)

- [x] **Task 3 : Créer `test/inventory_loss_test.dart`**
  - [x] Test validation (sans motif, avec motif, "Autre" incomplet)
  - [x] Test soumission réussie

- [x] **Task 4 : `flutter test` — zéro régression**

---

## Dev Notes

### Endpoint backend

```http
POST /inventory/movements
RBAC: owner, manager
Body: {
  type: "LOSS",
  catalogItemId: string,
  quantity: number,
  reason: string,
  tenantId: string
}
```

### Avertissement RBAC

Le PRD (FR34) indique que le commercial peut déclarer des pertes. **Mais le backend actuel (`@Roles('owner', 'manager')`) n'autorise que owner/manager** pour `POST /inventory/movements`. La discordance est documentée — à corriger dans une story ultérieure (Epic 17 ou hotfix). Pour cette story : implémenter selon les contraintes backend actuelles (cacher le bouton aux commerciaux côté frontend).

### Motifs et labels

```dart
const lossReasons = [
  'Casse',
  'Péremption',
  'Vol',
  'Frotte',
  'Autre',
];
```

Pour "Autre" : `reason = 'Autre : ${précisionController.text}'`

---

## Dev Agent Record

### Implementation Plan

- `LossDeclarationForm` réutilise le même pattern `Autocomplete<Product>` + `paginatedProductListProvider` que les formulaires précédents.
- Dropdown utilise `DropdownButtonFormField` avec `initialValue` (pas `value`, déprécié depuis Flutter 3.33).
- Le champ "Autre" est conditionnel (`if (_isAutre)`) — affiché uniquement quand "Autre" est sélectionné.
- `_canSubmit` vérifie tous les critères localement avant d'activer le bouton — aucun appel API possible si le formulaire est invalide.
- `createMovement(type: 'LOSS', reason: _reasonLabel)` réutilise la méthode existante du repository.

### Completion Notes

- **89/89 tests pass** (82 existants + 7 nouveaux), zéro régression.
- AC1 ✅ : Autocomplete produit, quantité, dropdown 5 motifs, champ conditionnel Autre
- AC2 ✅ : Bouton désactivé si motif manquant / Autre sans précision
- AC3 ✅ : POST LOSS avec reason, snackbar succès/erreur, reset
- AC4 ✅ : 7 tests — champs présents, 5 options dropdown, disabled sans motif, Autre conditionnel, Casse→LOSS, Autre sans précision, Autre avec précision

---

## File List

| Action | Path |
| ------ | ---- |
| Created | `apps/frontend/lib/features/dashboard/presentation/widgets/inventory/loss_declaration_form.dart` |
| Modified | `apps/frontend/lib/features/dashboard/data/repositories/inventory_repository.dart` |
| Created | `apps/frontend/test/inventory_loss_test.dart` |

---

## Change Log

| Date | Change |
| ---- | ------ |
| 2026-03-15 | Story créée — déclaration pertes avec motif obligatoire (FR34) |
| 2026-03-15 | Implemented: loss_declaration_form.dart, 7 tests — 89/89 pass |
