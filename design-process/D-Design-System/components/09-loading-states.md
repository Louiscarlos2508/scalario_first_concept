---
type: components
group: loading-states
components: [Skeleton, LoadingSpinner, ErrorState, PasswordStrengthBar, PINInput, ImageUploader]
---

# Composants — Loading States & Utilitaires

---

## Skeleton (Loading Placeholder)

**Rôle :** Placeholder animé pendant le chargement des données — évite le flash de contenu vide.
**Règle :** Toujours présent quand une vue charge depuis le réseau. Pas de spinner global bloquant.

### Quand utiliser

| Situation | Composant |
|-----------|-----------|
| Chargement dashboard | Skeleton KPICards (4 rectangles) |
| Chargement liste | Skeleton lignes (3–5 lignes) |
| Chargement rapport | Skeleton chart + KPIs |
| Chargement grille POS | Skeleton cards 2×3 |

### Sketches ASCII

```
SKELETON KPICard (2×2) :
╔══════════════╗  ╔══════════════╗
║ ░░░░░░░░░░   ║  ║ ░░░░░░░░░░   ║  ← shimmer animé
║ ░░░░░░░░░░   ║  ║ ░░░░░░░░░░   ║
║ ░░░░         ║  ║ ░░░░         ║
╚══════════════╝  ╚══════════════╝

SKELETON Liste (3 lignes) :
┌──────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░     ░░░░░░ ░░░░░░░  │
│ ░░░░░░░░░░░░░░░░         ░░░░░░░       │
├──────────────────────────────────────────┤
│ ░░░░░░░░░░░░░░░░░░     ░░░░░░ ░░░░░░░  │
│ ░░░░░░░░░░░░░░░░         ░░░░░░░       │
├──────────────────────────────────────────┤
│ ░░░░░░░░░░░░░░░░░░     ░░░░░░ ░░░░░░░  │
│ ░░░░░░░░░░░░░░░░         ░░░░░░░       │
└──────────────────────────────────────────┘

SKELETON ProductGrid (POS) :
╔══════════════╗  ╔══════════════╗
║ ░░░░░░░░░░   ║  ║ ░░░░░░░░░░   ║
║ ░░░░░░░░░░   ║  ║ ░░░░░░░░░░   ║
║ ░░░░░░       ║  ║ ░░░░░░       ║
║ ░░░░░░░░░░   ║  ║ ░░░░░░░░░░   ║
╚══════════════╝  ╚══════════════╝
```

---

## ErrorState (Backend Down)

**Rôle :** Affiché quand le backend est inaccessible ET que Drift n'a pas de données en cache.
**Distinct du mode offline** : offline = Drift fonctionne. ErrorState = données indisponibles même localement.

### Cas d'usage

| Situation | Comportement |
|-----------|-------------|
| Offline + Drift peuplé | `SyncStatusBar` ambre — app fonctionnelle |
| Offline + Drift vide (premier login jamais complété) | ErrorState — "Connexion requise pour le premier lancement" |
| Backend erreur 5XX + retry épuisé | ErrorState avec bouton "Réessayer" |
| Token expiré + pas de réseau pour refresh | ErrorState "Session expirée — reconnectez-vous" |

### Sketch ASCII

```
ERREUR RÉSEAU (Drift vide) :
┌──────────────────────────────────────────────┐
│                                              │
│            [illustration erreur]            │
│                                              │
│       Impossible de charger les données      │
│                                              │
│   _Vérifiez votre connexion internet et_    │
│   _réessayez._                              │
│                                              │
│   ┌────────────────────────────────────┐    │
│   │          Réessayer                 │    │
│   └────────────────────────────────────┘    │
│                                              │
│   _Contactez Kofi si le problème persiste_  │
│                                              │
└──────────────────────────────────────────────┘

SESSION EXPIRÉE :
┌──────────────────────────────────────────────┐
│            [illustration clé]               │
│       Session expirée                        │
│   _Votre session a expiré. Reconnectez-vous._│
│   ┌────────────────────────────────────┐    │
│   │      Se reconnecter                │    │
│   └────────────────────────────────────┘    │
└──────────────────────────────────────────────┘
```

---

## PasswordStrengthBar

**Rôle :** Indicateur visuel de la force d'un mot de passe en temps réel.
**Usage :** S23.1 (Forced Password Change), S25.2 (Edit Profile).

### Sketch ASCII

```
FAIBLE (< 8 chars) :
  [████░░░░░░░░░░░░░░░░░░░░]  Faible
  _[✕] Minimum 8 caractères_

MOYEN (8+ chars, pas de chiffre) :
  [████████████░░░░░░░░░░░░]  Moyen
  _[✕] Ajoutez au moins 1 chiffre_

FORT (8+ chars, chiffre, majuscule) :
  [████████████████████████]  Fort ✓
  _[✓] Mot de passe sécurisé_

couleurs: Faible=rouge | Moyen=ambre | Fort=vert
```

---

## PINInput

**Rôle :** Saisie d'un code PIN numérique à 4 ou 6 chiffres.
**Usage :** S24.1 (PIN Setup), re-auth quotidienne (remplace le clavier système).

### Sketch ASCII

```
SAISIE PIN 6 CHIFFRES :
  Choisissez votre PIN
  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐
  │● │  │● │  │● │  │● │  │  │  │  │  ← masqué (●)
  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘
         4 / 6 chiffres saisis

  Clavier numérique (clavier natif Flutter) :
  [1][2][3]
  [4][5][6]
  [7][8][9]
  [⌫][0][✓]

CONFIRMATION :
  Confirmez votre PIN
  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐
  │  │  │  │  │  │  │  │  │  │  │  │  ← vide

ERREUR (PIN ne correspond pas) :
  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ← bordure rouge
  _[✕] Les codes PIN ne correspondent pas_
```

---

## ImageUploader

**Rôle :** Upload d'une image depuis la galerie ou l'appareil photo.
**Usage :** S17.2 (logo tenant), éventuellement images produit (Phase suivante).

### Sketch ASCII

```
VIDE :
  ┌──────────────────────────────────────────┐
  │                                          │
  │          [📷]                            │
  │     Ajouter un logo                      │
  │  _Tap pour choisir depuis la galerie_    │
  │  _ou prendre une photo_                  │
  │                                          │
  └──────────────────────────────────────────┘

AVEC IMAGE :
  ┌──────────────────────────────────────────┐
  │  ┌──────────┐                            │
  │  │ [logo]   │  logo.png · 24 Ko          │
  │  └──────────┘  [Modifier]  [Supprimer]   │
  └──────────────────────────────────────────┘

UPLOAD EN COURS :
  ┌──────────────────────────────────────────┐
  │  [████████████████░░░░░░░░░░]  65%       │
  │  _Envoi en cours..._                     │
  └──────────────────────────────────────────┘
```

---

## LoadingSpinner

**Rôle :** Indicateur de chargement inline pour les actions (submit bouton, sync ponctuelle).
**Règle :** Jamais en plein écran bloquant — toujours inline dans le composant qui charge.

### Sketch ASCII

```
BOUTON EN LOADING :
┌────────────────────────────────────────────┐
│ ████████████ [↻] En cours... ██████████████│
└────────────────────────────────────────────┘

SYNC INLINE (ProfileLoader) :
  [↻] Chargement de votre profil...
  _Connexion sécurisée avec le serveur_
```
