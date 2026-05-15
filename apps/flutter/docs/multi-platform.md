# Multi-platform Flutter — Scalario

**STORY-012** — livré 2026-05-15. Garantit que les 3 cibles (Android, iOS, Web) compilent et tournent depuis un codebase unique.

---

## Cibles supportées Phase 1

| Plateforme | Cible primaire | Niveau de support Phase 1 |
|---|---|---|
| **Android 8.0+** (API 26) | Blandine en pharmacie, Snapdragon 680 mid-range | Production (priorité absolue) |
| **iOS 14.0+** | Ibrahim manager (iPhone) | Simulator + build Phase 1 ; signing prod Phase 2 |
| **Web** (Chrome 90+, Safari 14+, Firefox 88+) | Carlos admin desktop, partenaires intégrateurs | Production via staging.scalario.app (STORY-046) |

Linux/macOS/Windows desktop sont scaffoldés mais hors scope produit Phase 1.

---

## Configuration par plateforme

### Android — `apps/flutter/android/`
- `minSdk = 26`, `targetSdk = 34`, `compileSdk = 34`, Java 17.
- Permissions déclarées : `INTERNET`, `ACCESS_NETWORK_STATE`, `BLUETOOTH_*`, `CAMERA`. Runtime activation Phase 2 (STORY-PD-XX).
- Signing : debug key Phase 1 (placeholder). Upload key Play Store livrée par STORY-046.

### iOS — `apps/flutter/ios/`
- `MinimumOSVersion = 14.0`.
- Usage descriptions Info.plist : Bluetooth, Camera, Photo Library (préparation Phase 2).
- Pas de signing prod (compte Apple Developer = Phase 2).
- Build CI : `flutter build ios --release --no-codesign`.

### Web — `apps/flutter/web/`
- `index.html` : meta viewport, `theme-color = #2980B9` (ScalarioColors.primary500), splash anti-flash blanc.
- `manifest.json` : PWA installable (`name = Scalario`, `display = standalone`, icônes 192/512 + maskable).
- Service worker généré par Flutter (`flutter_service_worker.js`) — cache assets + retry offline pour `index.html`. Stratégie cache avancée → STORY-035.
- Renderer : `--web-renderer auto` (CanvasKit desktop pour qualité, HTML mobile-web pour bundle plus léger). À revisiter si Lighthouse perf < 70.

---

## Couche d'adaptation — `lib/core/platform/`

| Fichier | Responsabilité |
|---|---|
| `platform_info.dart` | Getters host : `isAndroid`, `isIOS`, `isWeb`, `isMobile`, `isDesktop`, `isMobileWeb(ctx)`, `isDesktopWeb(ctx)`, `name`. |
| `platform_capabilities.dart` | Feature flags : `bluetoothAvailable`, `cameraAvailable`, `filePickerAvailable`, `pushNotificationsAvailable`, `nativeFileSystemAvailable` + `snapshot()`. |
| `platform_specific/platform_storage.dart` | Contrat `PlatformStorage` (backend, location). |
| `platform_specific/storage.dart` | Bridge `conditional imports` (io ↔ web ↔ stub). |
| `platform_specific/storage_io.dart` | Impl native (Drift natif via STORY-035). |
| `platform_specific/storage_web.dart` | Impl web (IndexedDB via STORY-035). |
| `platform_specific/storage_stub.dart` | Stub d'erreur — couvre les plateformes sans `dart:io` ni `dart:html`. |
| `_platform_capabilities_showcase.dart` | Showcase debug — affiche les flags runtime. |

### Breakpoints web — alignement projet

`PlatformInfo.isMobileWeb(ctx)` et `isDesktopWeb(ctx)` réutilisent `BreakpointResolver` (canon projet `lib/engine/layout_resolver/breakpoints.dart`) :

- `mobile` : `width < 600`
- `tablet` : `600 ≤ width ≤ 1024`
- `desktop` : `width > 1024`

C'est une déviation **volontaire** par rapport au texte de la story (768 / 1024) — on garde une source unique de breakpoints à travers tout le DS pour éviter le drift. Si un jour la définition canon bouge, ces getters suivent automatiquement.

---

## Règle architecturale — pas de check direct

**Aucun fichier dans `lib/components/` ni `lib/features/` ne doit contenir :**
- `kIsWeb`
- `Platform.isAndroid` / `Platform.isIOS` / `Platform.is<X>`

Tout passe par `PlatformInfo` / `PlatformCapabilities`. Vérifié par `scripts/check_no_direct_platform_check.dart` (exécuté en CI).

Pour les implémentations runtime plateforme-spécifiques (storage, notifications, etc.), utiliser le pattern `conditional imports` Dart :

```dart
// lib/core/platform/platform_specific/storage.dart
export 'storage_stub.dart'
    if (dart.library.io) 'storage_io.dart'
    if (dart.library.html) 'storage_web.dart';
```

---

## Lancer les builds localement

```bash
cd apps/flutter

# Android — sur émulateur ou device connecté
flutter run -d android
flutter build apk --release       # APK Phase 1 (debug-signé)
flutter build appbundle --release # AAB upload-ready (debug-signé)

# iOS — Xcode requis (macOS uniquement)
flutter build ios --release --no-codesign

# Web — Chrome
flutter run -d chrome
flutter build web --release       # build/web/

# Showcase platform debug
flutter run --target=lib/core/platform/_platform_capabilities_showcase.dart -d <device>
```

---

## Workflow CI — `.github/workflows/build-multiplatform.yml`

4 jobs :

1. **`analyze-and-test`** (ubuntu) — `dart format`, `flutter analyze`, lint hardcoded tokens, lint platform check, `flutter test --coverage`. Bloque les 3 builds en cas d'échec.
2. **`android-build`** (ubuntu, JDK 17) — APK + AAB release. Warn si APK > 30 MB.
3. **`ios-build`** (macos-14) — release `--no-codesign`.
4. **`web-build`** (ubuntu) — release + verify manifest.json/service worker/theme-color. Warn si bundle > 5 MB.

Tous les artefacts sont uploadés (APK, AAB, Runner.app, bundle web).

---

## Performance — budgets

| Cible | Budget | Mesure CI |
|---|---|---|
| APK release | < 30 MB | warning si dépassé |
| Web bundle (build/web/) | < 5 MB | warning si dépassé |
| Cold start Android Snapdragon 680 | < 3 s | smoke test manuel Phase 1 |
| Lighthouse Web | Perf ≥ 70, A11y ≥ 90, Best Practices ≥ 90, SEO ≥ 80, PWA installable | manuel Phase 1 (auto Phase 2 via STORY-046) |

---

## Sécurité — notes Phase 1

- **Android signing** : debug key Phase 1. Documenté → Phase 2 dans `docs/security-android.md` (à créer par STORY-046).
- **iOS signing** : aucun Phase 1 (pas de compte Apple Developer).
- **Web HTTPS only** : enforcement naturel par hosting (Cloudflare/Vercel). Service Worker ne fonctionne qu'en HTTPS.
- **CSP header** : non configuré Phase 1 — TODO STORY-046 (strict, sans `unsafe-inline`/`unsafe-eval`).

---

## Backlog / suite

- **STORY-035** (FR-052) — Drift web IndexedDB + service worker cache stratégique.
- **STORY-046** — release management : prod signing Android, hosting staging.scalario.app, Lighthouse CI, CSP headers.
- **STORY-PD-XX** — Bluetooth runtime (balance + imprimante POS), camera scan code-barre.
- **Phase 2** — Apple Developer + TestFlight, Play Store deployment, perfo web (lazy loading, code split).
