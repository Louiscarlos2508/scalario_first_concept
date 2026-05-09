---
project: scalario
scenario: "26"
slug: 26-ouverture-caisse
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 26: Ouverture de Caisse (Fond de Caisse)

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Le Commercial (ou Blandine) ouvre la session de caisse en début de journée — il déclare le fond de caisse (montant cash initial en caisse) avant la première vente. Blandine reçoit une notification de confirmation d'ouverture.

---

## Business Goal (Q2)

**Goal:** O1.1 — Traçabilité comptable complète du flux cash journalier
**Objective:** Chaque session caisse a un fond de caisse déclaré → réconciliation propre à la fermeture (S03)

---

## User & Situation (Q3)

**Persona principal:** Le Commercial (rôle COMMERCIAL)
**Persona secondaire:** Blandine reçoit la notification d'ouverture
**Situation:** Matin, avant la première vente. Le Commercial arrive, déverrouille l'app, voit qu'aucune session n'est ouverte. Il compte les billets en caisse et déclare le fond.

---

## Driving Forces (Q4)

**Hope:** Ouvrir la caisse rapidement pour être prêt à vendre — pas de blocage avant la première transaction.

**Worry:** Se tromper dans le montant du fond de caisse — décalage comptable en fin de journée.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android (Commercial) — le matin, au comptoir
**Entry:** Commercial ouvre l'app → Dashboard COMMERCIAL avec `AlertBanner` ambre "Aucune session active — Ouvrir la caisse" + `ActionButton` "Ouvrir la caisse".

---

## Best Outcome (Q7)

**User Success:**
Session caisse ouverte en < 60 sec, fond de caisse déclaré — première vente possible immédiatement.

**Business Success:**
Blandine voit en temps réel que sa caisse est ouverte et avec quel fond — traçabilité complète du flux cash.

---

## Shortest Path (Q8)

1. **Bannière session** — `AlertBanner` ambre sur le dashboard COMMERCIAL → tap "Ouvrir la caisse"
2. **Saisie fond de caisse** — `NumberInput` montant FCFA + confirmation → session ouverte ✓
3. **Dashboard actif** — `SyncStatusBar` passe au vert, caisse ouverte — Blandine notifiée

---

## Trigger Map Connections

**Persona:** Commercial + Blandine (notification)

**Driving Forces Addressed:**
- ✅ **Want:** Commencer à vendre sans friction — CTA direct depuis la bannière
- ❌ **Fear:** Décalage comptable — fond de caisse confirmé avant la première transaction

**Business Goal:** O1.1 — Traçabilité complète fond→ventes→clôture

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 26.1 | `26.1-fond-de-caisse/` | Saisie du fond de caisse initial | Tap "Confirmer l'ouverture" |
| 26.2 | `26.2-confirmation-ouverture/` | Confirmation session active + notification Blandine | Session ouverte → dashboard actif |
