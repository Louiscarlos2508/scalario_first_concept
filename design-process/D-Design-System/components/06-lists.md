---
type: components
group: lists
components: [EmployeeList, SupplierList, ProductPriceList, AlertConfigList]
---

# Composants — Listes Métier

> Ces listes affichent des entités configurées (employés, fournisseurs, produits, alertes).
> Le contenu vient toujours de Drift / backend — jamais hardcodé.

---

## EmployeeList

**Rôle :** Liste des employés du tenant avec leur statut et accès rapide aux actions.
**Usage :** S10 (Team Management).

### Props

| Prop | Type | Description |
|------|------|-------------|
| `employees` | list | `{name, role, department, status, last_login}` |
| `actions` | list | Actions disponibles par ligne |

### Sketch ASCII

```
┌──────────────────────────────────────────────┐
│ 🔍 Rechercher un employé...                  │
├──────────────────────────────────────────────┤
│ [● Actifs]  [○ Inactifs]  [○ Tous]          │
├──────────────────────────────────────────────┤
│ Kofi Mensah              [● COMMERCIAL]      │
│ _Dernière connexion : aujourd'hui 09:12_     │
│                                    [⋮ Menu] │
├──────────────────────────────────────────────┤
│ Aminata Diallo           [● COMMERCIAL]      │
│ _Dernière connexion : hier 14:30_            │
│                                    [⋮ Menu] │
├──────────────────────────────────────────────┤
│ Ibrahim Coulibaly        [● MANAGER]         │
│ _Dernière connexion : aujourd'hui 07:45_     │
│                                    [⋮ Menu] │
├──────────────────────────────────────────────┤
│ Jean-Paul Traoré         [○ COMMERCIAL]      │
│ _Désactivé le 03/05_                         │
│                                    [⋮ Menu] │
└──────────────────────────────────────────────┘

Menu contextuel [⋮] :
  ┌──────────────────────┐
  │ Modifier             │
  │ Réinitialiser MDP    │
  │ ────────────────     │
  │ Désactiver           │  ← rouge
  └──────────────────────┘
```

---

## SupplierList

**Rôle :** Liste des fournisseurs configurés avec leurs articles associés.
**Usage :** S11 (Supplier Setup), S16 (Supplier Order).

### Sketch ASCII

```
┌──────────────────────────────────────────────┐
│ 🔍 Rechercher un fournisseur...              │
├──────────────────────────────────────────────┤
│ FrutPro                            [● Actif] │
│ _Tomates · Igname · Poivrons_                │
│ _Dernier achat : 05/05 · 45 000 FCFA_    ›  │
├──────────────────────────────────────────────┤
│ AgriSud Korhogo                    [● Actif] │
│ _Oignons · Ail · Gingembre_                  │
│ _Dernier achat : 02/05 · 28 000 FCFA_    ›  │
├──────────────────────────────────────────────┤
│ Marché Central                     [● Actif] │
│ _Bananes · Papayes · Mangues_                │
│ _Dernier achat : 28/04 · 15 500 FCFA_    ›  │
└──────────────────────────────────────────────┘
```

---

## ProductPriceList

**Rôle :** Liste des articles d'un fournisseur avec leurs prix d'achat et marges calculées.
**Usage :** S11 (config fournisseur), S16 (commande).
**Règle :** Si prix achat > prix vente → badge rouge "Marge négative".

### Sketch ASCII

```
Articles — FrutPro
┌──────────────────────────────────────────────┐
│ Tomates                                      │
│  Prix vente : 1 500 FCFA/kg                  │
│  Prix achat : ┌──────────────────┐  ┌──────┐│
│               │ 900              │  │FCFA/kg││
│               └──────────────────┘  └──────┘│
│  Marge : 40% ↑  [● OK]                       │
├──────────────────────────────────────────────┤
│ Igname                                       │
│  Prix vente : 800 FCFA/kg                    │
│  Prix achat : ┌──────────────────┐  ┌──────┐│
│               │ 500              │  │FCFA/kg││
│               └──────────────────┘  └──────┘│
│  Marge : 37% ↑  [● OK]                       │
├──────────────────────────────────────────────┤
│ Poivrons                                     │
│  Prix vente : 2 000 FCFA/kg                  │
│  Prix achat : ┌──────────────────┐  ┌──────┐│
│               │ 2100             │  │FCFA/kg││
│               └──────────────────┘  └──────┘│
│  [✕] Marge négative — prix achat > prix vente│
└──────────────────────────────────────────────┘
```

---

## AlertConfigList

**Rôle :** Liste des alertes disponibles dans le template JSON avec leur statut et config actuelle.
**Usage :** S13 (Alert Config).
**Source :** Template JSON — les alertes disponibles sont définies par le template, pas hardcodées.

### Sketch ASCII

```
Mes alertes
┌──────────────────────────────────────────────┐
│ Stock critique                    [●────]    │
│ _Seuil: 5 kg · Push immédiate_           ›  │
├──────────────────────────────────────────────┤
│ Clôture non faite                 [●────]    │
│ _Si pas de clôture avant 21:00_          ›  │
├──────────────────────────────────────────────┤
│ Livraison avec écarts             [●────]    │
│ _Écart > 10% — Push immédiate_           ›  │
├──────────────────────────────────────────────┤
│ Résumé soir                       [●────]    │
│ _Envoyé à 19:00 · Résumé uniquement_     ›  │
├──────────────────────────────────────────────┤
│ Perte déclarée                    [────○]    │
│ _Désactivé_                              ›  │
└──────────────────────────────────────────────┘
_Tap sur une alerte pour configurer en détail_

LIGNE DÉTAIL (toggle + config visible) :
│ Stock critique                    [●────]    │
│ _Seuil: 5 kg · Push immédiate · Silence: 22h-7h_ ›│
```
