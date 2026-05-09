---
project: scalario
scenario: "20"
slug: 20-blandines-owner-dashboard
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 20: Blandine's Owner Dashboard

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine ouvre son dashboard OWNER — vue complète de la journée : CA, alertes actives, stock critique, ventes en cours, résumé équipe — tout en un coup d'œil.

---

## Business Goal (Q2)

**Goal:** O1.1 — Dashboard pertinent = Blandine revient chaque matin → habitude = rétention
**Objective:** O2.2 — Dashboard surchargé ou vide = désengagement → churn

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER — priorité #1)
**Situation:** Chez elle le matin ou au magasin en journée. Check quotidien — entre 2 et 5 minutes max.

---

## Driving Forces (Q4)

**Hope:** Savoir en 30 secondes si tout va bien — ou où concentrer son attention.

**Worry:** Rater une alerte importante noyée dans trop d'infos.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA
**Entry:** Biometric/PIN unlock → dashboard OWNER (depuis S01).

---

## Best Outcome (Q7)

**User Success:**
Blandine comprend la situation de son magasin en 30 secondes. Aucune info critique manquée.

**Business Success:**
Session quotidienne confirmée → engagement élevé → O1.1.

---

## Shortest Path (Q8)

Vue unique — dashboard OWNER complet. Toutes les infos critiques above the fold sur mobile, layout étendu sur Flutter Web PWA.

---

## Trigger Map Connections

**Persona:** Blandine (OWNER — priorité #1)

**Driving Forces Addressed:**
- ✅ **Want:** "Situation du magasin en 30 secondes"
- ❌ **Fear:** "Info critique noyée" — résolu par hiérarchie visuelle : AlertBanner en premier si alerte active, KPIs ensuite

**Business Goal:** O1.1 — Session quotidienne = métrique d'engagement #1

---

## Scenario Steps

| Step | Dossier | Purpose |
|------|---------|---------|
| 20.1 | `20.1-dashboard-owner/` | Vue complète dashboard OWNER — tous widgets définis |

## Liens Scénarios

- **S01** (Blandine's Morning Read) — entrée vers ce dashboard
- **S04** (Blandine's Alert Response) — tap AlertBanner → S04
- **S12** (Blandine's Daily Report) — ActionButton "Rapports" → S12
- **S19** (Blandine's Stock History) — ActionButton "Stock" → S19
- **S10** (Blandine's Team Management) — ActionButton "Équipe" → S10
- **S13** (Blandine's Alert Config) — Settings → "Mes alertes" → S13
