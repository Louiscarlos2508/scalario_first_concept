---
project: scalario
scenario: "10"
slug: 10-blandines-team-management
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 10: Blandine's Team Management

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine ajoute un nouvel employé — crée son compte, assigne rôle + permissions — ou modifie / désactive un compte existant. Autonome, sans appeler Kofi.

---

## Business Goal (Q2)

**Goal:** O1.1 — Équipe configurée = système opérationnel (prérequis Gate 0)
**Objective:** O3.1 — Blandine autonome = Kofi scalable sans support continu post-déploiement

---

## User & Situation (Q3)

**Persona:** Blandine (OWNER — priorité #1)
**Situation:** Au magasin ou chez elle. Nouvel employé qui arrive, employé qui part, ou changement de rôle dans l'équipe.

---

## Driving Forces (Q4)

**Hope:** Nouveau membre opérationnel aujourd'hui — pas besoin d'appeler Kofi pour chaque changement.

**Worry:** Qu'un ex-employé garde un accès actif après son départ — risque fraude / vol silencieux.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA — gestion équipe plus confortable sur grand écran
**Entry:** Dashboard OWNER → navigation → "Mon équipe" → liste employés actifs → tap `ActionButton` "Ajouter un employé".

---

## Best Outcome (Q7)

**User Success:**
Compte créé, rôle assigné, credentials générés — nouvel employé opérationnel en < 5 min.

**Business Success:**
Blandine autonome → Kofi scalable sans support post-déploiement → O3.1.

---

## Shortest Path (Q8)

1. **Vue Équipe** — liste employés actifs avec rôles, `ActionButton` "Ajouter un employé"
2. **FormWidget Employé** — prénom, nom, téléphone (= username), rôle (COMMERCIAL / MANAGER), département si configuré, mot de passe temporaire auto-généré
3. **Confirmation + Credentials** — récap compte + credentials affichés à communiquer à l'employé → compte actif immédiatement ✓

---

## Trigger Map Connections

**Persona:** Blandine (OWNER — priorité #1)

**Driving Forces Addressed:**
- ✅ **Want:** "Contrôle total sur son équipe — sans dépendance technique"
- ❌ **Fear:** "Ex-employé avec accès actif" — résolu par désactivation immédiate en 1 tap

**Business Goal:** O1.1 + O3.1 — Équipe opérationnelle + autonomie Blandine = intégrateur scalable

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 10.1 | `10.1-vue-equipe/` | Liste équipe — accès création/édition | Tap "Ajouter un employé" |
| 10.2 | `10.2-form-employe/` | Saisie infos + rôle + credentials | Tap "Créer le compte" |
| 10.3 | `10.3-confirmation-credentials/` | Récap + credentials à communiquer | Compte actif ✓ |
