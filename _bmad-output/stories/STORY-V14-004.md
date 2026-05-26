# STORY-V14-004 : Catalogue composants × variantes (Scalario Profile)

**Epic :** EPIC-V14-002 — Scalario Canvas
**Priorité :** Must Have
**Story Points :** 5
**Status :** completed
**Sprint :** v14-2 (2026-06-09 → 2026-06-22)
**Dépendances :** V14-003 (Dispatch par variante)

---

## User Story

> **En tant que** Scalario Forge (Config Agent IA Phase 2) ou Scalario Labs (Phase 1),
> **je veux** un catalogue déclaratif qui dit quelles variantes sont autorisées par composant par métier,
> **so that** l'IA ne peut **pas inventer** de variantes hors registre, et chaque secteur (pharmacie, BTP, commerce_general…) impose sa cohérence métier sur l'UI.

---

## Description

### Background

PRD v14 §8.5 :
> L'IA ne peut choisir que parmi `allowed_variants`. Instructor rejette toute variante hors liste. Scalario Forge utilise `default_variant` si non précisé.

Cette story crée `catalog/ux_profiles/<sector>/components.json` qui déclare pour chaque composant DS :
- `default_variant` : utilisé si l'IA ne précise pas
- `mobile_variant` / `desktop_variant` : utilisés quand `variant: 'auto'` résout selon plateforme
- `allowed_variants` : liste exhaustive (l'IA ne peut pas sortir de cette liste)

Exemple : en pharmacie, on désactive `with-chart` sur KPICard (trop complexe pour ce métier), on autorise uniquement `default`, `compact`, `with-icon`, `hero`.

### Scope

**In scope :**
- 4 UX Profiles initiaux : `_base/`, `pharmacie/`, `commerce_general/`, `btp/`
- Fichier `components.json` par UX Profile listant 12 composants × variantes autorisées
- Validator Zod côté NestJS qui rejette toute variante hors `allowed_variants` du tenant
- Test : un tenant pharmacie tente `KPICard variant=with-chart` → 400 + message "variant not allowed in pharmacy UX profile"

**Out of scope :**
- Profils additionnels (cabinet_medical, restaurant…) — créés à la demande quand on aura ces clients
- Instructor Pydantic schema (Phase 2 — V14-019 Scalario Forge)

---

## Acceptance Criteria

### Structure catalogue

- [ ] **AC-01** — `catalog/ux_profiles/_base/components.json` créé (règles communes à tous secteurs).
- [ ] **AC-02** — `catalog/ux_profiles/commerce_general/components.json` créé.
- [ ] **AC-03** — `catalog/ux_profiles/pharmacie/components.json` créé (avec restrictions exemple : `with-chart` désactivé sur KPICard).
- [ ] **AC-04** — `catalog/ux_profiles/btp/components.json` créé.
- [ ] **AC-05** — Chaque fichier valide JSON, structure : `{ "<ComponentType>": { "default_variant", "mobile_variant?", "desktop_variant?", "allowed_variants[]" } }`.

### Héritage `_base` → secteur

- [ ] **AC-06** — Un UX Profile sectoriel peut omettre un composant → fallback `_base`.
- [ ] **AC-07** — `UXProfileLoader.load(tenant_id)` retourne le profile mergé (`_base` + sector override).

### Validation Zod NestJS

- [ ] **AC-08** — `UXProfileValidator.assertVariantAllowed(tenantId, componentType, variant)` throw si variant hors `allowed_variants`.
- [ ] **AC-09** — Hook dans `bdui.validator.ts` (refactoré V14-001) : avant de sauvegarder un `tenant_config.screens`, valide chaque `ComponentConfig.variant` contre l'UX Profile.

### Test E2E

- [ ] **AC-10** — Test E2E : tenant pharmacie tente PATCH `tenant_config` avec `{ type: 'KPICard', variant: 'with-chart' }` → 400 + `error: 'VARIANT_NOT_ALLOWED_IN_PROFILE', message: 'with-chart not allowed for KPICard in pharmacie UX profile'`.
- [ ] **AC-11** — Test E2E : tenant pharmacie avec `{ type: 'KPICard', variant: 'compact' }` → 200 OK.

---

## Technical Notes

### Structure fichier — exemple `catalog/ux_profiles/pharmacie/components.json`

```json
{
  "$schema_version": "1.0.0",
  "$inherits": "_base",
  "components": {
    "KPICard": {
      "default_variant": "with-icon",
      "mobile_variant": "compact",
      "desktop_variant": "hero",
      "allowed_variants": ["default", "compact", "with-icon", "hero"],
      "_comment": "with-chart désactivé en pharmacie — trop complexe"
    },
    "DataTable": {
      "default_variant": "default",
      "mobile_variant": "card-list",
      "desktop_variant": "default",
      "allowed_variants": ["default", "compact", "card-list"],
      "_comment": "timeline non pertinent en pharmacie"
    },
    "Button": {
      "default_variant": "primary",
      "allowed_variants": ["primary", "secondary", "ghost", "danger", "icon-only"]
    }
  }
}
```

### `_base` (~12 composants × toutes variantes par défaut)

```json
{
  "components": {
    "KPICard":      { "allowed_variants": ["default","compact","with-icon","hero","with-chart"] },
    "DataTable":    { "allowed_variants": ["default","compact","card-list","timeline"] },
    "ListTile":     { "allowed_variants": ["default","with-avatar","with-badge","dense"] },
    "AlertBanner":  { "allowed_variants": ["info","success","warning","danger","dismissible"] },
    "ChartBar":     { "allowed_variants": ["default","stacked","horizontal","mini"] },
    "ChartPie":     { "allowed_variants": ["default","donut","mini-legend"] },
    "Button":       { "allowed_variants": ["primary","secondary","ghost","danger","icon-only"] },
    "FAB":          { "allowed_variants": ["default","extended","mini"] },
    "FormField":    { "allowed_variants": ["text","number","date","select","search","scan"] },
    "StatCard":     { "allowed_variants": ["default","trend-up","trend-down","flat"] },
    "SyncStatusBar":{ "allowed_variants": ["syncing","synced","conflict","offline"] },
    "DocumentPreview":{ "allowed_variants": ["inline","card","fullscreen","thumbnail"] }
  }
}
```

### Edge cases

- UX Profile inexistant pour un tenant → fallback `_base` direct
- Variant `'auto'` → toujours autorisé (Flutter résout)
- Override partiel d'un composant → fusion deep (mobile_variant override, allowed_variants override complet)

---

## Dependencies

- **Prérequis :** V14-001 (nomenclature), V14-002 (schéma variant), V14-006 (catalogue v14 restructure)
- **Stories bloquées :** V14-019 (Scalario Forge — l'IA consomme ce catalogue), V14-007 (6 moteurs ERP — leurs ComponentConfigs sont validés)

---

## Definition of Done

- [ ] 4 fichiers `components.json` (`_base`, commerce_general, pharmacie, btp)
- [ ] `UXProfileLoader` + `UXProfileValidator` + test E2E
- [ ] Documentation `catalog/ux_profiles/README.md`
- [ ] sprint-status.yaml V14-004 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| 4 UX Profiles `_base` + 3 secteurs | 1.5 |
| UXProfileLoader (héritage `_inherits`) + Zod validator | 1.5 |
| Hook dans bdui.validator.ts | 1.0 |
| Tests E2E (2 cas) | 0.5 |
| Docs | 0.5 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
