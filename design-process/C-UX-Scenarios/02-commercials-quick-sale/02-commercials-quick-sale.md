---
project: scalario
scenario: "02"
slug: 02-commercials-quick-sale
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 02: Commercial's Quick Sale

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Le Commercial enregistre une vente de bout en bout — sélection articles, confirmation paiement cash — en moins de 30 secondes, sans formation préalable.

---

## Business Goal (Q2)

**Goal:** O1.1 — Usage quotidien du Commercial (volume transactions = preuve terrain du template)
**Objective:** O2.1 — Template `retail_fresh_produce.json` validé = second client sans modification

---

## User & Situation (Q3)

**Persona:** Le Commercial (employé de Blandine — rôle COMMERCIAL)
**Situation:** Au comptoir du magasin. Client devant lui, articles choisis. Téléphone en main, debout, une main, potentiellement en plein soleil — pression sociale : le client attend.

---

## Driving Forces (Q4)

**Hope:** Enregistrer la vente rapidement et sans erreur — être efficace devant le client.

**Worry:** Bloquer la file en cherchant comment utiliser l'app — perdre la face devant le client.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android mid-range — usage debout, une main, plein soleil possible
**Entry:** Le Commercial ouvre l'app — Dashboard COMMERCIAL s'affiche avec `ActionButton` "Nouvelle vente" au-dessus du fold. Tap immédiat sur le bouton primaire.

---

## Best Outcome (Q7)

**User Success:**
Vente enregistrée en < 30 sec, stock mis à jour automatiquement — client servi sans friction.

**Business Success:**
Transaction dans le système = données Blandine fiables en temps réel + volume prouve que le template fonctionne terrain.

---

## Shortest Path (Q8)

1. **Dashboard COMMERCIAL** — `ActionButton` "Nouvelle vente" visible above the fold, tap immédiat
2. **Sélection Articles** — `ProductSelector` liste articles depuis JSON stock, tap pour sélectionner, quantité ajustée
3. **Confirmation Paiement** — `PaymentConfirm` montant total (Roboto Mono grand), paiement cash validé → `TransactionLine` enregistrée ✓

---

## Trigger Map Connections

**Persona:** Le Commercial (rôle COMMERCIAL — sous-rôle équipe Blandine)

**Driving Forces Addressed:**
- ✅ **Want:** "Zéro friction entre client et caisse — zero learning curve" (principe Uber rider)
- ❌ **Fear:** "Bloquer devant un client — perte de face" — résolu par CTA primaire above the fold dès l'ouverture

**Business Goal:** O1.1 + O2.1 — Volume transactions terrain + validation template

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 02.1 | `02.1-dashboard-commercial/` | Dashboard rôle COMMERCIAL — CTA primaire visible | Tap "Nouvelle vente" |
| 02.2 | `02.2-selection-articles/` | Sélection articles + quantités depuis stock JSON | Tap "Confirmer" |
| 02.3 | `02.3-confirmation-paiement/` | Confirmation montant + paiement cash → transaction enregistrée | Vente validée ✓ |
