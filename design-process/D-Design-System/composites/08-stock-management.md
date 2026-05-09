---
type: composite
slug: stock-management
components: [KPICard, AlertBanner, TextInput, NumberInput, QuantityControl, ChipSelector, FilterChips, PeriodSelector, TransactionList, StatusBadge, ProgressBar, ConfirmationDialog, ActionButton]
scenarios: [05, 06, 18, 19]
---

# Composite — Gestion des Stocks

> Tous les flows de mouvement de stock : livraisons, pertes, inventaire, historique.

---

## Validation Livraison Fournisseur (S05.2)

```
┌──────────────────────────────────────────────┐
│ ←  RÉCEPTION LIVRAISON                       │
├──────────────────────────────────────────────┤
│ ╔══════════════════════════════════════════╗ │
│ ║ Fournisseur : Mamadou Diallo              ║ │
│ ║ Bon de commande : CMD-2026-0091           ║ │
│ ║ Date : 09/05/2026 · 10h30                ║ │
│ ╚══════════════════════════════════════════╝ │
│                                              │
│ Articles reçus *                             │
│ ┌──────────────────────────────────────────┐ │
│ │ Tomates cerises                          │ │
│ │ Commandé: 20 kg   Reçu: [──18,5──] kg   │ │  ← NumberInput
│ │ Prix achat: 600 FCFA/kg  _[✓] Conforme_  │ │
│ ├──────────────────────────────────────────┤ │
│ │ Igname                                   │ │
│ │ Commandé: 50 kg   Reçu: [──50────] kg   │ │
│ │ Prix achat: 350 FCFA/kg  _[✓] Conforme_  │ │
│ ├──────────────────────────────────────────┤ │
│ │ Poivrons                                 │ │
│ │ Commandé: 5 kg    Reçu: [──3,5───] kg   │ │
│ │ Prix achat: 1200 FCFA/kg  _[⚠ Écart]_  │ │  ← ambre
│ └──────────────────────────────────────────┘ │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ ⚠ Écart de livraison détecté             │ │  ← AlertBanner ambre
│ │ Poivrons: commandé 5 kg, reçu 3,5 kg     │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ Note (optionnel)                             │
│ ┌──────────────────────────────────────────┐ │
│ │ Poivrons en mauvais état — 1,5 kg refusé │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ ████████ Valider la réception ███████████│ │
│ └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘

CONFIRMATION (S05.3) :
┌──────────────────────────────────────────────┐
│ ←  RÉCEPTION VALIDÉE                         │
├──────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────┐ │
│ │ ✓ Livraison enregistrée — stock mis à jour│ │  ← vert
│ └──────────────────────────────────────────┘ │
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ Reçu         ║  ║ Valeur stock ║           │
│ ║ 72 kg        ║  ║ +38 500 FCFA ║           │
│ ╚══════════════╝  ╚══════════════╝           │
│                                              │
│ ⚠ Écart signalé : Poivrons -1,5 kg          │
│ _Blandine a été notifiée_                    │
└──────────────────────────────────────────────┘
```

---

## Déclaration de Perte (S06.2)

```
┌──────────────────────────────────────────────┐
│ ←  DÉCLARER UNE PERTE                        │
├──────────────────────────────────────────────┤
│ Article *                                    │
│ [● Tomates]  [○ Igname]  [○ Poivrons]        │
│ 🔍 Rechercher un article...                  │
│                                              │
│ Quantité perdue *                            │
│ ┌──────────────────┐  ┌───────────────────┐  │
│ │  1,5             │  │ kg                │  │
│ └──────────────────┘  └───────────────────┘  │
│                                              │
│ Cause *                                      │
│ [● Périmé]  [○ Casse/chute]  [○ Vol]  [○ Autre]│
│                                              │
│ Note (optionnel)                             │
│ ┌──────────────────────────────────────────┐ │
│ │ Tomates trop mûres — invendables         │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ ╔══════════════════════════════════════════╗ │
│ ║ Impact estimé : 1 500 FCFA               ║ │
│ ║ (1,5 kg × 1 000 FCFA/kg prix achat)      ║ │
│ ╚══════════════════════════════════════════╝ │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ ████████████ Déclarer la perte ██████████│ │
│ └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘

CONFIRMATION (dialogue gardien) :
╔══════════════════════════════════════════╗
║  Confirmer la déclaration de perte ?     ║
║                                          ║
║  Article : Tomates                       ║
║  Quantité : 1,5 kg                       ║
║  Impact : 1 500 FCFA                     ║
║  Déclarant : Ibrahim Coulibaly           ║
║  ────────────────────────────────        ║
║  Cette action ne peut pas être annulée.  ║
║                                          ║
║  [Annuler]     [Confirmer la perte]      ║
╚══════════════════════════════════════════╝
```

---

## Inventaire — Saisie Quantités (S18.2)

```
┌──────────────────────────────────────────────┐
│ ←  INVENTAIRE — LÉGUMES                      │
├──────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────┐ │
│ │ [████████████████░░░░░░░░]  4 / 8 items  │ │  ← ProgressBar
│ └──────────────────────────────────────────┘ │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ Tomates cerises                          │ │
│ │ Stock système : 12,5 kg                  │ │
│ │ Compté réel : [──11,0──] kg   [✓]        │ │  ← saisi, validé
│ │ Écart : -1,5 kg  [ambre]                 │ │
│ ├──────────────────────────────────────────┤ │
│ │ Igname                                   │ │
│ │ Stock système : 45 kg                    │ │
│ │ Compté réel : [──45────] kg   [✓]        │ │  ← conforme
│ │ Écart : 0 kg  [vert]                     │ │
│ ├──────────────────────────────────────────┤ │
│ │ Poivrons                                 │ │
│ │ Stock système : 3,5 kg                   │ │
│ │ Compté réel : [__________] kg  ← à saisir│ │
│ ├──────────────────────────────────────────┤ │
│ │ Oignons                                  │ │
│ │ Stock système : 18 kg                    │ │
│ │ Compté réel : [__________] kg  ← à saisir│ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ ███████ Valider l'inventaire ████████████│ │  ← actif quand tout saisi
│ └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘

CONFIRMATION (S18.3) :
┌──────────────────────────────────────────────┐
│ RÉCAP INVENTAIRE — LÉGUMES — 09/05/2026      │
├──────────────────────────────────────────────┤
│ ╔══════════════╗  ╔══════════════╗           │
│ ║ Articles     ║  ║ Écarts       ║           │
│ ║   8          ║  ║ 2 articles   ║           │
│ ╚══════════════╝  ╚══════════════╝           │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ Tomates    Syst:12,5  Réel:11,0  -1,5kg  │ │  ← ambre
│ │ Poivrons   Syst: 3,5  Réel: 4,0  +0,5kg  │ │  ← vert (excédent)
│ └──────────────────────────────────────────┘ │
│                                              │
│ _Blandine a été notifiée des écarts_         │
│ ┌──────────────────────────────────────────┐ │
│ │ ████████████████ Terminer ███████████████│ │
│ └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

---

## Historique Stock & Détail Mouvement (S19.1–S19.3)

```
VUE STOCK (S19.1) :
┌──────────────────────────────────────────────┐
│ ←  STOCK ACTUEL                              │
├──────────────────────────────────────────────┤
│ 🔍 Rechercher un article...                  │
│ [Tous ●]  [Critique ○]  [OK ○]               │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ Tomates       11,0 kg  [⚠ Critique]   ›  │ │  ← sous le seuil
│ │ Igname        45,0 kg  [✓ OK]          ›  │ │
│ │ Poivrons       4,0 kg  [✓ OK]          ›  │ │
│ │ Oignons       18,0 kg  [✓ OK]          ›  │ │
│ │ Bananes        8,4 kg  [⚠ Critique]   ›  │ │
│ └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘

HISTORIQUE ARTICLE (S19.2) :
┌──────────────────────────────────────────────┐
│ ←  TOMATES CERISES                           │
├──────────────────────────────────────────────┤
│ ╔══════════════════════════════════════════╗ │
│ ║ Stock actuel : 11,0 kg  [⚠ Critique]    ║ │
│ ║ Seuil alerte : 5 kg · Fraîcheur : 3j    ║ │
│ ╚══════════════════════════════════════════╝ │
│                                              │
│ [Aujourd'hui ●]  [Semaine ○]  [Mois ○]       │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ [↑] Livraison   +18,5 kg   10h30   Kofi ›│ │  ← vert
│ │ [↓] Vente        -2,5 kg   08h43   Kofi ›│ │  ← gris
│ │ [↓] Vente        -1,0 kg   09h15   Kofi ›│ │
│ │ [✕] Perte        -1,5 kg   11h20  Ibrahim›│ │  ← rouge
│ │ [↑] Stock init  +10,0 kg   08h00        ›│ │
│ └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘

DÉTAIL MOUVEMENT (S19.3) :
┌──────────────────────────────────────────────┐
│ ←  DÉTAIL MOUVEMENT                          │
├──────────────────────────────────────────────┤
│ ╔══════════════════════════════════════════╗ │
│ ║ [✕] Perte déclarée                       ║ │
│ ║ Tomates cerises · -1,5 kg                ║ │
│ ║ 09/05/2026 · 11h20                       ║ │
│ ╚══════════════════════════════════════════╝ │
│                                              │
│ Déclarant   Ibrahim Coulibaly                │
│ Cause       Périmé                           │
│ Note        Tomates trop mûres — invendables │
│ Impact      1 500 FCFA (prix achat)          │
│ Statut      ✓ Validé par Blandine            │
│                                              │
└──────────────────────────────────────────────┘
```
