---
project: scalario
scenario: "03"
slug: 03-blandine-commercial-caisse-close
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 03: Blandine & Commercial's Caisse Close

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Le Commercial clôture la caisse en fin de journée — saisit le montant physique — et Blandine valide depuis son téléphone sans confrontation face-à-face.

---

## Business Goal (Q2)

**Goal:** O1.1 — Clôture caisse = ritual journalier indispensable (usage quotidien)
**Objective:** O2.2 — Churn <3% — la validation croisée crée la confiance durable entre Blandine et son équipe

---

## User & Situation (Q3)

**Persona:** Le Commercial (rôle COMMERCIAL) + Blandine (OWNER) — scénario multi-persona
**Situation:** Fin de journée. Commercial : au magasin, fatigué, veut rentrer. Blandine : peut être à domicile ou au marché, reçoit une notification push.

---

## Driving Forces (Q4)

**Hope:** Blandine voit les chiffres validés et bouclés — certitude sans confrontation directe.

**Worry:** Un écart non documenté — manque ou erreur qui reste flou, source de tension entre eux.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android mid-range pour les deux — Blandine peut être hors du magasin
**Entry:** Commercial : ouvre l'app, tap "Clôture caisse" depuis son dashboard. Blandine : reçoit push FCM "Clôture soumise" → ouvre l'app pour valider.

---

## Best Outcome (Q7)

**User Success:**
Blandine — chiffres validés, journée bouclée avec certitude. Commercial — acte documenté, protégé en cas de question ultérieure.

**Business Success:**
Validation croisée enregistrée → rétention O2.2 + données fiables pour rapports Blandine.

---

## Shortest Path (Q8)

1. **Dashboard COMMERCIAL — Clôture** — `ActionButton` "Clôture caisse" visible, tap → `FormWidget` s'ouvre
2. **Saisie Clôture** — Commercial saisit montant caisse physique, soumet → push FCM envoyé à Blandine automatiquement
3. **Dashboard OWNER — Validation** — Blandine ouvre depuis push, `ConfirmationDialog` récap (montant saisi vs transactions enregistrées), compare, valide → `AlertBanner` vert "Clôture validée" ✓

---

## Trigger Map Connections

**Persona:** Blandine (Primary) + Le Commercial (COMMERCIAL)

**Driving Forces Addressed:**
- ✅ **Want Blandine:** "Clôture caisse validée sans confrontation" (score 14) — traçabilité mutuelle
- ❌ **Fear Blandine:** "Écart non détecté — vol silencieux" — résolu par comparaison automatique montant saisi vs système
- ✅ **Want Commercial:** Acte documenté = protection

**Business Goal:** O1.1 + O2.2 — Ritual journalier + confiance mutuelle → rétention

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 03.1 | `03.1-dashboard-commercial-cloture/` | Commercial accède à la clôture caisse | Tap "Clôture caisse" |
| 03.2 | `03.2-saisie-cloture/` | Saisie montant physique + soumission → push Blandine | Soumission formulaire |
| 03.3 | `03.3-dashboard-owner-validation/` | Blandine valide la clôture depuis push | Validation → clôture confirmée ✓ |
