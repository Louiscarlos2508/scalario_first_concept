---
project: scalario
scenario: "21"
slug: 21-commercials-dashboard
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 21: Commercial's Dashboard

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Le Commercial ouvre son dashboard — accès immédiat au POS, chiffre du jour, historique ventes récentes.

---

## Business Goal (Q2)

**Goal:** O1.1 — Dashboard Commercial utile = adoption POS = données ventes fiables
**Objective:** O2.2 — Dashboard lent ou complexe = contournement → ventes non enregistrées → données fausses

---

## User & Situation (Q3)

**Persona:** Commercial (rôle COMMERCIAL)
**Situation:** Au comptoir. Ouverture de session ou entre deux clients.

---

## Driving Forces (Q4)

**Hope:** Accéder au POS en 1 tap — pas de friction entre lui et la vente.

**Worry:** Perdre du temps avec l'app pendant qu'un client attend.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android
**Entry:** Biometric/PIN unlock → dashboard COMMERCIAL.

---

## Best Outcome (Q7)

**User Success:**
POS accessible en 1 tap, chiffre du jour visible, historique ventes sous la main.

**Business Success:**
Adoption POS = 100% ventes enregistrées → données fiables → O1.1.

---

## Shortest Path (Q8)

Vue unique — dashboard COMMERCIAL minimaliste, centré sur l'action.

---

## Trigger Map Connections

**Persona:** Commercial (rôle COMMERCIAL)

**Driving Forces Addressed:**
- ✅ **Want:** "POS en 1 tap, pas de friction"
- ❌ **Fear:** "Perdre du temps avec l'app" — résolu par dashboard ultra-épuré, ActionButton primaire impossible à rater

**Business Goal:** O1.1 — 100% ventes enregistrées = données fiables

---

## Scenario Steps

| Step | Dossier | Purpose |
|------|---------|---------|
| 21.1 | `21.1-dashboard-commercial/` | Vue complète dashboard COMMERCIAL — tous widgets définis |

## Liens Scénarios

- **S02** (Commercial's Quick Sale) — ActionButton "Nouvelle vente" → S02
- **S03** (Blandine-Commercial Caisse Close) — ActionButton "Clôture caisse" → S03
- **S14** (Commercial's Sale Return) — tap transaction → S14
- **S15** (Commercial's Credit Sale) — depuis POS mode paiement → S15
