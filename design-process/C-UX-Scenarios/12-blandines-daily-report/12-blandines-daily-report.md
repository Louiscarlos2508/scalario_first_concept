---
project: scalario
scenario: "12"
slug: 12-blandines-daily-report
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 12: Blandine's Daily Report

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine consulte ses rapports (CA, marge, pertes, stock) sur une période choisie pour prendre des décisions business éclairées.

---

## Business Goal (Q2)

**Goal:** O1.1 — Les rapports = raison de revenir chaque jour — usage quotidien
**Objective:** O2.3 — Fréquence ouverture app = leading indicator #1 — rapports = moteur d'engagement

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER — priorité #1)
**Situation:** En fin de journée ou le matin. Veut comprendre la performance de son business sur la semaine ou le mois — prendre des décisions (commander plus, changer un prix, alerter Ibrahim).

---

## Driving Forces (Q4)

**Hope:** Voir si son business va dans la bonne direction — CA en hausse, pertes sous contrôle, marges correctes.

**Worry:** Qu'une tendance négative soit en cours sans qu'elle le voie — CA qui baisse lentement, pertes qui s'accumulent.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA — rapports plus lisibles sur grand écran
**Entry:** Dashboard OWNER → navigation → "Rapports" → sélection période.

---

## Best Outcome (Q7)

**User Success:**
Voit clairement CA / marge / pertes sur la période en < 2 min — identifie tendance ou problème, peut agir.

**Business Success:**
Rapports utilisés régulièrement = Blandine engagée = O2.3 validé + preuve valeur Gate 0.

---

## Shortest Path (Q8)

1. **Vue Rapports** — sélecteur période (jour / semaine / mois), métriques clés chargées depuis Drift
2. **Rapport Période** — CA (courbe + total Roboto Mono), marge brute, top produits vendus, pertes accumulées, mouvements stock
3. **Drill-down Métrique** — tap sur un chiffre → détail (ex: pertes → liste déclarations de la période) ✓

---

## Trigger Map Connections

**Persona:** Blandine (OWNER — priorité #1)

**Driving Forces Addressed:**
- ✅ **Want:** "Voir l'état de son business — données claires, pas de calcul manuel"
- ❌ **Fear:** "Tendance négative non détectée" — résolu par visualisation période + drill-down

**Business Goal:** O1.1 + O2.3 — Rapports = moteur d'engagement quotidien + leading indicator Gate 0

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 12.1 | `12.1-vue-rapports/` | Sélection période + chargement métriques | Période sélectionnée |
| 12.2 | `12.2-rapport-periode/` | Vue complète : CA, marge, pertes, top produits | Tap métrique pour drill-down |
| 12.3 | `12.3-drilldown-metrique/` | Détail d'une métrique (liste transactions / pertes) | Compréhension atteinte ✓ |
