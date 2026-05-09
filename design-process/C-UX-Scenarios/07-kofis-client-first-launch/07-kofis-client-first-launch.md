---
project: scalario
scenario: "07"
slug: 07-kofis-client-first-launch
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 07: Kofi's Client First Launch

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Un nouvel employé déployé par Kofi lance l'app pour la première fois — comprend son rôle et son action primaire en moins de 3 minutes, sans formation intensive.

---

## Business Goal (Q2)

**Goal:** O1.2 — Onboarding fluide = intégrateur peut déployer plusieurs clients/mois
**Objective:** O3.1 — 3 intégrateurs certifiés actifs M6 — si l'onboarding est difficile, Kofi ne peut pas scaler

---

## User & Situation (Q3)

**Persona:** Nouvel employé d'un client PME — déployé par Kofi (intégrateur)
**Situation:** APK installé quelques minutes avant par Kofi. Premier lancement depuis l'icône, au magasin. Kofi peut être présent ou à distance. Téléphone personnel ou fourni.

---

## Driving Forces (Q4)

**Hope:** Comprendre ce qu'il doit faire et commencer à travailler immédiatement — pas perdre la face devant son patron le premier jour.

**Worry:** Ne pas comprendre l'interface, devoir demander de l'aide, ralentir l'équipe.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android mid-range — téléphone personnel ou fourni par le client
**Entry:** APK installé par Kofi → premier lancement depuis l'icône → Splash → Login (username ou numéro téléphone + mot de passe). Auth réussie → profil complet chargé depuis backend (tenant, département, rôle, permissions, layout JSON) → mis en cache Drift.

---

## Best Outcome (Q7)

**User Success:**
En < 3 min, l'employé voit son dashboard avec son action primaire évidente — peut commencer à travailler sans aide.

**Business Success:**
Onboarding < 3 min = Kofi déploie plusieurs employés en une matinée → O3.1 validé.

---

## Shortest Path (Q8)

1. **App Launch — Login** — Splash, écran login (username ou téléphone + mot de passe), auth → config JSON user chargée depuis backend → mise en cache Drift
2. **Dashboard Rôle — First Run** — Dashboard rendu depuis config JSON du user (rôle + modules + layout), `ActionButton` primaire visible above the fold, `OnboardingCard` contextuel non bloquant → employé peut agir immédiatement ✓

---

## Trigger Map Connections

**Persona:** Nouvel employé (end-user) — déployé par Kofi (intégrateur, priorité #2)

**Driving Forces Addressed:**
- ✅ **Want Kofi:** "Client utilisable dès J+1 sans formation intensive" — zero learning curve pour expert domaine
- ❌ **Fear Kofi:** "Client qui rappelle pour des questions basiques" — résolu par onboarding contextuel non bloquant + action primaire évidente

**Business Goal:** O1.2 + O3.1 — Déploiement rapide = intégrateur scalable = réseau certifiés M6

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 07.1 | `07.1-app-launch-login/` | Premier lancement + auth → config JSON chargée depuis backend | Dashboard affiché |
| 07.2 | `07.2-dashboard-role-first-run/` | Dashboard rôle rendu depuis config JSON — action primaire évidente | Premier geste métier ✓ |
