# Scalario — Stratégie de gestion des erreurs BDUI

> Implémentée dans **STORY-010** (Sprint 1). Architecture 3 niveaux.

---

## Principe fondamental

**L'app ne crashe jamais.** Une erreur dans un composant ne doit jamais interrompre le travail de Blandine en pharmacie.

---

## Les 3 niveaux

### Niveau 1 — Per-component : `ErrorBoundary`

**Fichier :** `lib/engine/error_boundary/error_boundary.dart`

Wraps chaque widget construit par `ComponentRegistry.build`. Si `child.build()` throw :

- Le composant défaillant est remplacé par `ErrorFallback` (banner danger "Composant indisponible")
- Les composants frères restent intacts
- L'erreur est loguée dans `ErrorLogger` avec le contexte structuré

```dart
ErrorBoundary(
  componentType: 'KPICard',
  componentId: 'kpi_ventes_jour',
  screenId: 'retail_dashboard',
  child: KPICard(...),
)
```

**Props :**
| Prop | Type | Rôle |
|------|------|------|
| `componentType` | `String` | Identifiant du type (pour le log) |
| `componentId` | `String?` | Identifiant de l'instance |
| `screenId` | `String?` | Écran parent (pour le log) |
| `fallbackBuilder` | `Widget Function(BuildContext, Object, StackTrace)?` | Override du fallback par défaut |

**Limitation :** Flutter ne fournit pas d'API ErrorBoundary native per-subtree. L'implémentation utilise un override scoped de `ErrorWidget.builder` coordonné par `ErrorCapture` pour éviter les interférences entre composants frères dans le même frame.

---

### Niveau 2 — Per-screen : `BDUIErrorBoundary`

**Fichier :** `lib/engine/error_boundary/bdui_error_boundary.dart`

Wraps la sortie de `BDUIEngine.render` (STORY-008). Si toute la pipeline échoue :

- Affiche `BDUIErrorScreen` : illustration + titre + sous-titre + bouton "Réessayer"
- En `kDebugMode`, panneau extensible avec type d'exception, message, JSON path, stack (10 frames)
- `onRetry` invalide le cache et relance le chargement

```dart
BDUIErrorBoundary(
  screenId: config.screenId,
  onRetry: () => ref.invalidate(screenProvider(config.screenId)),
  child: BDUIEngine.render(config, context),
)
```

**Exceptions métier :**
- `BDUIValidationException` — JSON invalide structurellement ou sémantiquement. Inclut `jsonPath` pour localiser le nœud fautif.
- `BDUIRenderException` — Erreur interne de l'engine lors du rendu.

---

### Niveau 3 — Global : `GlobalErrorHandler`

**Fichier :** `lib/engine/error_boundary/global_error_handler.dart`

Capture tout ce qui échappe aux niveaux 1 et 2 :

- `FlutterError.onError` — erreurs du framework Flutter
- `PlatformDispatcher.instance.onError` — erreurs isolate/platform
- `runZonedGuarded` dans `main()` — exceptions async non-awaited

**Comportement :**
- Debug : `print` en rouge avec type + stack
- Release : `SnackBar` non-bloquante "Erreur technique signalée"
- Dans tous les cas : log dans `ErrorLogger`

**Installation (dans `main()`) :**
```dart
void main() {
  GlobalErrorHandler.install(navigatorKey: _navigatorKey);
  runZonedGuarded(
    () { _setupDependencies(); runApp(ScalarioApp(navigatorKey: _navigatorKey)); },
    GlobalErrorHandler.handleZoneError,
  );
}
```

---

## ErrorLogger — Ring buffer local

**Fichier :** `lib/engine/error_boundary/error_logger.dart`

- **Singleton :** `ErrorLogger.instance`
- **Capacité :** 200 entrées (FIFO — la plus ancienne est droppée quand plein)
- **Purge :** `ErrorLogger.instance.clear()` — à appeler au logout (AC-17)
- **Payload :** `ErrorPayload` (voir schéma ci-dessous)

**Gap Sprint 1 :** Les erreurs s'accumulent en mémoire locale. La sync vers le backend Audit Log (STORY-026) et la Drift queue (STORY-033) n'est pas encore branchée — c'est intentionnel.

---

## Schéma du payload (AC-11)

```json
{
  "ts": "2026-05-12T14:32:11.123Z",
  "level": "error",
  "tenant_id": "uuid-or-null",
  "user_id": "uuid-or-null",
  "screen_id": "retail_dashboard",
  "component_type": "KPICard",
  "component_id": "kpi_ventes_jour",
  "error_type": "_Exception",
  "message": "Source 'ventes_today' not found",
  "stack_hash": "a1b2c3d4",
  "app_version": "0.1.0+1",
  "platform": "android"
}
```

**Règles PII (AC-15) :**
- `message` est passé par `ErrorPayload.sanitize()` qui retire : emails, nombres ≥ 7 chiffres
- La stack trace complète n'est jamais stockée (ni en mémoire en release, ni en base) — uniquement un hash 8 hex des 10 premières frames
- En `kDebugMode`, la stack complète est gardée dans `ErrorPayload.debugStack` (non-sérialisé)

---

## Fichiers créés / modifiés

```
lib/engine/error_boundary/
├── error_capture.dart         # Coordinateur frame-scoped (ErrorWidget.builder)
├── error_payload.dart         # Struct JSON + sanitizer PII
├── error_logger.dart          # Ring buffer singleton
├── error_fallback.dart        # Widget fallback per-component
├── error_screen.dart          # Widget fallback per-screen (BDUIErrorScreen)
├── error_boundary.dart        # Niveau 1 (remplace le stub STORY-005)
├── bdui_error_boundary.dart   # Niveau 2 + BDUIValidationException + BDUIRenderException
├── global_error_handler.dart  # Niveau 3
└── _error_boundary_showcase.dart  # Preview standalone

lib/l10n/
├── app_fr.arb   # bdui.error.* keys (FR)
└── app_en.arb   # bdui.error.* keys (EN)

lib/main.dart    # +GlobalErrorHandler.install() +runZonedGuarded

docs/error-handling.md  # Ce fichier
```

---

## Roadmap

| Story | Ce qu'elle ajoute |
|-------|-------------------|
| STORY-008 | Branche `BDUIErrorBoundary` autour de `BDUIEngine.render` |
| STORY-026 | Backend Audit Log — ingest les payloads du ring buffer |
| STORY-033 | Drift queue — flush du ring buffer vers STORY-026 au sync |
| Phase 2 | Sentry / GlitchTip self-hosted (souveraineté UEMOA) |
