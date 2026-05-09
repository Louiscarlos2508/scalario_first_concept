---
project: scalario
scenario: "11"
slug: 11-blandines-supplier-setup
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 11: Blandine's Supplier Setup

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine configure un fournisseur — nom, contact, produits livrés, prix d'achat — pour que les livraisons Ibrahim soient tracées avec le bon fournisseur et les marges calculées correctement.

---

## Business Goal (Q2)

**Goal:** O2.1 — Traçabilité fournisseur = template `retail_fresh_produce.json` validé
**Objective:** O1.1 — Marge brute calculable = rapports financiers fiables

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER — priorité #1)
**Situation:** Au magasin ou chez elle. Nouveau fournisseur à référencer, ou mise à jour prix d'achat après négociation.

---

## Driving Forces (Q4)

**Hope:** Livraisons tracées avec le bon fournisseur — marge calculée automatiquement sans effort.

**Worry:** Confondre les fournisseurs — prix d'achat erroné = marge fausse sans le savoir.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA
**Entry:** Dashboard OWNER → navigation → "Fournisseurs" → liste → tap `ActionButton` "Ajouter un fournisseur".

---

## Best Outcome (Q7)

**User Success:**
Fournisseur configuré, produits associés, prix d'achat saisis — prochaine livraison Ibrahim tracée correctement avec marge calculée.

**Business Success:**
Marge brute calculable automatiquement = rapports financiers fiables → O1.1 + O2.1.

---

## Shortest Path (Q8)

1. **Vue Fournisseurs** — liste fournisseurs configurés, `ActionButton` "Ajouter un fournisseur"
2. **FormWidget Fournisseur** — nom, téléphone, produits livrés (depuis catalogue), prix d'achat par produit
3. **Confirmation Fournisseur** — récap, enregistré → disponible dans flow livraison Ibrahim ✓

---

## Trigger Map Connections

**Persona:** Blandine (OWNER) + Ibrahim (MANAGER — bénéficiaire indirect)

**Driving Forces Addressed:**
- ✅ **Want:** "Traçabilité complète — qui livre quoi à quel prix"
- ❌ **Fear:** "Marge fausse non détectée" — résolu par association prix d'achat / produit / fournisseur

**Business Goal:** O2.1 + O1.1 — Traçabilité fournisseur = template validé + données financières fiables

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 11.1 | `11.1-vue-fournisseurs/` | Liste fournisseurs — accès création | Tap "Ajouter un fournisseur" |
| 11.2 | `11.2-form-fournisseur/` | Saisie infos + produits + prix d'achat | Tap "Enregistrer" |
| 11.3 | `11.3-confirmation-fournisseur/` | Récap + fournisseur actif dans le système | Fournisseur disponible ✓ |
