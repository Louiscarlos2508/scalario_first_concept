---
project: scalario
section: D
slug: admin-scalario
status: outlined
created: 2026-05-09
---

# D — Admin Scalario

**Project:** Scalario
**Created:** 2026-05-09
**Surface:** Flutter Web (écrans statiques — pas de BDUI engine)
**Accès:** Équipe Scalario uniquement (Carlos + équipe interne)

---

## Contexte

L'admin Scalario est la surface interne de pilotage de la plateforme. Elle est distincte des 3 autres surfaces :

| Surface | Utilisateur | Technologie |
|---------|-------------|-------------|
| Mobile Android | Blandine / Ibrahim / Commercial | Flutter mobile + BDUI |
| Flutter Web PWA | Blandine (back-office client) + Kofi (back-office intégrateur) | Flutter Web + BDUI |
| **Admin Scalario** | **Équipe Scalario (Carlos)** | **Flutter Web statique** |

Les écrans admin sont **hardcodés** — pas de JSON template, pas de BDUI engine. Design system Scalario standard.

---

## Périmètre Gate 0 — 8 juillet 2026

Tous les scénarios admin sont Gate 0.

---

## Scénarios Admin

| Scénario | Dossier | Périmètre |
|----------|---------|-----------|
| **A01** | `A01-dashboard-admin/` | KPIs plateforme — MRR, tenants, FCM, sync |
| **A02** | `A02-gestion-tenants/` | Liste tenants, détail, suspension, accès support |
| **A03** | `A03-gestion-integrateurs/` | Intégrateurs certifiés, certification, révocation |
| **A04** | `A04-facturation/` | MRR par tenant, paiements, relances |
| **A05** | `A05-monitoring/` | Erreurs sync Drift, FCM delivery, logs système |
