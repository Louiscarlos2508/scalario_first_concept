---
project: scalario
scenario: "04"
slug: 04-blandines-alert-response
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 04: Blandine's Alert Response

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine reçoit une alerte critique sur son téléphone, ouvre l'app, comprend immédiatement le contexte et agit — sans chercher, sans naviguer.

---

## Business Goal (Q2)

**Goal:** O1.1 — Push FCM = canal engagement hors app (usage prouvé au-delà de l'ouverture volontaire)
**Objective:** O2.2 — Churn <3% — si Blandine rate une alerte critique, elle perd confiance dans le système

---

## User & Situation (Q3)

**Persona:** Blandine (Primary — priorité #1)
**Situation:** Hors du magasin — domicile, transport, marché. Reçoit une notification push inattendue. Peut être en train de faire autre chose.

---

## Driving Forces (Q4)

**Hope:** Comprendre immédiatement ce qui se passe et reprendre le contrôle — même à distance.

**Worry:** Quelque chose de grave est arrivé (vol, stock disparu) et elle est trop loin pour agir à temps.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android mid-range — contexte variable, hors magasin
**Entry:** Push FCM reçue "⚠️ Stock critique : Tomates — 2 kg restants" → tap notification → app ouverte directement sur la vue alerte, zéro navigation intermédiaire.

---

## Best Outcome (Q7)

**User Success:**
En < 30 sec, Blandine voit le contexte complet (quel article, quelle quantité, seuil dépassé) et peut déléguer une action au Manager.

**Business Success:**
Push FCM capte l'attention hors app → prouve la valeur du canal notification → renforce l'usage quotidien O1.1.

---

## Shortest Path (Q8)

1. **Push Notification FCM** — Notification OS avec résumé clair, tap → deep link direct dans l'app
2. **Dashboard OWNER — Vue Alerte** — `AlertBanner` critique (rouge) en haut, `KPICard` contexte (article, quantité, seuil), `ActionButton` "Notifier le Manager"
3. **Confirmation Action** — Tap → Ibrahim reçoit push, `AlertBanner` vert "Manager notifié" ✓

---

## Trigger Map Connections

**Persona:** Blandine (Primary — priorité #1)

**Driving Forces Addressed:**
- ✅ **Want:** "Voir et comprendre les anomalies immédiatement" — deep link direct, zéro navigation
- ❌ **Fear:** "Stock disparu sans qu'elle le sache" (score 15) — résolu par push proactive + contexte complet

**Business Goal:** O1.1 + O2.2 — Canal push = engagement hors app + confiance système = rétention

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 04.1 | `04.1-push-notification-fcm/` | Notification OS reçue — format clair, deep link | Tap notification |
| 04.2 | `04.2-dashboard-owner-vue-alerte/` | Vue alerte avec contexte complet | Tap "Notifier le Manager" |
| 04.3 | `04.3-confirmation-action/` | Confirmation délégation → Manager notifié | Alerte traitée ✓ |
