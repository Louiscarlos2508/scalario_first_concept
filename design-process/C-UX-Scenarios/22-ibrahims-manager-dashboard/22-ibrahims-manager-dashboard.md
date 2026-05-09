---
project: scalario
scenario: "22"
slug: 22-ibrahims-manager-dashboard
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 22: Ibrahim's Manager Dashboard

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Ibrahim ouvre son dashboard MANAGER — vue opérationnelle terrain : stock actuel, réceptions en attente, pertes du jour, accès rapide aux actions.

---

## Business Goal (Q2)

**Goal:** O1.1 — Ibrahim bien équipé = opérations terrain fiables = données stock justes = Blandine satisfaite
**Objective:** O2.2 — Dashboard MANAGER sans infos terrain = Ibrahim désengagé → stock non géré → alertes fausses → churn

---

## User & Situation (Q3)

**Persona:** Ibrahim (MANAGER — priorité #3)
**Situation:** Au magasin. Début de journée ou entre deux opérations terrain.

---

## Driving Forces (Q4)

**Hope:** Voir d'un coup d'œil ce qu'il doit faire aujourd'hui — pas de surprise.

**Worry:** Oublier une réception attendue ou manquer une anomalie que Blandine va lui reprocher.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android
**Entry:** Biometric/PIN unlock → dashboard MANAGER.

---

## Best Outcome (Q7)

**User Success:**
Ibrahim voit ses tâches du jour, agit efficacement, rien n'est oublié.

**Business Success:**
Opérations terrain tracées = stock fiable = Blandine confiante → O1.1.

---

## Shortest Path (Q8)

Vue unique — dashboard MANAGER orienté tâches terrain.

---

## Trigger Map Connections

**Persona:** Ibrahim (MANAGER — priorité #3)

**Driving Forces Addressed:**
- ✅ **Want:** "Voir mes tâches du jour en un coup d'œil"
- ❌ **Fear:** "Oublier une réception" — résolu par AlertBanner commande en attente + KPICard réceptions

**Business Goal:** O1.1 — Opérations terrain tracées = fondation données stock

---

## Scenario Steps

| Step | Dossier | Purpose |
|------|---------|---------|
| 22.1 | `22.1-dashboard-manager/` | Vue complète dashboard MANAGER — tous widgets définis |

## Liens Scénarios

- **S05** (Ibrahim's Delivery Validation) — ActionButton "Réceptionner livraison"
- **S06** (Ibrahim's Loss Declaration) — ActionButton "Déclarer une perte"
- **S18** (Ibrahim's Inventory Count) — ActionButton "Inventaire"
- **S16** (Blandine's Supplier Order) — commandes en attente apparaissent dans AlertBanner
