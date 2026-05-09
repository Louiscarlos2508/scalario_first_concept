---
project: scalario
scenario: "19"
slug: 19-blandines-stock-history
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 19: Blandine's Stock History

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine consulte l'historique complet des mouvements de stock d'un article — ventes, livraisons, pertes, inventaires — pour comprendre et diagnostiquer une anomalie.

---

## Business Goal (Q2)

**Goal:** O1.1 — Traçabilité complète = Blandine peut diagnostiquer une anomalie sans dépendre d'Ibrahim
**Objective:** O2.2 — Si Blandine ne peut pas comprendre ses stocks, elle perd confiance → churn

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER — priorité #1)
**Situation:** Chez elle ou au magasin. Reçoit une alerte stock ou remarque une incohérence → veut retracer l'historique d'un article précis.

---

## Driving Forces (Q4)

**Hope:** Comprendre en 30 secondes ce qui s'est passé sur un article — sans appeler Ibrahim.

**Worry:** Découvrir des mouvements non justifiés — suggérant vol ou fraude.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA
**Entry:** Dashboard OWNER → section Stock → tap article → onglet "Historique" / ou depuis alerte stock critique → "Voir historique".

---

## Best Outcome (Q7)

**User Success:**
Blandine voit tous les mouvements, comprend l'anomalie, peut agir (déclarer, contacter Ibrahim, commander).

**Business Success:**
Transparence totale = confiance dans les données = O1.1.

---

## Shortest Path (Q8)

1. **Vue Stock** — liste articles avec stock actuel, alertes actives, filtre catégorie
2. **Historique Article** — tous mouvements d'un article (date, type, quantité, responsable)
3. **Détail Mouvement** — zoom sur un mouvement spécifique (inventaire avec écart, perte déclarée…)

---

## Trigger Map Connections

**Persona:** Blandine (OWNER — priorité #1)

**Driving Forces Addressed:**
- ✅ **Want:** "Comprendre l'historique d'un article en 30 secondes"
- ❌ **Fear:** "Mouvements non justifiés" — résolu par chaque mouvement horodaté + responsable nommé

**Business Goal:** O1.1 — Traçabilité = fondation de la confiance dans Scalario

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 19.1 | `19.1-vue-stock/` | Vue globale stock — articles, niveaux, alertes | Tap article |
| 19.2 | `19.2-historique-article/` | Tous mouvements d'un article — chronologique | Tap mouvement |
| 19.3 | `19.3-detail-mouvement/` | Zoom mouvement spécifique — contexte complet | Compréhension atteinte ✓ |

## Liens Scénarios

- **S18** (Ibrahim's Inventory Count) — inventaires apparaissent dans l'historique 19.2
- **S06** (Ibrahim's Loss Declaration) — pertes déclarées apparaissent dans l'historique 19.2
- **S05** (Ibrahim's Delivery Validation) — livraisons apparaissent dans l'historique 19.2
