---
project: scalario
scenario: "14"
slug: 14-commercials-sale-return
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 14: Commercial's Sale Return

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Commercial annule ou corrige une vente déjà enregistrée — avec motif documenté, stock remis à jour, Blandine notifiée.

---

## Business Goal (Q2)

**Goal:** O1.1 — Intégrité des données = confiance dans le système
**Objective:** O2.2 — Erreurs arrivent : si on ne peut pas corriger proprement, le système perd sa fiabilité → churn

---

## User & Situation (Q3)

**Persona:** Commercial (rôle COMMERCIAL)
**Situation:** Au comptoir. Client devant lui qui signale une erreur, ou Commercial détecte lui-même une saisie incorrecte juste après la vente.

---

## Driving Forces (Q4)

**Hope:** Corriger vite, proprement, sans drama — rester professionnel devant le client.

**Worry:** Blandine pense que c'est de la fraude — passer pour un voleur à cause d'une simple erreur.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android
**Entry:** Dashboard COMMERCIAL → Historique ventes du jour → tap vente concernée → ActionButton "Annuler cette vente".

---

## Best Outcome (Q7)

**User Success:**
Vente annulée proprement — stock remis à jour, motif documenté, Commercial protégé par la traçabilité.

**Business Success:**
Intégrité des données préservée → O1.1. Canal de confiance entre Commercial et OWNER → O2.2.

---

## Shortest Path (Q8)

1. **Historique Ventes** — liste ventes du jour, tap vente concernée
2. **Détail Vente + Annulation** — récap vente + motif obligatoire + ActionButton "Annuler"
3. **Confirmation Annulation** — stock remis, Blandine notifiée push, AlertBanner vert ✓

---

## Trigger Map Connections

**Persona:** Commercial (rôle COMMERCIAL)

**Driving Forces Addressed:**
- ✅ **Want:** "Corriger une erreur vite et proprement"
- ❌ **Fear:** "Être soupçonné de fraude" — résolu par motif obligatoire + notification transparente à Blandine

**Business Goal:** O1.1 + O2.2 — Confiance système = rétention long terme

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 14.1 | `14.1-historique-ventes/` | Liste ventes du jour — sélection vente à corriger | Tap sur vente |
| 14.2 | `14.2-detail-vente-annulation/` | Récap vente + saisie motif + confirmation annulation | Tap "Confirmer annulation" |
| 14.3 | `14.3-confirmation-annulation/` | Stock remis, Blandine notifiée, traçabilité créée | Annulation enregistrée ✓ |
