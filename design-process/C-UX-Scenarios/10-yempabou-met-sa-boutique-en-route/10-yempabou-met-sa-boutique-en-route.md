# 10: Yempabou met sa boutique en route

**Project:** Scalario Retail Phase 1
**Created:** 2026-04-06

---

## Transaction (Q1)

Première installation : créer le tenant boutique, paramétrer les modules essentiels, créer les comptes équipe (gérante + vendeurs), démarrer la première session de caisse.

## Business Goal (Q2)

**Time-to-first-value court** — Plus l'onboarding est rapide, plus l'adoption est probable.

## User & Situation (Q3)

Yempabou, premier jour avec Scalario, à la boutique. App fraîchement installée.

## Driving Forces (Q4)

**Hope:** Démarrer vite, configurer l'essentiel sans perdre 2 heures.
**Worry:** Manquer une étape, devoir tout recommencer, ne pas comprendre les paramètres.

## Device & Starting Point (Q5 + Q6)

**Device:** Tablette ou téléphone Android.
**Entry:** Première ouverture de l'app après installation.

## Best Outcome (Q7)

**User Success:** En 15 minutes : tenant créé, profil patron + gérante + vendeur, modules activés (POS, stock, factures, crédit on/off), première session POS lancée.

## Shortest Path (Q8)

1. **Onboarding boutique (3)** — Wizard création tenant.
2. **Sélection profil (2)** — Choisit son propre profil "Patron".
3. **Paramètres boutique (39)** — Configure modules + impression.
4. **Gestion équipe (40)** — Ajoute gérante + vendeurs.
5. **Dashboard Gérant (5) ou Vendeur (6)** — Bascule pour vérifier les vues.
6. **POS Vente en gros (8)** — Test rapide flow gros si applicable. ✓

## Trigger Map Connections

**Persona:** Tous patrons (mais ici Yempabou comme exemple)
**Want:** Démarrage simple

## Scenario Steps

| Step | Folder | Purpose | Statut écran existant |
|------|--------|---------|---|
| 10.1 | `10.1-onboarding-boutique/` | Wizard création tenant | ✅ **GARDER** — OnboardingWizardScreen |
| 10.2 | `10.2-selection-profil/` | Choisir profil utilisateur (multi-comptes local) | ❌ **CRÉER** — page absente, mais EmployeePinScreen + TeamPinScreen existent (à orchestrer) |
| 10.3 | `10.3-parametres-boutique/` | Modules, impression, devise, fiscalité | ✅ **GARDER** — GeneralSettingsScreen |
| 10.4 | `10.4-gestion-equipe/` | CRUD utilisateurs + rôles | ✅ **GARDER** — TeamScreen |
| 10.5 | `10.5-dashboard-gerant/` | Vue rôle gérant | ✅ **GARDER** — ManagerOverviewScreen |
| 10.6 | `10.6-dashboard-vendeur/` | Vue rôle vendeur (= POS) | ✅ **GARDER** — PosScreen |
| 10.7 | `10.7-pos-vente-gros/` | Test flow vente en gros | ✅ **GARDER** — ClientOrdersCommercialScreen |
