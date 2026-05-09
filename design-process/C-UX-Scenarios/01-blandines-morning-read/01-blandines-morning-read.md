---
project: scalario
scenario: "01"
slug: 01-blandines-morning-read
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 01: Blandine's Morning Read

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine vérifie l'état de son business en moins de 30 secondes — CA, stock, alertes — sans ouvrir aucun menu.

---

## Business Goal (Q2)

**Goal:** O1.1 — Blandine utilise l'app quotidiennement (Gate 0 = 8 juillet 2026)
**Objective:** O2.3 — Fréquence ouverture app Blandine = quotidien (leading indicator #1)

---

## User & Situation (Q3)

**Persona:** Blandine (Primary — priorité #1)
**Situation:** Commerçante fruits et légumes, Ouagadougou. 7h du matin, au marché ou devant son magasin avant l'ouverture. Téléphone en main, connexion 4G variable, plein air.

---

## Driving Forces (Q4)

**Hope:** Voir en un coup d'œil que tout va bien — ouvrir la journée sereinement.

**Worry:** Découvrir une anomalie qu'elle aurait pu voir plus tôt — stock disparu, caisse incohérente.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android mid-range (Tecno/Infinix, Snapdragon 680, 4GB RAM) — dark mode — usage plein air
**Entry:** Blandine ouvre l'app depuis l'icône → unlock rapide (fingerprint / Face ID / PIN selon appareil + config tenant) → dashboard immédiat. Action volontaire quotidienne — pas de re-saisie credentials.

---

## Best Outcome (Q7)

**User Success:**
En moins de 30 secondes, Blandine voit CA nominal, stock ok, zéro alerte — journée ouverte sereinement.

**Business Success:**
Ouverture app quotidienne enregistrée → leading indicator O2.3 validé → Gate 0 atteint.

---

## Shortest Path (Q8)

1. **App Init** — Splash 2 sec, Drift local chargé immédiatement (offline-first), Dashboard OWNER s'affiche avec données J-1 sans attendre le réseau
2. **Dashboard OWNER — Morning Scan** — `KPICard` CA (nominal), `KPICard` Stock (nominal), `SyncStatusBar` (synced), `AlertBanner` absent → certitude visuelle complète, journée ouverte ✓

---

## Trigger Map Connections

**Persona:** Blandine (Primary — priorité #1)

**Driving Forces Addressed:**
- ✅ **Want:** "Voir l'état de son business en moins de 30 secondes" (score F×I×Fit = 15)
- ❌ **Fear:** "Stock ou caisse anormale détectée trop tard" — résolu par données immédiates offline-first

**Business Goal:** O1.1 + O2.3 — Usage quotidien = Gate 0 validé

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 01.1 | `01.1-app-init/` | App se lance, données locales chargées immédiatement | Dashboard OWNER apparaît |
| 01.2 | `01.2-dashboard-owner-morning-scan/` | Blandine scanne KPIs + confirme état nominal | Ferme app ou navigue — scénario succès ✓ |
