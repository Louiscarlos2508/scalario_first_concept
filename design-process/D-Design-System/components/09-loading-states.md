---
type: components
group: loading-states
components: [Skeleton, LoadingSpinner, ErrorState, PasswordStrengthBar, PINInput, ImageUploader, SplashScreen, DriftLoader, ProfileLoader]
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

---

## SplashScreen

**Rôle :** Écran de démarrage affiché pendant l'initialisation de l'application — logo, animation, attente Drift + JWT check.
**Usage :** S01.1 (App Init — premier état avant dashboard ou login).
**Règle :** Durée maximale 3s. Si Drift initialisé + JWT valide → navigate vers Dashboard rôle. Si JWT absent/expiré → navigate vers LoginWidget. Jamais de spinner infini — ErrorState si > 5s sans réponse.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `status` | enum | `loading` / `success` / `error` |
| `on_ready` | callback | Navigation auto quand status = success |

### Sketch ASCII

```
CHARGEMENT (défaut) :
┌──────────────────────────────────────────────┐
│                                              │
│                                              │
│              ╔══════════╗                    │
│              ║  SCALARIO║                   │  Logo centré
│              ╚══════════╝                    │  Inter 24sp 700 neutral-900
│                                              │
│              [↻ animation]                   │  LoadingSpinner 32px primary-500
│                                              │
│       _Chargement de votre espace..._        │  Inter 13sp neutral-400
│                                              │
│                                              │
└──────────────────────────────────────────────┘
bg: color-white · centré vertical

SUCCÈS (transition rapide 200ms vers dashboard) :
  → navigate(role_dashboard_route)  — pas d'affichage intermédiaire

ERREUR (> 5s sans réponse) :
  → ErrorState remplace le SplashScreen
```

---

## DriftLoader

**Rôle :** État de chargement spécifique à l'initialisation de Drift — affiché pendant l'ouverture de la base de données locale au premier lancement ou après une mise à jour du schéma.
**Usage :** S01.1 (App Init — DriftLoader avant SplashScreen si migration en cours).
**Règle :** Distinct du LoadingSpinner : DriftLoader = opération de base de données locale, pas réseau. Toujours accompagné d'un message rassurant ("données locales en cours de préparation"). Durée typique < 500ms — invisible si rapide (seuil 300ms avant affichage).

### Props

| Prop | Type | Description |
|------|------|-------------|
| `migration_version` | int? | Version du schéma si migration en cours |
| `progress` | double? | 0.0–1.0 si progression quantifiable |

### Sketch ASCII

```
INIT DRIFT (affiché si > 300ms) :
┌──────────────────────────────────────────────┐
│                                              │
│              [↻]                             │  spinner 24px neutral-400
│                                              │
│   _Préparation des données locales..._       │  Inter 12sp neutral-400
│                                              │
└──────────────────────────────────────────────┘
bg: color-white · pas de logo — trop tôt dans le cycle

MIGRATION SCHÉMA (mise à jour app) :
  _Mise à jour de votre base de données locale..._
  [████████████████░░░░░░░░░░░░]  62%           ← ProgressBar si progress fourni
```

---

## ProfileLoader

**Rôle :** État de chargement inline affiché pendant la récupération des données de profil utilisateur post-authentification (JWT validé, profil en cours de fetch depuis le backend).
**Usage :** S07.1 (post-submit LoginWidget), S25.1 (chargement profil).
**Règle :** Jamais plein écran. Inline dans la zone de contenu (remplace le corps de la vue). Durée typique < 1s. Si > 3s → ErrorState.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `user_name` | string? | Prénom si déjà connu (JWT) |
| `tenant_name` | string? | Nom tenant si déjà connu |

### Sketch ASCII

```
POST-LOGIN (zone centrale) :
┌──────────────────────────────────────────────┐
│                                              │
│           [↻] Chargement du profil...        │  LoadingSpinner 24px primary-500
│                                              │
│    _Connexion sécurisée avec le serveur_     │  Inter 12sp neutral-400
│                                              │
└──────────────────────────────────────────────┘

POST-LOGIN (prénom connu depuis JWT) :
│           [↻] Bonjour, Blandine !            │  Inter 14sp 500 neutral-700
│    _Chargement de votre espace..._           │
```
