---
project: scalario
scenario: "05"
slug: 05-ibrahims-delivery-validation
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 05: Ibrahim's Delivery Validation

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Ibrahim valide la réception d'une livraison fournisseur — quantités contrôlées, écarts notés, stock mis à jour automatiquement — acte documenté qui le protège en cas de désaccord ultérieur.

---

## Business Goal (Q2)

**Goal:** O2.1 — Intégrité stock = template `retail_fresh_produce.json` validé (second client sans modification)
**Objective:** O1.1 — Données stock fiables = dashboard Blandine fiable en temps réel

---

## User & Situation (Q3)

**Persona:** Ibrahim (MANAGER — priorité #3)
**Situation:** À la réception du magasin ou à l'entrée du marché. Livreur devant lui, marchandises déchargées. Téléphone en main, vérification physique en cours — une main occupée.

---

## Driving Forces (Q4)

**Hope:** Documenter la réception avec précision — être protégé si un désaccord survient avec Blandine ou le fournisseur.

**Worry:** Signer pour une livraison incomplète sans preuve documentée — être tenu responsable d'un manque qu'il n'a pas commis.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android mid-range — debout, extérieur possible, usage une main
**Entry:** Ibrahim reçoit une livraison physique. Ouvre l'app depuis l'icône → Dashboard MANAGER → tap `ActionButton` "Réception livraison".

---

## Best Outcome (Q7)

**User Success:**
Livraison documentée en < 2 min — quantités saisies, écarts notés, Ibrahim protégé.

**Business Success:**
Stock Drift mis à jour en temps réel → données Blandine fiables + traçabilité fournisseur → O2.1 validé.

---

## Shortest Path (Q8)

1. **Dashboard MANAGER — Réception** — `ActionButton` "Réception livraison" visible, tap
2. **Saisie Livraison** — `FormWidget` liste articles attendus (depuis JSON), saisie quantités reçues par article via `QuantityControl`
3. **Confirmation Réception** — `ConfirmationDialog` récap (attendu vs reçu), tap "Valider" → stock Drift mis à jour, `AlertBanner` vert "Livraison enregistrée" ✓

---

## Trigger Map Connections

**Persona:** Ibrahim (MANAGER — priorité #3)

**Driving Forces Addressed:**
- ✅ **Want:** "Livraisons documentées sans ambiguïté" (score 14) — acte horodaté, quantités vs attendu
- ❌ **Fear:** "Être tenu responsable d'un manque non commis" — résolu par documentation automatique écart attendu/reçu

**Business Goal:** O2.1 + O1.1 — Intégrité stock = template validé + données Blandine fiables

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 05.1 | `05.1-dashboard-manager-reception/` | Dashboard MANAGER — accès réception livraison | Tap "Réception livraison" |
| 05.2 | `05.2-saisie-livraison/` | Saisie quantités reçues par article | Tap "Confirmer" |
| 05.3 | `05.3-confirmation-reception/` | Récap attendu vs reçu — validation → stock mis à jour | Livraison enregistrée ✓ |
