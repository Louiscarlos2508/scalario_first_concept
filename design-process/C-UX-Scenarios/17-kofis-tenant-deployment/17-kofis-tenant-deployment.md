---
project: scalario
scenario: "17"
slug: 17-kofis-tenant-deployment
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 17: Kofi's Tenant Deployment

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Kofi (intégrateur) configure un nouveau client sur Scalario — crée le tenant, choisit le template, configure les paramètres de base — le client est opérationnel.

---

## Business Goal (Q2)

**Goal:** O1.1 — Déploiement rapide = valeur perçue immédiate par le client
**Objective:** O2.2 — Déploiement long ou complexe = client doute avant même de commencer → risque churn

---

## User & Situation (Q3)

**Persona:** Kofi (intégrateur certifié — priorité #2)
**Situation:** Chez le client ou à distance. Première mise en service — contexte onboarding.

---

## Driving Forces (Q4)

**Hope:** Client opérationnel en moins d'1h — impressionner, justifier la valeur de l'intégration.

**Worry:** Mauvaise config template → données fausses dès le départ → client mécontent → mauvaise réputation Kofi.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Flutter Web PWA (back-office intégrateur)
**Entry:** Back-office Kofi → section "Mes clients" → ActionButton "Nouveau client".

---

## Best Outcome (Q7)

**User Success:**
Tenant créé, template actif, Blandine peut se connecter immédiatement avec ses credentials.

**Business Success:**
Time-to-value < 1h → différenciateur Scalario vs concurrents → O1.1.

---

## Shortest Path (Q8)

1. **Création Tenant** — nom entreprise, adresse, secteur, template sélectionné
2. **Config Paramètres** — monnaie, fuseau horaire, logo, premier compte OWNER, KYC tenant
3. **Confirmation Déploiement** — tenant actif, Blandine reçoit credentials, Kofi voit client dans dashboard

---

## Trigger Map Connections

**Persona:** Kofi (intégrateur certifié — priorité #2)

**Driving Forces Addressed:**
- ✅ **Want:** "Client opérationnel en moins d'1h"
- ❌ **Fear:** "Mauvaise config → données fausses" — résolu par template pré-validé + aperçu config avant activation

**Business Goal:** O1.1 — Time-to-value = argument commercial Kofi + rétention client

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 17.1 | `17.1-creation-tenant/` | Infos entreprise + sélection template | Tap "Configurer" |
| 17.2 | `17.2-config-parametres/` | Monnaie / fuseau / logo / compte OWNER / KYC | Tap "Activer le tenant" |
| 17.3 | `17.3-confirmation-deploiement/` | Tenant actif, credentials envoyés à Blandine | Déploiement ✓ |

## Liens Scénarios

- **S07** (Kofi's Client First Launch) — premier login Blandine après ce déploiement
- **S10** (Blandine's Team Management) — Blandine crée ses autres comptes après S17
