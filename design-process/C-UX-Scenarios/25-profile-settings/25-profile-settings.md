---
project: scalario
scenario: "25"
slug: 25-profile-settings
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 25: Profile Settings

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine (ou tout utilisateur) consulte et modifie ses informations de profil — nom, téléphone, mot de passe, méthode de déverrouillage.

---

## Business Goal (Q2)

**Goal:** O1.1 — Utilisateur autonome = moins de dépendance à Kofi pour les modifications simples
**Objective:** O2.2 — Si Blandine ne peut pas changer son MDP seule, elle appelle Kofi pour chaque problème → friction → churn

---

## User & Situation (Q3)

**Persona:** Tout utilisateur — principalement Blandine (OWNER).
**Situation:** Veut changer son mot de passe, mettre à jour son numéro, ou modifier son PIN.

---

## Driving Forces (Q4)

**Hope:** Gérer son profil sans avoir besoin d'appeler Kofi.

**Worry:** Faire une erreur et se retrouver bloquée hors de l'app.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA
**Entry:** Paramètres → "Mon profil" ou tap sur l'avatar utilisateur.

---

## Best Outcome (Q7)

**User Success:**
Profil mis à jour en autonomie — mot de passe changé, téléphone à jour.

**Business Success:**
Autonomie utilisateur → Kofi moins sollicité pour support → scalabilité → O1.1.

---

## Shortest Path (Q8)

1. **Vue Profil** — informations actuelles + accès rapide aux modifications
2. **Edit Profil** — formulaire modification (nom, téléphone, MDP, PIN/biométrie)

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 25.1 | `25.1-vue-profil/` | Infos profil actuelles + accès modifications | Tap "Modifier" |
| 25.2 | `25.2-edit-profil/` | Formulaire modification + confirmation | Sauvegardé ✓ |

## Liens Scénarios

- **S24** (PIN/Biometric Setup) → accès depuis 25.1 "Modifier déverrouillage"
- **S23** (Forced Password Change) → même UI réutilisée pour le changement volontaire
