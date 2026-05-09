---
project: scalario
scenario: "15"
slug: 15-commercials-credit-sale
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 15: Commercial's Credit Sale

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Commercial enregistre une vente à crédit ou paiement partiel — client repart avec les articles, solde dû tracé dans le système.

---

## Business Goal (Q2)

**Goal:** O1.1 — Traçabilité crédit = confiance Blandine dans le système
**Objective:** O2.2 — Sans gestion crédit, commerciaux contournent via ventes non enregistrées → données fausses → churn

---

## User & Situation (Q3)

**Persona:** Commercial (rôle COMMERCIAL)
**Situation:** Au comptoir. Client habituel ou de confiance — paiement complet impossible ce jour.

---

## Driving Forces (Q4)

**Hope:** Servir le client fidèle sans friction, garder la vente enregistrée proprement.

**Worry:** Blandine pense qu'il a gardé l'argent — ou que la dette ne sera jamais recouvrée.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android
**Entry:** Même flow que vente normale (S02) → au moment du paiement, mode "Crédit" ou "Partiel" → saisit montant versé + échéance + identification client.

---

## Best Outcome (Q7)

**User Success:**
Vente enregistrée proprement, client reparti satisfait, solde dû visible dans le système.

**Business Success:**
Créance tracée → Blandine suit les dettes clients → intégrité données → O1.1.

---

## Shortest Path (Q8)

1. **Sélection Articles** — ProductSelector + QuantityControl → montant total calculé
2. **Paiement Partiel** — mode paiement "Crédit/Partiel" + montant versé + montant dû + échéance + client
3. **Confirmation Crédit** — TransactionLine avec solde dû, Blandine notifiée, créance dans rapport

---

## Trigger Map Connections

**Persona:** Commercial (rôle COMMERCIAL)

**Driving Forces Addressed:**
- ✅ **Want:** "Servir le client fidèle proprement, vente enregistrée"
- ❌ **Fear:** "Être soupçonné de détournement" — résolu par traçabilité automatique + notification Blandine

**Business Goal:** O1.1 + O2.2 — Données fidèles = pilotage fiable = rétention

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 15.1 | `15.1-selection-articles/` | Sélection articles + calcul montant total | Tap "Procéder au paiement" |
| 15.2 | `15.2-paiement-partiel/` | Mode crédit + montant versé + solde + échéance + client | Tap "Confirmer vente crédit" |
| 15.3 | `15.3-confirmation-credit/` | Créance tracée, Blandine notifiée, solde visible | Vente crédit enregistrée ✓ |
