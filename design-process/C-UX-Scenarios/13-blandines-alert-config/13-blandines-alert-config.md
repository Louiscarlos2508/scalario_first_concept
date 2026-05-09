---
project: scalario
scenario: "13"
slug: 13-blandines-alert-config
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 13: Blandine's Alert Config

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine configure quelles alertes elle reçoit, à quels seuils et à quelle heure — pour que les notifications push soient pertinentes et non intrusives.

---

## Business Goal (Q2)

**Goal:** O1.1 — Alertes bien calibrées = Blandine revient + fait confiance au système
**Objective:** O2.2 — Alertes mal calibrées = spam = désactivation notifications = churn

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER — priorité #1)
**Situation:** Chez elle ou au magasin. Première config après déploiement Kofi, ou ajustement après avoir reçu des alertes non pertinentes.

---

## Driving Forces (Q4)

**Hope:** Recevoir uniquement les alertes qui comptent — au bon moment, sur les bons seuils.

**Worry:** Être noyée dans des notifications inutiles et désactiver les vraiment importantes.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA
**Entry:** Dashboard OWNER → Settings / Paramètres → "Mes alertes".

---

## Best Outcome (Q7)

**User Success:**
Alertes configurées selon ses priorités — stock critique à 5 kg, résumé soir à 19h, silence la nuit.

**Business Success:**
Push FCM pertinentes = taux ouverture élevé = canal engagement viable → O1.1 + O2.2.

---

## Shortest Path (Q8)

1. **Vue Alertes** — liste alertes disponibles avec statut actif/inactif (toggle)
2. **Config Alerte** — seuil déclencheur, heure d'envoi, canal (push immédiate / résumé / les deux)
3. **Confirmation Config** — récap alertes actives → sauvegardé ✓

---

## Trigger Map Connections

**Persona:** Blandine (OWNER — priorité #1)

**Driving Forces Addressed:**
- ✅ **Want:** "Alertes pertinentes au bon moment — pas de bruit"
- ❌ **Fear:** "Spam notifications → désactivation → manquer une vraie alerte" — résolu par config granulaire

**Business Goal:** O1.1 + O2.2 — Canal push = moteur d'engagement + rétention

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 13.1 | `13.1-vue-alertes/` | Liste alertes — activation / désactivation rapide | Tap alerte pour configurer |
| 13.2 | `13.2-config-alerte/` | Seuil + heure + canal pour une alerte | Tap "Sauvegarder" |
| 13.3 | `13.3-confirmation-config/` | Récap alertes actives | Config sauvegardée ✓ |
