---
project: scalario
scenario: "A05"
slug: monitoring
status: outlined
created: 2026-05-09
surface: admin-scalario
---

# A05 — Monitoring

## Page Metadata

| Property | Value |
|----------|-------|
| **Surface** | Admin Scalario |
| **Scénario** | A05 |
| **Platform** | Flutter Web (statique) |
| **Accès** | Équipe Scalario uniquement |

## Overview

**Page Purpose:** Surveillance en temps réel de la santé technique de la plateforme — erreurs sync Drift, FCM delivery, logs système, alertes actives.

**Entry Context:** Dashboard A01 → section "Monitoring" / menu latéral ou depuis alerte système A01.

**On-Page Interactions:**
- Vue santé globale — tous tenants
- Drill-down par tenant pour diagnostiquer
- Logs filtrables par type d'erreur
- Alertes actives avec timestamp

---

## Composants UI (Flutter Web statique)

### Vue Globale Santé

| Composant | Contenu | Notes |
|-----------|---------|-------|
| KPICard | Sync Drift OK | % tenants sans erreur sync — 24h |
| KPICard | FCM delivery rate | % messages FCM livrés — 7j |
| KPICard | Erreurs actives | Nb erreurs non résolues en cours |
| KPICard | Uptime API | % disponibilité backend — 30j |
| DataTable | Tenants en erreur | Nom / type erreur / timestamp / nb occurrences |
| StatusBadge | Santé tenant | Vert OK / ambre warning / rouge erreur critique |

### Vue Logs

| Composant | Contenu | Notes |
|-----------|---------|-------|
| FilterChips | Type log | Sync Drift / FCM / Auth / API / Webhook |
| FilterChips | Sévérité | Critique / Warning / Info |
| LogList | Logs temps réel | Timestamp / tenant / type / message / stack trace |
| SearchBar | Recherche | Par tenant, par type d'erreur, par message |

### Vue Détail Tenant (onglet Monitoring)

| Composant | Contenu | Notes |
|-----------|---------|-------|
| KPICard | Dernière sync | Timestamp + statut |
| KPICard | FCM 7j | Taux livraison + nb messages |
| LogList | Logs tenant | Erreurs spécifiques à ce tenant |
| ActionButton | "Forcer resync" | Déclenche sync manuelle Drift → backend |

## Types d'Alertes Système

| Type | Seuil | Sévérité |
|------|-------|----------|
| Sync Drift échouée | > 3 tentatives | Critique |
| FCM delivery < 85% | Sur 24h | Warning |
| Auth KYC échoué | Répété | Warning |
| API timeout | > 5s médiane | Critique |
| Erreur sync > 10% tenants | Simultané | Critique |
