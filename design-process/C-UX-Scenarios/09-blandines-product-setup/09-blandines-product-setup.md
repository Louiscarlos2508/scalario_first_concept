---
project: scalario
scenario: "09"
slug: 09-blandines-product-setup
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 09: Blandine's Product Setup

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine configure un produit dans son catalogue — nom, unité de vente, pos_type, prix, fraîcheur, taux de perte, seuil alerte — pour que le Commercial puisse vendre correctement et que les alertes fonctionnent.

---

## Business Goal (Q2)

**Goal:** O1.1 — Système inutilisable sans catalogue produits configuré — prérequis absolu Gate 0
**Objective:** O2.1 — Template `retail_fresh_produce.json` validé = catalogue opérationnel dès J+1

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER — priorité #1)
**Situation:** Au magasin ou chez elle. Nouveau produit à ajouter, prix de saison à modifier, ou paramètres fraîcheur/taux de perte à ajuster selon l'arrivage.

---

## Driving Forces (Q4)

**Hope:** Que le Commercial vende ce produit correctement dès aujourd'hui — bon prix, bonne unité, bon type POS.

**Worry:** Que le Commercial fasse une erreur de prix ou de calcul parce que le produit est mal configuré — perte financière invisible.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android mid-range OU Flutter Web PWA (ordinateur) — config catalogue plus confortable sur grand écran
**Entry:** Dashboard OWNER → navigation → "Catalogue" → liste produits → tap `ActionButton` "Ajouter un produit" (ou tap produit existant pour éditer).

---

## Best Outcome (Q7)

**User Success:**
Produit configuré en < 3 min — Commercial voit le produit dans le POS avec le bon rendu (vrac → saisie poids, unité → saisie quantité), alertes stock actives, taux de perte intégré.

**Business Success:**
Catalogue à jour = ventes fiables = template prouvé terrain → O2.1 + intégrité données O1.1.

---

## Shortest Path (Q8)

1. **Catalogue Produits** — liste produits depuis Drift, `ActionButton` "Ajouter un produit" visible
2. **FormWidget Produit** — nom, catégorie, `pos_type` (vrac / unité / service / autre), unité de vente (kg / pièce / botte / sac / caisse), prix unitaire, durée fraîcheur (jours), taux de perte attendu (%), seuil alerte stock minimum
3. **Confirmation Produit** — récap paramètres, tap "Enregistrer" → produit disponible dans le POS Commercial avec le rendu adapté au `pos_type` ✓

---

## Trigger Map Connections

**Persona:** Blandine (OWNER — priorité #1)

**Driving Forces Addressed:**
- ✅ **Want:** "Contrôle total sur son catalogue — prix justes, unités correctes"
- ❌ **Fear:** "Erreur de calcul invisible — perte financière non détectée" — résolu par config explicite + récap avant enregistrement

**Business Goal:** O1.1 + O2.1 — Catalogue opérationnel = système utilisable = Gate 0

---

## Architecture Note — POS Types

Le `pos_type` est configuré **par produit** dans le JSON — pas globalement par tenant. Le BDUI Engine adapte le rendu du POS selon ce champ :

| pos_type | Rendu POS Commercial | Calcul prix |
|----------|---------------------|-------------|
| `vrac` | Saisie poids (kg/g) — balance ou manuel | Poids × prix unitaire/kg |
| `unit` | Saisie quantité entière | Quantité × prix unitaire |
| `service` | Sélection forfait/durée | Prix forfait fixe |
| `mixed` | Articles + modifiers | Somme composants |

Un même magasin peut avoir des produits avec des `pos_type` différents (tomates = `vrac`, sachets = `unit`).

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 09.1 | `09.1-catalogue-produits/` | Vue catalogue — liste produits existants | Tap "Ajouter un produit" |
| 09.2 | `09.2-form-produit/` | Saisie paramètres produit dont pos_type | Tap "Enregistrer" |
| 09.3 | `09.3-confirmation-produit/` | Récap + validation → produit actif dans le POS | Produit disponible ✓ |
