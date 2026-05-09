---
project: scalario
scenario: "A01"
slug: dashboard-admin
status: outlined
created: 2026-05-09
surface: admin-scalario
---

# A01 — Dashboard Admin

## Page Metadata

| Property | Value |
|----------|-------|
| **Surface** | Admin Scalario |
| **Scénario** | A01 |
| **Platform** | Flutter Web (statique) |
| **Accès** | Équipe Scalario uniquement |

## Overview

**Page Purpose:** Vue d'ensemble de la santé de la plateforme — métriques clés, alertes système, accès rapide aux sections critiques.

**Entry Context:** Login admin → page d'accueil par défaut.

**On-Page Interactions:**
- KPIs plateforme en temps réel
- Alertes système actives (erreurs sync, FCM échoués)
- Accès rapide : tenant en difficulté, intégrateur à valider
- Graphique MRR évolution (30 derniers jours)

---

## Composants UI (Flutter Web statique)

| Composant | Contenu | Notes |
|-----------|---------|-------|
| KPICard | Nb tenants actifs | Total + variation J-1 |
| KPICard | MRR total | FCFA + variation M-1 |
| KPICard | FCM delivery rate | % messages livrés — 7 derniers jours |
| KPICard | Erreurs sync actives | Nb tenants avec erreur Drift en cours |
| ChartWidget | MRR évolution | Line chart — 30 derniers jours |
| ChartWidget | Tenants actifs | Bar chart — croissance mensuelle |
| AlertBanner | Alertes système | Erreurs critiques en rouge, warnings en ambre |
| ActionButton | "Voir monitoring" | Lien rapide → A05 |

## États Alertes Système

| Alerte | Seuil | Action |
|--------|-------|--------|
| Erreurs sync > 5% tenants | Rouge | Lien → A05 logs |
| FCM delivery < 90% | Ambre | Lien → A05 FCM |
| Paiement en retard | Ambre | Lien → A04 facturation |
| Intégrateur à certifier | Info | Lien → A03 |
