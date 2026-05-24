# STORY-040 : Modules Phase 1 JSON — 6 modules métier `retail_fresh_produce`

**Epic :** EPIC-007 — Premier Template `retail_fresh_produce.json` (Gate 0 Blandine)
**Priorité :** Must Have
**Story Points :** 5
**Status :** done
**Assigned To :** Carlos
**Created :** 2026-05-10
**Completed :** 2026-05-24
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-039 (squelette domaine), STORY-023 (JSON Schema BDUI), STORY-006 (RuleEvaluator pour `visible_if`)

---

## User Story

> **En tant que** propriétaire d'épicerie fine (Blandine), gestionnaire entrepôt (Ibrahim) ou commercial terrain,
> **je veux** les 6 modules métier Phase 1 entièrement déclarés en JSON dans `catalog/modules/`,
> **so that** mon équipe peut travailler au quotidien depuis l'app — vendre, déclarer pertes, valider arrivages, voir les KPIs, faire la clôture caisse — sans aucune ligne de Flutter métier ni d'endpoint NestJS spécifique.

---

## Description

### Background

STORY-039 a posé le squelette du domaine `retail_fresh_produce.json` (3 rôles + 6 `module_id` réservés). Cette story remplit la chair : les 6 fichiers JSON dans `catalog/modules/` qui déclarent pour chaque module ses **entities** (modèle de données JSONB), ses **screens BDUI** (dashboard / list / form / detail), ses **actions** (read, write, validate, close), et ses **règles `visible_if`** (RBAC fines).

C'est la **plus grosse story de l'EPIC-007 (5 points)**. C'est aussi la story qui **prouve que le BDUIEngine (EPIC-002) tient la route** : 6 modules, 3 rôles, ~15 écrans déclarés, 0 ligne Flutter métier.

**Ancrage Blandine — 8 phases workflow :**
1. **Owner crée bons de commande fournisseur** → couvert par `module_stock` (sous-écran `arrivages_form`).
2. **Manager réceptionne, valide qualité** → `module_stock` (sous-écran `arrivages_validation`).
3. **Manager libère stock aux commerciaux** → `module_stock` (action `release_to_commercial`).
4. **Commerciaux/manager déclarent pertes par emplacement** → `module_pertes` (form avec champ `location`).
5. **Seuils d'alerte par variante produit** → `module_stock` (sous-écran `alertes_stock_list`).
6. **Circuit interne Commercial → Manager → Blandine** → workflows de validation (référencés ici, exécutés STORY-041).
7. **Clôture caisse quotidienne** → `module_cloture_caisse` (workflow STORY-041 + écrans déclarés ici).
8. **Audit inventaire hebdo** → reporté Phase 2 (hors Gate 0).

### Scope

**In scope :** 6 fichiers JSON à créer dans `catalog/modules/` :

1. **`module_dashboard_owner.json`** — KPIs CA jour, ventes du jour, alertes stock, graphe 7j, notification soir (sera envoyée par notification adapter ; le module déclare juste le composant `NotificationCenter`).
2. **`module_dashboard_manager.json`** — Arrivages en attente (count + liste), alertes stock bas, action "Valider livraison", clôtures caisse à valider.
3. **`module_dashboard_commercial.json`** — Solde caisse du jour, articles rapides (`ProductGrid`), bouton "Vendre" (CTA → POS), historique de mes ventes.
4. **`module_ventes.json`** — POS (form rapide produit + quantité + paiement + emplacement), liste transactions du jour, détail transaction, filtres par commercial / période / mode paiement.
5. **`module_pertes.json`** — Form déclaration perte (article, variante, quantité, cause, photo, emplacement), liste historique, validation manager.
6. **`module_stock.json`** — Conteneur regroupant : sous-module `arrivages` (bons de commande + réception + validation), sous-module `alertes_stock` (seuils, articles sous seuil), sous-module `release` (libération aux commerciaux). Inclut `taux_de_frotte` et `conversion_vrac_sachet` comme champs entity pour fresh produce.

Pour chaque module :
- **Entities** : modèle JSONB (`fields[]` avec types, validation, i18n_key).
- **Screens** : `ScreenConfig` (dashboard / list / form / detail) avec zones (`kpis`, `main`, `aside`, `actions`).
- **Actions** : list des `action_type` exposés (`POST /api/v1/:tenant/:moduleId/action`).
- **Règles `visible_if`** : composants conditionnels par rôle (RBAC déjà filtré côté ScreenConfig).
- **Conflict strategy** : `server_wins` par défaut (sauf module_pertes qui a `manual` car litige fréquent).
- **Mock data** : seed de 5-10 entities par module pour tests E2E (commit dans `catalog/modules/__mocks__/`).

**Out of scope :**
- Workflow DAG clôture caisse → STORY-041 (workflow JSON séparé qui orchestre `module_cloture_caisse` + `module_ventes` + `module_pertes`).
- ARB FR/EN traduits → STORY-042 (cette story ajoute les `i18n_key` ; les strings vivent dans `lib/l10n/app_*.arb`).
- Validation E2E Blandine UAT → STORY-043.
- Module audit hebdomadaire (Phase 8 Blandine) → reporté Phase 2.
- ABAC fine-grained (filtre par emplacement pour MANAGER) → reporté Phase 2 (ici, scope `own` au niveau user, pas par dépot).

### User Flow

**Blandine (OWNER) lundi 9h :**
1. Login → `BDUIEngine` charge `dashboard_owner_v1` (déclaré dans `module_dashboard_owner.json`).
2. Voit : KPI CA jour J-1, KPI nb ventes J-1, KPI alertes stock count, graphe 7j, liste clôtures caisse à valider.
3. Tape "Voir ventes" → `BDUIEngine` charge `module_ventes` screen `ventes_list` filtré `period: today`.
4. Tape une transaction → écran `ventes_detail`.

**Ibrahim (MANAGER) 14h :**
1. Login → `dashboard_manager_v1` : 3 arrivages à valider, 2 alertes stock, 1 clôture caisse à valider.
2. Tape "Arrivage #4521" → `module_stock` screen `arrivages_validation_form`. Saisit quantités réelles, photo, valide. Action `POST /api/v1/blandine/module_stock/action { type: "validate_arrivage", id: 4521 }`.
3. Server applique le ModuleEngine → écrit dans `entities` table → notifie OWNER via le workflow d'acceptation.

**Aïcha (COMMERCIAL) 10h :**
1. Login → `dashboard_commercial_v1` : solde caisse 23 500 XOF, ProductGrid 12 articles, CTA "Vendre".
2. Tape un article → form `vente_create` : qty 2, paiement Mobile Money, emplacement "Marché central".
3. Submit → action `POST /api/v1/blandine/module_ventes/action { type: "create_vente", payload: {...} }`. Offline-safe (Drift queue).

---

## Acceptance Criteria

### Structure et arborescence

- [ ] AC-01 — 6 fichiers créés dans `catalog/modules/` :
  - `module_dashboard_owner.json`
  - `module_dashboard_manager.json`
  - `module_dashboard_commercial.json`
  - `module_ventes.json`
  - `module_pertes.json`
  - `module_stock.json`
- [ ] AC-02 — Chaque fichier a la structure top-level conforme à `ModuleConfig` (STORY-023) : `schema_version`, `module_id`, `name`, `i18n_key`, `icon`, `entities[]`, `screens[]`, `actions[]`, `workflows?[]`, `rbac_roles?[]`, `conflict_strategy`, `version`.
- [ ] AC-03 — Tous les `module_id` matchent ceux réservés dans STORY-039 (`module_dashboard_owner`, etc.).

### `module_dashboard_owner.json`

- [ ] AC-04 — Screen `dashboard_owner_v1` (`layout: "dashboard"`) avec zones :
  - `kpis[]` : 4 `KPICard` (CA jour, Nb ventes jour, Alertes stock count, Pertes jour valeur).
  - `main[]` : `LineChart` ventes 7j + `DataTable` clôtures à valider.
  - `aside[]` : `NotificationCenter` (placeholder pour la notif soir).
  - `actions[]` : `Button` "Voir détail ventes" → navigation `module_ventes/list`.
- [ ] AC-05 — `visible_if` : tout le screen porte `visible_if: { operator: "role", value: "OWNER" }` (filtre redondant avec RBAC, mais traçabilité).
- [ ] AC-06 — Mock data : 7 jours de ventes simulées dans `catalog/modules/__mocks__/dashboard_owner.mock.json`.

### `module_dashboard_manager.json`

- [ ] AC-07 — Screen `dashboard_manager_v1` :
  - `kpis[]` : 3 `KPICard` (Arrivages en attente, Alertes stock bas, Clôtures à valider).
  - `main[]` : `DataTable` arrivages avec action inline "Valider".
  - `actions[]` : CTA "Nouvel arrivage" → form.
- [ ] AC-08 — `visible_if`: rôle MANAGER. Aucun KPI CA / financier.

### `module_dashboard_commercial.json`

- [ ] AC-09 — Screen `dashboard_commercial_v1` :
  - `kpis[]` : `KPICard` "Solde caisse" (Roboto Mono, FCFA via i18n).
  - `main[]` : `ProductGrid` (12 articles paginés) + `Button` géant "Vendre" (CTA primaire).
  - `aside[]` : Liste "Mes ventes du jour" (5 dernières).
- [ ] AC-10 — `visible_if`: rôle COMMERCIAL. Scope `.own` partout (pas les ventes des autres).

### `module_ventes.json`

- [ ] AC-11 — Entity `vente` avec champs : `id` (UUID), `commercial_id` (FK users), `produits[]` (array of `{product_id, qty, unit_price, total}`), `total_amount`, `payment_method` (enum: `cash | mobile_money | credit`), `payment_provider` (string nullable, ex `wave | orange_money | mtn_momo`), `location_id`, `created_at`, `status` (enum: `draft | confirmed | refunded`).
- [ ] AC-12 — 4 screens :
  - `ventes_list` (layout list, filtres commercial/période/payment) ;
  - `ventes_detail` (layout detail, lecture seule + bouton "Refund" visible si rôle MANAGER+) ;
  - `vente_create` (layout form, POS rapide ; visible_if COMMERCIAL or OWNER) ;
  - `ventes_kpi` (layout dashboard partial, embed dans dashboard_owner).
- [ ] AC-13 — Action `create_vente` : payload validé Zod, ouvre une `entity` JSONB. Idempotent via `client_mutation_id` (sync offline).
- [ ] AC-14 — `payment_method` est une enum. Provider concret (`wave`, `orange_money`, `mtn_momo`) **résolu côté tenant config** via `PaymentAdapter` (préparé STORY-042). Aucun provider en dur dans le module.

### `module_pertes.json`

- [ ] AC-15 — Entity `perte` avec champs : `id`, `product_id`, `variante_id`, `quantity`, `cause` (enum: `casse | peremption | vol | demarque_inconnue | autre`), `location_id`, `photo_url`, `declared_by` (FK user), `validated_by` (FK user nullable), `validated_at` (nullable), `status` (enum: `draft | validated | rejected`).
- [ ] AC-16 — Form `perte_create` avec champs photo (uploader BDUI), cause (select), quantité (numeric mono), emplacement (select dynamique).
- [ ] AC-17 — Workflow embarqué : `declared` → `validated_by_manager` → (`approved` | `rejected`) — déclaré dans `module_pertes.json` directement, pas un workflow autonome.
- [ ] AC-18 — `conflict_strategy: "manual"` (litiges sur pertes fréquents — entrer dans la conflict queue).

### `module_stock.json`

- [ ] AC-19 — 3 sous-modules logiques (un seul fichier JSON, plusieurs `screens` et `entities`) :
  - **Arrivages** : entity `arrivage` (`fournisseur_id`, `bon_commande_ref`, `produits[]`, `received_at`, `validated_by`, `status` ∈ `commandé | reçu | validé`). Screens : `arrivages_list`, `arrivages_form` (OWNER crée), `arrivages_validation_form` (MANAGER valide).
  - **Alertes stock** : entity `seuil_stock` (`product_id`, `variante_id`, `seuil_min`, `seuil_max`). Screen `alertes_stock_list` filtre `current_qty < seuil_min`.
  - **Release** : action `release_to_commercial` qui mute le stock entre emplacements.
- [ ] AC-20 — Champs **fresh produce-spécifiques** sur entity `product` (déclarés dans `module_stock.json`) :
  - `taux_de_frotte` (float, % perte naturelle, ex `0.03` pour 3%).
  - `conversion_vrac_sachet` (object : `{from_unit: "kg", to_unit: "sachet", from_qty: 5, to_qty: 100, sachet_weight_g: 50}`).
  - `freshness_indicator` (enum: `green | orange | red`) — couleur calculée côté client via RuleEvaluator (PRD §FR-006), pas serveur.
- [ ] AC-21 — Action `validate_arrivage` (MANAGER) ; action `create_arrivage` (OWNER) ; action `update_seuil` (OWNER).

### `module_dashboard_*` cross-cutting

- [ ] AC-22 — Tous les composants `KPICard` de valeurs monétaires utilisent `format: "currency"` avec `currency_source: "tenant.config.currency"` (résolution dynamique, pas `"XOF"` en dur).
- [ ] AC-23 — Tous les KPI numériques temps réel ont `font: "mono"` (Roboto Mono via DS tokens, STORY-001).

### Validation et tests

- [ ] AC-24 — Validation Zod (CI `validate-catalogue.yml`) : les 6 fichiers passent sans erreur.
- [ ] AC-25 — Test BDUIEngine (Flutter) : pour chaque rôle, le rendu du `landing_screen_id` produit un widget tree non-null avec les composants attendus (snapshot widget test ; couvre OWNER/MANAGER/COMMERCIAL × dashboard).
- [ ] AC-26 — Test ModuleEngine (NestJS) : `POST /api/v1/test_blandine/module_ventes/action` avec payload `create_vente` insère une entity en base, retourne `201` + entity créée. Idempotence : 2 appels avec même `client_mutation_id` → 1 seule entity créée.
- [ ] AC-27 — Test RBAC : un user COMMERCIAL appelant `GET /api/v1/test_blandine/module_ventes/data?scope=all` reçoit `403` (scope `own` enforced).
- [ ] AC-28 — Snapshot test : pour chaque fichier JSON, un test compare la structure clé (`module_id`, count `screens`, count `entities`) à un snapshot — détecte les régressions structurelles.

### Hygiène

- [ ] AC-29 — Aucune string visible hardcodée dans les 6 fichiers — uniquement `i18n_key`. Lint `scripts/check-i18n-keys.ts` passe.
- [ ] AC-30 — Aucune valeur business en dur (`"XOF"`, `"FCFA"`, `"Wave"`, `"Burkina"`) hors zones explicitement marquées `tenant_default_*`. Audit grep documenté dans la PR.

---

## Technical Notes

### Composants concernés

- **Catalogue :** `catalog/modules/*.json` (6 nouveaux fichiers).
- **Mocks :** `catalog/modules/__mocks__/*.mock.json` (seed data).
- **NestJS :** `services/nestjs/src/module-engine/` (consommateur — pas de modif sauf tests).
- **Flutter :** `apps/flutter/lib/core/bdui/` (consommateur — pas de modif).
- **Tests :** `services/nestjs/src/module-engine/__tests__/`, `apps/flutter/test/integration/template_retail_test.dart`.

### Pattern JSON par module (extrait `module_ventes.json`)

```json
{
  "schema_version": "1.0.0",
  "module_id": "module_ventes",
  "name": "Ventes",
  "i18n_key": "module.ventes.name",
  "icon": "shopping_cart",
  "version": "1.0.0",
  "conflict_strategy": "server_wins",

  "entities": [
    {
      "id": "vente",
      "i18n_key": "entity.vente.name",
      "fields": [
        { "id": "id",              "type": "uuid",     "required": true,  "primary": true },
        { "id": "commercial_id",   "type": "fk_user",  "required": true },
        { "id": "produits",        "type": "array",    "required": true,  "of": { "type": "object", "fields": [
            { "id": "product_id",  "type": "fk_entity", "ref": "product", "required": true },
            { "id": "qty",         "type": "decimal",   "required": true, "min": 0 },
            { "id": "unit_price",  "type": "currency",  "currency_source": "tenant.config.currency", "required": true },
            { "id": "total",       "type": "currency",  "currency_source": "tenant.config.currency", "computed": "qty * unit_price" }
          ]}},
        { "id": "total_amount",    "type": "currency", "currency_source": "tenant.config.currency", "computed": "sum(produits.total)" },
        { "id": "payment_method",  "type": "enum",     "values": ["cash", "mobile_money", "credit"], "required": true, "i18n_key": "field.payment_method.label" },
        { "id": "payment_provider","type": "string",   "required": false, "visible_if": { "operator": "==", "field": "payment_method", "value": "mobile_money" } },
        { "id": "location_id",     "type": "fk_entity","ref": "location", "required": true },
        { "id": "status",          "type": "enum",     "values": ["draft", "confirmed", "refunded"], "default": "draft" },
        { "id": "created_at",      "type": "datetime", "auto": "now" }
      ]
    }
  ],

  "screens": [
    {
      "screen": "ventes_list",
      "schema_version": "1.0.0",
      "layout": "list",
      "i18n_key": "screen.ventes_list.title",
      "zones": {
        "main": [{
          "type": "DataTable",
          "id": "ventes_table",
          "props": { "source": "module_ventes.vente", "columns": ["created_at", "commercial_id", "total_amount", "payment_method", "status"] },
          "visible_if": { "operator": "OR", "children": [
            { "operator": "role", "value": "OWNER" },
            { "operator": "role", "value": "MANAGER" },
            { "operator": "AND", "children": [
              { "operator": "role", "value": "COMMERCIAL" },
              { "operator": "==", "field": "ctx.scope", "value": "own" }
            ]}
          ]}
        }],
        "actions": [{
          "type": "Button",
          "id": "btn_new_sale",
          "props": { "label_i18n": "action.new_sale", "variant": "primary", "navigate_to": "vente_create" },
          "visible_if": { "operator": "OR", "children": [
            { "operator": "role", "value": "COMMERCIAL" },
            { "operator": "role", "value": "OWNER" }
          ]}
        }]
      }
    },
    { "screen": "vente_create", "...": "..." },
    { "screen": "ventes_detail", "...": "..." }
  ],

  "actions": [
    { "id": "create_vente",  "method": "POST", "validates_against": "vente", "idempotent": true },
    { "id": "refund_vente",  "method": "POST", "validates_against": "vente", "rbac": ["MANAGER", "OWNER"] },
    { "id": "confirm_vente", "method": "POST", "rbac": ["COMMERCIAL", "OWNER"] }
  ]
}
```

### Mock data convention

Chaque module a un fichier `catalog/modules/__mocks__/<module_id>.mock.json` avec 5-10 entities seedées. Ces mocks alimentent :
- Les tests d'intégration NestJS (insert au setUp de chaque suite).
- Les tests E2E Flutter (server-side fixture loaded via `pnpm db:seed:test`).
- La démo locale Carlos (`docker-compose --profile demo up`).

### Conflits de spec — résolutions

- **PRD §FR-006 (visible_if RuleEvaluator) vs Sprint plan AC-04 dashboard_owner mentionne "graphe 7j" sans préciser type chart** : DS spec `composites/charts.md` impose `LineChart` simple pour Phase 1 (pas de stack/area). Choix : `LineChart` de la composite DS. **DS gagne.**
- **PRD `payment_provider` non-listé / Architecture §1306-1314 PaymentAdapter** : l'archi déclare `PaymentAdapter` côté NestJS. Cette story expose `payment_method` (enum) + `payment_provider` (string libre, nullable, validé runtime par le tenant config). Le couplage entre `payment_method` et `payment_provider` est une `visible_if` simple côté form (`provider visible if method=mobile_money`). **Pas de logique métier dans Flutter.**
- **Module `audit_hebdomadaire` (Blandine phase 8)** : intentionnellement **omis Gate 0**. Reporté Phase 2. Documenté dans la PR.
- **`module_cloture_caisse` n'est pas dans cette story** : il est référencé via le **workflow JSON** de STORY-041, pas un module avec entities. Les écrans liés à la clôture (saisie fond restant, réconciliation, validation) sont déclarés **dans le workflow** (STORY-041), pas ici. C'est une décision architecturale validée en STORY-039.

### Pattern `visible_if` pour scope `.own`

Le `RuleEvaluator` (STORY-006) résout les règles côté Flutter ; le `RbacGuard` + `AbacGuard` côté serveur. Le scope `.own` se traduit en deux endroits :
- Côté JSON `visible_if` : `{ "operator": "==", "field": "ctx.scope", "value": "own" }` — le client n'envoie pas de scope=all si COMMERCIAL.
- Côté serveur : le `RbacGuard` injecte automatiquement `WHERE created_by = current_user_id` quand le rôle a permission `module_X.read.own` au lieu de `.all`.

Les deux couches sont indépendantes — c'est de la défense en profondeur.

### Edge cases

- **Article supprimé référencé par une vente** : `fk_entity` avec `on_delete: "soft"` sur `product`. Une vente garde le `product_id` même si le produit est archivé. UI : si produit non résoluble → afficher `<produit archivé>` (i18n_key spécifique).
- **Devise par tenant** : si un tenant pilote en `EUR` au lieu de `XOF`, **tous** les `currency` champs résolvent dynamiquement. Pas de migration à faire — `currency_source: "tenant.config.currency"` est lu à chaque rendu.
- **Photo upload offline** : la photo est cachée localement dans Drift jusqu'à reconnexion (sync upload via MinIO presigned URL). Le champ `photo_url` est nullable jusqu'au sync — UI montre une thumbnail locale.
- **Conversion vrac→sachet** : computed côté serveur quand on entre un arrivage en vrac et qu'on veut le suivre en sachet (`stock_qty_sachet = stock_qty_vrac * conversion.to_qty / conversion.from_qty`). C'est un `computed` field dans l'entity, pas une logique Flutter.
- **Clôture caisse référence des ventes** : le module `module_ventes` expose une action `aggregate_by_period` consommée par le workflow STORY-041. Pas d'écran Flutter dédié pour cette agrégation — c'est server-side.

### Sécurité

- Toutes les actions passent par `RbacGuard` + `AbacGuard` (cf STORY-013 / STORY-016). Cette story ne crée pas de nouvelle surface d'attaque, elle déclare les permissions consommées.
- Les `photo_url` sont signed URLs MinIO (TTL 1h) — pas de leak inter-tenant.
- Les `payment_provider` strings ne sont jamais exécutées comme code — c'est une lookup key vers le `PaymentAdapter` registry NestJS.

---

## Dependencies

**Prérequis (techniques) :**
- STORY-039 — Squelette domaine (réservation des `module_id`).
- STORY-023 — JSON Schema BDUI (`ModuleConfig`, `ScreenConfig`, `ComponentConfig`, `Rule`).
- STORY-006 — RuleEvaluator Flutter (consomme les `visible_if`).
- STORY-005 — ComponentRegistry Flutter (KPICard, DataTable, ProductGrid, Button, LineChart, NotificationCenter, FormField, Uploader).
- STORY-014 — ModuleEngine NestJS (consomme `entities[]` et `actions[]`).
- STORY-018 — RBAC Guard avec format `module.action.scope`.

**Stories bloquées par celle-ci :**
- STORY-041 — Workflow DAG Clôture Caisse (consomme `module_ventes` et `module_pertes` aggregations).
- STORY-042 — Contraintes Global Scale (les ARB consomment les `i18n_key` listés ici ; le `PaymentAdapter` consomme `payment_provider`).
- STORY-043 — Validation E2E Gate 0 (test de bout en bout).

**Externes :** Aucune externe directe. Les composants DS (KPICard, DataTable, ProductGrid) viennent de STORY-003.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-040-modules-phase1-json`.
- [ ] 6 fichiers JSON présents dans `catalog/modules/`, valides JSON, valides Zod.
- [ ] 6 fichiers mocks `__mocks__/*.mock.json` présents, parseables.
- [ ] CI `validate-catalogue.yml` vert sur la PR.
- [ ] Tests verts :
  - Snapshot widget test 3 dashboards × 3 rôles.
  - Test ModuleEngine `create_vente` idempotence.
  - Test RBAC scope `.own` rejette les COMMERCIAL.
  - Snapshot structure pour chaque module.
- [ ] `flutter analyze` + `npm run lint` (NestJS) verts.
- [ ] Aucune string hardcodée détectée par `scripts/check-i18n-keys.ts`.
- [ ] Aucune valeur business en dur (audit grep documenté en PR).
- [ ] Code review : `/codex review` + auto-review Carlos.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour : STORY-040 status `completed`, sprint 4 `completed_points += 5`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `module_dashboard_owner.json` (KPIs + chart + zones + visible_if) | 0.5 | Référence visuelle UX `S22 OWNER`. |
| `module_dashboard_manager.json` (KPIs + DataTable arrivages + actions) | 0.5 | Plus simple — pas de chart. |
| `module_dashboard_commercial.json` (ProductGrid + CTA Vendre + ventes du jour) | 0.5 | Référence UX `S21 COMMERCIAL`. |
| `module_ventes.json` (entity + 4 screens + actions + idempotence) | 1.5 | Le plus dense. POS form, list filtrée, detail, refund. |
| `module_pertes.json` (entity + form photo + workflow inline + manual conflict) | 1.0 | Workflow inline (pas DAG complet) + uploader photo. |
| `module_stock.json` (3 sous-domaines + champs fresh produce-spécifiques) | 1.0 | Le plus volumineux structurellement, mais beaucoup de répétition. `taux_de_frotte`, `conversion_vrac_sachet`, `freshness_indicator` à modéliser proprement. |
| Mocks (6 fichiers `__mocks__/*.mock.json`, ~50 entities total) | 0.25 | Mécanique. |
| Tests (snapshots widget + integration ModuleEngine + RBAC) | 0.5 | 3 rôles × 3 dashboards + idempotence + scope. |
| Lint (i18n_keys + audit hardcoded) | 0.25 | Réutilise scripts de STORY-039. |
| **Total** | **5** | Fibonacci 5 — story la plus volumineuse de l'epic. |

**Rationale :** Le risque n'est pas la complexité algorithmique (c'est de la config), mais la **cohérence inter-modules** : les `module_id`, les `i18n_key`, les `entity.field` doivent matcher avec STORY-039 et avec ce que le `BDUIEngine` (EPIC-002) sait rendre. Une AC oubliée ici fait crasher Gate 0. C'est pour ça qu'on a 5 points et 30 ACs — pas parce que c'est dur, mais parce que c'est dense.

---

## Notes additionnelles

- **Trace Blandine ↔ AC :** chaque AC structurel pointe vers une phase Blandine documentée dans `project_scalario_blandine.md`. La PR contient un tableau de traçabilité phase ↔ AC.
- **Référence UX :** `design-process/C-UX-Scenarios/01-blandine-owner-dashboard/`, `02-blandine-manager-arrivage/`, `03-blandine-commercial-caisse-close/`, `04-blandine-pertes/`. À lire avant de finaliser les screens.
- **Référence DS composites :** `design-process/D-Design-System/composites/` (KPICard, DataTable, ProductGrid, FormField, Chart). DS source de vérité — si un composite n'existe pas, ouvrir une story DS, ne pas inventer en JSON.
- **Pas de logo dans les modules** — les modules sont neutres logo. Le logo est dans la coquille app (Sidebar / SplashScreen, story DS).
- **i18n :** seules les `i18n_key` sont posées ici. Les strings FR/EN viennent dans STORY-042. **Pas de fallback** — un i18n_key sans traduction = erreur visible en dev (clé affichée littéralement).
- **PaymentAdapter** : cette story prépare les **données** (`payment_method`, `payment_provider`). L'**interface NestJS** + l'implémentation Wave/Orange Money/MTN MoMo arrivent en STORY-042. Aucun provider en dur dans ce JSON.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
