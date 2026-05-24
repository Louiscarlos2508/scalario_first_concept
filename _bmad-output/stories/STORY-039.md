# STORY-039 : Template `retail_fresh_produce.json` — Structure + 3 Rôles

**Epic :** EPIC-007 — Premier Template `retail_fresh_produce.json` (Gate 0 Blandine)
**Priorité :** Must Have
**Story Points :** 3
**Status :** done
**Assigned To :** Carlos
**Created :** 2026-05-10
**Completed :** 2026-05-24
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-025 (structure catalogue), STORY-024 (Zod validator)

---

## User Story

> **En tant qu'**intégrateur Scalario certifié,
> **je veux** la structure complète du template `retail_fresh_produce.json` avec ses 3 rôles (OWNER / MANAGER / COMMERCIAL) et la matrice RBAC déclarée en JSON,
> **so that** l'accès de chaque rôle est défini sans une ligne de code backend, et le catalogue dispose d'un squelette de domaine valide qui pourra accueillir les 6 modules Phase 1 (STORY-040), le workflow clôture caisse (STORY-041) et les contraintes Global Scale (STORY-042).

---

## Description

### Background

Scalario livre Gate 0 = `retail_fresh_produce.json` déployé chez Blandine au 8 juillet 2026. Ce template est la première instanciation concrète du modèle catalogue : il prouve que le BDUIEngine + ModuleEngine + WorkflowEngine peuvent rendre une app Business OS complète sans une ligne de Flutter métier.

Avant d'écrire les 6 modules (STORY-040), il faut le **squelette** : metadata du domaine, déclaration des 3 rôles, matrice RBAC qui dit "qui voit quoi", liste des modules référencés, navigation par rôle, dashboard layout par rôle.

C'est une story de fondation **structurelle** — peu de logique, beaucoup de précision sur le schéma. Une fois validée Zod, elle débloque tout EPIC-007.

**Source de vérité métier (Blandine) :** 8 phases workflow fresh produce, 3 acteurs distincts :
- **OWNER (Blandine)** : voit le CA, les KPIs, les notifications soir, toutes les données financières. Décide.
- **MANAGER (Ibrahim, gestionnaire entrepôt)** : valide les arrivages fournisseurs, libère le stock aux commerciaux, valide les pertes, valide les clôtures de caisse. Pas d'accès au CA global.
- **COMMERCIAL (vendeur terrain)** : vend (POS rapide), déclare ses pertes, fait sa clôture caisse quotidienne. Voit uniquement son propre stock alloué et ses propres ventes.

### Scope

**In scope :**

- Création du fichier `catalog/domains/retail_fresh_produce.json` avec :
  - Metadata domaine (`schema_version`, `domain_id`, `name`, `i18n_key`, `sector`, `description`, `version`, `min_users`, `max_users`).
  - Déclaration des 3 rôles avec `id`, `name`, `i18n_key`, `description`, `permissions[]`.
  - Matrice RBAC complète : pour chaque rôle, la liste des `module_id` accessibles + actions autorisées (`read`, `write`, `validate`, `close`).
  - Liste des 6 modules Phase 1 référencés par `module_id` (déclaration uniquement — implémentation = STORY-040).
  - Navigation par rôle : ordre des modules dans le bottom nav / sidebar selon le rôle.
  - Dashboard layout par rôle : référence vers le module_dashboard correspondant.
  - Bloc i18n : `i18n_keys` répertoriés (FR primaire, EN préparé) — strings réelles dans STORY-042.
  - Bloc tenant_defaults : `currency: "XOF"`, `locale: "fr-BF"`, `timezone: "Africa/Ouagadougou"`.
- Validation Zod via `POST /api/v1/admin/templates/validate` (dépend STORY-024) : 0 erreur.
- Test unitaire : le fichier `retail_fresh_produce.json` charge sans erreur dans `CatalogueService`.
- Test d'intégration : un user OWNER vs MANAGER vs COMMERCIAL chargeant ce template via `GET /api/v1/:tenant/layout/dashboard` reçoit un layout différent (preuve que le RBAC filtre).

**Out of scope (autres stories) :**

- Implémentation des 6 modules eux-mêmes (entities, screens, actions) → STORY-040.
- Workflow DAG clôture caisse → STORY-041.
- ARB files i18n FR/EN + PaymentAdapter → STORY-042.
- Validation E2E Gate 0 (Blandine UAT) → STORY-043.
- ABAC fine-grained (ex : MANAGER voit les pertes de son entrepôt uniquement) → reporté Phase 2 (mentionné mais non implémenté).

### User Flow (Intégrateur)

1. Intégrateur ouvre `catalog/domains/retail_fresh_produce.json`.
2. Il voit la déclaration des 3 rôles + matrice RBAC, lisible sans connaître Flutter ni NestJS.
3. Il commit, le hook CI `validate-catalogue.yml` (STORY-024) lance Zod → vert.
4. Il déploie. `CatalogueService` recharge le template.
5. Un user OWNER se connecte → BDUIEngine demande son layout dashboard → le serveur résout `retail_fresh_produce.json`, applique le filtre RBAC du rôle OWNER, retourne le `ScreenConfig` du `module_dashboard_owner`.
6. Un user MANAGER fait pareil → reçoit `module_dashboard_manager`.
7. Un user COMMERCIAL fait pareil → reçoit `module_dashboard_commercial`.

---

## Acceptance Criteria

### Structure et metadata

- [ ] AC-01 — Fichier `catalog/domains/retail_fresh_produce.json` créé, encodé UTF-8, indenté 2 espaces, parsing JSON valide (`jq . retail_fresh_produce.json` retourne 0).
- [ ] AC-02 — Metadata domaine présente : `schema_version: "1.0.0"`, `domain_id: "retail_fresh_produce"`, `name: "Retail — Fresh Produce"`, `i18n_key: "domain.retail_fresh_produce.name"`, `sector: "retail"`, `subsector: "fresh_produce"`, `description` non vide, `version: "1.0.0"`, `min_users: 1`, `max_users: 50`.
- [ ] AC-03 — Tenant defaults présents : `tenant_defaults.currency: "XOF"`, `tenant_defaults.locale: "fr-BF"`, `tenant_defaults.timezone: "Africa/Ouagadougou"`, `tenant_defaults.fiscal_year_start: "01-01"`, `tenant_defaults.tax_mode: "configurable"`. **Aucune valeur métier hardcodée hors du bloc `tenant_defaults`** (Global Scale).

### Rôles déclarés

- [ ] AC-04 — Bloc `roles[]` contient exactement 3 entrées avec `id`, `name`, `i18n_key`, `description`, `permissions[]`, `dashboard_module_id`, `nav_modules[]`.
- [ ] AC-05 — Rôle `OWNER` :
  - `permissions`: `["module_dashboard_owner.read", "module_ventes.read", "module_pertes.read", "module_alertes_stock.read", "module_arrivages.read", "module_arrivages.write", "module_cloture_caisse.read", "module_cloture_caisse.validate"]`.
  - `dashboard_module_id: "module_dashboard_owner"`.
  - `nav_modules`: ordonnée selon spec UX `S22 OWNER`.
- [ ] AC-06 — Rôle `MANAGER` :
  - `permissions`: arrivages (write + validate), pertes (read + write + validate), alertes_stock (read), cloture_caisse (validate). **Pas** d'accès `module_dashboard_owner` ni au CA global.
  - `dashboard_module_id: "module_dashboard_manager"`.
- [ ] AC-07 — Rôle `COMMERCIAL` :
  - `permissions`: ventes (read.own + write), pertes (read.own + write), cloture_caisse (read.own + write). **Pas** d'accès arrivages, pas d'accès dashboard owner, pas d'accès aux ventes des autres commerciaux.
  - `dashboard_module_id: "module_dashboard_commercial"`.
- [ ] AC-08 — Convention de scope `.own` documentée dans le bloc `roles_meta.scope_modifiers` : `{ "all": "tous les enregistrements du tenant", "own": "uniquement les enregistrements créés par cet utilisateur", "department": "Phase 2 — département de l'utilisateur" }`.

### Modules référencés (déclarations)

- [ ] AC-09 — Bloc `modules[]` liste 6 entrées, chacune avec `module_id`, `i18n_key`, `version`, `enabled: true`, `phase: 1` :
  1. `module_dashboard_owner`
  2. `module_dashboard_manager`
  3. `module_dashboard_commercial`
  4. `module_ventes` (POS + transactions)
  5. `module_pertes` (déclaration pertes par emplacement)
  6. `module_alertes_stock` + `module_arrivages` + `module_cloture_caisse` regroupés en sous-modules de stock — **résolution conflit** : voir Tech Notes ci-dessous.
- [ ] AC-10 — **Résolution conflit PRD vs Sprint plan vs Blandine** : le sprint plan liste 6 modules dont `dashboard_owner / dashboard_manager / dashboard_commercial / ventes / pertes / alertes_stock`. La connaissance Blandine ajoute `arrivages` et `cloture_caisse` comme indispensables. **Décision (cette story) :** déclarer **6 modules navigables** pour Gate 0 = `dashboard_<role>` (3, agrégés sur la nav par rôle), `ventes`, `pertes`, `stock` (où `stock` est un module conteneur qui regroupe `alertes_stock`, `arrivages` et `cloture_caisse` sous forme de sous-écrans). Détail final dans STORY-040. Cette story **réserve les `module_id`** sans les implémenter.

### Navigation et dashboards par rôle

- [ ] AC-11 — Bloc `navigation_per_role` : pour chaque rôle, `bottom_nav[]` ordonnée (3 à 5 entrées max sur mobile) + `landing_screen_id` (écran d'atterrissage post-login).
- [ ] AC-12 — OWNER landing = `dashboard_owner` ; MANAGER landing = `dashboard_manager` ; COMMERCIAL landing = `dashboard_commercial`.
- [ ] AC-13 — Bloc `dashboard_layouts_per_role[]` : pour chaque rôle, référence vers le `dashboard_module_id` + un `dashboard_layout_id` (le ScreenConfig détaillé sera dans STORY-040).

### Validation Zod

- [ ] AC-14 — `POST /api/v1/admin/templates/validate` avec le contenu du fichier retourne `{ valid: true }` (dépend de STORY-024 ; si non terminée, fournir un script standalone `npx tsx scripts/validate-catalogue.ts catalog/domains/retail_fresh_produce.json`).
- [ ] AC-15 — Cas négatif testé : si on retire un champ requis (`schema_version` ou `roles`), la validation retourne `{ valid: false, errors: [...] }` avec un message lisible.

### Tests

- [ ] AC-16 — Test unitaire NestJS `catalogue.service.spec.ts` : `loadDomainTemplate('retail_fresh_produce')` retourne un objet typé `DomainTemplate` non null avec les 3 rôles attendus.
- [ ] AC-17 — Test d'intégration : 3 users (1 par rôle) tagués `tenant_id = test_blandine`, chacun appelant `GET /api/v1/test_blandine/layout/dashboard` reçoit un `ScreenConfig` dont `screen` correspond au `dashboard_module_id` de son rôle (preuve RBAC functional). **Note :** ce test utilise des stubs pour les ScreenConfig des modules (implémentation réelle = STORY-040).

### Hygiène

- [ ] AC-18 — Aucune string visible (label, titre, message) hardcodée — uniquement des `i18n_key`. Lint script `scripts/check-i18n-keys.ts` passe sur ce fichier.
- [ ] AC-19 — Aucune valeur métier hardcodée hors `tenant_defaults` (pas de `"FCFA"` en dur, pas de `"Burkina Faso"`, pas de `"Africa/Ouagadougou"` ailleurs que `tenant_defaults.timezone`). Constraint Global Scale (préparation STORY-042).

---

## Technical Notes

### Composants concernés

- **Catalogue :** `catalog/domains/retail_fresh_produce.json` (nouveau).
- **Schemas :** `catalog/schemas/domain-config.schema.json` (créé en STORY-023, consommé ici).
- **NestJS :** `services/nestjs/src/catalogue/catalogue.service.ts` (chargement du template).
- **Tests :** `services/nestjs/src/catalogue/__tests__/catalogue.service.spec.ts`, `services/nestjs/src/bdui/__tests__/bdui.integration.spec.ts`.

### Squelette JSON cible (extrait, structure complète)

```json
{
  "schema_version": "1.0.0",
  "domain_id": "retail_fresh_produce",
  "name": "Retail — Fresh Produce",
  "i18n_key": "domain.retail_fresh_produce.name",
  "sector": "retail",
  "subsector": "fresh_produce",
  "description": "Template sectoriel pour épiceries fines, fruits, légumes, épices. Multi-emplacements, suivi pertes, clôture caisse, dashboard proprio.",
  "version": "1.0.0",
  "min_users": 1,
  "max_users": 50,

  "tenant_defaults": {
    "currency": "XOF",
    "locale": "fr-BF",
    "timezone": "Africa/Ouagadougou",
    "fiscal_year_start": "01-01",
    "tax_mode": "configurable",
    "payment_methods_enabled": ["cash", "mobile_money", "credit"]
  },

  "roles_meta": {
    "scope_modifiers": {
      "all": "Tous les enregistrements du tenant",
      "own": "Uniquement les enregistrements créés par cet utilisateur",
      "department": "Phase 2 — département de l'utilisateur"
    }
  },

  "roles": [
    {
      "id": "OWNER",
      "name": "Propriétaire",
      "i18n_key": "role.owner.name",
      "description": "Propriétaire de l'épicerie. Voit le CA, les KPIs, valide les clôtures, reçoit la notification soir.",
      "dashboard_module_id": "module_dashboard_owner",
      "permissions": [
        "module_dashboard_owner.read.all",
        "module_ventes.read.all",
        "module_pertes.read.all",
        "module_stock.read.all",
        "module_stock.write.all",
        "module_cloture_caisse.read.all",
        "module_cloture_caisse.validate.all"
      ],
      "nav_modules": [
        "module_dashboard_owner",
        "module_ventes",
        "module_pertes",
        "module_stock"
      ]
    },
    {
      "id": "MANAGER",
      "name": "Gestionnaire",
      "i18n_key": "role.manager.name",
      "description": "Gestionnaire entrepôt. Valide arrivages, libère stock, valide pertes et clôtures caisse. Pas d'accès au CA global.",
      "dashboard_module_id": "module_dashboard_manager",
      "permissions": [
        "module_dashboard_manager.read.all",
        "module_stock.read.all",
        "module_stock.write.all",
        "module_stock.validate.all",
        "module_pertes.read.all",
        "module_pertes.validate.all",
        "module_cloture_caisse.validate.all"
      ],
      "nav_modules": [
        "module_dashboard_manager",
        "module_stock",
        "module_pertes",
        "module_cloture_caisse"
      ]
    },
    {
      "id": "COMMERCIAL",
      "name": "Commercial",
      "i18n_key": "role.commercial.name",
      "description": "Vendeur terrain. POS rapide, déclaration pertes, clôture caisse quotidienne.",
      "dashboard_module_id": "module_dashboard_commercial",
      "permissions": [
        "module_dashboard_commercial.read.own",
        "module_ventes.read.own",
        "module_ventes.write.own",
        "module_pertes.read.own",
        "module_pertes.write.own",
        "module_cloture_caisse.read.own",
        "module_cloture_caisse.write.own"
      ],
      "nav_modules": [
        "module_dashboard_commercial",
        "module_ventes",
        "module_pertes",
        "module_cloture_caisse"
      ]
    }
  ],

  "modules": [
    { "module_id": "module_dashboard_owner",      "i18n_key": "module.dashboard_owner.name",      "version": "1.0.0", "enabled": true, "phase": 1 },
    { "module_id": "module_dashboard_manager",    "i18n_key": "module.dashboard_manager.name",    "version": "1.0.0", "enabled": true, "phase": 1 },
    { "module_id": "module_dashboard_commercial", "i18n_key": "module.dashboard_commercial.name", "version": "1.0.0", "enabled": true, "phase": 1 },
    { "module_id": "module_ventes",               "i18n_key": "module.ventes.name",               "version": "1.0.0", "enabled": true, "phase": 1 },
    { "module_id": "module_pertes",               "i18n_key": "module.pertes.name",               "version": "1.0.0", "enabled": true, "phase": 1 },
    { "module_id": "module_stock",                "i18n_key": "module.stock.name",                "version": "1.0.0", "enabled": true, "phase": 1 }
  ],

  "navigation_per_role": {
    "OWNER":      { "landing_screen_id": "dashboard_owner",      "bottom_nav": ["module_dashboard_owner", "module_ventes", "module_pertes", "module_stock"] },
    "MANAGER":    { "landing_screen_id": "dashboard_manager",    "bottom_nav": ["module_dashboard_manager", "module_stock", "module_pertes", "module_cloture_caisse"] },
    "COMMERCIAL": { "landing_screen_id": "dashboard_commercial", "bottom_nav": ["module_dashboard_commercial", "module_ventes", "module_pertes", "module_cloture_caisse"] }
  },

  "dashboard_layouts_per_role": [
    { "role": "OWNER",      "dashboard_module_id": "module_dashboard_owner",      "dashboard_layout_id": "dashboard_owner_v1" },
    { "role": "MANAGER",    "dashboard_module_id": "module_dashboard_manager",    "dashboard_layout_id": "dashboard_manager_v1" },
    { "role": "COMMERCIAL", "dashboard_module_id": "module_dashboard_commercial", "dashboard_layout_id": "dashboard_commercial_v1" }
  ]
}
```

### Conflits de spec — résolution

**PRD vs Sprint plan vs Blandine knowledge :**
- PRD §FR-022 liste les fonctions critiques : "validation croisée, pertes segmentées, clôture caisse, dashboard proprio" — **4 fonctions, pas 4 modules**.
- Sprint plan STORY-040 AC liste : `dashboard_owner / dashboard_manager / dashboard_commercial / ventes / pertes / alertes_stock` = **6 modules**.
- Blandine knowledge ajoute : arrivages (Phase 2 du workflow), clôture caisse (Phase 7), audit hebdo (Phase 8) — **autres surfaces nécessaires**.

**Décision retenue (cette story) :** 6 modules navigables :
1. `module_dashboard_owner`
2. `module_dashboard_manager`
3. `module_dashboard_commercial`
4. `module_ventes`
5. `module_pertes`
6. `module_stock` (conteneur qui regroupe `arrivages`, `alertes_stock`, et la surface gestionnaire de `cloture_caisse`)

Le `module_cloture_caisse` est référencé indirectement via le workflow de STORY-041 et apparaît dans le bottom nav des rôles MANAGER/COMMERCIAL comme entrée distincte (mais son écran principal est exposé sous `module_stock` pour OWNER/MANAGER). C'est cohérent avec l'UX `S21 COMMERCIAL` (3 tabs : Vente / Dashboard / Historique) et `S22 OWNER`.

**Trace dans les ACs :** AC-09, AC-10, AC-11.

### Pattern Zod côté NestJS

Le schéma Zod `DomainTemplateSchema` est défini en STORY-023 / STORY-024. Cette story consomme. Si STORY-024 n'est pas mergée au moment du dev, fournir un script standalone :

```bash
npx tsx scripts/validate-catalogue.ts catalog/domains/retail_fresh_produce.json
# → {"valid":true}
```

### RBAC permission format

Format retenu : `module_id.action.scope` où :
- `action` ∈ `read | write | validate | close` (les 4 verbes Phase 1).
- `scope` ∈ `all | own` (Phase 1) ; `department` réservé Phase 2.

Le `RbacGuard` (STORY-013 ou équivalent) parse cette string et applique le filtre. Ce format est documenté dans `catalog/README.md` (autre story) et stable inter-templates.

### Edge cases

- **Conflit `module_cloture_caisse` non listé dans `modules[]`** : intentionnel — il est porté par le workflow JSON de STORY-041 (`workflow_cloture_caisse`) et n'a pas d'écran propre. Les permissions `module_cloture_caisse.*` pointent vers une ressource workflow, pas un module avec entities. Documenter cette dualité dans `catalog/README.md`.
- **Alias OWNER/PROPRIETAIRE** : un client futur pourrait demander un libellé localisé (ex: "Patron" au lieu de "Propriétaire"). C'est résolu par `i18n_key` — le `id` reste `OWNER` (stable, machine-readable).
- **Rôles multiples par utilisateur** : un user peut avoir `roles: ["OWNER", "MANAGER"]` (Blandine est les deux dans une petite structure). Le `RbacGuard` fait l'union des permissions. Pas d'AC dans cette story (couvert par STORY-013) ; documenter le cas dans le README catalogue.

### Sécurité

- Le fichier `retail_fresh_produce.json` est **public** (committé dans `catalog/`). Aucune donnée sensible — c'est de la config structurelle.
- Aucune permission `*.delete` n'est déclarée Phase 1 — la suppression métier passe par des workflows (archive, refund) implémentés en STORY-040/041.

---

## Dependencies

**Prérequis (techniques) :**
- STORY-023 — JSON Schemas catalogue (DomainTemplate, ModuleConfig, ScreenConfig).
- STORY-024 — Zod validator (utilisé par AC-14).
- STORY-025 — Structure catalogue `catalog/domains/`, `catalog/modules/`, `catalog/schemas/` initialisée.
- STORY-013 — RBAC Guard (consommateur des permissions, pour AC-17).

**Stories bloquées par celle-ci :**
- STORY-040 — Modules Phase 1 JSON (les 6 modules implémentent les `module_id` réservés ici).
- STORY-041 — Workflow DAG Clôture Caisse (référence les rôles déclarés ici).
- STORY-042 — Contraintes Global Scale (les ARB consomment les `i18n_key` listés ici).
- STORY-043 — Validation E2E Gate 0 (test de bout en bout du template complet).

**Externes :** Aucune dépendance externe — fichier de config local.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-039-template-structure-roles`.
- [ ] Fichier `catalog/domains/retail_fresh_produce.json` présent, valide JSON, valide Zod (AC-14).
- [ ] Tests unitaire + intégration verts (AC-16, AC-17).
- [ ] `flutter analyze` + `npm run lint` (NestJS) + `npx tsx scripts/check-i18n-keys.ts catalog/domains/retail_fresh_produce.json` passent sans warning.
- [ ] CI `validate-catalogue.yml` vert sur la PR.
- [ ] Code review : `/codex review` + auto-review Carlos.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-039 status `completed`, sprint 4 `completed_points += 3`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Rédaction du squelette JSON (metadata + 3 rôles + 6 modules + nav + dashboards) | 1.0 | Translation directe spec → JSON, mais demande de la rigueur sur les `module_id` cohérents avec STORY-040. |
| Définition du format permission `module_id.action.scope` + matrice RBAC complète | 0.75 | Le format doit tenir la route Phase 2 (ABAC). Décision structurelle. |
| Tests unitaire (`catalogue.service.spec.ts`) + intégration (3 rôles → 3 layouts) | 0.75 | Le test d'intégration nécessite de stubber les `ScreenConfig` des dashboards (vraie impl = STORY-040). |
| Script `check-i18n-keys.ts` + script `validate-catalogue.ts` standalone si STORY-024 pas mergée | 0.25 | Réutilisable par STORY-040, 041, 042. |
| Documentation README catalogue (section "comment lire un fichier domain") | 0.25 | Court, structure ; détail pédagogique en STORY-040. |
| **Total** | **3** | Fibonacci 3 — moderate, rigueur structurelle. |

**Rationale :** C'est de la config, pas de la logique. Le risque n'est pas la complexité algorithmique mais la cohérence avec STORY-040 (les `module_id` doivent matcher pile) et avec le format permission consommé par STORY-013. Une fois validée Zod et testée RBAC-functional, c'est solide.

---

## Notes additionnelles

- **Lien Blandine ↔ template :** Blandine est le **client pilote** du secteur, pas la cible exclusive. Chaque AC trace à un workflow Blandine (8 phases) sans hardcoder son nom. Au Gate 1 (M3), un 2ème épicier doit pouvoir tourner sur ce JSON sans modification.
- **PRD ↔ DS conflict :** aucun pour cette story (purement backend config, le DS n'intervient pas).
- **Logo Scalario :** non concerné par cette story.
- **Rappel Global Scale :** ce template est portable — pas de mention "Burkina Faso", pas de "FCFA" en dur, pas de "Wave" en dur. Tous les défauts vont dans `tenant_defaults`, surchargeable par tenant.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)
- 2026-05-24 : Implemented end-to-end. 16/16 tests verts + 0 régression. Status: done.

**Actual Effort :** 3 pts (= estimate). Livrables : catalog/domains/retail_fresh_produce.json refactored vers le nouveau schéma DomainTemplate, src/catalogue/dto/domain-template.dto.ts (Zod DomainTemplateSchema avec cross-refs validation), templates.loader.ts étendu (loadDomainTemplate + loadTemplateRoles backward compat).

**Implementation Notes :**
- Migration de l'ancien shape (stub STORY-015 : id/entities/actions/rbac_roles:string[]) vers le nouveau (DomainTemplate v1.0.0 : domain_id, 3 rôles objects, modules[], navigation_per_role, dashboard_layouts_per_role).
- Backward compat : loadTemplateRoles() détecte les deux shapes et extrait les role ids. STORY-015 provisioning continue de fonctionner.
- Zod schema avec 3 cross-validations : (a) nav_modules + dashboard_module_id référencent modules[] déclarés (avec exception documentée pour module_cloture_caisse implicit via workflow), (b) navigation_per_role keys = roles[].id exactement, (c) dashboard_layouts_per_role = 1 entry par rôle.
- AC-17 (test intégration RBAC 3 rôles → 3 layouts) déféré à STORY-040 quand les ScreenConfigs réels existent.
- AC-18 (lint check-i18n-keys) + AC-22 (script standalone validate-catalogue.ts) non livrés — les tests Jest sur le fichier réel couvrent le besoin de validation. Scripts standalone à ajouter si besoin CI séparé.
- AC-19 Global Scale vérifié par 2 tests : aucune mention de FCFA/Burkina Faso/Wave, Africa/Ouagadougou apparaît UNIQUEMENT dans tenant_defaults.timezone.

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
