---
project: scalario
scenario: "28"
slug: 28-export-rapport
status: outlined
created: 2026-05-09
template: retail_fresh_produce.json
---

# 28: Export de Rapport

**Project:** Scalario
**Created:** 2026-05-09
**Method:** Whiteport Design Studio (WDS)

---

## Transaction (Q1)

**What this scenario covers:**
Blandine exporte son rapport journalier, hebdomadaire ou mensuel en PDF ou CSV — pour l'envoyer à son comptable, l'imprimer, ou l'archiver. L'export est généré depuis la vue rapport (S12) en un tap.

---

## Business Goal (Q2)

**Goal:** O1.2 — Blandine a confiance dans ses chiffres et peut les partager
**Objective:** O2.1 — Template validé : export = preuve que Scalario remplace le cahier + tableur Excel

---

## User & Situation (Q3)

**Persona:** Blandine (rôle OWNER)
**Situation:** Fin de semaine ou fin de mois. Blandine est sur son téléphone ou l'app web, regarde son rapport. Son comptable lui demande les chiffres. Elle exporte directement depuis l'app.

---

## Driving Forces (Q4)

**Hope:** Exporter les chiffres proprement formatés — plus besoin de tout recopier dans Excel ou d'appeler quelqu'un.

**Worry:** Le fichier n'est pas lisible par son comptable / les chiffres ne correspondent pas à ce qu'elle voit dans l'app.

---

## Device & Starting Point (Q5 + Q6)

**Device:** Mobile Android OU Flutter Web PWA — depuis la vue rapport S12.2
**Entry:** Vue Rapport (S12.2) → icône export ou `ActionButton` "Exporter" en bas de page.

---

## Best Outcome (Q7)

**User Success:**
Rapport exporté en PDF propre avec en-tête tenant + logo en < 30 sec — partagé directement via WhatsApp ou email.

**Business Success:**
Blandine ne dépend plus d'un tiers pour avoir ses chiffres — autonomie comptable = réduction des frictions opérationnelles.

---

## Shortest Path (Q8)

1. **Vue Rapport** — `ActionButton` "Exporter" visible en bas de S12.2
2. **Choix format** — `ChipSelector` : PDF / CSV → `ChipSelector` canal : WhatsApp / Email / Télécharger
3. **Génération & partage** — Fichier généré et partagé → confirmation ✓

---

## Formats d'export

| Format | Usage | Destinataire |
|--------|-------|-------------|
| PDF | Rapport mis en page, en-tête tenant, logo, chiffres clés + chart | Comptable, banque, partage WhatsApp |
| CSV | Données brutes toutes transactions pour la période | Comptable, import Excel |

---

## Trigger Map Connections

**Persona:** Blandine (OWNER)

**Driving Forces Addressed:**
- ✅ **Want:** Autonomie comptable — chiffres propres sans effort
- ❌ **Fear:** Données inexploitables hors de l'app

**Business Goal:** O1.2 — Confiance Blandine dans ses données

---

## Scenario Steps

| Step | Dossier | Purpose | Exit Action |
|------|---------|---------|-------------|
| 28.1 | `28.1-export-rapport/` | Choix format + canal + génération du fichier | Fichier partagé → retour S12.2 |
