---
type: components
group: feedback
components: [AlertBanner, StatusBadge, SyncStatusBar, ProgressBar, NotificationBadge]
---

# Composants — Feedback

> Ces composants communiquent l'état du système à l'utilisateur.
> Ils ne demandent pas d'action — ils informent.

---

## AlertBanner

**Rôle :** Communique un état important qui nécessite l'attention de l'utilisateur.
**Position :** Toujours en haut de la vue, sous l'AppBar. Jamais au milieu du contenu.
**Règle :** Une seule AlertBanner visible à la fois. Hiérarchie : rouge > ambre > vert > bleu.

### Props (depuis JSON / backend)

| Prop | Type | Description |
|------|------|-------------|
| `type` | enum | `critical` / `warning` / `success` / `info` |
| `message` | string | Texte affiché — en français |
| `action_label` | string? | Label bouton action (optionnel) |
| `action_route` | string? | Route deep link si action |
| `auto_dismiss_ms` | int? | Auto-dismiss en ms (null = persistant) |

### États & Sketches ASCII

```
CRITIQUE (rouge) — persistant jusqu'à action :
┌──────────────────────────────────────────────┐
│ [!] Stock critique : Tomates — 2,3 kg        │
│                                  [Voir stock]│
└──────────────────────────────────────────────┘
bg: color-danger-100 | texte: color-danger-700 | bordure gauche: color-danger-500

WARNING (ambre) — persistant ou dismiss manuel :
┌──────────────────────────────────────────────┐
│ [⚠] Livraison FrutPro en attente             │
│                              [Réceptionner]  │
└──────────────────────────────────────────────┘
bg: color-warning-100 | texte: color-warning-700 | bordure gauche: color-warning-500

SUCCÈS (vert) — auto-dismiss 2 secondes :
┌──────────────────────────────────────────────┐
│ [✓] Vente enregistrée — 12 500 FCFA          │
└──────────────────────────────────────────────┘
bg: color-success-100 | texte: color-success-700 | bordure gauche: color-success-500

INFO (bleu) — discret, dismissable :
┌──────────────────────────────────────────────┐
│ [i] Hors ligne — données locales à jour      │
└──────────────────────────────────────────────┘
bg: color-info-100 | texte: color-info-500 | bordure gauche: color-info-500

ABSENT (état nominal) :
[aucun composant rendu — la zone disparaît]
```

### Comportement

- Tap sur le banner (si action_route) → navigation deep link
- Auto-dismiss : animation slide-up après `auto_dismiss_ms`
- Swipe horizontal : dismiss manuel (sauf critique)
- Critique : pas de dismiss jusqu'à action résolue

---

## StatusBadge

**Rôle :** Indicateur visuel compact d'un état sur un item de liste.
**Position :** Inline dans une ligne de liste, à droite ou en haut à droite d'une card.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `status` | enum | `active` / `inactive` / `pending` / `credit` / `cancelled` / `surplus` / `critical` |
| `label` | string | Texte du badge |

### États & Sketches ASCII

```
  [● Actif]      bg: color-success-100  texte: color-success-700
  [○ Inactif]    bg: color-neutral-100  texte: color-neutral-500
  [↻ En attente] bg: color-info-100     texte: color-info-500
  [! Crédit]     bg: color-warning-100  texte: color-warning-700
  [✕ Annulé]     bg: color-danger-100   texte: color-danger-700  (texte barré)
  [↑ Surplus]    bg: color-info-100     texte: color-info-500
  [! Critique]   bg: color-danger-100   texte: color-danger-700
```

---

## SyncStatusBar

**Rôle :** Indique l'état de synchronisation Drift ↔ backend. Discret — ne perturbe pas le flux.
**Position :** Toujours en bas de page, au-dessus de la navigation bottom.
**Règle UX :** Jamais de couleur rouge — offline n'est pas une erreur (P3).

### Props

| Prop | Type | Description |
|------|------|-------------|
| `status` | enum | `synced` / `syncing` / `offline` / `error` |
| `last_sync` | datetime? | Timestamp dernière sync réussie |

### États & Sketches ASCII

```
SYNCED (vert discret) :
  ──────────────────────────────────────────────
  [●] Synchronisé — il y a 2 min
  ──────────────────────────────────────────────
  h=28px | texte: text-caption | couleur: color-success-500

SYNCING (animation) :
  ──────────────────────────────────────────────
  [↻] Synchronisation...
  ──────────────────────────────────────────────
  icône tourne | couleur: color-primary-500

OFFLINE (ambre neutre — pas alarmiste) :
  ──────────────────────────────────────────────
  [○] Hors ligne — données locales à jour
  ──────────────────────────────────────────────
  couleur: color-neutral-500 | PAS rouge

ERROR (ambre — uniquement si sync échoue > 3 fois) :
  ──────────────────────────────────────────────
  [⚠] Sync en attente depuis 2h
  ──────────────────────────────────────────────
  couleur: color-warning-500
```

---

## ProgressBar

**Rôle :** Indique la progression dans une tâche quantifiable (inventaire, import).
**Position :** Sous le titre de la vue ou au-dessus de la liste en cours.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `current` | int | Valeur actuelle |
| `total` | int | Valeur totale |
| `label` | string | Texte descriptif |

### États & Sketches ASCII

```
EN COURS :
  Inventaire : 12 / 35 articles comptés
  [████████████████░░░░░░░░░░░░░░░░░░░░]  34%

  barre: color-primary-500 | fond: color-neutral-100 | h=8px | radius-full

COMPLET :
  Inventaire : 35 / 35 articles comptés
  [████████████████████████████████████] 100%

  barre: color-success-500
```

---

## NotificationBadge

**Rôle :** Badge numérique superposé à une icône (typiquement la cloche 🔔 dans l'AppBar) pour signaler des notifications non lues. Rendu via un `Stack` Flutter.
**Usage :** S01.2 AppBar (🔔 + badge), S04 (alertes critiques), S10 (invitations équipe).
**Règle :** Disparaît à 0. Affiche "99+" si count > 99. Couleur rouge invariable (toujours `color-danger-500`) — indépendant du thème du rôle.

### Props

| Prop | Type | Description |
|------|------|-------------|
| `count` | int | Nombre de notifications non lues (0 = badge masqué) |
| `max_display` | int | Seuil "+" — défaut 99 |

### Tokens

| Élément | Token | Valeur |
|---------|-------|--------|
| Fond badge | `color-danger-500` | #EF4444 |
| Texte | `color-white` | Inter 10sp 700 |
| Diamètre (1 chiffre) | — | 16px |
| Diamètre (2 chiffres) | — | 20px (pill) |
| Position | — | top-right offset (-4px, -4px) relative à l'icône |

### Sketch ASCII

```
1 NOTIFICATION :
  🔔
   ●2   ← badge 16px rouge, centré sur coin sup-droit
         Inter 10sp 700 color-white

10 NOTIFICATIONS :
  🔔
   ●10  ← pill 20px

99+ NOTIFICATIONS :
  🔔
   ●99+ ← pill 24px

0 NOTIFICATION : badge absent — rendu neutre
  🔔
```
