# STORY-V14-036 : Swagger public + portail intégrateurs Phase 3

**Epic :** EPIC-V14-005 — DX & Documentation
**Priorité :** Should Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-16 (Phase 3 — fin de cycle)
**Dépendances :** V14-009 (Swagger interne), V14-029 (multi-tenant prêt pour intégrateurs externes)

---

## User Story

> **En tant qu'**intégrateur certifié Scalario Phase 3 (modèle semi-self-service),
> **je veux** un portail intégrateurs (`integrators.scalario.app`) avec : Swagger public, documentation v14 complète, exemples curl, sandbox tenant pour tester, support ticketing,
> **so that** je peux livrer un ERP Scalario à un client en 45 min via Scalario Forge sans avoir besoin de Carlos en hotline 24/7.

---

## Description

### Background

PRD v14 Phase 3 — préparation Phase 2 business (semi self-service). Les intégrateurs certifiés deviennent autonomes via portail.

### Scope

**In scope :**
- Hébergement Swagger sur `api.scalario.app/docs` (Phase 1 = interne, Phase 3 = public)
- Sous-domaine `integrators.scalario.app` (Flutter Web)
- Sections portail :
  - Login intégrateur
  - Documentation API Swagger + exemples
  - Sandbox tenant (Demo Space pré-configuré pour test)
  - Catalogue capabilities + queries SQL nommées
  - Status page (uptime monitoring)
  - Support ticketing (intégration externe ex: Plain ou similaire)
- Authentification dédiée intégrateurs (rôle `INTEGRATOR` distinct)
- Rate limiting plus permissif pour intégrateurs certifiés
- Tests : intégrateur fictif peut créer tenant sandbox + tester via Forge

**Out of scope :**
- Marketplace plugins/extensions (Phase 4)
- Affiliate / referral program (Phase 4)

---

## Acceptance Criteria

- [ ] **AC-01** — Swagger public à `https://api.scalario.app/docs` (sans auth, mais rate-limited).
- [ ] **AC-02** — Portail Flutter Web `integrators.scalario.app` déployé.
- [ ] **AC-03** — Login intégrateur (séparé des login tenants — table `public.integrators`).
- [ ] **AC-04** — Sandbox tenant fonctionnel : 1 intégrateur peut créer N tenants sandbox (TTL 30j).
- [ ] **AC-05** — Documentation API exhaustive (générée auto Swagger + docs hand-written sur architecture).
- [ ] **AC-06** — Exemples curl par endpoint principal (auth, bdui, action, sync, payment).
- [ ] **AC-07** — Status page (uptime, latency par région, incidents).
- [ ] **AC-08** — Support ticketing intégré (Plain ou linear).
- [ ] **AC-09** — Test : intégrateur fictif s'inscrit → crée tenant sandbox → onboard via Forge → ERP fonctionnel.

---

## Technical Notes

- Sub-domain Flutter Web : `integrators.scalario.app` pointe vers une build Flutter Web séparée
- Auth intégrateurs : JWT avec scope `integrator` ≠ scope tenant user
- Sandbox TTL 30j : cron purge tenants `is_sandbox=true AND created_at < NOW() - 30 days`
- Rate limiting intégrateurs : 1000 req/min vs 100 req/min pour tenants

### Edge cases

- Sandbox tenant prend trop de DB → quotas par intégrateur (max 5 sandboxes actifs)
- Intégrateur crée un client prod → bascule "sandbox → live" via achat license

---

## Dependencies

- **Prérequis :** V14-009 (Swagger interne), V14-029 (multi-tenant), V14-019 (Forge accessible)
- **Stories bloquées :** Phase 2 business (semi self-service via intégrateurs certifiés)

---

## Definition of Done

- [ ] Swagger public déployé
- [ ] Portail intégrateurs Flutter Web
- [ ] Sandbox tenant + TTL
- [ ] Support ticketing intégré
- [ ] Test E2E intégrateur fictif
- [ ] Docs intégrateur public
- [ ] sprint-status.yaml V14-036 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Swagger public deploy + auth intégrateur | 1.0 |
| Portail Flutter Web | 2.0 |
| Sandbox tenant + TTL | 1.0 |
| Support ticketing integration | 0.5 |
| Docs intégrateur publique | 0.5 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
