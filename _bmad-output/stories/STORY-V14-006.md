# STORY-V14-006 : Catalogue v14 — restructuration (`modules/` génériques + `ux_profiles/` + `queries/` + `capabilities/`)

**Epic :** EPIC-V14-003 — Catalogues Scalario Kit/Profile/Pipe
**Priorité :** Must Have
**Story Points :** 5
**Status :** defined
**Sprint :** v14-1 (2026-05-26 → 2026-06-08)
**Dépendances :** V14-001 (nomenclature)

---

## User Story

> **En tant que** Scalario Labs (Phase 1) ou Scalario Forge (Phase 2+),
> **je veux** un catalogue `catalog/` restructuré en 4 sous-dossiers nommés (`modules/`, `ux_profiles/`, `capabilities/`, `queries/`),
> **so that** la séparation des concerns est nette : modules génériques par métier, UX par secteur, capabilities hardware, SQL nommé pour rapports complexes — et l'IA sait quoi chercher où.

---

## Description

### Background

PRD v14 §16 + §11 + §9 + §12 imposent 4 catalogues distincts :
- **`catalog/modules/`** — modules ERP génériques (commandes, stock, factures, employes…) hérités par tenant
- **`catalog/ux_profiles/`** — règles UX par métier (variantes autorisées, layouts, patterns)
- **`catalog/capabilities/`** — Scalario Sense : scan, GPS, print, NFC, Mobile Money (catalogue input/output/auth/payment)
- **`catalog/queries/`** — SQL nommé par métier pour les rapports complexes (Scalario Vault niveau 3)

v13 avait juste `catalog/domains/` + `catalog/modules/` (avec les 6 modules métier de STORY-040). Cette story restructure.

### Scope

**In scope :**
- Création de la nouvelle arborescence `catalog/`
- Migration `git mv` des fichiers v13 existants vers la nouvelle structure
- Définition des conventions de naming par dossier
- README dans chaque sous-dossier expliquant son rôle + format attendu
- Validators côté NestJS pour les nouveaux types (`ux_profile`, `capability`, `query`)

**Out of scope :**
- Implémentation effective des 6 modules génériques — V14-007
- Implémentation capabilities Flutter — V14-024 (Scalario Sense)
- Implémentation Hybrid RAG sur `queries/` — V14-016

---

## Acceptance Criteria

### Nouvelle arborescence

- [ ] **AC-01** — `catalog/modules/` avec sous-dossiers `gestion/`, `finance/`, `rh/`, `operations/`, `_overrides_per_tenant/`.
- [ ] **AC-02** — `catalog/ux_profiles/` avec `_base/`, `commerce_general/`, `pharmacie/`, `btp/`, `cabinet_medical/`.
- [ ] **AC-03** — `catalog/capabilities/` avec `input/`, `output/`, `location/`, `auth/`, `integration/`, `payment/`.
- [ ] **AC-04** — `catalog/queries/` avec `commun/`, `pharmacie/`, `btp/`, `finance/`.
- [ ] **AC-05** — `catalog/schemas/` reste (JSON Schemas), `catalog/domains/` archivé dans `catalog/_archive_v13/`.

### Migration des fichiers v13

- [ ] **AC-06** — `catalog/domains/retail_fresh_produce.json` (v13) déplacé → `catalog/_archive_v13/domains/retail_fresh_produce.json` + note de transition.
- [ ] **AC-07** — Les 6 `module_*.json` v13 (dashboard_owner, ventes, pertes, stock, etc.) déplacés → `catalog/_archive_v13/modules/` (référence audit STORY-040).
- [ ] **AC-08** — `catalog/workflows/wf_cloture_caisse.json` (v13) déplacé → `catalog/modules/operations/cloture_caisse.json` reformaté en module standard.

### Validators NestJS

- [ ] **AC-09** — `src/catalog-loader/loaders/module-loader.ts` charge depuis `catalog/modules/<sector>/<module>.json` avec héritage `inherits`.
- [ ] **AC-10** — `src/catalog-loader/loaders/ux-profile-loader.ts` (V14-004 dependency) charge depuis `catalog/ux_profiles/`.
- [ ] **AC-11** — `src/catalog-loader/loaders/capability-loader.ts` charge depuis `catalog/capabilities/`.
- [ ] **AC-12** — `src/catalog-loader/loaders/query-loader.ts` charge depuis `catalog/queries/` (NB: SQL brut, jamais exposé à l'IA — référencé par query_id).

### Docs

- [ ] **AC-13** — `catalog/README.md` réécrit avec la nouvelle structure + naming conventions.
- [ ] **AC-14** — Chaque sous-dossier a son `README.md` (`modules/README.md`, `ux_profiles/README.md`, etc.) avec exemples.

---

## Technical Notes

### Arborescence cible complète

```
catalog/
├── README.md                          ← Vue d'ensemble v14
├── schemas/                           ← JSON Schemas (no change vs v13)
│   ├── module-config.schema.json
│   ├── screen-config.schema.json
│   ├── component-config.schema.json
│   ├── workflow.schema.json
│   ├── ux-profile.schema.json         ← NOUVEAU v14
│   ├── capability.schema.json         ← NOUVEAU v14
│   └── examples/
│
├── modules/                           ← Modules ERP génériques (Scalario Kit)
│   ├── README.md
│   ├── gestion/
│   │   ├── commandes.json
│   │   ├── stock.json
│   │   ├── clients.json
│   │   └── fournisseurs.json
│   ├── finance/
│   │   ├── factures.json
│   │   ├── paiements.json
│   │   └── rapports_fin.json
│   ├── rh/
│   │   ├── employes.json
│   │   ├── conges.json
│   │   └── paie.json
│   ├── operations/
│   │   ├── livraisons.json
│   │   ├── planning.json
│   │   ├── chantiers.json
│   │   └── cloture_caisse.json       ← migré depuis catalog/workflows/wf_cloture_caisse.json v13
│   └── _overrides_per_tenant/         ← Phase 2 : Scalario Forge dépose les overrides ici
│       └── (vide Phase 1)
│
├── ux_profiles/                       ← UX par métier (Scalario Profile)
│   ├── README.md
│   ├── _base/
│   │   ├── components.json
│   │   ├── layout_rules.json
│   │   └── ux_patterns.json
│   ├── commerce_general/
│   ├── pharmacie/
│   ├── btp/
│   └── cabinet_medical/
│
├── capabilities/                      ← Hardware/système (Scalario Sense)
│   ├── README.md
│   ├── input/
│   │   ├── barcode_scan.json
│   │   ├── photo_capture.json
│   │   ├── signature_capture.json
│   │   ├── nfc_read.json
│   │   ├── voice_input.json
│   │   └── document_scan.json
│   ├── output/
│   │   ├── printer_bluetooth.json
│   │   ├── sms_send.json
│   │   └── share_file.json
│   ├── location/
│   │   ├── gps_position.json
│   │   └── gps_track.json
│   ├── auth/
│   │   └── biometrie.json
│   ├── integration/
│   │   ├── webhook_send.json
│   │   └── http_call.json
│   └── payment/                       ← Phase 2 (V14-025)
│       ├── wave_pay.json
│       ├── orange_money.json
│       └── mtn_momo.json
│
├── queries/                           ← SQL nommé (Scalario Vault niveau 3)
│   ├── README.md (RÈGLE : jamais exposé à l'IA, référencé par query_id)
│   ├── commun/
│   │   ├── dashboard_kpis.sql
│   │   └── audit_trail.sql
│   ├── pharmacie/
│   │   ├── rapport_ventes_medicaments.sql
│   │   ├── alerte_peremption.sql
│   │   └── ca_par_famille.sql
│   ├── btp/
│   │   ├── avancement_chantier.sql
│   │   └── cout_materiaux.sql
│   └── finance/
│       ├── balance_comptable.sql
│       └── rapprochement_bancaire.sql
│
└── _archive_v13/                      ← Sauvegarde des anciens fichiers
    ├── README.md (pointe vers STORY-AUDIT-v14.md)
    ├── domains/
    │   └── retail_fresh_produce.json
    └── modules/
        ├── module_dashboard_owner.json
        ├── module_dashboard_manager.json
        ├── module_dashboard_commercial.json
        ├── module_ventes.json
        ├── module_pertes.json
        └── module_stock.json
```

### Convention de naming

- Fichiers JSON : snake_case (`gestion/commandes.json`, `pharmacie/components.json`)
- Dossiers : kebab-case ou snake_case selon les conventions du subset (`ux_profiles/`, `cabinet_medical/`)
- `_base/` : règles communes héritées par tous les secteurs
- `_overrides_per_tenant/` : underscore préfixe = dossier "système" (pas un secteur)
- `_archive_v13/` : underscore préfixe + suffixe version = archive

### Edge cases

- Module standard surchargé par tenant : `catalog/modules/gestion/commandes.json` (standard) + `catalog/modules/_overrides_per_tenant/<tenant_id>/commandes.json` (override)
- Tenant utilisant 2 secteurs (rare) : UX Profile principal + sections d'autres profiles via `inherits[]`
- Migration v13 reversible : `_archive_v13/` permet d'inspecter facilement les anciens fichiers si besoin

---

## Dependencies

- **Prérequis :** V14-001 (nomenclature), V14-005 (restructure NestJS pour avoir `src/catalog-loader/`)
- **Stories bloquées :** V14-004 (UX Profiles consomme ces dossiers), V14-007 (6 moteurs ERP), V14-024 (Capabilities Flutter), V14-016 (RAG sur queries)

---

## Definition of Done

- [ ] Arborescence créée
- [ ] Migration `git mv` des fichiers v13
- [ ] 4 loaders NestJS (module, ux_profile, capability, query)
- [ ] Tests : chaque loader retrouve ses fichiers, validate Zod OK
- [ ] Docs README dans chaque sous-dossier
- [ ] sprint-status.yaml V14-006 = completed

---

## Story Points Breakdown

| Tâche | Points |
|---|---|
| Restructure dossiers + git mv | 1.0 |
| 4 loaders NestJS | 2.0 |
| 2 nouveaux schemas (ux-profile, capability) | 0.5 |
| README × 4 sous-dossiers + global | 0.75 |
| Tests loaders | 0.75 |
| **Total** | **5** |

---

## Progress Tracking

- 2026-05-25 : Created (Carlos via `/bmad:create-story`)

**Actual Effort :** TBD
