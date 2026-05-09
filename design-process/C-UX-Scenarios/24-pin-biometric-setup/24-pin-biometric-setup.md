---
project: scalario
scenario: "24"
slug: 24-pin-biometric-setup
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 24: PIN / Biometric Setup

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Après le premier login (S07) ou le changement de MDP (S23), l'app propose de configurer un déverrouillage rapide (PIN, empreinte ou Face ID) pour les ouvertures quotidiennes.

---

## Business Goal (Q2)

**Goal:** O1.1 — Re-auth rapide = adoption quotidienne = Blandine ouvre l'app chaque matin
**Objective:** O2.2 — Sans PIN/biométrie, Blandine doit retaper son MDP complet chaque matin → friction → elle ouvre moins → données incomplètes → churn

---

## User & Situation (Q3)

**Persona:** Tout utilisateur (Blandine, Ibrahim, Commercial) — juste après premier login ou depuis Paramètres.
**Situation:** Premier setup : proposé automatiquement. Modification : depuis Paramètres → Sécurité.

---

## Driving Forces (Q4)

**Hope:** Ouvrir l'app en 1 seconde le matin — comme déverrouiller son téléphone.

**Worry:** Oublier le PIN et se retrouver bloqué.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android (biométrie + PIN) OU Flutter Web PWA (PIN uniquement — pas de biométrie)
**Entry:** Après S23 → redirect automatique, OU Paramètres → Sécurité → "Configurer le déverrouillage".

---

## Best Outcome (Q7)

**User Success:**
PIN ou empreinte configuré — prêt pour le matin suivant.

**Business Success:**
Taux d'ouverture quotidienne → engagement → O1.1.

---

## Shortest Path (Q8)

1. **Setup Re-auth** — choix méthode + configuration + confirmation

---

## Scenario Steps

| Step | Dossier | Purpose |
|------|---------|---------|
| 24.1 | `24.1-setup-reauth/` | Choix méthode (PIN/empreinte/face) + configuration |

## Liens Scénarios

- **S23** (First Login Password Change) → redirect automatique après S23
- **S01** (Blandine's Morning Read) — ce setup rend S01 possible dès le lendemain
- **S25** (Profile Settings) → accès depuis Paramètres pour modifier
