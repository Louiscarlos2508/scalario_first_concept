---
type: composite
slug: dashboard-commercial
components: [ActionButton, KPICard, TransactionList, SyncStatusBar]
scenarios: [02, 21]
---

# Composite — Dashboard COMMERCIAL

> Ultra-épuré. Un seul objectif : POS en 1 tap.
> Règle : "Nouvelle vente" impossible à rater, above fold sur tout écran Android.

---

## Mobile Android — État Standard

```
┌──────────────────────────────────────────────┐
│ 📶 🔋                              09:45     │
├──────────────────────────────────────────────┤
│ ≡  CAISSE                                    │  AppBar
├──────────────────────────────────────────────┤
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ ████████████ + Nouvelle vente ███████████│ │  ActionButton primaire
│ └──────────────────────────────────────────┘ │  h=56px — impossible à rater
│                                              │
│ ╔══════════════════╗  ╔══════════════════╗   │
│ ║ Mon CA du jour   ║  ║ Mes ventes       ║   │
│ ║   34 500 FCFA    ║  ║      14          ║   │
│ ║   _+3 vs hier_   ║  ║   _transactions_ ║   │
│ ╚══════════════════╝  ╚══════════════════╝   │
│                                              │
│  ─────── Mes ventes du jour ───────         │
│ ┌──────────────────────────────────────────┐ │
│ │ Vente · 09:31               8 500 FCFA   │ │
│ │ _Tomates 2kg · Igname 5kg_    [● Actif]  │ │
│ ├──────────────────────────────────────────┤ │
│ │ Vente · 09:12               4 000 FCFA   │ │
│ │ _Poivrons 2kg_                [● Actif]  │ │
│ ├──────────────────────────────────────────┤ │
│ │ ~~Vente · 08:55~~          ~~6 500 FCFA~~│ │
│ │ _Erreur saisie_               [✕ Annulé] │ │
│ ├──────────────────────────────────────────┤ │
│ │ Vente · 08:30               8 200 FCFA   │ │
│ │ _Oignons 3kg · Ail 500g_      [● Actif]  │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │         Clôture caisse                   │ │  Secondaire — moins proéminent
│ └──────────────────────────────────────────┘ │
│                                              │
├──────────────────────────────────────────────┤
│  [●] Synchronisé — il y a 1 min              │  SyncStatusBar
├──────────────────────────────────────────────┤
│ 🏠 Dashboard         📋 Historique           │  Bottom nav simplifié
└──────────────────────────────────────────────┘
```

---

## Mobile Android — État Offline

```
├──────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────┐ │
│ │ ████████████ + Nouvelle vente ███████████│ │  ← même apparence offline
│ └──────────────────────────────────────────┘ │
│  (fonctionne depuis Drift — transparent)      │
├──────────────────────────────────────────────┤
│  [○] Hors ligne — données locales à jour     │  SyncStatusBar ambre discret
└──────────────────────────────────────────────┘
```
