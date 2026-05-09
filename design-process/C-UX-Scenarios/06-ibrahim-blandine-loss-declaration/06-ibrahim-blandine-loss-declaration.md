---
project: scalario
scenario: "06"
slug: 06-ibrahim-blandine-loss-declaration
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 06: Ibrahim & Blandine's Loss Declaration

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Ibrahim constate une perte physique — produit avarié, casse, manque — et la déclare dans l'app avec contexte. Blandine reçoit l'information sans confrontation directe.

---

## Business Goal (Q2)

**Goal:** O2.1 — Pertes tracées = données stock fiables = template `retail_fresh_produce.json` validé
**Objective:** O2.2 — Churn <3% — pertes non documentées = source de tension et de churn

---

## User & Situation (Q3)

**Persona:** Ibrahim (MANAGER — priorité #3) + Blandine (OWNER — notifiée)
**Situation:** Ibrahim au magasin, constate une perte physique sur place — produits avariés, casse lors d'une livraison, ou manque inexpliqué. Téléphone en main, debout.

---

## Driving Forces (Q4)

**Hope:** Déclarer avec contexte clair — être protégé, pas accusé d'une perte qu'il n'a pas causée.

**Worry:** Que Blandine pense que c'est lui le responsable sans avoir le contexte — tension, méfiance mutuelle.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android mid-range — au magasin, debout, usage une main possible
**Entry:** Ibrahim constate la perte physiquement. Ouvre l'app → Dashboard MANAGER → tap `ActionButton` "Déclarer une perte".

---

## Best Outcome (Q7)

**User Success:**
Ibrahim — perte documentée avec contexte et horodatage = protégé. Blandine — voit l'info sans confrontation, données fiables.

**Business Success:**
Pertes tracées → rapports Blandine complets + résolution UX de la tension centrale du Trigger Map (surveillance vs traçabilité mutuelle).

---

## Shortest Path (Q8)

1. **Dashboard MANAGER — Déclaration** — `ActionButton` "Déclarer une perte" visible, tap
2. **FormWidget Perte** — article, quantité, nature (avarié / casse / vol / autre), note optionnelle
3. **Confirmation Déclaration** — récap, tap "Soumettre" → perte enregistrée, Blandine notifiée push discrète, `AlertBanner` vert "Perte enregistrée" ✓

---

## Trigger Map Connections

**Persona:** Ibrahim (MANAGER) + Blandine (OWNER — notifiée)

**Driving Forces Addressed:**
- ✅ **Want Ibrahim:** "Actes documentés — protection en cas de question" — horodatage + contexte obligatoire
- ❌ **Fear Ibrahim:** "Être accusé sans preuve" — résolu par déclaration contextuelle tracée
- ✅ **Tension résolue:** Blandine veut voir / Ibrahim craint surveillance → traçabilité mutuelle = les deux protégés

**Business Goal:** O2.1 + O2.2 — Intégrité données + résolution tension centrale = rétention

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 06.1 | `06.1-dashboard-manager-declaration/` | Dashboard MANAGER — accès déclaration perte | Tap "Déclarer une perte" |
| 06.2 | `06.2-form-perte/` | Saisie nature + quantité + contexte perte | Tap "Soumettre" |
| 06.3 | `06.3-confirmation-declaration/` | Récap + validation → perte enregistrée + Blandine notifiée | Déclaration confirmée ✓ |
