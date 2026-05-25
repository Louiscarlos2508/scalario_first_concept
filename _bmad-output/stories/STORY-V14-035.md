# STORY-V14-035 : Multi-région — réplication DB pour clients dans plusieurs pays africains

**Epic :** EPIC-V14-021 — Infrastructure
**Priorité :** Should Have
**Story Points :** 8
**Status :** defined
**Sprint :** v14-15 (Phase 3)
**Dépendances :** V14-029 (schema-per-tenant)

---

## User Story

> **En tant que** Scalario à plusieurs dizaines de tenants dans 5-10 pays africains,
> **je veux** une infrastructure multi-région (au moins West Africa + East Africa + North Africa) avec réplication PostgreSQL streaming + routage géographique des requêtes,
> **so that** la latency client est < 100ms (vs 300-500ms si tout est dans 1 région européenne), et la souveraineté des données est respectée (données du Sénégal restent en Afrique de l'Ouest).

---

## Description

### Background

PRD v14 §26 Phase 3 — multi-région pour scaling géographique. PostgreSQL streaming replication entre primary (West Africa) et read replicas (East Africa, North Africa).

### Scope

**In scope :**
- Infra cloud : provider supportant Afrique (OVH, Hetzner, ou cloud africain natif comme Layer3 Cloud)
- 3 régions initiales : West Africa (primary), East Africa (replica), North Africa (replica)
- PostgreSQL streaming replication (1 primary, N replicas)
- Routage NestJS : reads → replica le plus proche (geo IP), writes → primary
- Tenant pinning : option `tenant.config.region = 'west_africa'` pour data residency
- Tests : latency < 100ms p95 dans chaque région
- Failover : si primary tombe, replica West Africa devient primary auto

**Out of scope :**
- Multi-cloud (AWS + GCP) — Phase 4
- Active-active multi-master — Phase 4+ (complexe)

---

## Acceptance Criteria

- [ ] **AC-01** — Infra 3 régions provisionnée + accessibles.
- [ ] **AC-02** — PostgreSQL streaming replication configurée + replication lag < 1s p95.
- [ ] **AC-03** — Routage NestJS : reads vers replica proche (via header `X-Region` ou geo IP), writes → primary.
- [ ] **AC-04** — Tenant `region` field dans `public.tenants` (`west_africa` | `east_africa` | `north_africa`).
- [ ] **AC-05** — Data residency : si tenant marqué `west_africa`, ses données ne sortent jamais de West Africa (vérifié par failover scope).
- [ ] **AC-06** — Latency tests : ping client Dakar → API < 80ms (vs 250ms Paris).
- [ ] **AC-07** — Failover automatique : primary down → West Africa replica promoted → downtime < 60s.
- [ ] **AC-08** — Runbook ops : DR (Disaster Recovery), procedures de failover manuel.

---

## Technical Notes

- PostgreSQL 16 streaming replication standard
- Alternative : Logical Replication pour plus de granularité
- Routage NestJS : DataSource pool par région, sélection dynamique selon `req.headers['x-region']` ou ip2region
- Caveats : write-after-read consistency (replica lag) → utiliser strong reads (primary) pour les workflows critiques

### Edge cases

- Tenant change de pays (rare) → migration data manuelle entre régions
- Replication lag > 5s → alerte + fallback primary pour reads critiques
- Network partition cross-region → primary continue, replicas catch-up

---

## Dependencies

- **Prérequis :** V14-029 (schema-per-tenant)
- **Stories bloquées :** Phase 4 (Scalario Network nécessite multi-région)

---

## Definition of Done

- [ ] Infra 3 régions opérationnelle
- [ ] Streaming replication + monitoring lag
- [ ] Routage NestJS
- [ ] Data residency vérifié
- [ ] Failover runbook
- [ ] sprint-status.yaml V14-035 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Provisionnement infra 3 régions | 2.0 |
| Streaming replication + monitoring | 2.0 |
| Routage NestJS + tenant region pinning | 2.0 |
| Tests latency + failover | 1.5 |
| Runbook DR | 0.5 |
| **Total** | **8** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
