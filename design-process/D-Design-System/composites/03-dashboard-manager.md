---
type: composite
slug: dashboard-manager
components: [AlertBanner, KPICard, ActionButton, TransactionList, SyncStatusBar]
scenarios: [05, 06, 22]
---

# Composite — Dashboard MANAGER (Ibrahim)

> Orienté tâches terrain. Réceptions, pertes, inventaires.
> Règle : Si commande en attente → AlertBanner ambre en premier.

---

## Mobile Android — Réception en attente

```
┌──────────────────────────────────────────────┐
│ 📶 🔋                              07:50     │
├──────────────────────────────────────────────┤
│ ≡  OPÉRATIONS                                │
├──────────────────────────────────────────────┤
│ [⚠] Livraison FrutPro attendue aujourd'hui  │  AlertBanner ambre
│                              [Réceptionner] │
├──────────────────────────────────────────────┤
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ Réceptions   ║  ║ Stock crit.  ║           │
│ ║  en attente  ║  ║              ║           │
│ ║      1       ║  ║      2       ║           │
│ ║  _commandes_ ║  ║  _articles_  ║           │
│ ╚══════════════╝  ╚══════════════╝           │
│ ╔══════════════════════════════════╗         │
│ ║ Pertes déclarées — Aujourd'hui   ║         │
│ ║      0  déclarations             ║         │
│ ╚══════════════════════════════════╝         │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─        │
│ ┌──────────────────────────────────────────┐ │
│ │ ████ + Réceptionner livraison ███████████│ │  Primaire — réception en attente
│ └──────────────────────────────────────────┘ │
│ ┌──────────────┐  ┌───────────────────────┐  │
│ │ Déclarer     │  │      Inventaire        │  │  Secondaires — égaux
│ │ une perte    │  │                        │  │
│ └──────────────┘  └───────────────────────┘  │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─        │
│  Dernières opérations du jour                │
│ ┌──────────────────────────────────────────┐ │
│ │ Inventaire · 18:00 hier    Écart: −2 kg  │ │
│ │ _Tomates · Stock théo: 12kg réel: 10kg_  │ │
│ └──────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│  [●] Synchronisé — il y a 3 min              │
├──────────────────────────────────────────────┤
│ 🏠 Dashboard    📦 Stock    📋 Opérations    │
└──────────────────────────────────────────────┘
```

---

## Mobile Android — État Nominal (rien en attente)

```
├──────────────────────────────────────────────┤
│  (pas d'AlertBanner — état nominal)          │
├──────────────────────────────────────────────┤
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ Réceptions   ║  ║ Stock crit.  ║           │
│ ║  en attente  ║  ║              ║           │
│ ║      0       ║  ║      0       ║           │
│ ║  _[● OK]_    ║  ║  _[● OK]_    ║           │
│ ╚══════════════╝  ╚══════════════╝           │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─        │
│ ┌──────────┐  ┌──────────────┐  ┌──────────┐ │
│ │Réceptionner│ │ Déclarer    │  │Inventaire│ │  3 actions égales (aucune en attente)
│ │ livraison │ │  une perte  │  │          │ │
│ └──────────┘  └──────────────┘  └──────────┘ │
```
