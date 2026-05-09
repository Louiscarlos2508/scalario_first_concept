---
type: composite
slug: admin-dashboard
components: [KPICard, ChartWidget, AlertBanner, ActionButton]
scenarios: [A01, A02, A03, A04, A05]
surface: admin-scalario
---

# Composite — Admin Scalario (Flutter Web statique)

> Surface interne Scalario. Écrans hardcodés — pas de BDUI engine.
> Design system Scalario standard — adaptations densité desktop.

---

## A01 — Dashboard Admin

```
┌──────────────────────────────────────────────────────────────────┐
│ [Sc] SCALARIO ADMIN                [🔔 2]  Carlos Simporé ▾     │  TopBar h=64px
├──────────┬───────────────────────────────────────────────────────┤
│          │ [⚠] Erreurs sync sur 2 tenants       [Voir monitoring]│  AlertBanner ambre
│ Dashboard│───────────────────────────────────────────────────────│
│ Tenants  │ ╔══════════════╗ ╔══════════════╗ ╔══════════════╗   │
│ Intégrat.│ ║ Tenants act. ║ ║ MRR total    ║ ║ FCM delivery ║   │
│ Facturati│ ║     12       ║ ║ 480 000 F    ║ ║   97,3%      ║   │
│ Monitorin│ ║ +2 ce mois   ║ ║ +40k vs M-1  ║ ║ ↑ vs 95% M-1 ║   │
│          │ ╚══════════════╝ ╚══════════════╝ ╚══════════════╝   │
│ ──────── │ ╔══════════════╗                                      │
│ Carlos   │ ║ Erreurs sync ║                                      │
│ [Déconn] │ ║      2       ║  ← rouge                            │
│          │ ║ tenants      ║                                      │
│          │ ╚══════════════╝                                      │
│          │───────────────────────────────────────────────────────│
│          │ MRR — 12 derniers mois        Tenants — Croissance    │
│          │ ┌────────────────────────┐    ┌───────────────────┐   │
│          │ │    line chart MRR ↗    │    │   bar chart 📈    │   │
│          │ └────────────────────────┘    └───────────────────┘   │
│          │───────────────────────────────────────────────────────│
│          │ Alertes actives                                       │
│          │ [⚠] Sync échouée — Épicerie Aminata depuis 2h  [Voir]│
│          │ [⚠] Sync échouée — Marché Central depuis 3h    [Voir]│
└──────────┴───────────────────────────────────────────────────────┘
```

---

## A02 — Gestion Tenants

```
┌──────────────────────────────────────────────────────────────────┐
│ [Sc] SCALARIO ADMIN                                Carlos ▾      │
├──────────┬───────────────────────────────────────────────────────┤
│          │ Tenants                              [+ Nouveau client]│
│ Dashboard│───────────────────────────────────────────────────────│
│ Tenants ●│ 🔍 Rechercher un tenant...                            │
│ Intégrat.│ [● Actifs]  [○ Suspendu]  [○ Trial]  [○ Impayé]      │
│ Facturati│───────────────────────────────────────────────────────│
│ Monitorin│ Nom             Intégrateur  Template     MRR  Statut │
│          │ ─────────────── ──────────── ──────────── ──── ────── │
│          │ Épicerie Aminata Kofi M.     Retail Fresh 40k [● Actif]│
│          │                                          [Voir] [⋮]  │
│          │ ─────────────────────────────────────────────────────  │
│          │ Marché Central  Kofi M.     Retail Fresh 40k [● Actif]│
│          │                                          [Voir] [⋮]  │
│          │ ─────────────────────────────────────────────────────  │
│          │ Boutique Traoré Ama K.      Retail Fresh 40k [⚠ Trial]│
│          │                                          [Voir] [⋮]  │
│          │ ─────────────────────────────────────────────────────  │
│          │ Fruiterie Sud   Kofi M.     Retail Fresh 40k [✕ Impay]│
│          │                                          [Voir] [⋮]  │
└──────────┴───────────────────────────────────────────────────────┘

Vue Détail Tenant (panel droit ou page dédiée) :
┌──────────────────────────────────────────────────────────────────┐
│ ← Tenants  /  Épicerie Aminata                                   │
├──────────────────────────────────────────────────────────────────┤
│ ╔══════════════════╗  ╔══════════════════╗  ╔══════════════════╗ │
│ ║ MRR              ║  ║ Dernière sync    ║  ║ FCM 7j           ║ │
│ ║  40 000 FCFA     ║  ║  il y a 2h [⚠]  ║  ║   94,2%          ║ │
│ ╚══════════════════╝  ╚══════════════════╝  ╚══════════════════╝ │
│                                                                  │
│ Informations        Utilisateurs (3)       Actions               │
│ ─────────────────   ─────────────────────  ─────────────────────│
│ Template: Retail    Aminata (OWNER) ●       [  Accès lecture  ]  │
│ Intégr.: Kofi M.    Ibrahim (MANAGER) ●     [  Contacter Kofi ]  │
│ Actif depuis: 01/04 Kofi (COMMERCIAL) ●     [  Suspendre      ]  │
│ RCCM: CI-ABJ-2024   ──────────────────      ← rouge, confirm.   │
└──────────────────────────────────────────────────────────────────┘
```

---

## A03 — Gestion Intégrateurs

```
┌──────────────────────────────────────────────────────────────────┐
│ [Sc] SCALARIO ADMIN                                Carlos ▾      │
├──────────┬───────────────────────────────────────────────────────┤
│          │ Intégrateurs                    [+ Certifier nouveau] │
│ Dashboard│───────────────────────────────────────────────────────│
│ Tenants  │ Nom          Zone         Clients  MRR généré  Statut │
│ Intégrat.●│ ──────────── ──────────── ──────── ──────────  ────── │
│ Facturati│ Kofi Mensah  Abidjan-Sud  8        192 000F [● Certif]│
│ Monitorin│                                         [Voir] [⋮]   │
│          │ ──────────────────────────────────────────────────── │
│          │ Ama Konan    Abidjan-Nord  3         72 000F [● Certif]│
│          │                                         [Voir] [⋮]   │
│          │ ──────────────────────────────────────────────────── │
│          │ Moussa Diallo Bouaké       0              0F [↻ Attent]│
│          │                                  [Certifier] [✕ Refus]│
└──────────┴───────────────────────────────────────────────────────┘
```

---

## A04 — Facturation

```
┌──────────────────────────────────────────────────────────────────┐
│ [Sc] SCALARIO ADMIN                                Carlos ▾      │
├──────────┬───────────────────────────────────────────────────────┤
│          │ Facturation                                           │
│ Dashboard│───────────────────────────────────────────────────────│
│ Tenants  │ ╔════════════════╗ ╔════════════════╗ ╔═════════════╗ │
│ Intégrat.│ ║ MRR total      ║ ║ En retard      ║ ║ Impayés >30j║ │
│ Facturati●│ ║  480 000 FCFA  ║ ║    2 tenants   ║ ║   1 tenant  ║ │
│ Monitorin│ ║ +40k vs M-1    ║ ║  80 000 FCFA   ║ ║  40 000 F   ║ │
│          │ ╚════════════════╝ ╚════════════════╝ ╚═════════════╝ │
│          │───────────────────────────────────────────────────────│
│          │ Tenant           Plan     Montant    Statut    Prochain│
│          │ ──────────────── ──────── ──────── ─────────  ────────│
│          │ Épicerie Aminata Standard 40 000F  [● À jour]  01/06  │
│          │ Marché Central   Standard 40 000F  [⚠ Retard]  01/05* │
│          │                                    [Relancer]         │
│          │ Fruiterie Sud    Standard 40 000F  [✕ Impayé]  01/04* │
│          │                                    [Relancer] [Suspendre]│
└──────────┴───────────────────────────────────────────────────────┘
```

---

## A05 — Monitoring

```
┌──────────────────────────────────────────────────────────────────┐
│ [Sc] SCALARIO ADMIN                                Carlos ▾      │
├──────────┬───────────────────────────────────────────────────────┤
│          │ Monitoring                                            │
│ Dashboard│───────────────────────────────────────────────────────│
│ Tenants  │ ╔═══════════╗ ╔═══════════╗ ╔═══════════╗ ╔════════╗ │
│ Intégrat.│ ║ Sync OK   ║ ║ FCM deliv.║ ║ Erreurs   ║ ║ Uptime ║ │
│ Facturati│ ║  10/12    ║ ║  97,3%    ║ ║     2     ║ ║ 99,97% ║ │
│ Monitorin●│ ║ tenants   ║ ║ ↑ vs 95%  ║ ║ actives   ║ ║ 30j    ║ │
│          │ ╚═══════════╝ ╚═══════════╝ ╚═══════════╝ ╚════════╝ │
│          │───────────────────────────────────────────────────────│
│          │ [● Sync Drift] [○ FCM] [○ Auth] [○ API]  🔍 Recherche│
│          │───────────────────────────────────────────────────────│
│          │ [✕] ERREUR  Épicerie Aminata  Sync Drift  il y a 2h   │
│          │     _SyncException: timeout after 30s on queue flush_ │
│          │                              [Forcer resync] [Ignorer]│
│          │ ────────────────────────────────────────────────────  │
│          │ [✕] ERREUR  Marché Central    Sync Drift  il y a 3h   │
│          │     _SyncException: conflict detected on transaction_  │
│          │                              [Forcer resync] [Ignorer]│
│          │ ────────────────────────────────────────────────────  │
│          │ [i] INFO    Fruiterie Sud     FCM         il y a 5min  │
│          │     _FCM token expired — refreshed automatically_     │
└──────────┴───────────────────────────────────────────────────────┘
```
