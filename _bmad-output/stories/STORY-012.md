# STORY-012 : Support Multi-plateforme Flutter

**Epic :** EPIC-002 — BDUI Engine Flutter
**Priorité :** Must Have
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 2 (2026-05-26 → 2026-06-06)
**Dependencies :** STORY-007 (LayoutResolver — breakpoints) ; STORY-008 (BDUIEngine doit fonctionner sur les 3 plateformes pour démontrer l'engagement) ; STORY-001 (tokens — polices Google Fonts doivent fonctionner offline mobile)

---

## User Story

> **En tant que** client Scalario (Blandine sur Android terrain, Ibrahim manager sur tablette, Carlos admin sur desktop web),
> **je veux** accéder à exactement la même app — mêmes screens, mêmes composants, même comportement — depuis Android, iOS et un navigateur web,
> **so that** je ne suis pas limité à un seul appareil et que Scalario tient sa promesse "Business OS qui marche partout depuis un codebase unique".

---

## Description

### Background

Flutter est l'un des rares frameworks qui produit un **vrai** codebase unique pour mobile + web (cf. architecture ligne 145). React Native ne peut pas. PWA seul ne donne pas une vraie app native. C'est l'argument de différenciation technique de Scalario : un dev (Carlos) maintient une seule base, et tous les utilisateurs voient le même produit.

**Cas d'usage Phase 1 :**
- **Android (priorité absolue)** : Blandine en pharmacie, terrain, Snapdragon 680, écran 5-6", offline-first. C'est le 80% du trafic Phase 1.
- **iOS (Phase 1 nice-to-have)** : managers (Ibrahim) qui ont un iPhone. Build fonctionnel, pas optimisé.
- **Web (admin only Phase 1)** : Carlos qui pilote depuis un laptop, fournisseurs IT certifiés, partenaires intégrateurs. Le client mobile reste l'expérience principale ; le web sert au pilotage admin.

Cette story ne livre **pas** un nouveau composant. Elle livre la **garantie cross-plateforme** :
1. Les 3 builds compilent et tournent.
2. Les breakpoints (STORY-007) routent correctement vers les variantes responsives.
3. Les API plateforme-spécifiques (Bluetooth POS, fonts offline, file picker) ont des fallbacks documentés ou des stubs Phase 1.
4. Le PWA installable est configuré (manifest + service worker).
5. Le CI matrix construit les 3 cibles à chaque PR.

**Cf. PRD §FR-001b ligne 201, sprint plan ligne 280, NFR-008 architecture ligne 926.**

### Scope

**In scope :**

- **Build Android** :
  - Configuration `apps/flutter/android/` : `minSdkVersion 26` (Android 8.0+), `targetSdkVersion 34`.
  - Signing config debug + placeholder release (vraies clés en STORY-046 release management).
  - Tests sur émulateur Snapdragon 680 (mid-range) et Pixel 6 (high-end).
  - APK + AAB générés en CI sur chaque PR `main`.
- **Build iOS** :
  - Configuration `apps/flutter/ios/` : `iOS 14+` deployment target.
  - Capabilities : Bluetooth (préparation pour Phase 2 connexion balance/imprimante), Camera (préparation Phase 2 scan code-barre).
  - Build sur simulateur iPhone 13 / iPad Air en CI.
  - Pas de signing prod Phase 1 (Carlos n'a pas encore de compte Apple Developer ; placeholder).
- **Build Web** :
  - Configuration `apps/flutter/web/` :
    - `index.html` avec meta viewport + theme color.
    - `manifest.json` pour PWA installable.
    - Service Worker généré par Flutter (`flutter_service_worker.js`) pour cache assets + offline fallback.
  - Cibles : Chrome 90+, Safari 14+, Firefox 88+ (testées via headless browser CI).
  - Renderer Flutter Web : **CanvasKit** (perfo) pour desktop, **HTML** (lighter) en fallback mobile web. Décision documentée.
- **Couche d'adaptation plateforme** :
  - Package `lib/core/platform/` :
    - `platform_info.dart` — `PlatformInfo.isAndroid`, `isIOS`, `isWeb`, `isMobileWeb`, `isDesktopWeb`.
    - `platform_capabilities.dart` — feature flags par plateforme (Bluetooth dispo ? File picker ? Camera ?).
    - `platform_specific/` — implémentations dédiées (utiliser `conditional imports` Dart pour tree-shake).
- **Règle architecturale** :
  - Aucun composant DS ni widget BDUI ne doit contenir un `if (kIsWeb) ... else if (Platform.isIOS) ...` direct. Tout passe par `PlatformCapabilities`. Vérifié par lint custom.
- **CI Matrix** :
  - GitHub Actions (ou équivalent) : 3 jobs parallèles (android-build, ios-build, web-build) sur chaque PR.
  - Web build → déployé en staging URL `staging.scalario.app` via Cloudflare Pages ou Vercel (configuration STORY-046).
- **Tests** :
  - Smoke test sur les 3 plateformes : ouverture sandbox, sélection `retail_dashboard.json`, screen rendu sans erreur.
  - Test breakpoint web : dimension fenêtre 360 → mobile layout, 1440 → desktop layout.
  - Test PWA install prompt : sur Chrome desktop, le manifest déclenche l'install icon.

**Out of scope (autres stories) :**

- Bluetooth runtime (connexion réelle balance / imprimante POS) → STORY-PD-XX (Pharmacie/Retail).
- Camera scan code-barre → backlog Phase 2.
- Offline web (Drift IndexedDB) → STORY-035 (FR-052).
- Prod signing iOS (compte Apple Developer + provisioning profiles) → STORY-046 release.
- App Store / Play Store deployment → backlog Phase 2.
- Optimisation perfo Web (lazy loading, code split) → backlog Phase 2 si bottleneck mesuré.
- Tests sur appareils physiques iOS → Phase 2 quand Carlos a un device de test (utiliser BrowserStack en attendant).

### User Flow

**Cas Android (Blandine) :**
1. Blandine reçoit le lien APK via WhatsApp d'Ibrahim.
2. Sideload APK Android 8.0+. App lance ; splash screen ; login.
3. Toutes les features BDUI fonctionnent identiques (sandbox dev mode pour la Phase 1).

**Cas Web (Carlos) :**
1. Carlos ouvre `https://staging.scalario.app` sur Chrome.
2. App Flutter Web charge en < 4s (CanvasKit ~3MB compressed).
3. Manifest détecté → "Installer l'app" dans la barre URL.
4. Carlos clique → app installée en PWA, lance comme une app native.
5. Layout adapté desktop (LayoutResolver `> 1024px`).

**Cas iOS (Ibrahim, Phase 1 simulateur) :**
1. Build TestFlight Phase 2. En Phase 1, smoke test sur simulator iPhone 13.
2. App fonctionne identique à Android.

---

## Acceptance Criteria

### Builds — Compilation et lancement

- [ ] AC-01 — `flutter build apk --release` produit un APK de < 30MB (objectif performance pour réseaux UEMOA lents).
- [ ] AC-02 — `flutter build appbundle --release` produit un AAB upload-ready Play Store (placeholder signing Phase 1).
- [ ] AC-03 — `flutter build ios --release --no-codesign` compile sans erreur (signing Phase 2).
- [ ] AC-04 — `flutter build web --release` produit un bundle Web avec service worker fonctionnel.
- [ ] AC-05 — APK installé sur émulateur Snapdragon 680 — app lance en < 3s, ouvre sandbox, rend `retail_dashboard.json` sans erreur (smoke test enregistré en CI).
- [ ] AC-06 — Build iOS lance sur simulator iPhone 13 — smoke test équivalent.
- [ ] AC-07 — Build Web servi via `flutter run -d chrome` — smoke test équivalent (Chrome 120+).

### Configuration plateforme

- [ ] AC-08 — **Android** : `android/app/build.gradle.kts` (ou Groovy) : `minSdk 26`, `targetSdk 34`, `compileSdk 34`. ProGuard rules placeholder pour Phase 1 (sans obfuscation).
- [ ] AC-09 — **iOS** : `ios/Runner/Info.plist` : `MinimumOSVersion 14.0`, `UIRequiredDeviceCapabilities`. Capabilities Bluetooth + Camera déclarées (utilisation Phase 2).
- [ ] AC-10 — **Web** : `web/index.html` avec meta viewport `width=device-width, initial-scale=1.0`, theme-color = `ScalarioColors.primary500`, favicon Scalario.
- [ ] AC-11 — **Web** : `web/manifest.json` PWA :
  - `name: "Scalario"`, `short_name: "Scalario"`.
  - `start_url: "/"`, `display: "standalone"`.
  - `theme_color`, `background_color` depuis tokens.
  - Icônes 192x192 et 512x512 (PNG depuis logo Scalario monogramme).
- [ ] AC-12 — **Web** : `flutter_service_worker.js` (généré) cache les assets Flutter + retry-on-offline pour `index.html`.

### Renderer Flutter Web

- [ ] AC-13 — Renderer **CanvasKit** par défaut sur desktop (`> 1024px`) pour qualité de rendu.
- [ ] AC-14 — Renderer **HTML** sur mobile web (`< 768px`) pour bundle plus léger (~700KB vs 3MB CanvasKit).
- [ ] AC-15 — Switch via `flutter run --web-renderer canvaskit|html` ou config build : utiliser `--web-renderer auto` (Flutter détecte). Documenter le choix.

### Couche d'adaptation plateforme

- [ ] AC-16 — `PlatformInfo` exposé : `isAndroid`, `isIOS`, `isWeb`, `isMobileWeb` (web + width <768), `isDesktopWeb` (web + width ≥1024). Tous getters statiques.
- [ ] AC-17 — `PlatformCapabilities` :
  - `bluetoothAvailable: bool` (true sur mobile, false sur web Phase 1).
  - `cameraAvailable: bool` (true mobile, true web si HTTPS, false sinon).
  - `filePickerAvailable: bool` (true partout).
  - `pushNotificationsAvailable: bool` (true mobile, false web Phase 1).
- [ ] AC-18 — Aucun composant `lib/components/` ni `lib/features/` ne contient de check `kIsWeb` ou `Platform.is*` direct — vérifié par lint CI (grep contre `kIsWeb`, `Platform\.is`).
- [ ] AC-19 — Conditional imports utilisés pour les implémentations plateforme-spécifiques (ex: `import 'storage_io.dart' if (dart.library.html) 'storage_web.dart'`).

### LayoutResolver — Breakpoints sur web

- [ ] AC-20 — Test : ouvrir l'app web dans Chrome avec viewport `360x740` → composants rendus en variante `mobile` (LayoutResolver). Resize fenêtre à `1440x900` → re-render en variante `desktop`. Aucune erreur, aucun flicker.
- [ ] AC-21 — `MediaQuery.size.width` correctement lu sur web (équivalent à window.innerWidth).
- [ ] AC-22 — Test : LayoutResolver fallback sur android 5" (~360 logical) → mobile ; tablette 10" (~800 logical) → tablet ; iPad Pro 12.9" (~1024+) → desktop.

### CI Matrix

- [ ] AC-23 — `.github/workflows/build-multiplatform.yml` (ou équivalent) avec 3 jobs :
  - `android-build` : `flutter build apk --release`, smoke test émulateur, upload APK artifact.
  - `ios-build` : `flutter build ios --release --no-codesign`, smoke test simulator, upload bundle artifact.
  - `web-build` : `flutter build web --release`, smoke test headless Chrome, deploy preview URL.
- [ ] AC-24 — Tous les jobs CI passent sur la PR de cette story (et restent verts en non-régression).

### PWA & déploiement web

- [ ] AC-25 — Web staging déployé à `staging.scalario.app` (Cloudflare Pages, Vercel, ou serveur VPS Phase 1 — décision STORY-046).
- [ ] AC-26 — Lighthouse audit web : `Performance ≥ 70`, `Accessibility ≥ 90`, `Best Practices ≥ 90`, `SEO ≥ 80`, `PWA installable: yes`. Scores documentés dans la PR.
- [ ] AC-27 — PWA install prompt apparaît dans Chrome desktop (manuel test, screenshot dans la PR).

### Tests

- [ ] AC-28 — Smoke tests automatisés sur les 3 plateformes (intégrés au CI matrix) — exécution sandbox + rendu d'un screen.
- [ ] AC-29 — Tests unitaires `PlatformInfo` + `PlatformCapabilities` (mock plateforme, vérification getters).
- [ ] AC-30 — Couverture ≥ 80% sur `lib/core/platform/`.

---

## Technical Notes

### Composants concernés

- **Nouveau package :** `apps/flutter/lib/core/platform/`.
- **Configuration :** `apps/flutter/android/`, `apps/flutter/ios/`, `apps/flutter/web/`.
- **CI :** `.github/workflows/build-multiplatform.yml`.
- **Hosting staging web :** Cloudflare Pages ou Vercel (décision tactique en STORY-046).

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   └── core/
│       └── platform/
│           ├── platform_info.dart
│           ├── platform_capabilities.dart
│           ├── platform.dart                  # barrel
│           └── platform_specific/
│               ├── storage_io.dart            # mobile + desktop
│               ├── storage_web.dart           # IndexedDB (Drift web hook)
│               └── conditional/
│                   └── platform_router.dart   # conditional import bridge
├── android/
│   └── app/
│       └── build.gradle.kts                   # minSdk 26, targetSdk 34
├── ios/
│   └── Runner/
│       └── Info.plist                         # iOS 14+, capabilities
├── web/
│   ├── index.html                             # viewport + theme-color
│   ├── manifest.json                          # PWA
│   ├── icons/
│   │   ├── icon-192.png
│   │   └── icon-512.png
│   └── favicon.png
├── test/
│   └── core/
│       └── platform/
│           ├── platform_info_test.dart
│           └── platform_capabilities_test.dart
└── .github/
    └── workflows/
        └── build-multiplatform.yml
```

### Pattern Dart recommandé

```dart
abstract final class PlatformInfo {
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS     => !kIsWeb && Platform.isIOS;
  static bool get isWeb     => kIsWeb;

  static bool isMobileWeb(BuildContext ctx) =>
      isWeb && MediaQuery.of(ctx).size.width < 768;
  static bool isDesktopWeb(BuildContext ctx) =>
      isWeb && MediaQuery.of(ctx).size.width >= 1024;
}

abstract final class PlatformCapabilities {
  static bool get bluetoothAvailable     => !kIsWeb;
  static bool get cameraAvailable        => true;
  static bool get filePickerAvailable    => true;
  static bool get pushNotifsAvailable    => !kIsWeb;
}
```

Pour les fonctionnalités plateforme-spécifiques :

```dart
// lib/core/platform/platform_specific/storage.dart
export 'storage_io.dart' if (dart.library.html) 'storage_web.dart';
```

### Spec source — résolution du conflit

**1. Renderer Web (CanvasKit vs HTML)** : Phase 1, le PRD ne tranche pas. La spec architecture (ligne 145) parle de Flutter Web sans préciser. **Décision pragmatique** : `--web-renderer auto` qui choisit selon la device (CanvasKit desktop, HTML mobile web). Documenté ; à revisiter si Lighthouse score insuffisant.

**2. Bluetooth runtime Phase 1** : le sprint plan ne le mentionne pas spécifiquement, mais EPIC-007 (templates Pharmacie/Retail) implique potentiellement balance/imprimante. **Décision** : préparer les capabilities iOS/Android (déclaration manifest), mais ne pas implémenter le runtime. Stories Phase 1 = STORY-PD ne dépendent pas du Bluetooth réel ; on simule avec un `BluetoothDeviceSelector` qui renvoie des stubs.

**3. PWA Phase 1** : le sprint plan ligne 290 demande "PWA installable". Cohérent avec FR-001b. **Décision** : manifest + service worker générés par Flutter. Le service worker offline complet (cache stratégique) est repoussé en STORY-035 (Offline Web FR-052) Should Have.

### Edge cases

- **Android API 25 et inférieur** : non supporté. `minSdk 26`. Si un utilisateur a un device 5+ ans, message clair en sortie de signature APK install.
- **iOS Safari Web (mobile web)** : Flutter Web rend mais avec quelques limitations (CSS scroll, pickers natifs). Documenter ; tester manuellement Phase 1.
- **Firefox Web Service Worker** : moins permissif que Chrome. Tester en CI Firefox au moins le manifest.
- **Web bundle size** : CanvasKit ajoute ~3MB. Pour UEMOA (latence + débit), critique. Mesure cible : `flutter build web --release` < 5MB total compressed (Brotli). Si dépassement, basculer en HTML renderer par défaut + dégradation visuelle acceptée.
- **Hot reload sur web** : Flutter Web hot reload est plus lent que mobile. Documenter pour les devs.
- **`MediaQuery.of(ctx)` en mobile web** : retourne la viewport CSS, pas la device pixel size. Le LayoutResolver doit donc bien se baser sur `MediaQuery.size.width`, pas sur `WidgetsBinding.window.physicalSize`.
- **iOS notch / safe area** : tous les widgets utilisent `SafeArea`. Vérifié par revue manuelle des layouts STORY-007.
- **Splash screen white flash** : sur Android, `flutter_native_splash` configuré (couleur `ScalarioColors.primary500`). Sur web, splash via `index.html` styled.

### Sécurité

- **Web HTTPS** : tous les builds web déployés via HTTPS uniquement (Cloudflare/Vercel par défaut). `Service Worker` ne fonctionne qu'en HTTPS — natural enforcement.
- **CSP header** : configurer `Content-Security-Policy` strict côté staging (pas de `unsafe-inline`, pas de `unsafe-eval`). Phase 2 — mais documenter dès cette story.
- **APK signature** : Phase 1 = debug key. Phase 2 = upload key Play Store + verified rotation. Documentation dans `docs/security-android.md`.
- **iOS** : pas de jailbreak detection Phase 1 ; documenter pour Phase 2.

### Performance

- Bundle Web cible : < 5MB total compressed.
- APK release : < 30MB.
- iOS IPA : ~ même range qu'APK.
- Service Worker : cache assets, fallback offline pour `index.html`.

---

## Dependencies

**Prérequis :**

- STORY-001 (tokens) — `merged` (pour les couleurs splash + theme-color web).
- STORY-007 (LayoutResolver) — `merged` (breakpoints essentiels).
- STORY-008 (BDUIEngine) — `merged` (smoke test rend un écran réel).
- Logo Scalario monogramme (asset PNG 192/512) — coordination avec design ; à fournir avant la PR.

**Stories bloquées par celle-ci :**

- STORY-035 (Offline Web FR-052) — directe.
- STORY-046 (Release management — signing, store deploy) — directe.
- Toutes les stories EPIC-007 (Sprint Demo) qui veulent une démo web.

**Externes :**

- Compte Cloudflare Pages ou Vercel (Phase 1 — gratuit suffisant).
- Compte Apple Developer Phase 2 (pas Phase 1).
- Émulateur Android Snapdragon 680 ou GitHub Actions runner avec android-emulator action.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-012-multiplatform`.
- [ ] `flutter analyze` passe sans warning.
- [ ] `flutter test test/core/platform/` vert avec ≥ 80% coverage.
- [ ] CI matrix `.github/workflows/build-multiplatform.yml` vert sur les 3 jobs.
- [ ] APK release < 30MB ; bundle web release < 5MB compressed (mesures dans la PR).
- [ ] Smoke tests sur 3 plateformes passent (sandbox + rendu retail_dashboard.json).
- [ ] Web staging déployé et accessible (URL dans la PR).
- [ ] Lighthouse audit web ≥ 70/90/90/80/PWA-installable (rapport dans la PR).
- [ ] Aucun `kIsWeb` ni `Platform.is*` direct dans `lib/components/` ni `lib/features/` (vérifié par grep CI).
- [ ] Documentation `docs/multi-platform.md` couvre les 3 plateformes + breakpoints + capabilities + workflow CI.
- [ ] Code review passé.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour par l'orchestrateur (STORY-012 status `completed`, completed_points sprint 2 += 5).

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Configuration Android (build.gradle, signing placeholder, splash) | 0.5 | Standard, mais à blinder pour Snapdragon 680. |
| Configuration iOS (Info.plist, capabilities, simulator smoke) | 0.5 | Configuration sans signing prod. |
| Configuration Web (index.html, manifest.json, service worker) | 1 | PWA proprement configurée + icônes + meta + theme-color. |
| `PlatformInfo` + `PlatformCapabilities` + tests | 0.5 | Petit code, mais base de toute la couche d'adaptation. |
| Conditional imports + `platform_specific/` stubs | 0.25 | Préparation pour stories futures. |
| CI matrix workflow `.github/workflows/build-multiplatform.yml` | 1 | 3 jobs parallèles, smoke tests, artifact uploads. |
| Web staging deploy (Cloudflare Pages ou Vercel) | 0.5 | Setup compte + config DNS staging.scalario.app. |
| Smoke tests intégrés CI + Lighthouse audit | 0.5 | Headless Chrome script, capture résultats. |
| Lint custom no-direct-platform-check + grep CI | 0.25 | Script bash. |
| **Total** | **5** | Fibonacci 5 — moderate, infrastructure transverse. |

**Rationale :** Chaque plateforme a ses configs propres (Gradle, Info.plist, manifest.json) + un CI matrix qui les garde verts. Le filet anti-régression (lint + smoke tests + Lighthouse) est ce qui empêche un dev de "fix" pour Android et casser silencieusement Web en sprint 4. Le coût "réel" de cette story = la mise en place du CI matrix + déploiement staging — sans quoi on découvre les casses à la démo. 5 points est juste — ne pas sous-estimer le tooling devops Phase 1.

---

## Notes additionnelles

- **Promesse différenciante Scalario** : "même app partout depuis un codebase unique". Cette story matérialise la promesse. Quand un investisseur demande "ça marche aussi sur web ?", Carlos ouvre `staging.scalario.app` sur son laptop et l'app tourne — même JSON, même rendu, même UX adaptée.
- **Single codebase ≠ identical UX** : un mobile en pharmacie a des contraintes différentes d'un desktop admin. Le LayoutResolver gère la responsivité ; mais certaines features (Bluetooth POS) restent logiquement mobile-only — c'est OK et documenté dans `PlatformCapabilities`.
- **Phase 2 Bluetooth POS** : balance Bluetooth (FR-PD) + imprimante thermique. Implementation plateforme-spécifique via `platform_specific/`. La couche d'adaptation livrée ici est ce qui rendra l'ajout naturel.
- **iOS prod Phase 2** : Carlos ouvrira un compte Apple Developer (~99$/an) quand un client iOS le justifiera. Phase 1 = simulateur uniquement. Pas de blocage produit (Blandine + Ibrahim sur Android).
- **Logo Scalario** : monogramme PNG 192/512 nécessaire pour favicon + PWA icon. Respecter la règle (Sc, jamais S seul). Coordination design.
- **Pattern Showcase (cf. mémoire utilisateur)** : créer `platform_capabilities_showcase.dart` qui affiche les flags actuels — utile pour debug + démo.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
