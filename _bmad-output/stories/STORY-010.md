# STORY-010 : Error Boundaries BDUI

**Epic :** EPIC-002 — BDUI Engine Flutter
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** STORY-005 (ComponentRegistry — fournit le hook `ErrorBoundary` autour de chaque build) ; STORY-001 + STORY-002 (tokens + theme — pour le fallback UI cohérent visuellement)

---

## User Story

> **En tant qu'**utilisateur Scalario (Blandine en pharmacie, Ibrahim manager, Carlos admin),
> **je veux** que l'app ne crashe **jamais** à cause d'un composant défaillant,
> **so that** une erreur isolée (composant bugué, source de données absente, JSON cassé) n'interrompt pas mon travail — je vois un fallback localisé "Composant indisponible" et je continue.

---

## Description

### Background

Scalario est **data-driven** : un JSON corrompu, un bug dans un composant, ou une source de données manquante peuvent survenir n'importe quand. Un crash full-screen pour Blandine en pleine vente est inacceptable — elle perdra confiance et reviendra à son cahier en 5 minutes. Pour Carlos, un crash en démo investisseur tue la levée.

L'architecture (`_bmad-output/architecture-scalario-2026-05-09.md` lignes 49, 858-872 NFR-004) impose :

> "Chaque composant Flutter est isolé dans un error boundary. JSON invalide → fallback UI localisé, jamais crash."

Cette story livre **3 niveaux d'error boundaries** :

1. **Per-component** : chaque widget construit par `ComponentRegistry.build` est enveloppé dans un `ErrorBoundary`. Si ce composant throw, on affiche un fallback `AlertBanner danger` "Composant indisponible" à sa place. Les autres composants du screen restent intacts.

2. **Per-screen** : le `BDUIScreen` (STORY-008) entier est enveloppé dans un `BDUIErrorBoundary`. Si toute la pipeline render échoue (parse, validation, layout), on affiche un `BDUIErrorScreen` complet avec retry.

3. **Global app** : `runZonedGuarded` + `FlutterError.onError` capturent toute exception non-attrapée et les routent vers un sink local (Audit Log STORY-026 + télémétrie future).

Cette story est **transverse** : elle complète le stub livré par STORY-005 (qui exposait juste l'API `ErrorBoundary`) et instrumente STORY-008 et tout `lib/main.dart`.

### Scope

**In scope :**

- Package `lib/engine/error_boundary/` :
  - `error_boundary.dart` — `ErrorBoundary` widget (StatefulWidget) avec props `componentType`, `componentId`, `screenId`, `tenantId`, `child`, `fallbackBuilder`.
  - `bdui_error_boundary.dart` — `BDUIErrorBoundary` (variante per-screen) avec props `screenId`, `child`, retry callback.
  - `error_fallback.dart` — Widget fallback per-component : `AlertBanner` variant `danger` + texte i18n "Composant indisponible".
  - `error_screen.dart` — Widget fallback per-screen : illustration EmptyState + bouton "Réessayer" + détails dev (kDebugMode only).
  - `error_logger.dart` — Sink local qui logge les erreurs avec contexte structuré (JSON), prêt à connecter à l'Audit Log backend (STORY-026).
  - `global_error_handler.dart` — install `FlutterError.onError`, `PlatformDispatcher.onError`, et `runZonedGuarded` dans `main.dart`.
- Tous les composants rendus par `ComponentRegistry.build` (STORY-005) traversent `ErrorBoundary`. Le stub Sprint 1 livré par STORY-005 est remplacé par cette implémentation complète — backward-compatible (même API).
- Tous les screens BDUI rendus par `BDUIEngine.render` (STORY-008) sont enveloppés dans `BDUIErrorBoundary`.
- Logs structurés JSON : `tenant_id`, `screen_id`, `component_type`, `component_id`, `error_type`, `stack_trace_hash`, `timestamp`, `user_role`, `app_version`. Stockés en mémoire ring buffer (200 entries) pour debug + flushés vers Drift queue (STORY-033) → backend Audit Log (STORY-026) à la prochaine sync.
- Internationalisation : tous les messages fallback ont une `arb_key` dans `lib/l10n/`.
- Tests : crash simulé d'un composant → fallback rendu, autres composants OK, log capturé. Aucune exception ne propage.
- Mode dev : `kDebugMode` fait apparaître un overlay "stack trace + path JSON" sur le fallback, pour accélérer le debug. En release, seul le message i18n.

**Out of scope (autres stories) :**

- Audit Log backend (NestJS service qui ingest les erreurs) → STORY-026 ; cette story prépare le payload mais ne POST pas.
- Sync queue offline → STORY-034 / EPIC-006 ; les logs s'empilent en local et seront sync quand la sync queue est branchée.
- Télémétrie tierce (Sentry, Firebase Crashlytics) → backlog Phase 2 (souveraineté UEMOA — préférer self-hosted).
- Recovery action automatique (réessayer le composant après 3s) → backlog Phase 2.
- Error boundary autour de la sync queue, des routes navigation, etc. → ces zones seront couvertes par leurs stories respectives ; ici on couvre **uniquement** le runtime BDUI.

### User Flow (Runtime)

**Cas 1 — composant individuel cassé :**

1. JSON contient un `KPICard` avec une source de données mal référencée.
2. `KPICard.fromConfig` throw `DataSourceNotFoundException` à la construction.
3. `ErrorBoundary` autour de ce KPICard catch via `didChangeDependencies` (Flutter ne capture pas naturellement les exceptions de build via `try/catch` — il faut utiliser `ErrorWidget.builder` global + override `widget.build` flow).
4. Affiche `AlertBanner danger` "Composant indisponible" à la place du KPI.
5. Logue l'erreur avec contexte (`tenant_id`, `screen_id: "retail_dashboard"`, `component_type: "KPICard"`, `component_id: "kpi_ventes_jour"`).
6. Les 7 autres KPIs et la DataTable du screen restent intactes. Blandine peut continuer.

**Cas 2 — screen entier cassé :**

1. JSON `screen_config` est syntaxiquement invalide.
2. `BDUIEngine.loadScreen` throw `BDUIValidationException`.
3. `BDUIErrorBoundary` catch.
4. Affiche `BDUIErrorScreen` : illustration `EmptyState` + texte "Écran indisponible. Réessayer ?" + bouton.
5. Bouton "Réessayer" relance `loadScreen` (cache invalidé).
6. Si dev mode, le screen affiche aussi le path du nœud fautif + raison.

**Cas 3 — exception globale non-attrapée :**

1. Une isolate throw, ou une `Future` non-awaited rejette.
2. `runZonedGuarded` ou `PlatformDispatcher.onError` catch.
3. Loggue en local + notifie l'utilisateur via une `SnackBar` non-bloquante "Erreur technique signalée".
4. App continue de fonctionner.

---

## Acceptance Criteria

### ErrorBoundary per-component

- [ ] AC-01 — `ErrorBoundary` widget StatefulWidget avec props : `componentType: String`, `componentId: String?`, `screenId: String?`, `child: Widget`, `fallbackBuilder: Widget Function(BuildContext, Object error, StackTrace stack)?`.
- [ ] AC-02 — Catch les exceptions throwées dans `child.build()` via override de `Element.build` ou wrapping `child` avec `ErrorWidget.builder` scoped + une zone `runZonedGuarded` autour du build.
- [ ] AC-03 — Fallback par défaut : widget `ErrorFallback` (AlertBanner danger) avec texte i18n `bdui.error.component_unavailable` ("Composant indisponible").
- [ ] AC-04 — Hauteur min du fallback = 56dp ; padding horizontal = `ScalarioSpacing.space4` ; couleur = `ColorScheme.errorContainer`.
- [ ] AC-05 — Custom `fallbackBuilder` permet à un composant DS de fournir un fallback dédié (ex: `DataTable` peut afficher un placeholder de skeleton à la place).

### BDUIErrorBoundary per-screen

- [ ] AC-06 — `BDUIErrorBoundary` widget StatefulWidget avec props : `screenId: String`, `child: Widget`, `onRetry: VoidCallback?`.
- [ ] AC-07 — Catch les exceptions de `BDUIEngine.render` (qui peut throw `BDUIValidationException`, `BDUIRenderException`).
- [ ] AC-08 — Fallback : `BDUIErrorScreen` avec :
  - Illustration `EmptyState` (composant DS).
  - Titre i18n `bdui.error.screen_title` ("Écran indisponible").
  - Sous-titre i18n `bdui.error.screen_subtitle` ("Une erreur est survenue. Réessayez ou contactez votre administrateur.").
  - Bouton primaire "Réessayer" → appelle `onRetry`.
  - En `kDebugMode`, panneau extensible "Détails techniques" qui affiche : exception type, message, JSON path, stack trace tronquée (10 frames).

### Global error handler

- [ ] AC-09 — `GlobalErrorHandler.install()` appelé dans `main()` avant `runApp(...)` :
  - `FlutterError.onError = (details) => GlobalErrorHandler.handle(details)`.
  - `PlatformDispatcher.instance.onError = (error, stack) => GlobalErrorHandler.handle(...); return true;`.
  - `runApp` enveloppé dans `runZonedGuarded(() => runApp(MyApp()), GlobalErrorHandler.handle)`.
- [ ] AC-10 — `GlobalErrorHandler.handle` :
  - Logue via `ErrorLogger.log(...)`.
  - En `kDebugMode`, fait `print(...)` + rouge.
  - En release, affiche une `SnackBar` non-bloquante via un `GlobalKey<NavigatorState>` "Erreur technique signalée".
  - Aucune exception ne propage au-delà de `runZonedGuarded`.

### ErrorLogger — contexte structuré

- [ ] AC-11 — Chaque erreur est loguée avec un payload JSON conforme :

```json
{
  "ts": "2026-05-12T14:32:11.123Z",
  "level": "error",
  "tenant_id": "uuid-or-null",
  "user_id": "uuid-or-null",
  "screen_id": "retail_dashboard",
  "component_type": "KPICard",
  "component_id": "kpi_ventes_jour",
  "error_type": "DataSourceNotFoundException",
  "message": "Source 'ventes_today' not found",
  "stack_hash": "sha1-abc123",
  "app_version": "0.1.0+1",
  "platform": "android"
}
```

- [ ] AC-12 — Stack trace **non-stockée** intégrale (PII risk + taille) — uniquement le hash SHA-1 des 10 premières frames + pour `kDebugMode`, la stack complète est gardée en mémoire.
- [ ] AC-13 — Ring buffer en mémoire 200 entries (configurable) — accessible via `ErrorLogger.recentErrors` pour debug.
- [ ] AC-14 — En attendant STORY-033 (Drift queue) et STORY-026 (Audit Log backend), les erreurs ne sont **que** loguées local. Documentation explicite de ce gap dans `error_logger.dart`.

### Sécurité — pas de PII

- [ ] AC-15 — Aucune donnée utilisateur (montants, noms clients, emails) ne doit apparaître dans les logs. Le `error.message` doit être un message d'exception structuré (`"Source X not found"`), jamais un dump de payload.
- [ ] AC-16 — Lint custom CI : grep dans `lib/engine/error_boundary/` contre patterns `payload`, `data:`, `value:` qui pourraient leaker des données.
- [ ] AC-17 — Le ring buffer en mémoire est purgé à la déconnexion utilisateur (logout).

### Tests

- [ ] AC-18 — Tests widget :
  - Composant qui throw dans `build` → ErrorBoundary affiche fallback, log enregistré.
  - 5 composants côte à côte, le 3e throw → seul le 3e a un fallback, les 4 autres rendent normalement.
  - `BDUIErrorBoundary` autour d'un screen qui throw → BDUIErrorScreen rendu, bouton retry fonctionnel.
  - `GlobalErrorHandler` capture une exception async non-awaited → loguée, aucun crash.
- [ ] AC-19 — Test "no PII in logs" : un composant qui throw avec un message contenant un email mock → vérifié que le payload log ne contient pas l'email (sanitization).
- [ ] AC-20 — Couverture ≥ 90% sur `lib/engine/error_boundary/`.

### i18n

- [ ] AC-21 — Toutes les chaînes de fallback ont une `arb_key` dans `lib/l10n/app_en.arb` + `lib/l10n/app_fr.arb`.
- [ ] AC-22 — Si la `arb_key` n'est pas résolue (i18n setup non finalisé), fallback en français hardcodé (le marché UEMOA est francophone Phase 1).

---

## Technical Notes

### Composants concernés

- **Nouveau package :** `apps/flutter/lib/engine/error_boundary/`.
- **Stub remplacé :** STORY-005 livre un `ErrorBoundary` passe-through ; cette story le remplace par l'implémentation complète. API identique → STORY-005 ne se casse pas.
- **Hooks installés dans :** `lib/main.dart` (avant `runApp`).
- **Composants DS consommés :** `AlertBanner` (variant danger), `EmptyState`, `ActionButton` (livrés par STORY-003).

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   ├── engine/
│   │   └── error_boundary/
│   │       ├── error_boundary.dart            # Per-component
│   │       ├── bdui_error_boundary.dart       # Per-screen
│   │       ├── error_fallback.dart            # Widget fallback per-component
│   │       ├── error_screen.dart              # Widget fallback per-screen
│   │       ├── error_logger.dart              # Sink local + ring buffer
│   │       ├── error_payload.dart             # Payload JSON struct
│   │       └── global_error_handler.dart      # FlutterError.onError + zone
│   ├── l10n/
│   │   ├── app_fr.arb                         # +bdui.error.* keys
│   │   └── app_en.arb
│   └── main.dart                              # + GlobalErrorHandler.install()
├── test/
│   └── engine/
│       └── error_boundary/
│           ├── error_boundary_test.dart
│           ├── bdui_error_boundary_test.dart
│           ├── error_logger_test.dart
│           └── global_error_handler_test.dart
```

### Pattern Dart recommandé

```dart
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.componentType,
    this.componentId,
    this.screenId,
    required this.child,
    this.fallbackBuilder,
  });

  final String componentType;
  final String? componentId;
  final String? screenId;
  final Widget child;
  final Widget Function(BuildContext, Object, StackTrace)? fallbackBuilder;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  @override
  Widget build(BuildContext ctx) {
    if (_error != null) {
      final builder = widget.fallbackBuilder ?? _defaultFallback;
      return builder(ctx, _error!, _stack ?? StackTrace.empty);
    }
    return _CaptureBuilder(
      child: widget.child,
      onError: (e, s) {
        ErrorLogger.log(ErrorPayload(
          tenantId: GetIt.I<UserContextProvider>().current.tenantId,
          screenId: widget.screenId,
          componentType: widget.componentType,
          componentId: widget.componentId,
          error: e,
          stack: s,
        ));
        if (mounted) setState(() { _error = e; _stack = s; });
      },
    );
  }

  Widget _defaultFallback(BuildContext ctx, Object e, StackTrace s) {
    return ErrorFallback(componentType: widget.componentType);
  }
}
```

`_CaptureBuilder` utilise `ErrorWidget.builder` scoped via un `Builder` + un `runZonedGuarded` autour de la construction enfant. **Détail d'implémentation Flutter délicat** — Flutter 3.x permet de capturer via `FlutterError.onError` global mais pas naturellement par sub-tree. Solution recommandée : combiner `runZonedGuarded` (pour les erreurs async) + un override local de `ErrorWidget.builder` poussé sur stack à l'entrée du build et restauré en sortie.

Note : la lib `flutter_error_boundary` (community package) résout ce point — à évaluer en spike ; si elle est mature et MIT, l'utiliser plutôt que ré-inventer.

### Spec source — résolution du conflit

Aucun conflit majeur PRD ↔ DS. Le PRD §FR-050 (ligne 292) et le sprint plan ligne 252 sont alignés : "fallback UI 'Composant indisponible' localisé".

**Décision propre :** réutiliser le composant DS `AlertBanner` (livré par STORY-003) variant `danger` plutôt qu'inventer un nouveau widget — cohérence visuelle. C'est la résolution implicite du choix "composant générique vs custom" — DS gagne (cf. principe DS de cette équipe).

### Edge cases

- **Erreur dans le `fallbackBuilder` lui-même** : si l'`ErrorFallback` throw (théoriquement impossible mais...), on utilise le `ErrorWidget` Flutter par défaut (banner rouge) + log critique. Pas de boucle infinie.
- **Erreur dans `ErrorLogger.log`** : try/catch + `print(stderr)` ultime fallback. L'app ne doit jamais crasher à cause de l'observabilité.
- **Récursion `setState`** : si l'exception est levée pendant le `setState` du fallback, on échec proprement (utiliser `WidgetsBinding.instance.addPostFrameCallback`).
- **Composant async qui throw après le build** (`Future` rejected) : c'est `runZonedGuarded` global qui capture, pas l'`ErrorBoundary` per-component. Documenter cette limitation — l'utilisateur voit une SnackBar plutôt qu'un fallback localisé.
- **Mode prod sans i18n setup** : i18n est livré progressivement (STORY-042). Pour cette story, on hardcode les chaînes en français + commentaire `// TODO i18n: bdui.error.component_unavailable`.
- **Crash très tôt dans `main()`** (avant `runApp`) : `runZonedGuarded` ne peut pas afficher de SnackBar (pas encore de `Navigator`). Fallback : `print(stderr)` + `runApp(EmergencyApp())` qui affiche un screen blanc avec "Erreur de démarrage". Phase 1 nice-to-have.

### Sécurité

- **PII protection** : c'est l'AC le plus critique côté sécurité. Une erreur leakant un email ou un montant dans les logs est un incident RGPD potentiel. Triple verrou :
  1. Lint regex CI dans `lib/engine/error_boundary/` contre patterns suspects.
  2. Sanitizer `ErrorLogger.sanitize(message)` qui regex out emails, IBAN-like, montants à 7+ chiffres.
  3. Code review explicite à chaque PR touchant `error_logger.dart`.
- **Stack trace** : le hash SHA-1 des frames suffit pour déduplication backend ; la stack complète n'est jamais persistée en local (sauf debug mode).

### Performance

- ErrorBoundary est un wrapper léger — overhead < 0.1ms par composant.
- ErrorLogger ring buffer : 200 × ~500 octets = ~100KB max en mémoire. Acceptable.
- Sanitization regex : ~1ms par log. Acceptable car erreurs sont rares.

---

## Dependencies

**Prérequis :**

- STORY-001, STORY-002, STORY-003 (tokens + theme + composants `AlertBanner`, `EmptyState`) — `merged`.
- STORY-005 (ComponentRegistry) — `merged` (cette story remplace le stub `ErrorBoundary`).

**Stories bloquées par celle-ci :**

- STORY-008 (BDUIEngine) — directe (consomme `BDUIErrorBoundary`).
- STORY-026 (Audit Log backend) — collaborative (cette story prépare le payload, STORY-026 ingest).
- STORY-033 (Drift queue) — collaborative (sync queue prendra le ring buffer).

**Externes :**

- `flutter_error_boundary` package (à évaluer — sinon implémentation maison via `ErrorWidget.builder` scoped).

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-010-error-boundaries`.
- [ ] `flutter analyze` passe sans warning sur `lib/engine/error_boundary/`.
- [ ] `flutter test test/engine/error_boundary/` vert avec ≥ 90% coverage.
- [ ] Test "no PII leak" passe (sanitization regex).
- [ ] `GlobalErrorHandler.install()` appelé dans `main.dart` avant `runApp`.
- [ ] `ComponentRegistry.build` (STORY-005) utilise désormais le vrai `ErrorBoundary` (pas le stub).
- [ ] `BDUIEngine.render` (STORY-008) enveloppe son output dans `BDUIErrorBoundary`.
- [ ] Démo manuelle dans la sandbox (STORY-009) : modifier un fichier JSON pour casser un composant → screenshot du fallback dans la PR.
- [ ] Documentation README dev : `docs/error-handling.md` avec la stratégie des 3 niveaux.
- [ ] Code review passé.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour par l'orchestrateur (STORY-010 status `completed`, completed_points sprint 1 += 3).

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `ErrorBoundary` widget per-component (capture build error) | 0.75 | Détail Flutter délicat ; spike possible sur `flutter_error_boundary` package vs maison. |
| `BDUIErrorBoundary` per-screen + `BDUIErrorScreen` UI | 0.5 | Réutilise EmptyState + ActionButton DS. |
| `ErrorFallback` widget (AlertBanner danger + i18n) | 0.25 | Trivial. |
| `ErrorLogger` + `ErrorPayload` + ring buffer + sanitization | 0.5 | La sanitization regex demande de la rigueur. |
| `GlobalErrorHandler` (FlutterError.onError + runZonedGuarded) | 0.5 | Câblage main.dart + tests d'intégration. |
| Tests widget + test no-PII + couverture | 0.5 | 4 scénarios + sanitization + couverture stricte. |
| **Total** | **3** | Fibonacci 3 — petit mais critique. |

**Rationale :** Logique simple mais beaucoup de **détails subtils** (Flutter ne fournit pas d'API ErrorBoundary native, sanitization PII, tests d'absence de leak). 3 points est juste — sous-estimer ferait sauter le filet PII qui est non-négociable. Si en cours de sprint on découvre que `flutter_error_boundary` package est mature et fiable, on récupère ~0.5 point qu'on réinvestit dans plus de tests d'intégration.

---

## Notes additionnelles

- **Promesse Scalario :** "l'app ne crashe jamais". Cette story est ce qui matérialise la promesse. Sans elle, on n'a pas le droit de mettre l'app entre les mains de Blandine. C'est le **fondement de la confiance terrain**.
- **Demo investisseur :** une démo où "tout casse mais l'app continue" est plus impressionnante qu'une démo parfaite. Préparer un fixture sandbox `error_state.json` pour montrer le fallback en live.
- **Sentry / Crashlytics Phase 2 :** les payloads JSON ici sont déjà structurés pour ingestion future. Si UEMOA souveraineté pousse vers self-hosted, Plausible-style ou GlitchTip (open source) sont prefs.
- **Logo Scalario / branding :** non concerné.
- **Pattern Showcase (cf. mémoire utilisateur Santera)** : créer `error_boundary_showcase.dart` avec preview Light+Dark + main() standalone — démontre les fallbacks dans tous les contextes. Aligné avec convention projet.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
