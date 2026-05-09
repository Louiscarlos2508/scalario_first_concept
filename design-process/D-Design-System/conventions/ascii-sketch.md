---
type: conventions
slug: ascii-sketch
---

# Conventions — ASCII Hi-Fi Sketches

> Référence unique pour tous les sketches ASCII du projet Scalario.
> Tout sketch produit dans ce projet DOIT respecter ces conventions.

---

## Dimensions

| Surface | Largeur ASCII | Représente |
|---------|--------------|------------|
| Mobile Android | 44 chars internes | 360px |
| Flutter Web (colonne) | 38 chars internes | ~400px colonne |
| Flutter Web (full) | 120 chars internes | 1200px |
| Admin (full) | 120 chars internes | 1200px |

---

## Boîtes et Conteneurs

```
Écran mobile complet :
┌──────────────────────────────────────────────┐
│ StatusBar                              🔋 📶 │
├──────────────────────────────────────────────┤
│ [← Retour]   TITRE PAGE                      │
├──────────────────────────────────────────────┤
│                                              │
│  contenu                                     │
│                                              │
└──────────────────────────────────────────────┘

Card (elevation-1) :
╔══════════════════════════════════════════╗
║  contenu card                            ║
╚══════════════════════════════════════════╝

Section sans bordure :
  contenu section sans boîte

Séparateur :
  ──────────────────────────────────────────
```

---

## Typographie ASCII

```
TITRE PAGE          ← text-headline (28px Bold) = MAJUSCULES
Titre Section       ← text-title (18px SemiBold) = Casse normale
Corps de texte      ← text-body (14px Regular)
_note ou hint_      ← text-caption (12px) = italique simulé
**valeur importante** ← text-body-medium = gras simulé
```

---

## Composants de Base

### ActionButton

```
Primaire (pleine largeur) :
┌────────────────────────────────────────┐
│ ████████████ Nouvelle vente ██████████ │  ← bg color-primary-500
└────────────────────────────────────────┘

Secondaire :
┌────────────────────────────────────────┐
│         Clôture caisse                 │  ← bg neutre, bordure
└────────────────────────────────────────┘

Destructif :
┌────────────────────────────────────────┐
│ ██████████ Confirmer annulation ██████ │  ← bg color-danger-500
└────────────────────────────────────────┘

Disabled :
┌────────────────────────────────────────┐
│ ░░░░░░░░░░░░ Sauvegarder ░░░░░░░░░░░░ │  ← opacity réduite
└────────────────────────────────────────┘
```

### AlertBanner

```
Critique (rouge) :
┌──────────────────────────────────────────────┐
│ [!] Stock critique : Tomates — 2,3 kg restants│
└──────────────────────────────────────────────┘

Warning (ambre) :
┌──────────────────────────────────────────────┐
│ [⚠] Livraison en attente : FrutPro           │
└──────────────────────────────────────────────┘

Succès (vert) :
┌──────────────────────────────────────────────┐
│ [✓] Vente enregistrée — 12 500 FCFA          │
└──────────────────────────────────────────────┘

Info (bleu) :
┌──────────────────────────────────────────────┐
│ [i] Mode hors ligne — données sauvegardées   │
└──────────────────────────────────────────────┘
```

### KPICard

```
Nominal :
╔══════════════════════╗
║ CA du jour           ║
║  47 500 FCFA         ║  ← text-display
║  _+12% vs hier_      ║  ← text-caption vert
╚══════════════════════╝

Alerte :
╔══════════════════════╗
║ Stock critique       ║
║  3 articles          ║  ← text-display rouge
║  _−2 vs hier_        ║  ← text-caption rouge
╚══════════════════════╝

Grille 2×2 mobile :
╔══════════════╗  ╔══════════════╗
║ CA du jour   ║  ║ Marge brute  ║
║  47 500      ║  ║  18 200      ║
║  _FCFA +12%_ ║  ║  _FCFA  38%_ ║
╚══════════════╝  ╚══════════════╝
╔══════════════╗  ╔══════════════╗
║ Transactions ║  ║ Stock crit.  ║
║     23       ║  ║     3        ║
║  _+3 vs hier_║  ║  _[!] alerte_║
╚══════════════╝  ╚══════════════╝
```

### SyncStatusBar

```
Synced :
  ────────────────────────────────────────────
  [●] Synchronisé — il y a 2 min
  ────────────────────────────────────────────

Syncing :
  ────────────────────────────────────────────
  [↻] Synchronisation en cours...
  ────────────────────────────────────────────

Offline :
  ────────────────────────────────────────────
  [○] Hors ligne — données locales à jour
  ────────────────────────────────────────────
```

### StatusBadge

```
  [● Actif]      ← vert pill
  [○ Inactif]    ← gris pill
  [! Crédit]     ← ambre pill
  [✕ Annulé]     ← rouge barré
  [↑ Surplus]    ← bleu pill
```

### Toggle

```
Actif  : [●────]   Inactif : [────○]
```

### ChipSelector (sélection unique)

```
  [● Push immédiate]  [○ Résumé]  [○ Les deux]
```

### FilterChips (multi-sélection)

```
  [✓ Ventes]  [✓ Pertes]  [○ Livraisons]  [○ Inventaires]
```

### TextInput

```
  Label champ *
  ┌────────────────────────────────────────┐
  │ Valeur saisie                          │
  └────────────────────────────────────────┘
  _hint text optionnel_

  Focus :
  ┌────────────────────────────────────────┐  ← bordure color-primary-500
  │ Valeur|                                │  ← curseur
  └────────────────────────────────────────┘

  Erreur :
  ┌────────────────────────────────────────┐  ← bordure rouge
  │ Valeur invalide                        │
  └────────────────────────────────────────┘
  _[✕] Ce champ est obligatoire_
```

### QuantityControl

```
  ┌──────┐  ┌──────────────┐  ┌──────┐
  │  −   │  │   4,5 kg     │  │  +   │
  └──────┘  └──────────────┘  └──────┘
```

### ProgressBar

```
  Inventaire : 12/35 articles
  [████████████████░░░░░░░░░░░░░░░░░░░░]  34%
```

---

## Ligne de Liste (TransactionLine)

```
  ┌────────────────────────────────────────────┐
  │ Vente · 09:34              12 500 FCFA [●] │
  │ _Tomates 2kg · Igname 5kg_                 │
  └────────────────────────────────────────────┘

  Annulée :
  ┌────────────────────────────────────────────┐
  │ ~~Vente · 09:34~~         ~~8 000 FCFA~~ [✕]│
  │ _Annulée — Erreur saisie_                  │
  └────────────────────────────────────────────┘
```

---

## Navigation Mobile

```
┌──────────────────────────────────────────────┐
│ 🏠 Accueil  📊 Rapports  📦 Stock  ⚙ Params  │  ← Bottom nav
└──────────────────────────────────────────────┘
```

---

## Notation des États dans les Sketches

| Notation | Signification |
|----------|--------------|
| `[●]` | Actif / sélectionné / succès |
| `[○]` | Inactif / désélectionné |
| `[!]` | Warning / alerte ambre |
| `[✕]` | Erreur / danger / annulé |
| `[✓]` | Validé / succès |
| `[↻]` | En cours / syncing |
| `[i]` | Info |
| `*` | Champ obligatoire |
| `~~texte~~` | Barré / annulé |
| `_texte_` | Caption / secondaire |
| `█` | Fond plein (bouton primaire) |
| `░` | Fond léger / disabled |
| `▓` | Fond medium (hover) |

---

## Structure d'un Fichier Sketch

Chaque fichier sketch dans `Sketches/` suit cette structure :

```markdown
---
scenario: "XX"
step: "XX.Y"
sketch-type: hi-fi-ascii
platform: mobile-android | flutter-web | admin
---

# Sketch — XX.Y Nom du Step

## État Principal

[ASCII sketch ici]

## États Alternatifs

### État : [nom état]
[ASCII sketch ici]

## Notes d'Interaction
- Tap sur X → Y
- Swipe Z → W
```
