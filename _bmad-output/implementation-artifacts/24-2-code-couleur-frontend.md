# Story 24.2 — Frontend : Code couleur dans catalogue et POS (vert/orange/rouge)

## Metadata

- **Epic:** Epic 24 — Fraîcheur + code couleur priorité vente
- **Story ID:** 24-2-code-couleur-frontend
- **Status:** done
- **Priority:** High
- **Depends on:** 24-1 (endpoint batches/expiring disponible)

---

## Story

**As a** cashier or manager,
**I want** a color freshness indicator on product cards in the POS grid and catalog,
**So that** I can prioritize selling perishable articles before they expire (FR85).

---

## Acceptance Criteria

### AC1 — Widget indicateur fraîcheur

**Given** un article a `expiryDays != null` et un batch actif
**When** la card de l'article s'affiche (POS grid ou catalogue)
**Then** une bande de couleur ou un chip apparaît sur la card : **Vert** si `freshnessPercent > 50%`, **Orange** si entre 20–50%, **Rouge** si `freshnessPercent < 20%` ou date dépassée
**And** le chip affiche le nombre de jours restants (ex: "3j" en rouge, "12j" en vert)
**And** les articles sans `expiryDays` ou sans batch actif n'affichent aucun indicateur

### AC2 — Seuils configurables par tenant

**Given** l'owner modifie les seuils dans les paramètres tenant (`PATCH /api/v1/tenants/freshness-thresholds`)
**When** les seuils sont mis à jour (`greenThreshold: 50, orangeThreshold: 20`)
**Then** tous les indicateurs couleur recalculent selon les nouveaux seuils
**And** les seuils sont persistés et chargés au démarrage de l'app (Isar local)

### AC3 — Tri priorité orange/rouge dans la grille POS

**Given** la grille POS s'affiche
**When** des articles avec indicateurs orange ou rouge sont présents
**Then** ces articles apparaissent en premier dans la grille (avant les verts et les sans-indicateur)
**And** à l'intérieur du groupe rouge, tri par `expiresAt` croissant (plus urgent en premier)
**And** le tri fraîcheur est appliqué après le tri par catégorie (catégorie est prioritaire)

### AC4 — Filtre "Articles urgents" dans la grille POS

**Given** l'utilisateur est dans la grille POS
**When** il active le filtre "Articles urgents" (toggle ou chip dans la barre de filtres)
**Then** seuls les articles avec indicateur orange ou rouge sont affichés
**And** le filtre est persisté pour la session POS courante

### AC5 — Offline

**Given** l'appareil est hors ligne
**When** la grille POS ou le catalogue s'affiche
**Then** la couleur est calculée localement depuis le batch Isar le plus récent de l'article
**And** aucun appel réseau n'est requis pour afficher les indicateurs

---

## Tasks/Subtasks

- [x] **Task 1 : Widget FreshnessChip**
  - [x] Créer `apps/frontend/lib/features/shared/catalog/presentation/widgets/freshness_chip.dart`
  - [x] Paramètres : `expiresAt DateTime`, `expiryDays int`, `greenThreshold double`, `orangeThreshold double`
  - [x] Couleur calculée : vert / orange / rouge selon `freshnessPercent`
  - [x] Afficher jours restants : "3j", "12j"

- [x] **Task 2 : Modèle Product — nearestExpiryDate + expiryDays**
  - [x] Ajouter `DateTime? nearestExpiryDate`, `int? expiryDays` dans `product.dart`
  - [x] Mettre à jour `fromJson()`

- [x] **Task 3 : ProductGrid — afficher FreshnessChip**
  - [x] Sur chaque card, si `product.nearestExpiryDate != null`, afficher `FreshnessChip`
  - [x] Tri priorité : rouge → orange → vert → sans indicateur (dans chaque catégorie)
  - [x] Toggle filtre "Articles urgents" en barre de filtres

- [x] **Task 4 : Seuils tenant configurables**
  - [x] Provider `freshnessThresholdsProvider` : charger seuils depuis settings tenant (Isar local)
  - [x] Endpoint `PATCH /api/v1/tenants/freshness-thresholds` côté backend (peut être inclus ici)

- [x] **Task 5 : POS screen — toggle filtre urgent**
  - [x] Ajouter chip/toggle "Articles urgents" dans la barre de filtres POS

---

## Files to Create

- `apps/frontend/lib/features/shared/catalog/presentation/widgets/freshness_chip.dart`

## Files to Modify

- `apps/frontend/lib/features/retail/pos/data/models/product.dart` — `nearestExpiryDate`, `expiryDays`
- `apps/frontend/lib/features/shared/catalog/presentation/widgets/product_grid.dart` — tri priorité + filtre + chip fraîcheur
- `apps/frontend/lib/features/retail/pos/presentation/screens/pos_screen.dart` — toggle filtre urgent

## Dev Notes

- `freshnessPercent` peut être calculé localement : `(expiresAt.difference(now).inDays / expiryDays) × 100`
- Le modèle `Product` Dart doit exposer le batch courant (`nearestExpiryDate`, `freshnessPercent`)
