# Scalario Design System

## Design Philosophy

Scalario serves merchants in West Africa. The UI must handle:
- Users with varying tech literacy (some use smartphones daily, some barely)
- Bright outdoor environments (markets, shop fronts)
- Touch-first devices (Android tablets for POS)
- Intermittent connectivity
- French as primary language

### Core Principles

1. **Gros et clair** — Big buttons, big text, high contrast
2. **2 taps maximum** — Any frequent action reachable in 2 taps
3. **Pas de surprise** — Confirm destructive actions, show clear feedback
4. **Ça marche sans internet** — Offline indicators, never block on network
5. **Français d'abord** — All labels and messages in French by default

## Platform Adaptations

| Aspect | Tablette POS (Android) | Bureau (Windows) | Web Admin |
|--------|----------------------|-------------------|-----------|
| Usage | Caissier, vente rapide | Gestionnaire, back-office | Propriétaire, reporting |
| Input | Tactile | Souris + clavier | Souris + clavier |
| Écran | 10" paysage | 13"+ | Variable |
| Layout | Mono-tâche | Multi-panneaux | Dashboard complet |
| Offline | Obligatoire | Souhaité | Online uniquement |

### Breakpoints

```
compact:  < 600px    (téléphone — support basique)
medium:   600-1024px (tablette — device principal POS)
expanded: > 1024px   (desktop, web admin)
```

## Couleurs

### Palette Principale

```
Primaire:     #1565C0 (Bleu confiance — actions principales)
Succès:       #2E7D32 (Vert — confirmations, synchronisé)
Erreur:       #C62828 (Rouge — erreurs, alertes, pertes)
Attention:    #F9A825 (Jaune — en attente, sync pending)
Surface:      #FFFFFF (Cartes, modales)
Fond:         #F5F5F5 (Fond app)
Texte:        #212121 (Texte principal)
Texte léger:  #757575 (Texte secondaire)
```

### Couleurs Verticales

Chaque vertical a une teinte d'accent subtile dans la barre de navigation :

```
Retail (Boutique):  #1565C0 (Bleu)
Pharmacy (futur):   #2E7D32 (Vert)
School (futur):     #6A1B9A (Violet)
Enterprise (futur): #E65100 (Orange)
```

### Code Couleur Fraîcheur (Vertical Grocery)

Pour les produits périssables — Blandine en a besoin :

```
🟢 Vert:   Frais — date OK, stock normal
🟠 Orange: Attention — proche expiration, vendre en priorité
🔴 Rouge:  Urgent — dernière chance, promo flash ou déclasser
⚫ Gris:   Expiré — à déclarer en perte
```

## Typographie

```
Titre principal:  22sp / Bold / Texte principal
Titre section:    18sp / SemiBold / Texte principal
Titre carte:      16sp / SemiBold / Texte principal
Corps:            14sp / Regular / Texte principal
Corps petit:      12sp / Regular / Texte léger
Étiquette:        11sp / Medium / MAJUSCULES pour catégories
Prix:             20sp / Bold / Monospace — toujours bien visible
Quantité:         18sp / Bold / Monospace
```

Polices système uniquement (Roboto Android, Segoe UI Windows, sans-serif Web).

## Composants Clés

### POS — Écran de Vente

Layout tablette (10" paysage) :

```
┌──────────────────────────────────────────────────┐
│ [Barre supérieure: Nom boutique | Caissier | ●🟢] │
├────────────────────────────┬─────────────────────┤
│                            │                     │
│   GRILLE PRODUITS          │   PANIER            │
│   (3-4 colonnes)           │                     │
│                            │   Produit 1  2x 500 │
│   [🍅 Tomate]  [🧅 Oignon] │   Produit 2  1x 300 │
│   [🌶 Piment]  [🧄 Ail]    │   Produit 3  3x 150 │
│   [🥬 Laitue]  [🥕 Carotte]│                     │
│                            │   ─────────────     │
│   [Catégories en haut]     │   TOTAL: 1 750 F    │
│                            │                     │
│                            │  [  ENCAISSER  ]    │
│                            │  (gros bouton vert) │
├────────────────────────────┴─────────────────────┤
│ [🔍 Recherche produit]  [📊 Historique] [⚙️ Plus] │
└──────────────────────────────────────────────────┘
```

Règles :
- Carte produit : minimum 90x90px, image + nom + prix
- Bouton Encaisser : le plus gros élément de l'écran
- Panier toujours visible à droite
- Total toujours visible, gros, en gras
- Catégories par onglets en haut de la grille
- Recherche par nom ou scan (futur code-barres)

### Pavé Numérique

Pour saisie quantité et prix — NE PAS utiliser le clavier natif :

```
┌─────────────────────┐
│     [ 1.500 F ]     │  ← Affichage valeur actuelle
├─────┬─────┬─────────┤
│  7  │  8  │    9    │
├─────┼─────┼─────────┤
│  4  │  5  │    6    │
├─────┼─────┼─────────┤
│  1  │  2  │    3    │
├─────┼─────┼─────────┤
│  .  │  0  │   ←     │  ← Effacer dernier chiffre
├─────┴─────┴─────────┤
│    [ VALIDER ✓ ]    │
└─────────────────────┘
```

Boutons : minimum 56px, retour tactile (haptic feedback).

### Indicateur de Synchronisation

Toujours visible dans la barre supérieure :

```
🟢 "Connecté"                    → En ligne, tout synchro
🟡 "Synchronisation... (3)"      → En ligne, 3 éléments en attente
⚪ "Hors ligne"                  → Pas de réseau, fonctionne quand même
🟡 "Hors ligne — 5 en attente"  → Pas de réseau, modifications en file
🔴 "Erreur sync — Réessayer"    → Échec, tap pour relancer
```

L'utilisateur doit comprendre en un coup d'œil si tout va bien.

### Tableaux de Données

Pour les listes de produits, mouvements, ventes :

- Barre de recherche/filtre en haut
- Colonnes triables (tap sur en-tête)
- Lignes de hauteur confortable (min 48px)
- Actions par icônes à droite (pas de menu contextuel)
- Pagination simple : "Page 1 sur 12 — Suivant →"
- Pull-to-refresh sur mobile/tablette

### Formulaires

- Labels flottants (floating labels)
- Validation en temps réel sous le champ
- Bouton "Effacer" sur chaque champ texte
- Sélecteurs natifs pour dates (pas de saisie manuelle de date)
- Dropdowns pour les choix limités (catégories, unités)
- Bouton "Enregistrer" bien visible, vert, en bas

### Dialogues de Confirmation

Pour actions critiques (clôture caisse, déclaration perte, suppression) :

```
┌──────────────────────────────────┐
│  ⚠️ Confirmer la clôture        │
│                                  │
│  Vous allez clôturer la caisse   │
│  du jour. Cette action ne peut   │
│  pas être annulée.               │
│                                  │
│  Total ventes: 45.750 F          │
│  Espèces comptées: 44.500 F     │
│  Écart: -1.250 F                │
│                                  │
│  [Annuler]      [Confirmer ✓]   │
└──────────────────────────────────┘
```

Toujours montrer un résumé de ce qui va se passer.

## Navigation

### Navigation Principale (Rail gauche sur tablette/desktop)

```
┌────┐
│ 🏪 │ Ventes (POS)
│ 📦 │ Stock
│ 💰 │ Caisse
│ 📋 │ Commandes
│ 📊 │ Rapports
├────┤
│ ⚙️ │ Paramètres
│ 👤 │ Profil
└────┘
```

- Affiche uniquement les modules activés pour ce tenant
- Icônes + labels courts
- Le module actif est mis en évidence (fond coloré)

### Navigation Compact (téléphone)

Barre de navigation en bas, maximum 5 éléments.
Overflow "Plus ⋯" pour les modules supplémentaires.

## Thème Flutter

```dart
ThemeData scalarioTheme({
  required String verticalType,
  Brightness brightness = Brightness.light,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: verticalColors[verticalType] ?? primaryBlue,
      brightness: brightness,
    ),
    textTheme: const TextTheme(
      // Use system fonts, adapted sizes
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),  // Touch-friendly
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
```

Pas de dark mode en v1. Priorité : lisibilité en plein soleil.

## Animations et Feedback

- Durée max 300ms — les commerçants sont pressés
- Haptic feedback sur POS (vente confirmée, article ajouté)
- Toast vert en bas pour succès
- Dialog rouge pour erreurs avec explication simple
- Aucune animation décorative — tout mouvement = information
