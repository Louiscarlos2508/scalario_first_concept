---
project: scalario
scenario: "18"
slug: 18-ibrahims-inventory-count
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 18: Ibrahim's Inventory Count

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Ibrahim fait un inventaire physique partiel ou complet — saisit les quantités réelles — le système détecte les écarts avec le stock théorique Drift.

---

## Business Goal (Q2)

**Goal:** O1.1 — Stock théorique vs réel aligné = chiffres fiables = Blandine fait confiance aux alertes
**Objective:** O2.2 — Sans inventaire, pertes non déclarées s'accumulent → stock théorique faux → alertes inutiles → désactivation → churn

---

## User & Situation (Q3)

**Persona:** Ibrahim (MANAGER — priorité #3)
**Situation:** Au magasin. Fin de journée ou hebdomadaire. Comptage physique produit par produit.

---

## Driving Forces (Q4)

**Hope:** Clôturer l'inventaire vite et proprement — confirmer que le stock est sous contrôle.

**Worry:** Trouver des écarts importants non explicables — devoir les justifier à Blandine.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android
**Entry:** Dashboard MANAGER → ActionButton "Inventaire" ou section dédiée inventaire.

---

## Best Outcome (Q7)

**User Success:**
Inventaire enregistré, écarts documentés, Ibrahim a une trace propre.

**Business Success:**
Stock réel = stock Drift → alertes fiables → O1.1.

---

## Shortest Path (Q8)

1. **Sélection Périmètre** — inventaire complet ou par catégorie
2. **Saisie Quantités** — liste articles, quantité réelle, écart calculé temps réel
3. **Confirmation Inventaire** — stock Drift mis à jour, écarts notifiés Blandine, rapport créé

---

## Trigger Map Connections

**Persona:** Ibrahim (MANAGER — priorité #3)

**Driving Forces Addressed:**
- ✅ **Want:** "Inventaire vite et proprement — stock sous contrôle"
- ❌ **Fear:** "Écarts inexplicables" — résolu par écarts visibles avec historique (pertes déclarées S06 déduites)

**Business Goal:** O1.1 — Alignement stock théorique/réel = fondation de la fiabilité Scalario

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 18.1 | `18.1-selection-perimetre/` | Périmètre inventaire : complet ou par catégorie | Tap "Commencer l'inventaire" |
| 18.2 | `18.2-saisie-quantites/` | Saisie quantités réelles + écarts temps réel | Tap "Valider l'inventaire" |
| 18.3 | `18.3-confirmation-inventaire/` | Stock Drift mis à jour, Blandine notifiée, rapport créé | Inventaire enregistré ✓ |

## Liens Scénarios

- **S06** (Ibrahim's Loss Declaration) — pertes déclarées déduites du stock avant calcul écart
- **S19** (Blandine's Stock History) — Blandine consulte l'historique des inventaires
