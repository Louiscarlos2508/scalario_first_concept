---
type: conventions
slug: surfaces
---

# Conventions — Surfaces & Adaptations

> Scalario a 3 surfaces distinctes. Le design system couvre les 3.
> Les composants atomiques sont les mêmes — leur rendu s'adapte selon la surface.

---

## Les 3 Surfaces

| Surface | Technologie | Utilisateurs | Largeur type |
|---------|-------------|--------------|--------------|
| **Mobile Android** | Flutter mobile | Blandine, Ibrahim, Commercial | 360–414px |
| **Flutter Web PWA** | Flutter Web | Blandine (back-office), Kofi (intégrateur) | 768–1440px |
| **Admin Scalario** | Flutter Web statique | Équipe Scalario (Carlos) | 1024–1440px |

---

## Règles d'Adaptation par Composant

### ActionButton

| Surface | Comportement |
|---------|-------------|
| Mobile | Pleine largeur (full_width=true) — h=48px — touch target généreux |
| Flutter Web | Largeur auto (fit content) — h=40px — inline ou dans une grille |
| Admin | Largeur auto — h=36px — dense, souvent dans une DataTable |

```
MOBILE (pleine largeur) :
┌────────────────────────────────────────────┐
│ ████████████ Nouvelle vente ███████████████│
└────────────────────────────────────────────┘

FLUTTER WEB (inline) :
┌──────────────────────┐  ┌──────────────────┐
│  + Nouvelle vente    │  │  Clôture caisse  │
└──────────────────────┘  └──────────────────┘

ADMIN (dense, dans une ligne) :
  FrutPro · 45 000 FCFA · Actif   [Modifier]  [Suspendre]
```

---

### KPICard

| Surface | Comportement |
|---------|-------------|
| Mobile | Grille 2×2 — cartes compactes (largeur ~45% viewport) |
| Flutter Web | Grille 4 colonnes ou 3 colonnes — cartes plus larges |
| Admin | Rangée horizontale — cartes larges avec plus de détail |

```
MOBILE (2×2) :
╔═══════════╗  ╔═══════════╗
║ CA du jour║  ║ Marge     ║
║ 47 500 F  ║  ║ 18 200 F  ║
║ +12%↑     ║  ║ 38% ↑     ║
╚═══════════╝  ╚═══════════╝

FLUTTER WEB (4 colonnes) :
╔════════════╗ ╔════════════╗ ╔════════════╗ ╔════════════╗
║ CA du jour ║ ║ Marge brute║ ║ Transaction║ ║ Stk crit.  ║
║ 47 500 F   ║ ║ 18 200 F   ║ ║     23     ║ ║     0      ║
║ +12% ↑     ║ ║ 38% ↑      ║ ║ +3 vs hier ║ ║ [● OK]     ║
╚════════════╝ ╚════════════╝ ╚════════════╝ ╚════════════╝

ADMIN (rangée avec stats plateforme) :
╔══════════════════╗ ╔══════════════════╗ ╔══════════════════╗
║ Tenants actifs   ║ ║ MRR total        ║ ║ FCM delivery     ║
║       12         ║ ║  480 000 FCFA    ║ ║     97,3%        ║
║ +2 ce mois       ║ ║ +40k vs M-1      ║ ║ ↑ vs 95% M-1     ║
╚══════════════════╝ ╚══════════════════╝ ╚══════════════════╝
```

---

### Navigation

| Surface | Navigation |
|---------|-----------|
| Mobile | Bottom navigation bar (4 tabs max) |
| Flutter Web PWA | Sidebar gauche fixe (240px) + TopBar |
| Admin | Sidebar gauche fixe (200px) + TopBar |

```
MOBILE — Bottom Nav OWNER :
┌─────────────────────────────────────────────┐
│ 🏠 Dashboard  📊 Rapports  📦 Stock  ⚙ Param│
└─────────────────────────────────────────────┘

FLUTTER WEB PWA — Sidebar :
┌──────────┬──────────────────────────────────┐
│ [Sc]     │                                  │
│ SCALARIO │   CONTENU PRINCIPAL              │
│ ──────── │                                  │
│ 🏠 Dash. │                                  │
│ 📊 Rapp. │                                  │
│ 📦 Stock │                                  │
│ 👥 Équipe│                                  │
│ 🚚 Fourn.│                                  │
│ ⚙ Params │                                  │
│ ──────── │                                  │
│ Blandine │                                  │
│ Déconn.  │                                  │
└──────────┴──────────────────────────────────┘

ADMIN — Sidebar :
┌──────────┬──────────────────────────────────┐
│ [Sc]     │                                  │
│ SC ADMIN │   CONTENU ADMIN                  │
│ ──────── │                                  │
│ Dashboard│                                  │
│ Tenants  │                                  │
│ Intégrat.│                                  │
│ Facturati│                                  │
│ Monitorin│                                  │
└──────────┴──────────────────────────────────┘
```

---

### TransactionList

| Surface | Comportement |
|---------|-------------|
| Mobile | Liste verticale full-width, tap → push navigation |
| Flutter Web | Liste à gauche, détail à droite (split view 40/60) |
| Admin | DataTable avec colonnes, tri, pagination |

```
MOBILE (liste push) :
┌──────────────────────────────────────────┐
│ Vente · 14:30              8 500 FCFA    │
│ _Tomates 2kg · Igname 5kg_  [● Actif] › │
└──────────────────────────────────────────┘

FLUTTER WEB (split view) :
┌────────────────────┬─────────────────────────┐
│ Vente · 14:30      │ DÉTAIL VENTE             │
│ 8 500 FCFA [● Actif│ ─────────────────────── │
├────────────────────┤ Tomates 2 kg   3 000 F  │
│ Vente · 12:15      │ Igname 5 kg    4 000 F  │
│ 6 200 FCFA [● Actif│ Poivrons 1 kg  1 500 F  │
├────────────────────┤ ─────────────────────── │
│ ...                │ TOTAL          8 500 F  │
│                    │ Mode: Espèces           │
└────────────────────┴─────────────────────────┘

ADMIN (DataTable) :
┌──────┬──────────────┬──────────────┬──────────┬──────────┐
│ Date │ Tenant       │ Montant      │ Statut   │ Actions  │
├──────┼──────────────┼──────────────┼──────────┼──────────┤
│ 09/05│ Épicerie Ami │ 12 500 FCFA  │ [● Actif]│ [Voir]   │
│ 08/05│ Marché Kofi  │  8 200 FCFA  │ [● Actif]│ [Voir]   │
└──────┴──────────────┴──────────────┴──────────┴──────────┘
```

---

### AlertBanner

| Surface | Comportement |
|---------|-------------|
| Mobile | Pleine largeur sous l'AppBar |
| Flutter Web | Pleine largeur sous le TopBar, au-dessus du contenu |
| Admin | Pleine largeur — ou en sidebar si alerte système globale |

Le style visuel est identique sur les 3 surfaces — seule la largeur change.

---

### FormWidget (pages de saisie)

| Surface | Comportement |
|---------|-------------|
| Mobile | Formulaire pleine largeur, scroll vertical |
| Flutter Web | Formulaire 2 colonnes max (640px max-width centré) |
| Admin | Formulaire 2-3 colonnes, panneau latéral ou modal |

```
MOBILE (1 colonne) :
  Prénom *
  ┌──────────────────────────────────────┐
  │ Ibrahim                              │
  └──────────────────────────────────────┘
  Téléphone *
  ┌──────────────────────────────────────┐
  │ +225 07 08 12 34                     │
  └──────────────────────────────────────┘

FLUTTER WEB (2 colonnes) :
  Prénom *                    Nom *
  ┌────────────────────┐      ┌────────────────────┐
  │ Ibrahim            │      │ Coulibaly          │
  └────────────────────┘      └────────────────────┘
  Téléphone *                 Rôle *
  ┌────────────────────┐      [● COMMERCIAL] [○ MANAGER]
  │ +225 07 08 12 34   │
  └────────────────────┘
```
