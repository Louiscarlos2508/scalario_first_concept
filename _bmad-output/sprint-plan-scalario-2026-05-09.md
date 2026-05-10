# Sprint Plan : Scalario — Phase 1 MVP (Gate 0)

**Date :** 2026-05-09
**Scrum Master :** Carlos Simpore
**Project Level :** 4 (plateforme complexe, multi-horizon)
**Version :** 1.0

---

## Résumé exécutif

Sprint plan pour la **Phase 1 MVP** de Scalario — le nouveau Instant Business OS construit sur architecture BDUI Engine + Catalogue JSON. Repartie de zéro (nouveau repo, aucun carry-over de l'ancien code).

**Contrainte critique :** Gate 0 = **8 juillet 2026** — Blandine live sur `retail_fresh_produce.json`, 4 fonctions critiques opérationnelles. Date non-négociable.

**Avantage clé :** Le Design System est entièrement spécifié dans `design-process/D-Design-System/` (tokens, composants, composites, sketches hi-fi, UX rules). Les histoires EPIC-001 et EPIC-002 s'implémentent depuis des specs déjà validées.

**Métriques clés :**
- Stories totales Phase 1 : **43 stories** (40 committed + 3 stretch)
- Points totaux : **172pts** (159pts committed + 13pts stretch)
- Sprints : **4 × 2 semaines**
- Capacité : **~42pts/sprint** (solo dev AI-augmenté, 5.5h/jour)
- Utilisation capacité : **95%** (avec stretch) / **88%** committed seul
- Date cible Gate 0 : **8 juillet 2026**

---

## Inventaire des Stories

### EPIC-001 — Design System Scalario
**FRs :** FR-005, FR-007 | **Phase :** 1 MVP | **Priorité :** Must Have

> **Base UI :** Material 3 natif Flutter + ThemeData Scalario depuis les tokens. Zéro dépendance UI externe.

#### STORY-001 : Design Tokens Flutter
**Epic :** EPIC-001 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que dev, je veux un système de tokens Scalario centralisé so that tous les composants partagent automatiquement la même palette, typographie et espacements sans valeurs hardcodées.

**Acceptance Criteria :**
- [ ] Couleurs sémantiques définies : `primary`, `success`, `danger`, `warning`, `surface`, `onSurface`, `background`
- [ ] Typographie : Inter — h1 (24px semi-bold), h2 (18px semi-bold), body (14px regular), caption (12px regular), mono (Roboto Mono 13px)
- [ ] Spacing scale 4px : xs=4, sm=8, md=16, lg=24, xl=32, xxl=48, xxxl=64
- [ ] Icons : bibliothèque Material Icons + tokens taille (sm=16, md=24, lg=32, xl=48)
- [ ] Palette dark-first + light mode — dual theme configurable
- [ ] Aucune couleur ou taille hardcodée dans un widget (linting rule)

**Technical Notes :** Implémenter depuis `design-process/D-Design-System/tokens/` (colors.md, typography.md, spacing.md, icons.md). ThemeData Flutter + ThemeExtensions.

**Dependencies :** Aucune

---

#### STORY-002 : Material 3 + ThemeData Scalario

**Epic :** EPIC-001 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que dev, je veux que les primitives Material 3 Flutter soient configurées avec le thème Scalario so that tous les composants de plus haut niveau s'appuient sur une base cohérente sans dépendance externe.

**Acceptance Criteria :**

- [ ] `ThemeData` Scalario configuré depuis les tokens (STORY-001) — `ColorScheme`, `TextTheme`, `IconTheme`
- [ ] `ThemeExtensions` custom pour les tokens spécifiques (couleurs sémantiques sync/conflict, spacing scale)
- [ ] Primitives Material 3 utilisées : `FilledButton`, `OutlinedButton`, `TextButton`, `Card`, `DataTable`, `Badge`, `TextField`, `DropdownMenu`, `Dialog`
- [ ] Variants Scalario : `primary` / `secondary` / `ghost` / `danger` mappés sur les variantes Material 3
- [ ] Aucune valeur hardcodée — tout depuis le thème (vérifié par lint)
- [ ] Dark mode fonctionnel + transition fluide light↔dark
- [ ] Aucune dépendance UI externe — uniquement le SDK Flutter et Material 3 natif

**Technical Notes :** On reste sur Material 3 natif Flutter — déjà flat, accessible, à jour. Le DS Scalario s'applique via `ThemeData` + `ThemeExtensions`. Référence : `design-process/D-Design-System/components/05-actions.md`.

**Dependencies :** STORY-001

---

#### STORY-003 : Composants BDUI Métier
**Epic :** EPIC-001 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que moteur BDUI, je veux les composants métier Scalario implémentés so that le ComponentRegistry peut instancier n'importe lequel depuis un type string JSON.

**Acceptance Criteria :**
- [ ] `KPICard` : valeur + label + tendance + couleur sémantique + état loading/vide/erreur
- [ ] `DataTable` : colonnes configurables + tri + pagination + état vide
- [ ] `AlertBanner` : severity (info/warning/danger/success) + message + action CTA
- [ ] `FAB` (Floating Action Button) : icône + label + position bas-droite configurable
- [ ] `ListTile` : leading/title/subtitle/trailing + tap callback configurable
- [ ] `FormSection` : titre section + champs groupés
- [ ] `ChartBar` : données + labels + couleur + légende
- [ ] Chaque composant a ses états : Normal, Warning, Danger, Loading, Vide, Erreur

**Technical Notes :** Référence exhaustive : `design-process/D-Design-System/components/` (01 à 10). Chaque composant = classe Dart standalone + paramètres depuis `ComponentConfig` JSON.

**Dependencies :** STORY-001, STORY-002

---

#### STORY-004 : Showcase Files + Flutter Widget Preview + Thème Global

**Epic :** EPIC-001 | **Priorité :** Must Have | **Points :** 4

**User Story :**
En tant que dev, je veux un fichier showcase par composant (pattern `_<feature>_showcase.dart`) avec annotations `@Preview` Light + Dark + main() runnable so that je peux visualiser chaque composant soit dans l'IDE (widget-preview), soit en standalone Flutter app, sans setup additionnel.

**Acceptance Criteria :**

- [ ] Pattern Santera adopté (référence : projet `recherchelivraisonmedicament`) — un fichier `_<feature>_showcase.dart` par composant BDUI
- [ ] Header standardisé avec commandes : `// Run: flutter run --target=lib/.../X_showcase.dart` + `// Preview: flutter widget-preview start`
- [ ] Import `package:flutter/widget_previews.dart` + helpers `PreviewThemeData scalarioXThemes()` + `Widget scalarioXWrap(child)`
- [ ] `@Preview` : **un seul** par variant (sm/md/lg, loading, disabled, etc.) — pas de duplication Light/Dark
- [ ] `main()` standalone : `MaterialApp` avec **toggle dark/light dans AppBar** (c'est là qu'on switche les modes, pas dans `@Preview`)
- [ ] Tous les composants BDUI de STORY-003 ont leur showcase : KPICard, DataTable, AlertBanner, FAB, ListTile, FormSection, ChartBar
- [ ] `ThemeData` Scalario depuis tokens (STORY-001) — hot reload dev
- [ ] Compositions showcases : `_dashboard_owner_showcase.dart`, `_pos_commercial_showcase.dart`, etc.
- [ ] Widgetbook gardé en backup pour galerie CI + snapshot tests non-régression visuelle

**Technical Notes :**

Pattern de référence (fichier `_buttons_showcase.dart` du projet santera) :

```dart
// Run:     flutter run --target=lib/.../X_showcase.dart
// Preview: flutter widget-preview start
import 'package:flutter/widget_previews.dart';

PreviewThemeData scalarioXThemes() => PreviewThemeData(
      materialLight: buildLightTheme(),
      materialDark: buildDarkTheme(),
    );

Widget scalarioXWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(padding: EdgeInsets.all(16), child: child),
    );

@Preview(name: 'X', theme: scalarioXThemes, wrapper: scalarioXWrap)
Widget previewX() => const _XSection();

void main() => runApp(const _XShowcaseApp()); // standalone — toggle dark/light dans AppBar
```

**Dependencies :** STORY-001, STORY-002, STORY-003

---

### EPIC-002 — BDUI Engine Flutter
**FRs :** FR-001, FR-001b, FR-002, FR-003, FR-004, FR-006, FR-050, FR-051 | **Phase :** 1 MVP | **Priorité :** Must Have

#### STORY-005 : ComponentRegistry
**Epic :** EPIC-002 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que BDUIEngine, je veux un registry extensible so that n'importe quel type string depuis le JSON est résolu en widget Flutter builder sans modifier l'Engine.

**Acceptance Criteria :**
- [ ] `ComponentRegistry.build(config, ctx)` résout tout type enregistré en widget
- [ ] Type inconnu → `UnknownComponent` affiché (message clair, jamais crash)
- [ ] Nouveau composant = 1 ligne `registry.register("type", builder)`, aucun autre changement
- [ ] Composants initiaux enregistrés : KPICard, DataTable, AlertBanner, FAB, ListTile, FormSection, ChartBar
- [ ] Tests unitaires : rendu nominal + type inconnu + composant null config

**Technical Notes :** Pattern Registry/Factory. Le registry est un singleton injecté par DI. `ComponentConfig` est le contrat d'entrée (issu de STORY-023 JSON Schema).

**Dependencies :** STORY-003

---

#### STORY-006 : RuleEvaluator
**Epic :** EPIC-002 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que BDUIEngine, je veux évaluer les règles `visible_if` du JSON so that les composants se masquent/affichent selon le rôle utilisateur sans aucun `if` métier dans Flutter.

**Acceptance Criteria :**
- [ ] Opérateurs supportés : `AND`, `OR`, `role`, `>`, `<`, `==`
- [ ] `{ "role": ["MANAGER", "DG"] }` → masque pour tous les autres rôles
- [ ] `visible_if: null` → composant toujours visible
- [ ] Évaluation < 1ms par composant (benchmark sur screen avec 20+ composants)
- [ ] Tests : AND/OR imbriqués, rôle inconnu, opérateurs comparaison, cas limites (null, empty)

**Technical Notes :** Évaluateur récursif pur (pas de dépendances externes). Les claims JWT (role, tenant_id) sont injectés depuis `AuthContext`. Phase 1 = RBAC uniquement.

**Dependencies :** STORY-023 (JSON Schema pour les types Rule)

---

#### STORY-007 : LayoutResolver
**Epic :** EPIC-002 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que BDUIEngine, je veux résoudre le layout à appliquer depuis le JSON so that chaque screen s'adapte automatiquement au viewport sans décision Flutter.

**Acceptance Criteria :**
- [ ] 4 layouts implémentés : `dashboard`, `list`, `form`, `detail`
- [ ] Chaque layout × 3 breakpoints : mobile (< 600px), tablet (600-1024px), desktop (> 1024px)
- [ ] `DashboardLayout` : zone kpis (GridView 2 cols mobile, 4 cols desktop), zone main, FAB bas-droite
- [ ] Layout inconnu → fallback `dashboard` + log warning
- [ ] Tests : 4 layouts × 3 breakpoints = 12 combinaisons testées

**Technical Notes :** `LayoutResolver.resolve(layoutType, viewport)` → widget layout concret. Référence : `design-process/D-Design-System/ux-rules/layout.md`.

**Dependencies :** Aucune directe (composants injectés dynamiquement)

---

#### STORY-008 : BDUIEngine Orchestrateur
**Epic :** EPIC-002 | **Priorité :** Must Have | **Points :** 6

**User Story :**
En tant que client Flutter, je veux un BDUIEngine qui prend un JSON et retourne un screen complet fonctionnel so that n'importe quel JSON du catalogue devient une UI sans une ligne Flutter métier.

**Acceptance Criteria :**
- [ ] Pipeline complet : `parse JSON` → `RuleEvaluator` → `data resolution` → `ComponentRegistry` → `LayoutResolver`
- [ ] Rendu cold (depuis cache Drift) : < 200ms sur Android mid-range (Snapdragon 680)
- [ ] Rendu hot (depuis mémoire) : < 50ms
- [ ] Aucune logique métier dans l'Engine (vérifié via lint rule custom)
- [ ] Tests d'intégration : 3 JSONs différents → 3 screens corrects rendus
- [ ] Error boundary global sur l'Engine (échec partiel = dégradation, pas crash)

**Technical Notes :** Widget principal `BDUIScreen(screenConfig)`. Data sources résolus depuis le cache local Drift en Phase 1 (calls backend async en arrière-plan). Référence architecture : `_bmad-output/architecture-scalario-2026-05-09.md` section BDUI.

**Dependencies :** STORY-005, STORY-006, STORY-007, STORY-010, STORY-033 (Drift — résolution data sources)

---

#### STORY-009 : Sandbox JSON + Hot Reload Dev
**Epic :** EPIC-002 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que dev, je veux un écran sandbox qui charge un JSON local et affiche le résultat rendu so that je peux tester n'importe quel layout instantanément sans déploiement backend.

**Acceptance Criteria :**
- [ ] Chargement depuis `assets/sandbox/` → rendu immédiat par BDUIEngine
- [ ] Hot reload : modifier le fichier JSON → rendu mis à jour < 1s sans redémarrer l'app
- [ ] Affiché seulement en mode `kDebugMode` (pas en production)
- [ ] Fichier exemple : `sandbox/retail_dashboard.json` (dashboard OWNER minimal)
- [ ] Erreur JSON invalide → message d'erreur lisible dans la sandbox (pas crash)

**Dependencies :** STORY-008

---

#### STORY-010 : Error Boundaries BDUI
**Epic :** EPIC-002 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant qu'utilisateur, je veux que l'app ne crashe jamais à cause d'un composant défaillant so that une erreur isolée n'interrompt pas mon travail.

**Acceptance Criteria :**
- [ ] Chaque composant rendu par BDUIEngine est isolé dans un `ErrorBoundaryWidget`
- [ ] Composant qui échoue → fallback UI "Composant indisponible" localisé
- [ ] Source de données manquante → état erreur isolé au composant, reste fonctionnel
- [ ] Aucune exception non-gérée ne propage vers le root widget
- [ ] Erreurs loguées avec contexte : `tenant_id` + `screen_id` + `component_type`

**Dependencies :** STORY-005

---

#### STORY-011 : Validation Formulaires Data-Driven
**Epic :** EPIC-002 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que FormSection BDUI, je veux que les règles de validation soient lues depuis le JSON so that je n'ai jamais à coder de validation métier dans Flutter.

**Acceptance Criteria :**
- [ ] Règles supportées : `required`, `type` (string/number/date), `min`, `max`, `minLength`, `maxLength`, `regex`, `enum`
- [ ] Validation en temps réel configurable : `onBlur` (défaut) ou `onChange` depuis le JSON
- [ ] Messages d'erreur localisables depuis le JSON (`error_messages` field)
- [ ] Double validation : Flutter (UX) + backend NestJS (sécurité — FR-014 Zod)
- [ ] Tests : chaque règle + combinaisons + cas limite (null, undefined, edge values)

**Technical Notes :** Référence : `design-process/D-Design-System/components/03-inputs.md`. ValidatorFactory résout les règles JSON en `FormFieldValidator<T>` Flutter.

**Dependencies :** STORY-003 (FormSection), STORY-023 (JSON Schema field validation)

---

#### STORY-012 : Support Multi-plateforme Flutter
**Epic :** EPIC-002 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que client Scalario, je veux accéder à l'app depuis Android, iOS et un navigateur web so that je ne suis pas limité à un seul appareil.

**Acceptance Criteria :**
- [ ] Build Android APK/AAB fonctionnel — Android 8.0+ (API 26+) testé
- [ ] Build iOS fonctionnel — iOS 14+ testé
- [ ] Build Flutter Web — Chrome 90+, Safari 14+, Firefox 88+
- [ ] PWA installable depuis le navigateur (manifest.json + Service Worker)
- [ ] LayoutResolver gère breakpoints : mobile < 600px, tablet 600-1024px, desktop > 1024px
- [ ] Aucun composant avec logique plateforme-spécifique dans le code métier

**Technical Notes :** Utiliser `Platform.isAndroid`/`kIsWeb` uniquement dans la couche adaptation (pas dans les widgets BDUI). Service Worker via `flutter_service_worker`. Référence : `design-process/A-Product-Brief/platform-requirements.md`.

**Dependencies :** STORY-007 (LayoutResolver pour breakpoints)

---

### EPIC-003 — Backend Foundation
**FRs :** FR-009, FR-010, FR-013, FR-015, FR-016, FR-017, FR-019 | **Phase :** 1 MVP | **Priorité :** Must Have

#### STORY-013 : Monorepo Setup + NestJS + Docker Compose

**Epic :** EPIC-003 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que dev, je veux un monorepo structuré (`apps/` + `packages/` + `catalog/`) avec NestJS et Docker Compose 5 services so that l'environnement de dev est reproductible en une commande et le code partagé entre frontend et backend a une place unique.

**Acceptance Criteria :**

- [ ] Structure monorepo créée :

  ```text
  scalario/
  ├── apps/{flutter,nestjs,fastapi}/
  ├── packages/{bdui-schema,bdui-types}/
  ├── catalog/{domains,modules,fusions,schemas}/
  ├── docker-compose.yml
  ├── package.json (root — pnpm workspaces)
  └── .github/workflows/
  ```

- [ ] `pnpm-workspace.yaml` configuré : `apps/*` + `packages/*`
- [ ] `apps/nestjs/` : project structure avec modules séparés (auth, bdui, module-engine, workflow, audit)
- [ ] `apps/fastapi/` : squelette vide Phase 1 (Dockerfile + main.py minimal pour health check)
- [ ] `apps/flutter/` : projet Flutter créé (`flutter create`) — STORY-001 à STORY-012 codent dedans
- [ ] `docker compose up` démarre les 5 services : `nestjs`, `fastapi`, `postgresql`, `redis`, `minio`
- [ ] Health checks configurés sur tous les services
- [ ] `.env.example` à la racine + un par app (jamais de secrets en dur, gitignore strict)
- [ ] CI GitHub Actions : lint + test + build sur chaque PR (matrix : flutter / nestjs)
- [ ] PostgreSQL : migrations TypeORM/Prisma configurées dans `apps/nestjs/` (schema versionné)
- [ ] README racine : "Quickstart en 3 commandes" (clone → pnpm install → docker compose up)

**Technical Notes :** pnpm workspaces choisi pour l'orchestration TypeScript (apps + packages). Flutter n'est pas dans les workspaces pnpm — pubspec.yaml local. Pas de Nx/Turborepo Phase 1 (overkill solo dev) — ajoutable plus tard sans casser la structure.

---

#### STORY-014 : Auth JWT Multi-tenant
**Epic :** EPIC-003 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant qu'utilisateur, je veux pouvoir me connecter et rester authentifié so that mes actions sont tracées à mon identité et à mon tenant sans pouvoir accéder aux données d'un autre client.

**Acceptance Criteria :**
- [ ] Access token JWT (15 min) + Refresh token (7 jours) avec rotation automatique
- [ ] Claims obligatoires : `tenant_id`, `user_id`, `roles[]`, `department_id`
- [ ] Token d'un tenant A invalide sur les routes du tenant B (test d'isolation)
- [ ] Provisioning nouveau tenant < 30 secondes
- [ ] Logout invalide le refresh token (Redis blacklist avec TTL)
- [ ] OAuth2 préparé (interface `AuthProvider` définie, Google/Apple = future implémentation)

**Dependencies :** STORY-013

---

#### STORY-015 : RBAC Guards Dynamiques
**Epic :** EPIC-003 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant qu'intégrateur, je veux définir les rôles et permissions en JSON so that ajouter un nouveau rôle ne nécessite aucun déploiement backend.

**Acceptance Criteria :**
- [ ] Rôles chargés depuis `tenant_config.roles` en DB (zéro rôle hardcodé dans le code)
- [ ] Nouveau rôle = mise à jour JSON config tenant, redémarrage backend non requis
- [ ] Guard `@Roles()` compatible avec rôles dynamiques (chargés depuis DB au démarrage + cache Redis)
- [ ] Rôles par défaut retail : `OWNER`, `MANAGER`, `COMMERCIAL` (dans le template JSON)
- [ ] Test : user avec rôle COMMERCIAL ne peut pas appeler route réservée OWNER → 403

**Dependencies :** STORY-014

---

#### STORY-016 : Multi-tenant Isolation
**Epic :** EPIC-003 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que système, je veux que chaque requête soit automatiquement scopée à son tenant so qu'un bug de code ne puisse jamais exposer des données d'un autre client.

**Acceptance Criteria :**
- [ ] Colonne `tenant_id` sur toutes les tables métier (migration TypeORM)
- [ ] `TenantMiddleware` NestJS injecte `tenant_id` depuis le JWT sur chaque requête
- [ ] Impossible de requêter sans `tenant_id` valide (guard global)
- [ ] Path de migration shared schema → schema-per-tenant documenté et préparé (Phase 2)
- [ ] Test : requête SQL directe avec `tenant_id` d'un autre tenant → données bloquées

**Dependencies :** STORY-014

---

#### STORY-017 : PostgreSQL RLS
**Epic :** EPIC-003 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant qu'architecte sécurité, je veux que la DB bloque toute fuite de données inter-tenant même si NestJS est compromis so que la 5ème couche de sécurité soit indépendante du code applicatif.

**Acceptance Criteria :**
- [ ] Politique RLS active sur toutes les tables contenant des données métier
- [ ] `SET app.current_tenant_id` par connexion PostgreSQL (via NestJS `DataSource.query`)
- [ ] Test d'intrusion : requête SQL directe avec `tenant_id` forgé → 0 résultat (bloquée)
- [ ] Overhead RLS mesuré < 5% vs requête sans RLS (benchmark sur 10K rows)
- [ ] Migration RLS : script rollback documenté

**Dependencies :** STORY-016

---

#### STORY-018 : Redis Sessions + Cache Layouts BDUI
**Epic :** EPIC-003 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que système, je veux que les refresh tokens révoqués soient blacklistés et que les layouts BDUI soient mis en cache so que les performances soient optimales et la révocation instantanée.

**Acceptance Criteria :**
- [ ] Refresh tokens révoqués dans Redis avec TTL = durée restante du token
- [ ] Layouts BDUI cachés par clé `{tenant_id}:{screen_id}:{role}` avec TTL 5 min
- [ ] Invalidation automatique du cache si la config tenant change (event-driven)
- [ ] Service Redis séparé du PostgreSQL (service Docker indépendant)
- [ ] Test : layout modifié → cache invalidé → prochaine requête retourne nouveau layout

**Dependencies :** STORY-013, STORY-014

---

#### STORY-019 : ABAC CASL — Layer 3 Sécurité
**Epic :** EPIC-003 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que MANAGER, je veux que mes permissions soient contextuelles (ex: voir uniquement les factures de mon département) so que le contrôle d'accès soit précis au-delà du simple rôle.

**Acceptance Criteria :**
- [ ] CASL configuré dans NestJS pour les règles `(User + Resource + Context) → Decision`
- [ ] Règles ABAC déclarées dans la config JSON tenant (pas dans le code NestJS)
- [ ] Chaque requête passe par CASL APRÈS le RBAC Guard (Layer 3, après Layer 2)
- [ ] Exemple fonctionnel : MANAGER voit les ventes de SON département uniquement
- [ ] Extension Rete Algorithm préparée Phase 3 (interface `ABACEngine` définie)

**Dependencies :** STORY-015

---

#### STORY-020 : Audit Log
**Epic :** EPIC-003 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant qu'auditeur ou propriétaire, je veux un log immuable de toutes les actions sensibles so que je puisse retracer qui a fait quoi et quand.

**Acceptance Criteria :**
- [ ] Chaque `POST /:moduleId/action` logué : `user_id`, `tenant_id`, `action`, `payload_hash`, `timestamp`
- [ ] Chaque appel LLM logué : `user_id`, `query_hash`, `model`, `tokens_used`, `timestamp`
- [ ] Table `audit_log` : insert-only (0 UPDATE/DELETE autorisé — enforced par RLS)
- [ ] Rétention configurable par tenant (défaut : 90 jours, job de purge planifié)
- [ ] Index sur `tenant_id + timestamp` pour queries rapides

**Dependencies :** STORY-014, STORY-016

---

### EPIC-004 — Module Engine & Catalogue JSON
**FRs :** FR-011, FR-012, FR-014, FR-020, FR-021, FR-053, FR-054, FR-055 | **Phase :** 1 MVP | **Priorité :** Must Have

#### STORY-021 : BDUIService NestJS
**Epic :** EPIC-004 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que client Flutter, je veux récupérer le layout JSON d'un écran filtré par mon rôle so que le backend ne m'envoie jamais des composants que je ne suis pas autorisé à voir.

**Acceptance Criteria :**
- [ ] `GET /api/:tenant/layout/:screenId` → JSON layout filtré par rôle (claims JWT)
- [ ] Cache Redis : layout servi en < 20ms après premier chargement
- [ ] Cache invalidé automatiquement si la config tenant change
- [ ] Composants non autorisés absents du payload JSON (pré-filtrés, pas masqués côté Flutter)
- [ ] Test : OWNER et COMMERCIAL appellent le même screen → payloads différents (OWNER voit CA)

**Dependencies :** STORY-014, STORY-015, STORY-018, STORY-023

---

#### STORY-022 : ModuleEngine — 2 Endpoints Génériques
**Epic :** EPIC-004 | **Priorité :** Must Have | **Points :** 6

**User Story :**
En tant que client Flutter, je veux que 2 endpoints génériques servent 100% des opérations de tous les modules so que le backend n'ait jamais besoin de connaître la logique d'un domaine métier.

**Acceptance Criteria :**
- [ ] `GET /api/:tenant/:moduleId/data` → données du module (liste/KPIs/stats) depuis config JSON
- [ ] `POST /api/:tenant/:moduleId/action` → exécute une action (create/update/delete/custom)
- [ ] Le `moduleId` est résolu depuis la config JSON tenant (zéro hardcode backend)
- [ ] Tout module défini dans un template JSON fonctionne sans déploiement backend
- [ ] Idempotence : `X-Client-Mutation-Id` requis sur tous les POST (STORY-036)
- [ ] Test : 3 modules différents (ventes, stock, caisse) servis par les mêmes 2 endpoints

**Dependencies :** STORY-014, STORY-015, STORY-017, STORY-021

---

#### STORY-023 : JSON Schema BDUI v1.0.0
**Epic :** EPIC-004 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant qu'intégrateur, je veux un contrat JSON versionné et documenté so que je sache précisément ce que je peux déclarer pour construire un template sectoriel.

**Acceptance Criteria :**
- [ ] Types définis : `ComponentConfig`, `ScreenConfig`, `Rule`, `LayoutConfig`, `WorkflowStep`, `ModuleConfig`, `RBACRole`
- [ ] Schema versionné semver : `"schema_version": "1.0.0"` dans chaque payload
- [ ] Exemples valides inclus dans le catalogue pour chaque type
- [ ] Documentation auto-générée (JSON Schema → HTML doc via json-schema-to-html ou similaire)
- [ ] Le schema est la source de vérité — TypeScript et Dart en dérivent (STORY-027)

**Dependencies :** STORY-013

---

#### STORY-024 : Zod Validator + API Validation
**Epic :** EPIC-004 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que système, je veux qu'un JSON template invalide soit bloqué avant tout stockage or déploiement so qu'aucun JSON cassé ne puisse atteindre le moteur de rendu.

**Acceptance Criteria :**
- [ ] Schema Zod couvre tous les types de STORY-023 (`ComponentConfig`, `ScreenConfig`, `Rule`, `WorkflowStep`, `RBACRole`)
- [ ] `POST /admin/templates/validate` → retourne erreurs détaillées avec path JSON si invalide
- [ ] Validation exécutée en CI avant tout déploiement catalogue (GitHub Actions step)
- [ ] Messages d'erreur lisibles par un intégrateur non-développeur (pas de jargon technique)
- [ ] Tests : JSON valide → 200 OK, JSON invalide → 422 avec liste d'erreurs précises

**Dependencies :** STORY-023

---

#### STORY-025 : Structure Catalogue + README Intégrateur

**Epic :** EPIC-004 | **Priorité :** Must Have | **Points :** 2

**User Story :**
En tant qu'intégrateur, je veux une structure catalogue claire et documentée à la racine du repo so que je puisse créer un nouveau template sectoriel sans toucher au code des apps.

**Acceptance Criteria :**

- [ ] `catalog/` est à la **racine du monorepo** (pas dans `apps/`) — donnée métier séparée du code applicatif
- [ ] Sous-dossiers créés : `catalog/domains/`, `catalog/modules/`, `catalog/fusions/`, `catalog/schemas/`
- [ ] `catalog/README.md` : "Comment créer un nouveau template sectoriel" (checklist en 5 étapes, lisible non-dev)
- [ ] Chaque fichier JSON validé par Zod en CI (pas de JSON cassé en main) — workflow GitHub Actions dédié `catalog-validate.yml`
- [ ] Exemple : `catalog/domains/retail_fresh_produce.json` placeholder (implémenté STORY-039)
- [ ] Nouveau template = PR + CI validation, 0 déploiement backend requis (documenté)
- [ ] NestJS lit `catalog/` au démarrage via volume Docker monté (pas de copie dans l'image)

**Dependencies :** STORY-013, STORY-024

---

#### STORY-026 : Validation Bidirectionnelle JSON Runtime
**Epic :** EPIC-004 | **Priorité :** Must Have | **Points :** 2

**User Story :**
En tant que BDUIEngine Flutter, je veux valider le JSON reçu du backend avant de le parser so qu'un JSON cassé ne crashe jamais l'app même si le backend envoie quelque chose d'inattendu.

**Acceptance Criteria :**
- [ ] JSON Schema validé côté Flutter avant parsing par le BDUIEngine
- [ ] Erreur validation → fallback UI + log erreur (jamais crash)
- [ ] Les deux validateurs (Zod NestJS + JSON Schema Flutter) partagent le même contrat (STORY-023)
- [ ] Test E2E : backend envoie JSON intentionnellement invalide → Flutter affiche fallback propre

**Dependencies :** STORY-008, STORY-023

---

#### STORY-027 : Code-gen Contrat Partagé *(STRETCH)*
**Epic :** EPIC-004 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que dev, je veux que les types TypeScript et les classes Dart soient auto-générés depuis le JSON Schema so qu'une désynchronisation entre backend et frontend soit impossible.

**Acceptance Criteria :**
- [ ] Script : `json-schema → TypeScript interfaces` (pour NestJS)
- [ ] Script : `json-schema → Dart classes` (pour Flutter)
- [ ] Exécuté automatiquement en CI à chaque modification du schema
- [ ] Compilation TS ou Dart échoue si types utilisés incorrectement
- [ ] Version schema dans chaque payload API

**Technical Notes :** Outils : `json-schema-to-typescript` (TS) + `json_serializable` / `freezed` (Dart). STRETCH — priorité post-Gate 0 si Sprint 4 saturé.

**Dependencies :** STORY-023

---

#### STORY-028 : Tests Coverage Moteur ≥90% *(STRETCH)*
**Epic :** EPIC-004 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que dev solo, je veux une couverture de tests suffisante sur le moteur BDUI so que je puisse itérer sans craindre les régressions silencieuses.

**Acceptance Criteria :**
- [ ] Unit tests ComponentRegistry : chaque composant + type inconnu + états erreur
- [ ] Unit tests RuleEvaluator : tous opérateurs + imbrication + cas limites
- [ ] Unit tests LayoutResolver : 4 layouts × 3 breakpoints (12 cas)
- [ ] Integration tests ModuleEngine : GET + POST pour 3 modules différents
- [ ] Coverage global moteur ≥ 90% (mesuré en CI)
- [ ] Widgetbook snapshot tests = référence non-régression visuelle

**Technical Notes :** STRETCH — si Sprint 4 a de la marge. La couverture des stories individuelles (STORY-005, STORY-006, STORY-007) inclut déjà des tests unitaires. Cet story complète la couverture d'intégration.

**Dependencies :** STORY-005, STORY-006, STORY-007, STORY-008, STORY-022

---

### EPIC-005 — Workflow DAG Engine
**FRs :** FR-018, FR-028 | **Phase :** 1 MVP | **Priorité :** Must Have

#### STORY-029 : DAG Validator — Kahn's Algorithm
**Epic :** EPIC-005 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que système, je veux valider qu'un workflow JSON est un DAG valide (sans cycle, sans étape inaccessible) so qu'un workflow cassé soit bloqué au déploiement, jamais en production.

**Acceptance Criteria :**
- [ ] Kahn's algorithm implémenté en NestJS (`WorkflowValidator.validateDAG(steps)`)
- [ ] Cycle détecté → erreur bloquante avec détail des nœuds circulaires
- [ ] Étape inaccessible (nœud orphelin) → warning bloquant
- [ ] Validation exécutée au déploiement du template JSON (via Zod + DAG check)
- [ ] `POST /admin/templates/validate` inclut la validation DAG
- [ ] Tests : DAG valide → OK, cycle simple → erreur, cycle complexe → erreur, nœud orphelin → warning

**Dependencies :** STORY-024 (pipeline de validation templates)

---

#### STORY-030 : Workflow Executor
**Epic :** EPIC-005 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que system, je veux exécuter un workflow DAG déclaré en JSON so que n'importe quel workflow métier (clôture caisse, validation arrivage) fonctionne sans coder une seule ligne backend spécifique.

**Acceptance Criteria :**
- [ ] Étapes exécutées dans l'ordre topologique (respecte les dépendances DAG)
- [ ] Conditions évaluées avant chaque étape (`condition: { "field": "montant", "op": ">", "value": 500000 }`)
- [ ] Actions déclenchées : `send_notification`, `update_field`, `create_record`, `call_api`
- [ ] Tout workflow défini en JSON s'exécute via `WorkflowExecutor.run(workflowId, context)`
- [ ] Tests : workflow clôture caisse (3 étapes) exécuté correctement

**Dependencies :** STORY-029

---

#### STORY-031 : XState State Machine
**Epic :** EPIC-005 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que système de workflow, je veux que les transitions d'état d'une entité métier (commande, clôture) soient validées par une State Machine so qu'une transition illégale soit impossible même avec un appel API direct.

**Acceptance Criteria :**
- [ ] XState configuré dans NestJS (`@xstate/fsm` ou `xstate`)
- [ ] FSM générée depuis la section `states` du workflow JSON tenant
- [ ] Transition légale → état mis à jour en DB
- [ ] Transition illégale → `409 Conflict` avec état actuel + transitions autorisées dans la réponse
- [ ] Exemple : clôture caisse `ouvert → en_cours → fermé` → revenir à `ouvert` → 409
- [ ] Tests : transitions légales + illégales pour le workflow clôture caisse

**Dependencies :** STORY-030

---

#### STORY-032 : Integration Workflow ↔ ModuleEngine
**Epic :** EPIC-005 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que client Flutter, je veux qu'un `POST /:moduleId/action` puisse déclencher un workflow so que clôturer une caisse via l'action JSON est automatiquement géré par le WorkflowExecutor.

**Acceptance Criteria :**
- [ ] `POST /:moduleId/action` avec `action_type: "start_workflow"` → déclenche le WorkflowExecutor
- [ ] Workflow ID résolu depuis la config JSON du module
- [ ] Retour : état courant du workflow + prochaines transitions possibles
- [ ] Test E2E : cliquer "Clôturer caisse" dans le template → workflow DAG exécuté → état `fermé`

**Dependencies :** STORY-022, STORY-031

---

### EPIC-006 — Offline-First & Sync
**FRs :** FR-008, FR-052, FR-056, FR-057, FR-058, FR-059 | **Phase :** 1 MVP | **Priorité :** Must Have

#### STORY-033 : Drift/Isar Setup Mobile — Persistance Locale
**Epic :** EPIC-006 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant qu'utilisateur mobile en zone sans réseau, je veux que l'app démarre et fonctionne complètement depuis les données locales so que la connectivité instable n'impacte jamais mon travail quotidien.

**Acceptance Criteria :**
- [ ] Drift configuré comme ORM local Android/iOS (alternative : Isar — décision au setup)
- [ ] Premier lancement : télécharge et cache la config tenant JSON + données init depuis le backend
- [ ] Mode offline : navigation complète, saisie données, exécution actions (toutes en queue)
- [ ] Config JSON chiffrée localement (flutter_secure_storage ou SQLCipher)
- [ ] Cache max configurable par tenant (limite défaut : 500MB)
- [ ] Drift est la première source de vérité — le backend est un service de sync, pas une dépendance de démarrage

**Technical Notes :** Drift tables principales : `tenant_config`, `cached_layouts`, `sync_queue`, `local_data`. Les data sources du BDUIEngine lisent depuis Drift, pas directement le backend.

**Dependencies :** STORY-008 (BDUIEngine doit lire depuis Drift)

---

#### STORY-034 : Sync Queue Locale Drift
**Epic :** EPIC-006 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant qu'utilisateur offline, je veux que toutes mes actions soient enregistrées dans une queue ordonnée so qu'à la reconnexion elles partent dans l'ordre chronologique sans perte.

**Acceptance Criteria :**
- [ ] Queue Drift `sync_queue` : `mutation_id` (UUID), `module_id`, `action`, `payload`, `timestamp`, `status`
- [ ] Statuts : `pending` → `sending` → `success | conflict | error`
- [ ] Queue persistée dans Drift (survit à un kill process + redémarrage)
- [ ] Reprise automatique à la reconnexion (connectivity_plus + background worker)
- [ ] Ordre chronologique garanti (ORDER BY timestamp ASC)
- [ ] Test : 5 actions offline → reconnexion → toutes envoyées dans l'ordre + statuts mis à jour

**Dependencies :** STORY-033

---

#### STORY-035 : Conflict Resolution Phase 1
**Epic :** EPIC-006 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant qu'utilisateur, je veux que les conflits de sync soient résolus automatiquement (server wins) et que les cas ambigus soient présentés clairement so que mes données restent cohérentes sans intervention technique.

**Acceptance Criteria :**
- [ ] Stratégies supportées : `server_wins` (défaut), `client_wins`, `manual`
- [ ] Stratégie déclarée dans le JSON du module : `"conflict_strategy": "server_wins"`
- [ ] Conflit `manual` → entrée dans la conflict queue (table Drift + badge UI)
- [ ] Interface résolution : affiche version locale vs serveur + bouton choix utilisateur
- [ ] Test : mutation offline + modification backend simultanée → `server_wins` résout automatiquement
- [ ] Test `manual` : conflit créé → affiché dans UI → utilisateur choisit → résolu

**Dependencies :** STORY-034

---

#### STORY-036 : Idempotence Endpoints POST
**Epic :** EPIC-006 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que système de sync, je veux que rejouer deux fois la même mutation ne crée pas de doublon so que les timeouts réseau et les retries soient transparents pour l'utilisateur.

**Acceptance Criteria :**
- [ ] Header obligatoire : `X-Client-Mutation-Id: {uuid}` sur tous les POST ModuleEngine
- [ ] Backend stocke les `client_mutation_id` traités avec TTL 24h (Redis)
- [ ] Requête dupliquée → retourne le résultat original sans ré-exécuter l'action (idempotent)
- [ ] Test E2E : simulation timeout réseau + replay → un seul enregistrement créé en DB

**Dependencies :** STORY-022

---

#### STORY-037 : Sync Status UI — Data-driven
**Epic :** EPIC-006 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant qu'utilisateur, je veux voir en permanence si mes données sont synchronisées so que je sache si je travaille sur des données fraîches ou en mode offline.

**Acceptance Criteria :**
- [ ] États affichés : "Hors ligne", "Sync en cours…", "À jour", "X conflits en attente"
- [ ] Indicateur configurable dans le JSON template (position, style depuis composant BDUI)
- [ ] Badge sur l'icône app si conflits en attente (mobile — Android + iOS)
- [ ] Détail expandable : liste des mutations en attente avec timestamp et module
- [ ] Composant `SyncStatusBar` du Design System utilisé (STORY-003)

**Dependencies :** STORY-034, STORY-035

---

#### STORY-038 : Drift Web Offline + PWA *(Déféré post-Gate 0)*
**Epic :** EPIC-006 | **Priorité :** Should Have | **Points :** 5

**User Story :**
En tant qu'utilisateur web, je veux que l'app fonctionne en mode dégradé hors connexion so que je ne sois pas bloqué si le réseau coupe pendant une session de travail sur navigateur.

**Acceptance Criteria :**
- [ ] Drift web (IndexedDB backend) configuré pour Flutter Web
- [ ] Mode offline web : données en lecture depuis cache, actions mises en queue
- [ ] Service Worker configuré pour mise en cache des assets Flutter
- [ ] Indicateur offline/online visible (même SyncStatusBar que mobile)
- [ ] Sync identique à mobile à la reconnexion

**Technical Notes :** **DÉFÉRÉ** — FR-052 est "Should Have". Priorité après Gate 0 (Blandine = mobile Android). Inclus dans le plan post-Gate 0.

**Dependencies :** STORY-012, STORY-033

---

### EPIC-007 — Premier Template `retail_fresh_produce.json`
**FRs :** FR-022, FR-023 | **Phase :** 1 MVP | **Priorité :** Must Have

#### STORY-039 : Structure Template + 3 Rôles JSON
**Epic :** EPIC-007 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant qu'intégrateur, je veux la structure complète du template retail_fresh_produce.json avec les 3 rôles et la matrix RBAC déclarée so que l'accès de chaque rôle est défini sans une ligne de code backend.

**Acceptance Criteria :**
- [ ] Fichier `catalog/domains/retail_fresh_produce.json` — structure valide schema v1.0.0
- [ ] 3 rôles déclarés en JSON : `OWNER` (proprietaire), `MANAGER` (ibrahim), `COMMERCIAL` (vendeur)
- [ ] Matrix RBAC complète : OWNER voit CA + toutes données, MANAGER valide arrivages + pertes, COMMERCIAL vend uniquement
- [ ] Metadata template : `sector`, `description`, `min_users`, `max_users`, `modules[]`
- [ ] Validation Zod → 0 erreur

**Dependencies :** STORY-025 (structure catalogue), STORY-024 (Zod validator)

---

#### STORY-040 : Modules Phase 1 JSON
**Epic :** EPIC-007 | **Priorité :** Must Have | **Points :** 5

**User Story :**
En tant que propriétaire d'une épicerie fine, je veux les 6 modules métier Phase 1 déclarés en JSON so que mon équipe peut travailler au quotidien depuis l'app sans aucune formation technique.

**Acceptance Criteria :**
- [ ] `module_dashboard_owner` : KPIs (CA jour, ventes, stock alert count), graphe 7j, notifications soir
- [ ] `module_dashboard_commercial` : solde caisse, articles rapides (ProductGrid), action "Vendre"
- [ ] `module_dashboard_manager` : arrivages en attente, alertes stock bas, action "Valider livraison"
- [ ] `module_ventes` : list transactions jour avec détail, filtres par commercial/période
- [ ] `module_pertes` : formulaire déclaration perte (article, quantité, cause, photo), historique
- [ ] `module_alertes_stock` : liste articles sous seuil minimum, action "Commander" (future)
- [ ] Chaque module : layouts JSON (dashboard/list/form), visible_if RBAC, données mockées pour test

**Technical Notes :** Référence UX : `design-process/C-UX-Scenarios/` (scénarios 01 à 06). Référence composites : `design-process/D-Design-System/composites/`.

**Dependencies :** STORY-039, STORY-023 (JSON Schema), STORY-006 (RuleEvaluator pour visible_if)

---

#### STORY-041 : Workflow DAG Clôture Caisse
**Epic :** EPIC-007 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que COMMERCIAL, je veux suivre un workflow guidé de clôture caisse so que la procédure de fin de journée soit irréprochable et tracée.

**Acceptance Criteria :**
- [ ] Workflow `workflow_cloture_caisse` déclaré dans le JSON : étapes = `saisie_fond_restant` → `reconciliation` → `validation_manager` → `cloture_confirmee`
- [ ] DAG validé (STORY-029) — 0 cycle
- [ ] XState FSM : transition illégale (`cloture_confirmee` → `saisie_fond_restant`) → 409
- [ ] Exécutable via `POST /api/:tenant/caisse/action` avec `action_type: "start_workflow"`
- [ ] Test E2E : COMMERCIAL clôture → MANAGER valide → état `cloture_confirmee`
- [ ] Référence UX : `design-process/C-UX-Scenarios/03-blandine-commercial-caisse-close/`

**Dependencies :** STORY-040, STORY-032 (Integration Workflow↔ModuleEngine)

---

#### STORY-042 : Contraintes Global Scale
**Epic :** EPIC-007 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que dev, je veux que les contraintes d'internationalisation et d'adaptabilité soient posées dès le premier template so que l'expansion vers d'autres marchés ne nécessite pas de refactoring.

**Acceptance Criteria :**
- [ ] i18n Flutter : 0 string visible hardcodée dans les widgets (flutter_localizations + intl)
- [ ] Locale fr-BF définie par défaut, structure prête pour en-US, ar (RTL préparé)
- [ ] Format monétaire configurable dans le JSON tenant : `"currency": "XOF"` (défaut)
- [ ] Interface `PaymentAdapter` définie dans NestJS — Wave = 1 implémentation future (interface only Phase 1)
- [ ] Lint rule Flutter : `no_hardcoded_strings_in_widgets` actif en CI

**Dependencies :** STORY-012 (Flutter Web + mobile), STORY-013 (NestJS setup)

---

#### STORY-043 : Validation E2E Gate 0
**Epic :** EPIC-007 | **Priorité :** Must Have | **Points :** 3

**User Story :**
En tant que Carlos, je veux valider que l'architecture BDUI fonctionne end-to-end avec le template retail so que Blandine peut utiliser l'app au quotidien sans aide et que le template peut servir un 2ème client du même secteur sans modification.

**Acceptance Criteria :**
- [ ] BDUIEngine rend `retail_fresh_produce.json` sans une ligne Flutter métier (code review + lint)
- [ ] Les 4 fonctions Gate 0 fonctionnelles sur Android : dashboard proprio, validation arrivage, déclaration perte, clôture caisse
- [ ] Test offline : mode avion → 10 actions offline → reconnexion → tout synchronisé
- [ ] Test multi-rôle : 3 users (OWNER/MANAGER/COMMERCIAL) → chacun voit son dashboard
- [ ] Blandine UAT : session d'utilisation guidée, 0 bug bloquant
- [ ] Template validé "sector-first" : checklist que le même JSON marcherait pour un 2ème épicier

**Dependencies :** STORY-039, STORY-040, STORY-041, STORY-026, STORY-037

---

## Calcul de Capacité

```
Développeur : 1 solo dev AI-augmenté (Claude Code + BMAD)
Niveau : Senior (expérience NestJS + Flutter depuis projets précédents)
Heures dev/jour : 5.5h (entre 5-6h, CEO/sales non inclus)
Sprint : 2 semaines = 10 jours ouvrés
Ratio points AI-augmenté : 1pt = 1.5h (2x plus vite qu'un dev senior seul)

Capacité brute : 10j × 5.5h = 55h
Capacité points : 55h / 1.5h = ~37pts
Arrondi avec buffer complexité : 42pts/sprint

Buffer sprint : 10% (4pts) pour bugs, intégrations imprévues, retours UAT

Capacité totale (4 sprints) : 4 × 42pts = 168pts
```

**Avantage Design System disponible :** `design-process/D-Design-System/` contient les specs complètes des composants. EPIC-001 et EPIC-002 s'implémentent depuis des spécifications validées → estimation conservative (pourrait aller plus vite).

---

## Allocation par Sprint

### Sprint 1 (12-23 mai 2026) — 41pts, 10 stories

**Goal :** "Le BDUIEngine rend n'importe quel JSON en screen Flutter fonctionnel — Design System complet, composants BDUI, RuleEvaluator, LayoutResolver, Sandbox opérationnelle."

| Story | Titre | Epic | Points | Priorité |
|-------|-------|------|--------|----------|
| STORY-001 | Design Tokens Flutter | E001 | 3 | Must Have |
| STORY-002 | Material 3 + ThemeData Scalario | E001 | 3 | Must Have |
| STORY-003 | Composants BDUI Métier | E001 | 5 | Must Have |
| STORY-004 | Widgetbook + Thème Global | E001 | 4 | Must Have |
| STORY-005 | ComponentRegistry | E002 | 5 | Must Have |
| STORY-006 | RuleEvaluator | E002 | 5 | Must Have |
| STORY-007 | LayoutResolver | E002 | 5 | Must Have |
| STORY-009 | Sandbox JSON + Hot Reload | E002 | 3 | Must Have |
| STORY-010 | Error Boundaries BDUI | E002 | 3 | Must Have |
| STORY-011 | Validation Formulaires Data-driven | E002 | 3 | Must Have |

**Total : 39pts / 42pts (93% utilisation — 3pts buffer supplémentaire)**

**Risques Sprint 1 :**
- Widgetbook snapshot tests : configuration CI peut prendre du temps
- Flutter Widget Preview : vérifier la version Flutter compatible (annotations stables vs experimental)

**Dépendances Sprint 1 :** Aucune externe

---

### Sprint 2 (26 mai – 6 juin 2026) — 41pts, 10 stories

**Goal :** "Backend multi-tenant sécurisé (5 couches) + BDUIEngine orchestrateur end-to-end + support multi-plateforme Flutter. Le pipeline complet JSON→screen fonctionne avec auth réelle."

| Story | Titre | Epic | Points | Priorité |
|-------|-------|------|--------|----------|
| STORY-008 | BDUIEngine Orchestrateur | E002 | 6 | Must Have |
| STORY-012 | Support Multi-plateforme Flutter | E002 | 5 | Must Have |
| STORY-013 | NestJS Setup + Docker Compose | E003 | 3 | Must Have |
| STORY-014 | Auth JWT Multi-tenant | E003 | 5 | Must Have |
| STORY-015 | RBAC Guards Dynamiques | E003 | 5 | Must Have |
| STORY-016 | Multi-tenant Isolation | E003 | 3 | Must Have |
| STORY-017 | PostgreSQL RLS | E003 | 5 | Must Have |
| STORY-018 | Redis Sessions + Cache Layouts | E003 | 3 | Must Have |
| STORY-019 | ABAC CASL — Layer 3 | E003 | 3 | Must Have |
| STORY-020 | Audit Log | E003 | 3 | Must Have |

**Total : 41pts / 42pts (98% utilisation)**

**Risques Sprint 2 :**
- STORY-008 (BDUIEngine) dépend de STORY-033 (Drift) pour les data sources → implémenter data sources mockées Phase 1, Drift en Sprint 3
- PostgreSQL RLS : configuration complexe, prévoir du temps pour les tests d'intrusion

**Dépendances Sprint 2 :** Sprint 1 terminé (STORY-005, STORY-006, STORY-007)

---

### Sprint 3 (9-20 juin 2026) — 38pts, 9 stories

**Goal :** "ModuleEngine opérationnel — 2 endpoints servent 100% des modules. DAG Validator valide les workflows. Drift offline mobile setup. Le backend générique est prouvé."

| Story | Titre | Epic | Points | Priorité |
|-------|-------|------|--------|----------|
| STORY-021 | BDUIService NestJS | E004 | 5 | Must Have |
| STORY-022 | ModuleEngine — 2 Endpoints | E004 | 6 | Must Have |
| STORY-023 | JSON Schema BDUI v1.0.0 | E004 | 5 | Must Have |
| STORY-024 | Zod Validator + API Validation | E004 | 3 | Must Have |
| STORY-025 | Structure Catalogue + README | E004 | 2 | Must Have |
| STORY-026 | Validation Bidirectionnelle JSON | E004 | 2 | Must Have |
| STORY-029 | DAG Validator — Kahn's Algorithm | E005 | 5 | Must Have |
| STORY-030 | Workflow Executor | E005 | 5 | Must Have |
| STORY-033 | Drift/Isar Setup Mobile | E006 | 5 | Must Have |

**Total : 38pts / 42pts (90% utilisation) — 4pts buffer pour imprévus**

**Risques Sprint 3 :**
- STORY-022 (ModuleEngine) : la résolution dynamique depuis config JSON est le cœur du système. Prévoir des tests exhaustifs.
- STORY-023 (JSON Schema) doit être finalisé avant STORY-024 et STORY-026

**Dépendances Sprint 3 :** STORY-014, STORY-015 (Sprint 2), STORY-008 (Sprint 2)

---

### Sprint 4 (23 juin – 4 juillet 2026) — 41pts committed + 8pts stretch

**Goal :** "Gate 0 : retail_fresh_produce.json déployé, workflow clôture caisse fonctionnel, sync offline mobile opérationnelle, Blandine utilise l'app. 4 fonctions critiques validées."

| Story | Titre | Epic | Points | Priorité | Type |
|-------|-------|------|--------|----------|------|
| STORY-031 | XState State Machine | E005 | 5 | Must Have | Committed |
| STORY-032 | Integration Workflow↔ModuleEngine | E005 | 3 | Must Have | Committed |
| STORY-034 | Sync Queue Locale Drift | E006 | 5 | Must Have | Committed |
| STORY-035 | Conflict Resolution Phase 1 | E006 | 5 | Must Have | Committed |
| STORY-036 | Idempotence Endpoints POST | E006 | 3 | Must Have | Committed |
| STORY-037 | Sync Status UI — Data-driven | E006 | 3 | Must Have | Committed |
| STORY-039 | Template : Structure + 3 Rôles JSON | E007 | 3 | Must Have | Committed |
| STORY-040 | Modules Phase 1 JSON (6 modules) | E007 | 5 | Must Have | Committed |
| STORY-041 | Workflow DAG Clôture Caisse | E007 | 3 | Must Have | Committed |
| STORY-042 | Contraintes Global Scale | E007 | 3 | Must Have | Committed |
| STORY-043 | Validation E2E Gate 0 | E007 | 3 | Must Have | Committed |
| STORY-027 | Code-gen Contrat Partagé | E004 | 3 | Must Have | **STRETCH** |
| STORY-028 | Tests Coverage Moteur ≥90% | E004 | 5 | Must Have | **STRETCH** |

**Total committed : 41pts / 42pts (98%)**
**Total avec stretch : 49pts (capacité dépassée — stretch = si le sprint va vite)**

**Risques Sprint 4 :**
- STORY-040 (6 modules JSON) : volume élevé, mais le JSON est déclaratif — accéléré avec Claude Code
- STORY-043 (E2E + UAT Blandine) : dépend de la disponibilité de Blandine pour le test

**Dépendances Sprint 4 :** STORY-029, STORY-030 (Sprint 3), STORY-033 (Sprint 3)

**Buffer Gate 0 :** Sprint 4 se termine le 4 juillet. Gate 0 = 8 juillet. **4 jours de buffer** pour corrections critiques, onboarding Blandine, monitoring initial.

---

## Traceabilité Epics → Stories → FRs

| Epic ID | Epic | Stories | Points | FRs couverts | Sprint |
|---------|------|---------|--------|--------------|--------|
| EPIC-001 | Design System | 001-004 | 15pts | FR-005, FR-007 | S1 |
| EPIC-002 | BDUI Engine | 005-012 | 35pts | FR-001, FR-001b, FR-002, FR-003, FR-004, FR-006, FR-050, FR-051 | S1-S2 |
| EPIC-003 | Backend Foundation | 013-020 | 30pts | FR-009, FR-010, FR-013, FR-015, FR-016, FR-017, FR-019 | S2 |
| EPIC-004 | Module Engine | 021-028 | 31pts | FR-011, FR-012, FR-014, FR-020, FR-021, FR-053, FR-054, FR-055 | S3-S4 |
| EPIC-005 | Workflow DAG | 029-032 | 18pts | FR-018, FR-028 | S3-S4 |
| EPIC-006 | Offline-First | 033-038 | 26pts | FR-008, FR-052, FR-056, FR-057, FR-058, FR-059 | S3-S4 |
| EPIC-007 | Template fresh produce | 039-043 | 17pts | FR-022, FR-023 | S4 |

## Couverture des FRs

| FR | Titre | Story | Sprint |
|----|-------|-------|--------|
| FR-001 | ComponentRegistry | STORY-005 | S1 |
| FR-001b | Multi-plateforme Flutter | STORY-012 | S2 |
| FR-002 | RuleEvaluator | STORY-006 | S1 |
| FR-003 | LayoutResolver | STORY-007 | S1 |
| FR-004 | BDUIEngine | STORY-008 | S2 |
| FR-005 | Design Tokens | STORY-001, STORY-002 | S1 |
| FR-006 | Sandbox JSON | STORY-009 | S1 |
| FR-007 | Widgetbook | STORY-004 | S1 |
| FR-008 | Offline-first Mobile | STORY-033 | S3 |
| FR-009 | Auth JWT Multi-tenant | STORY-014 | S2 |
| FR-010 | RBAC Guards Dynamiques | STORY-015 | S2 |
| FR-011 | BDUIService | STORY-021 | S3 |
| FR-012 | ModuleEngine | STORY-022 | S3 |
| FR-013 | Multi-tenant Basique | STORY-016 | S2 |
| FR-014 | Zod Validator | STORY-024 | S3 |
| FR-015 | PostgreSQL RLS | STORY-017 | S2 |
| FR-016 | Redis Sessions | STORY-018 | S2 |
| FR-017 | ABAC Basique CASL | STORY-019 | S2 |
| FR-018 | Workflow DAG Engine | STORY-029, STORY-030, STORY-031 | S3-S4 |
| FR-019 | Audit Log | STORY-020 | S2 |
| FR-020 | JSON Schema BDUI | STORY-023 | S3 |
| FR-021 | Structure Catalogue | STORY-025 | S3 |
| FR-022 | Template retail_fresh_produce | STORY-039, STORY-040, STORY-041 | S4 |
| FR-023 | Contraintes Global Scale | STORY-042 | S4 |
| FR-028 | FSM Auto-géré | STORY-031 | S4 |
| FR-050 | Error Boundaries BDUI | STORY-010 | S1 |
| FR-051 | Validation Formulaires | STORY-011 | S1 |
| FR-052 | Offline Web | STORY-038 | Post-Gate 0 |
| FR-053 | Validation JSON Bidirectionnelle | STORY-026 | S3 |
| FR-054 | Code-gen Contrat Partagé | STORY-027 | S4 (STRETCH) |
| FR-055 | Tests Coverage ≥90% | STORY-028 | S4 (STRETCH) |
| FR-056 | Sync Queue Locale | STORY-034 | S4 |
| FR-057 | Conflict Resolution | STORY-035 | S4 |
| FR-058 | Sync Status UI | STORY-037 | S4 |
| FR-059 | Idempotence Endpoints | STORY-036 | S4 |

---

## Risques & Mitigation

### Risques Hauts

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|-----------|
| BDUIEngine trop complexe pour les délais | Moyen | Critique | Commencer STORY-008 dès Sprint 2 avec data sources mockées. Pit stop mid-sprint si bloqué. |
| ModuleEngine — résolution JSON trop lente au runtime | Faible | Haut | Benchmark dès Sprint 3. Redis cache obligatoire (STORY-021). |
| Drift offline — bugs de sync en conditions terrain | Moyen | Haut | Tests E2E offline dès Sprint 3. Simuler déconnexion réseau dans CI. |
| UAT Blandine — indisponibilité fin juin | Faible | Haut | Planifier session UAT mi-juillet (buffer Gate 0). Ne pas dépendre d'une seule date. |

### Risques Moyens

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|-----------|
| PostgreSQL RLS — overhead performance | Faible | Moyen | Benchmark obligatoire dans STORY-017. Seuil < 5% overhead. |
| JSON Schema v1.0.0 incomplet | Moyen | Moyen | STORY-023 est la priorité #1 de Sprint 3. Revue avec les scénarios UX avant de coder. |

### Risques Faibles

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|-----------|
| STORY-027/028 stretch non livrés | Haut | Faible | Code-gen et coverage tests ne bloquent pas Gate 0 — reportés post-Gate 0 si nécessaire. |
| STORY-038 (Drift Web) non livré | Certain | Faible | Explicitement déféré — Blandine = Android mobile. |

---

## Dépendances

### Externes
- **Blandine** : disponible pour UAT Gate 0 (semaine 7-11 juillet)
- **Compte Claude API** : accès pour les stories EPIC-008 (Phase 2, hors Gate 0)
- **Android device physique** : pour les tests Blandine (Snapdragon mid-range)

### Infrastructure
- Docker Hub ou registry privé : pour images Docker des 5 services
- VPS/Cloud : déploiement backend Gate 0 (VPS Ubuntu minimal, Docker Compose)
- GitHub Actions : CI/CD configuré dès Sprint 1 (STORY-013)

---

## Definition of Done

Pour qu'une story soit considérée complète :
- [ ] Code implémenté et commité en branch feature
- [ ] Tests unitaires écrits et passent (coverage requis par story)
- [ ] Lint : `flutter analyze` 0 warning + ESLint 0 erreur
- [ ] Code review validé (auto-review via BMAD code-review skill)
- [ ] Acceptance criteria de la story cochées
- [ ] Pas de régression sur les stories précédentes (Widgetbook snapshot + tests existants)

---

## Backlog Post-Gate 0

*Stories non bloquantes pour Gate 0 — à planifier en Sprint 5+ :*

| Story | Points | FR | Raison du report |
|-------|--------|----|-----------------|
| STORY-027 (Code-gen) | 3pts | FR-054 | Qualité dev — pas bloquant Gate 0 |
| STORY-028 (Tests coverage) | 5pts | FR-055 | Qualité dev — partiellement couvert dans chaque story |
| STORY-038 (Drift Web offline) | 5pts | FR-052 | Should Have, Blandine = Android |
| EPIC-008 (Config IA) | ~50pts | FR-024 à FR-035 | Phase 2 — M4-M6 |
| EPIC-009 (Admin Web) | ~35pts | FR-029, FR-030 | Phase 2 |
| EPIC-010 (Infrastructure Phase 2) | ~25pts | FR-031, FR-032, FR-034, FR-039 | Phase 2 |
| EPIC-012 (Intégrateurs) | ~25pts | - | Phase 2 — M6-M9 |

---

## Prochaines étapes

**Immédiat (lundi 12 mai) :**
1. Commencer STORY-001 : Design tokens Flutter (3pts) — specs dans `design-process/D-Design-System/tokens/`
2. Run `/bmad:dev-story STORY-001` pour démarrer l'implémentation

**Cadence sprint :**
- Sprint length : 2 semaines
- Revue de sprint : vendredi de la 2ème semaine
- Démarrage sprint suivant : lundi suivant

**Checkpoints Gate 0 :**
- **Semaine 3 (fin Sprint 1)** : BDUIEngine rend un JSON local en screen
- **Semaine 5 (fin Sprint 2)** : Auth + backend sécurisé, pipeline Flutter↔NestJS
- **Semaine 7 (fin Sprint 3)** : ModuleEngine prouvé, offline mobile setup
- **Semaine 9 (fin Sprint 4)** : Template live, Blandine teste
- **8 juillet 2026** : Gate 0 — Blandine en production

---

*Ce plan a été créé avec BMAD Method v6 — Phase 4 (Sprint Planning)*
*Scalario — Instant Business OS | 2026-05-09*
