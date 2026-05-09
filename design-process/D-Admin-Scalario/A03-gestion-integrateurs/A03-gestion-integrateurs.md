---
project: scalario
scenario: "A03"
slug: gestion-integrateurs
status: outlined
created: 2026-05-09
surface: admin-scalario
---

# A03 — Gestion Intégrateurs

## Page Metadata

| Property | Value |
|----------|-------|
| **Surface** | Admin Scalario |
| **Scénario** | A03 |
| **Platform** | Flutter Web (statique) |
| **Accès** | Équipe Scalario uniquement |

## Overview

**Page Purpose:** Gestion des intégrateurs certifiés — certification, suivi performance, révocation accès si nécessaire.

**Entry Context:** Dashboard A01 → section "Intégrateurs" / menu latéral.

**On-Page Interactions:**
- Liste intégrateurs avec statut certification et performance
- Tap intégrateur → fiche détail + clients associés
- Actions : certifier, suspendre, voir clients, contacter

---

## Composants UI (Flutter Web statique)

### Vue Liste

| Composant | Contenu | Notes |
|-----------|---------|-------|
| DataTable | Liste intégrateurs | Nom / nb clients / MRR généré / statut certification / date |
| FilterChips | Statut | Certifié / En attente / Suspendu |
| StatusBadge | Certification | Vert certifié / ambre en attente / rouge suspendu |

### Vue Détail Intégrateur

| Composant | Contenu | Notes |
|-----------|---------|-------|
| InfoCard | Profil | Nom / téléphone / zone géographique / date certification |
| KPICard | Nb clients actifs | Tenants assignés à cet intégrateur |
| KPICard | MRR généré | Part intégrateur (60%) vs Scalario (40%) |
| KPICard | Taux déploiement | Avg time-to-value par client (< 1h = excellent) |
| TenantList | Clients | Liste tenants de l'intégrateur + statut |
| ActionButton | "Certifier" | Passe statut → Certifié + accès back-office activé |
| ActionButton | "Suspendre accès" | Révoque accès back-office — tenants non affectés |
| ActionButton | "Contacter" | Deeplink WhatsApp |

## Modèle Certification

| Étape | Condition | Action Admin |
|-------|-----------|--------------|
| Candidature | Intégrateur remplit formulaire | Notification A01 |
| Validation | Carlos vérifie profil + compétences | Tap "Certifier" dans A03 |
| Actif | Accès back-office intégrateur | Kofi peut créer tenants (S17) |
| Révocation | Fraude / inactivité > 6 mois | Tap "Suspendre accès" |

## Modèle Rémunération (affiché en A03)

| Part | Intégrateur | Scalario |
|------|-------------|----------|
| MRR client | 60% | 40% |
| Abonnement annuel | 60% | 40% |
