---
type: components
group: actions
components: [ActionButton, ConfirmationDialog]
---

# Composants — Actions

> Ces composants déclenchent des actions utilisateur.
> ActionButton = l'action. ConfirmationDialog = le garde-fou pour les irréversibles.

---

## ActionButton

**Rôle :** Déclenche une action. Variantes par importance et type d'action.
**Règle :** Un seul bouton primaire par vue. Pleine largeur sur mobile.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `label` | string | Texte du bouton (depuis JSON) |
| `variant` | enum | `primary` / `secondary` / `destructive` / `ghost` |
| `size` | enum | `large` / `medium` / `small` |
| `enabled` | bool | Activé ou désactivé |
| `loading` | bool | État chargement |
| `icon` | string? | Icône préfixe optionnelle |
| `route` | string? | Route de navigation |
| `action` | string? | Action handler |
| `full_width` | bool | Pleine largeur (défaut true sur mobile) |

### Sketches ASCII

```
PRIMAIRE (pleine largeur) :
┌────────────────────────────────────────────┐
│ ██████████████ Nouvelle vente █████████████│
└────────────────────────────────────────────┘
bg: color-primary-500 | texte: white | h=48px | radius-md

PRIMAIRE AVEC ICÔNE :
┌────────────────────────────────────────────┐
│ ████████ + Réceptionner livraison █████████│
└────────────────────────────────────────────┘

SECONDAIRE :
┌────────────────────────────────────────────┐
│           Clôture caisse                   │
└────────────────────────────────────────────┘
bg: white | texte: color-primary-500 | bordure: color-primary-300

DESTRUCTIF :
┌────────────────────────────────────────────┐
│ ████████████ Confirmer annulation ████████ │
└────────────────────────────────────────────┘
bg: color-danger-500 | texte: white

GHOST (lien texte) :
                    Voir tout l'historique →
texte: color-primary-500 | pas de fond ni bordure

DISABLED :
┌────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░ Sauvegarder ░░░░░░░░░░░░░░░ │
└────────────────────────────────────────────┘
bg: color-neutral-100 | texte: color-neutral-500 | non tappable

LOADING :
┌────────────────────────────────────────────┐
│ ████████████ [↻] En cours... ██████████████│
└────────────────────────────────────────────┘
spinner centré | non tappable pendant loading

SMALL (inline dans une liste) :
  ┌──────────────┐
  │ + Ajouter    │
  └──────────────┘
  h=32px | radius-sm | pas pleine largeur

GRILLE D'ACTIONS (3 boutons secondaires) :
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│  📊 Rapports  │ │  📦 Stock     │ │  👥 Équipe    │
└───────────────┘ └───────────────┘ └───────────────┘
  Égaux — aucun ne prime sur les autres
```

---

## ConfirmationDialog

**Rôle :** Modal de confirmation avant une action irréversible.
**Règle :** Obligatoire pour toute action destructive (P10). Annuler à gauche, Confirmer à droite.
**Comportement :** Tap outside → dismiss (équivalent Annuler). Back Android → dismiss.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `title` | string | Titre clair de l'action |
| `body` | string | Description des conséquences |
| `confirm_label` | string | Label bouton confirmation |
| `cancel_label` | string | Label bouton annulation (défaut: "Annuler") |
| `confirm_variant` | enum | `primary` / `destructive` |

### Sketches ASCII

```
DESTRUCTIF (annulation vente) :
┌──────────────────────────────────────────────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  ← overlay
│▓▓  ╔══════════════════════════════════════╗ ▓│
│▓▓  ║  Confirmer l'annulation ?            ║ ▓│
│▓▓  ║                                      ║ ▓│
│▓▓  ║  Annuler la vente de 12 500 FCFA.    ║ ▓│
│▓▓  ║  Le stock sera remis à jour.         ║ ▓│
│▓▓  ║  Cette action est irréversible.      ║ ▓│
│▓▓  ║                                      ║ ▓│
│▓▓  ║  ┌──────────┐  ┌────────────────┐   ║ ▓│
│▓▓  ║  │  Annuler │  │ ████ Confirmer ████│  ║ ▓│
│▓▓  ║  └──────────┘  └────────────────┘   ║ ▓│
│▓▓  ╚══════════════════════════════════════╝ ▓│
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
└──────────────────────────────────────────────┘
Annuler: secondaire gauche | Confirmer: color-danger-500 droite

PRIMAIRE (confirmation action importante mais réversible) :
│▓▓  ╔══════════════════════════════════════╗ ▓│
│▓▓  ║  Activer le tenant ?                 ║ ▓│
│▓▓  ║                                      ║ ▓│
│▓▓  ║  Blandine recevra ses identifiants.  ║ ▓│
│▓▓  ║  Le tenant sera immédiatement actif. ║ ▓│
│▓▓  ║                                      ║ ▓│
│▓▓  ║  ┌──────────┐  ┌────────────────┐   ║ ▓│
│▓▓  ║  │  Annuler │  │ ████ Activer ████│  ║ ▓│
│▓▓  ║  └──────────┘  └────────────────┘   ║ ▓│
│▓▓  ╚══════════════════════════════════════╝ ▓│
Confirmer: color-primary-500 droite
```
