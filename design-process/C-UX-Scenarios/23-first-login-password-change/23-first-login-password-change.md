---
project: scalario
scenario: "23"
slug: 23-first-login-password-change
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 23: First Login Password Change

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine (ou tout employé) se connecte pour la première fois avec le mot de passe temporaire généré par Kofi — le système force immédiatement un changement avant d'accéder à l'app.

---

## Business Goal (Q2)

**Goal:** O1.1 — Sécurité de base = credentials personnels dès le premier jour
**Objective:** O2.2 — Si le mot de passe temporaire reste actif, Kofi (ou n'importe qui) peut accéder au compte → risque sécurité → perte de confiance → churn

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER) ou tout employé — premier login après déploiement Kofi (S17).
**Situation:** Vient de recevoir ses credentials de Kofi via WhatsApp — ouvre l'app pour la première fois.

---

## Driving Forces (Q4)

**Hope:** Accéder rapidement à l'app — ne pas être bloqué par une procédure complexe.

**Worry:** Oublier son nouveau mot de passe, ou que ça prenne trop de temps.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA
**Entry:** S07.1 (App Launch Login) → login avec mot de passe temporaire → forced redirect vers 23.1.

---

## Best Outcome (Q7)

**User Success:**
Nouveau mot de passe défini en < 1 minute — accès immédiat à l'app.

**Business Success:**
Credentials sécurisés dès le premier jour → O1.1. Kofi n'a plus accès → confiance tenant.

---

## Shortest Path (Q8)

1. **Forced Password Change** — formulaire simple : ancien MDP (pré-rempli), nouveau MDP, confirmation

---

## Scenario Steps

| Step | Dossier | Purpose |
|------|---------|---------|
| 23.1 | `23.1-forced-password-change/` | Formulaire changement obligatoire — bloquant jusqu'à complétion |

## Liens Scénarios

- **S17.3** (Confirmation Déploiement) — Kofi génère le mot de passe temporaire
- **S07.1** (App Launch Login) — login avec credentials temp → redirige ici
- **S24** (PIN/Biometric Setup) — proposé juste après 23.1
