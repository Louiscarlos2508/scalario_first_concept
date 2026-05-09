---
project: scalario
scenario: "A02"
slug: gestion-tenants
status: outlined
created: 2026-05-09
surface: admin-scalario
---

# A02 — Gestion Tenants

## Page Metadata

| Property | Value |
|----------|-------|
| **Surface** | Admin Scalario |
| **Scénario** | A02 |
| **Platform** | Flutter Web (statique) |
| **Accès** | Équipe Scalario uniquement |

## Overview

**Page Purpose:** Liste et gestion de tous les tenants clients — statut, intégrateur assigné, santé sync, actions admin.

**Entry Context:** Dashboard A01 → section "Tenants" / menu latéral.

**On-Page Interactions:**
- Liste tous tenants avec statut et métriques clés
- Filtres par statut, intégrateur, template
- Tap tenant → fiche détail
- Actions : suspendre, réactiver, accès lecture support

---

## Composants UI (Flutter Web statique)

### Vue Liste

| Composant | Contenu | Notes |
|-----------|---------|-------|
| DataTable | Liste tenants | Nom / intégrateur / template / statut / date activation / MRR |
| FilterChips | Statut | Actif / Suspendu / Trial / Impayé |
| SearchBar | Recherche | Par nom tenant ou intégrateur |
| StatusBadge | Statut tenant | Vert actif / rouge suspendu / ambre trial / gris impayé |

### Vue Détail Tenant

| Composant | Contenu | Notes |
|-----------|---------|-------|
| InfoCard | Infos entreprise | Nom / adresse / secteur / RCCM |
| InfoCard | Config technique | Template / monnaie / fuseau / date activation |
| InfoCard | Intégrateur | Kofi ou autre — nom + téléphone |
| KPICard | Santé sync | Dernière sync Drift réussie |
| KPICard | FCM | Taux livraison 7j |
| KPICard | MRR | Montant abonnement actuel |
| UserList | Utilisateurs | Comptes actifs du tenant — rôle + dernier login |
| ActionButton | "Suspendre" | Destructif — ConfirmationDialog obligatoire |
| ActionButton | "Accès lecture" | Mode support — lecture seule données tenant |
| ActionButton | "Contacter intégrateur" | Deeplink WhatsApp Kofi |

## Actions Disponibles

| Action | Condition | Effet |
|--------|-----------|-------|
| Suspendre | Impayé > 30j ou fraude | Tenant désactivé — users ne peuvent plus se connecter |
| Réactiver | Après régularisation | Tenant réactivé — données intactes |
| Accès lecture | Support client | Admin voit les données du tenant en lecture seule |
| Transférer intégrateur | Changement Kofi | Réassigne tenant à un autre intégrateur |
