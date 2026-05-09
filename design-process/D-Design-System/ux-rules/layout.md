---
type: ux-rules
slug: layout
---

# UX Rules — Layout & Navigation

---

## Navigation Mobile Android

### Structure Globale

```
┌──────────────────────────────────────────────┐
│ StatusBar Android (système)                  │
├──────────────────────────────────────────────┤
│ AppBar : [← ou ≡]   TITRE          [actions] │  h=56px
├──────────────────────────────────────────────┤
│                                              │
│  Contenu scrollable                          │  flex
│                                              │
├──────────────────────────────────────────────┤
│ SyncStatusBar (discret)                      │  h=28px
├──────────────────────────────────────────────┤
│ 🏠 Accueil  📊 Rapports  📦 Stock  ⚙ Params  │  h=56px
└──────────────────────────────────────────────┘
```

### Tabs Bottom Navigation par Rôle

**OWNER (Blandine) :**
```
  🏠 Dashboard  |  📊 Rapports  |  📦 Stock  |  ⚙ Paramètres
```

**COMMERCIAL :**
```
  🏠 Dashboard  |  📋 Historique
```
(Minimaliste — le POS est la seule vraie action)

**MANAGER (Ibrahim) :**
```
  🏠 Dashboard  |  📦 Stock  |  📋 Opérations
```

### Règles AppBar

- Titre : `text-headline`, centré ou gauche selon contexte
- Retour `←` : toujours à gauche si vue non-racine
- Actions droite : max 2 icônes (ex: recherche + filtre)
- Pas de sous-titre dans l'AppBar — réservé au contenu

---

## Layout Flutter Web PWA

### Structure Globale

```
┌────────────────────────────────────────────────────────────┐
│ TopBar : Logo Scalario [tenant]          [user] [settings] │  h=64px
├──────────┬─────────────────────────────────────────────────┤
│          │                                                 │
│  Nav     │  Contenu principal                              │
│  240px   │  fluid — max 960px centré                      │
│  fixe    │                                                 │
│          │                                                 │
│ Dashboard│                                                 │
│ Rapports │                                                 │
│ Stock    │                                                 │
│ Équipe   │                                                 │
│ Fourniss.│                                                 │
│ Paramèt. │                                                 │
│          │                                                 │
│ ─────── │                                                 │
│ [user]   │                                                 │
│ Déconn.  │                                                 │
└──────────┴─────────────────────────────────────────────────┘
```

### Grilles Dashboard Flutter Web

**OWNER (S20) — 3 colonnes :**
```
┌────────────────────────────────────────────────────────┐
│ AlertBanner (pleine largeur si active)                 │
├──────────────┬──────────────┬──────────────────────────┤
│ KPICard CA   │ KPICard Mg.  │  ChartWidget CA 7j       │
│ KPICard Tx   │ KPICard Stk  │                          │
├──────────────┴──────────────┤                          │
│ RankingList Top 3           │                          │
├─────────────────────────────┴──────────────────────────┤
│ ActionButtons : Rapports | Stock | Équipe | Commander  │
└────────────────────────────────────────────────────────┘
```

### Split View (Liste + Détail) Flutter Web

```
┌──────────────────────┬─────────────────────────────────┐
│ Liste (filtrée)      │ Détail sélectionné              │
│ ─────────────────    │ ──────────────────────────────  │
│ Item 1 [●]           │ TITRE DÉTAIL                    │
│ Item 2               │ Corps détail                    │
│ Item 3               │ Actions                         │
│ ...                  │                                 │
└──────────────────────┴─────────────────────────────────┘
  40% largeur             60% largeur
```

---

## Layout Admin Scalario (Flutter Web statique)

### Structure Globale

```
┌───────────────────────────────────────────────────────────┐
│ [Sc] SCALARIO ADMIN           [Carlos]  [notifications]   │
├──────────┬────────────────────────────────────────────────┤
│          │                                                │
│ Dashboard│  Contenu — max 1140px                         │
│ Tenants  │                                               │
│ Intégrat.│                                               │
│ Facturati│                                               │
│ Monitorin│                                               │
│          │                                               │
└──────────┴────────────────────────────────────────────────┘
  200px fixe  fluid
```

---

## Règles Layout Générales

### Mobile — Zone de confort des pouces

```
  ┌─────────────┐
  │  Zone       │  ← Difficile d'atteindre — réservé contenu lecture
  │  haute      │
  │             │
  │  Zone       │  ← Confortable — KPIs, contenu principal
  │  centrale   │
  │             │
  │  Zone       │  ← Facile — ActionButton primaire, navigation
  │  basse      │
  └─────────────┘
```

**Règles :**
- `ActionButton` primaire toujours dans la zone basse ou centrale basse
- Navigation toujours en bas (bottom nav)
- Alertes toujours en haut (zone haute — lecture, pas interaction)
- Formulaires : labels en haut, submit en bas

### Ordre de Priorité d'Affichage (top → bottom)

1. **AlertBanner** (si active) — critique en rouge prime
2. **KPICards** — état actuel au-dessus du fold
3. **ActionButtons** primaires — l'action la plus fréquente
4. **Listes / Charts** — contexte et historique (scroll)
5. **ActionButtons** secondaires — actions moins fréquentes
6. **SyncStatusBar** — toujours dernier, toujours discret

### Responsive Breakpoints

| Breakpoint | Largeur | Layout |
|------------|---------|--------|
| Mobile | < 600px | 1 colonne, bottom nav |
| Tablet | 600–1024px | 2 colonnes, sidebar |
| Desktop | > 1024px | 3 colonnes, sidebar fixe |
