---
project: scalario
scenario: "A04"
slug: facturation
status: outlined
created: 2026-05-09
surface: admin-scalario
---

# A04 — Facturation

## Page Metadata

| Property | Value |
|----------|-------|
| **Surface** | Admin Scalario |
| **Scénario** | A04 |
| **Platform** | Flutter Web (statique) |
| **Accès** | Équipe Scalario uniquement |

## Overview

**Page Purpose:** Suivi de la facturation par tenant — MRR, historique paiements, relances automatiques ou manuelles.

**Entry Context:** Dashboard A01 → section "Facturation" / menu latéral ou alerte paiement en retard.

**On-Page Interactions:**
- Vue MRR global + par tenant
- Historique paiements par tenant
- Statut paiements : à jour / en retard / impayé
- Actions : relance manuelle, suspension

---

## Composants UI (Flutter Web statique)

### Vue Globale

| Composant | Contenu | Notes |
|-----------|---------|-------|
| KPICard | MRR total | FCFA — tous tenants actifs |
| KPICard | Paiements en retard | Nb tenants + montant total |
| KPICard | Impayés > 30j | Nb tenants — risque suspension |
| ChartWidget | MRR évolution | Line chart — 12 derniers mois |
| DataTable | Liste tenants | Nom / plan / montant / statut / prochain paiement |

### Vue Détail Tenant (onglet Facturation)

| Composant | Contenu | Notes |
|-----------|---------|-------|
| InfoCard | Plan actuel | Mensuel / annuel + montant |
| TransactionList | Historique paiements | Date / montant / statut / mode |
| StatusBadge | Statut paiement | Vert à jour / ambre retard / rouge impayé |
| ActionButton | "Envoyer relance" | Push FCM + SMS vers OWNER du tenant |
| ActionButton | "Suspendre" | Si impayé > 30j — lien vers A02 suspension |

## Plans Tarifaires Gate 0

| Plan | Cible | Montant |
|------|-------|---------|
| PME Standard | Blandine — retail | 40 000 – 60 000 FCFA/mois |
| PME Premium | Multi-département | 150 000 – 200 000 FCFA/mois |
