# STORY-009 : Sandbox JSON + Hot Reload Dev

**Epic :** EPIC-002 — BDUI Engine Flutter
**Priorité :** Must Have
**Story Points :** 3
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 1 (2026-05-12 → 2026-05-23)
**Dependencies :** STORY-008 (BDUIEngine) — pour le rendu. Note : STORY-008 est planifiée Sprint 2 ; cette story prend en parallèle un **stub** d'Engine ou démarre Sprint 2 derrière. Décision : ajuster ce point avec STORY-008. Voir "Spec source" ci-dessous.

---

## User Story

> **En tant que** dev Flutter sur Scalario,
> **je veux** un écran sandbox qui charge un fichier JSON local et affiche immédiatement le résultat rendu par le BDUIEngine, avec hot reload sur modification du fichier,
> **so that** je peux tester n'importe quel layout en < 1 seconde sans backend ni redémarrage de l'app — c'est l'outil de dogfood quotidien du BDUI.

---

## Description

### Background

Le BDUIEngine (STORY-008) prend un JSON et rend un screen. Mais sans backend Phase 1 et sans Drift cache encore branché (Sprint 3), comment un dev teste-t-il que ça marche ?

La **sandbox** résout ce problème. C'est un écran dev-only (`kDebugMode`) accessible via une route cachée (`/dev/sandbox`) qui :

1. Liste les fichiers JSON sous `assets/sandbox/`.
2. Sur sélection, charge le fichier et appelle `BDUIEngine.render(...)`.
3. Surveille le fichier (file watcher) → recharge automatiquement à chaque sauvegarde, **sans hot restart de l'app**.

C'est l'**outil de validation principal** des templates IA pendant tout EPIC-007 (Sprint Demo) : un dev modifie un JSON, sauvegarde, et voit le rendu update instantanément — sans cycle dev classique (build + emulator restart de 30 secondes).

**Cf. PRD §FR-006 ligne 259 :** "Preuve que le BDUI fonctionne bout en bout."

C'est aussi la première **démonstrable** que la promesse "n'importe quel JSON → un screen" est réelle. C'est le moment où Carlos peut montrer à Ibrahim ou à un investisseur "regarde, je change ce JSON et l'écran change".

### Scope

**In scope :**

- Package `lib/sandbox/` (dev-only, exclu du release build via `kDebugMode` guard) :
  - `sandbox_screen.dart` — écran principal avec sélecteur de fichier + zone de rendu BDUI.
  - `sandbox_file_watcher.dart` — détection de modification de fichier (`dart:io` File watcher pour mobile/desktop ; pour Flutter Web, polling ou désactivé — voir edge cases).
  - `sandbox_json_loader.dart` — lit `assets/sandbox/*.json`, parse, retourne `ScreenConfig`.
  - `sandbox_error_view.dart` — vue d'erreur dédiée dev qui affiche le JSON path + line/col du parse error.
- Liste de fichiers fixtures fournis :
  - `assets/sandbox/retail_dashboard.json` (déjà créé par STORY-008 — réutilisé).
  - `assets/sandbox/simple_form.json` (idem).
  - `assets/sandbox/transactions_list.json` (idem).
  - `assets/sandbox/empty_screen.json` — minimal (titre + 1 EmptyState).
  - `assets/sandbox/error_state.json` — composant volontairement invalide pour tester ErrorBoundary.
- Sélecteur de UserContext mock (DropdownButton) : OWNER, ADMIN, MANAGER, CASHIER, CASHIER_LIMITED → permet de tester `visible_if` rapidement.
- Sélecteur de breakpoint (mobile/tablet/desktop) : redimensionne le viewport sandbox via `MediaQuery` overlay → permet de valider la responsivité sans changer de device.
- Hot reload custom : file watcher déclenche `setState()` qui re-call `bduiEngine.loadScreen` (cache invalidé pour ce screenId) → re-render < 300ms après save.
- Affiché **uniquement en `kDebugMode`** : la route `/dev/sandbox` n'existe pas en release build (vérifié par tests).
- Exclu du tree-shaking release : utiliser `kDebugMode` guards et idéalement un flavor Flutter dédié ou pragma `assert`.

**Out of scope (autres stories) :**

- BDUIEngine lui-même → STORY-008.
- Mode production navigation BDUI → STORY-021 (Navigation dynamique).
- Hot reload du backend (NestJS catalog) → STORY-040.
- Outil d'édition JSON (linter visuel, autocomplete) → backlog Phase 2.
- Distribution de la sandbox aux non-devs → backlog Phase 2 (Widgetbook STORY-004 couvre une partie).

### User Flow (Developer Experience)

1. Dev lance l'app en debug (`flutter run`).
2. Dans l'app login screen, swipe à 4 doigts vers le bas (ou bouton caché en debug) → ouvre `/dev/sandbox`.
3. Sandbox affiche :
   - Header : sélecteur fichier (Dropdown listant `assets/sandbox/*.json`), sélecteur UserContext mock, sélecteur breakpoint.
   - Body : rendu du screen sélectionné via BDUIEngine, dans un viewport contraint si breakpoint != desktop.
4. Dev sélectionne `retail_dashboard.json` → screen rendu en < 200ms.
5. Dev ouvre le fichier dans VS Code, modifie un titre KPI, sauvegarde.
6. File watcher détecte le changement → invalide cache mémoire BDUIEngine pour ce screen → setState → re-render en < 300ms total (file event + invalidation + render).
7. Dev change le UserContext de `OWNER` à `CASHIER` → re-render avec composants masqués selon `visible_if`.
8. Dev change breakpoint de `mobile` à `desktop` → MediaQuery overlay change la largeur → LayoutResolver bascule.
9. Si JSON invalide à la sauvegarde, sandbox affiche `SandboxErrorView` avec le path JSON + raison (ex: `zones.kpis[2].props.value: expected number, got "abc"`). Le dev corrige, re-save → resync.

---

## Acceptance Criteria

### Accessibilité dev-only

- [ ] AC-01 — Route `/dev/sandbox` enregistrée **uniquement** en `kDebugMode`. En release build (`flutter run --release`), accéder à la route → 404 / fallback login screen.
- [ ] AC-02 — Vérification automatisée : test golden release build qui tente de naviguer vers `/dev/sandbox` → screen non trouvé.
- [ ] AC-03 — Le code de `lib/sandbox/` est exclu du bundle release via `kDebugMode` guards en haut de chaque fichier (commentaire dev only) ou via flavor Flutter.

### UI sandbox

- [ ] AC-04 — Header avec 3 sélecteurs :
  - Dropdown fichier JSON : liste tous les `assets/sandbox/*.json` détectés au boot.
  - Dropdown UserContext : 5 presets (OWNER, ADMIN, MANAGER, CASHIER, CASHIER_LIMITED) + un preset "Custom JSON" qui ouvre un text field pour saisir un context arbitraire.
  - Dropdown breakpoint : 3 options (mobile 360x740, tablet 768x1024, desktop 1440x900). Default = device actuel.
- [ ] AC-05 — Body : zone de rendu BDUI dans un `Container(width: bp.width, height: bp.height)` clipped, scrollable si overflow.
- [ ] AC-06 — Bouton "Reload" manuel en haut à droite (icône refresh) qui force un `loadScreen` cache-invalidé.
- [ ] AC-07 — Bouton "Reset" qui retourne à la sélection initiale.

### Hot reload

- [ ] AC-08 — Sur mobile/desktop : file watcher (`dart:io File.watch`) détecte `assets/sandbox/<fichier>.json` modifié → re-render automatique en **< 300ms** total après save (mesure : event reçu → invalidate cache → setState → next frame rendu).
- [ ] AC-09 — Sur Flutter Web : file watcher non disponible → fallback polling toutes les 1.5s (vérifie `lastModified` via fetch HEAD). Documenté comme limitation acceptable dev-only.
- [ ] AC-10 — Pendant le re-render, indicateur visuel discret (loader 80x80 overlay coin haut-droit pendant 300ms).

### Robustesse JSON invalide

- [ ] AC-11 — JSON syntaxiquement invalide (`{ "screen": "x", `) → `SandboxErrorView` affiche : path fichier, ligne/colonne du parse error, message du parser, action "Réessayer" qui re-tente.
- [ ] AC-12 — JSON valide syntaxiquement mais invalide schema (composant inconnu, layout inconnu, type mismatch) → `SandboxErrorView` affiche le path du nœud fautif (`zones.kpis[2].type: "FooBar" not in registered components`) + la liste des types valides à proximité.
- [ ] AC-13 — JSON qui rend un screen avec un composant qui throw → `BDUIErrorBoundary` du composant prend le relais (fallback UI per-component, STORY-010), reste du screen fonctionnel. Un log structuré apparaît dans une console sandbox dev.
- [ ] AC-14 — Aucune exception propage à un point de crashe la sandbox elle-même.

### Fixtures inclues

- [ ] AC-15 — 5 fichiers JSON dans `assets/sandbox/` :
  - `retail_dashboard.json` — dashboard OWNER complet (kpis + DataTable + ActionButtons).
  - `simple_form.json` — formulaire 4 champs avec validation.
  - `transactions_list.json` — list layout + filters + 20 entries.
  - `empty_screen.json` — minimum viable (1 EmptyState + 1 ActionButton).
  - `error_state.json` — contient volontairement un composant `type: "DoesNotExist"` pour tester le fallback.
- [ ] AC-16 — Chaque fixture est valide contre `screen-config.schema.json` (sauf `error_state.json` volontairement) — vérifié par script CI.

### UserContext mock

- [ ] AC-17 — `SandboxUserContextProvider` permet de basculer entre les 5 presets en runtime sans restart.
- [ ] AC-18 — Le preset "Custom JSON" parse un text input en `UserContext` ; erreur de format → message inline.
- [ ] AC-19 — Changement de UserContext → re-render automatique avec les nouvelles règles `visible_if`.

### Tests

- [ ] AC-20 — Tests widget de la sandbox :
  - Sélection fichier → screen rendu.
  - Modification simulée du fichier (file mock) → re-render déclenché.
  - JSON invalide → `SandboxErrorView` rendu.
  - UserContext switch OWNER → CASHIER → composants `visible_if: role: ['OWNER']` masqués.
- [ ] AC-21 — Test "release build n'expose pas la route" — exécuté avec `--release` ou flag équivalent.
- [ ] AC-22 — Couverture ≥ 80% sur `lib/sandbox/` (moins strict que le moteur car code dev-only).

---

## Technical Notes

### Composants concernés

- **Nouveau package :** `apps/flutter/lib/sandbox/` (dev-only).
- **Dépend de :** `lib/engine/bdui_engine/` (STORY-008).
- **Pattern :** route Flutter `/dev/sandbox` enregistrée conditionnellement dans `lib/main.dart` :

```dart
final routes = {
  '/login': (ctx) => const LoginScreen(),
  '/home': (ctx) => const HomeScreen(),
  if (kDebugMode) '/dev/sandbox': (ctx) => const SandboxScreen(),
};
```

### Structure de fichiers (cible)

```
apps/flutter/
├── lib/
│   └── sandbox/
│       ├── sandbox_screen.dart
│       ├── sandbox_file_watcher.dart
│       ├── sandbox_json_loader.dart
│       ├── sandbox_user_context_provider.dart
│       ├── sandbox_breakpoint_overlay.dart
│       ├── sandbox_error_view.dart
│       └── sandbox_console.dart          # dev console pour logs
├── assets/
│   └── sandbox/
│       ├── retail_dashboard.json
│       ├── simple_form.json
│       ├── transactions_list.json
│       ├── empty_screen.json
│       └── error_state.json
├── test/
│   └── sandbox/
│       ├── sandbox_screen_test.dart
│       ├── sandbox_file_watcher_test.dart
│       └── sandbox_release_exclusion_test.dart
```

### Pattern Dart recommandé

```dart
class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  String? _selectedFile;
  Breakpoint _breakpoint = Breakpoint.desktop;
  late final SandboxUserContextProvider _userCtxProvider;
  StreamSubscription<FileSystemEvent>? _watcherSub;

  @override
  void initState() {
    super.initState();
    _userCtxProvider = SandboxUserContextProvider();
    _userCtxProvider.addListener(_onUserCtxChanged);
  }

  void _selectFile(String path) {
    _watcherSub?.cancel();
    setState(() => _selectedFile = path);

    if (!kIsWeb) {
      // dart:io File.watch — mobile + desktop
      _watcherSub = File(path).watch().listen((event) {
        if (event.type == FileSystemEvent.modify) {
          _reloadFile();
        }
      });
    } else {
      // Polling lastModified pour Flutter Web
      _startPolling(path);
    }
  }

  void _reloadFile() {
    GetIt.I<BDUIEngine>().invalidateCache(_selectedFile!);
    setState(() {}); // trigger rebuild
  }
  // ...
}
```

### Spec source — résolution du conflit dépendance

Le sprint plan ligne 240 dit : "Dependencies : STORY-008". Mais STORY-008 est en Sprint 2 et celle-ci en Sprint 1. **Conflit.**

**Décision :** réordonner — cette story (STORY-009) **passe en Sprint 2** dans la pratique, ou bien Sprint 1 livre une **version stub** :
- Stub Sprint 1 : la sandbox lit le JSON, affiche le `JsonView` brut + une zone "BDUIEngine output (Sprint 2)" en placeholder. Cela permet aux devs de valider les fixtures JSON et d'avoir l'infra de file watcher prête.
- Version complète Sprint 2 : branche le BDUIEngine quand STORY-008 mergée.

**Recommandation :** garder la story formellement Sprint 1 (3 points) mais faire l'**intégration BDUIEngine en début Sprint 2 dès STORY-008 mergée**. Ce micro-glissement est documenté en commentaire dans le sprint-status.yaml.

Le sprint plan PRD/sprint sera ajusté en `correct-course` mid-sprint si bloqué.

### Edge cases

- **Asset reload Flutter** : changer un fichier dans `assets/` ne déclenche **pas** automatiquement le reload Flutter. Il faut soit utiliser `rootBundle.load(...)` qui re-lit au runtime, soit charger les JSON depuis le filesystem (`File(path).readAsStringSync()`) en dev. Choix : **filesystem direct en dev** (le path absolu est résolu via `assets/sandbox/`), `rootBundle` en fallback. Documenter dans `sandbox_json_loader.dart`.
- **Flutter Web — pas de filesystem** : file watcher impossible. Polling toutes les 1.5s sur l'URL de l'asset. Limitation acceptable car Flutter Web sandbox sert principalement à valider le rendu desktop, pas le hot reload.
- **iOS dev** : `dart:io File.watch` fonctionne sur le simulateur. En physique, requiert que le fichier soit accessible — limite Phase 1, on documente "test sur emulator" dans le README.
- **Multiples sandbox ouvertes simultanément** : impossible (single screen). OK.
- **Modifier le JSON pendant un render en cours** : les invalidations cache + setState doivent être debouncées (200ms) pour éviter le flicker en cas de save multiples rapprochés.
- **Cache global BDUIEngine** : `invalidateCache(screenId)` doit être exposé par STORY-008. Si pas dispo en S1 stub, sandbox `setState` suffit (cache memory miss).
- **Composant qui crash silencieusement** : la sandbox ouvre une `SandboxConsole` discrète en bas qui montre les logs BDUI structurés (filtrés sur cette session). Aide énorme au debug.

### Sécurité

- **Sandbox jamais en prod** : c'est l'AC le plus critique. Une sandbox active en release = catastrophe (un attaquant pourrait charger des JSON arbitraires). Triple verrou :
  1. `kDebugMode` guards.
  2. Test release build CI.
  3. Code review check explicite "any new sandbox/ code wrapped in kDebugMode?".
- **Pas de PII dans les fixtures** : les fixtures `assets/sandbox/data/*.json` contiennent des données fake (Aïssata, "Tomate Locale", montants exemples). Vérifié par convention naming + revue PR.

### Performance

- Hot reload < 300ms total :
  - File event → ~10ms.
  - Cache invalidate → ~1ms.
  - setState + rebuild + render → ~200ms (cold render BDUIEngine).
  - Marge → ~89ms.
- Polling Web 1.5s → trade-off latence acceptable pour dev.

---

## Dependencies

**Prérequis :**

- STORY-008 (BDUIEngine) — `merged`. Si pas mergé en Sprint 1, version stub livrée et complétée Sprint 2.
- STORY-007 (LayoutResolver) — `merged` (breakpoint overlay nécessite breakpoints).

**Stories bloquées par celle-ci :**

- Aucune en termes de dépendance directe — c'est un outil dev. Mais elle accélère **toutes** les stories EPIC-007 (Sprint Demo) qui livrent des templates JSON.

**Externes :**

- Aucun.

---

## Definition of Done

- [ ] Code commité sur branche `feat/story-009-sandbox-hot-reload`.
- [ ] `flutter analyze` passe sans warning.
- [ ] `flutter test test/sandbox/` vert avec ≥ 80% coverage.
- [ ] 5 fixtures JSON dans `assets/sandbox/` valides (sauf `error_state.json` volontairement).
- [ ] Hot reload < 300ms vérifié manuellement (vidéo dans la PR).
- [ ] Test release build : route `/dev/sandbox` indisponible.
- [ ] Documentation README dev : `docs/dev-sandbox.md` avec screenshot + raccourci d'accès.
- [ ] Code review passé.
- [ ] PR mergée sur `main`.
- [ ] `_bmad-output/implementation-artifacts/sprint-status.yaml` mis à jour par l'orchestrateur (STORY-009 status `completed`, completed_points sprint += 3).

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `SandboxScreen` UI (3 sélecteurs + zone rendu + console) | 0.75 | Layout simple mais 3 widgets + responsivité interne. |
| `SandboxFileWatcher` (mobile/desktop + Web polling) | 0.5 | `dart:io File.watch` simple ; polling Web déco séparée. |
| `SandboxJsonLoader` + `SandboxErrorView` (parse error path/line) | 0.5 | Le path/line oblige à utiliser un parser JSON qui expose la position (`json_annotation` standard ne le donne pas → utiliser `package:json5` ou parsing manuel). |
| `SandboxUserContextProvider` + presets | 0.25 | Trivial. |
| `SandboxBreakpointOverlay` + MediaQuery wrapping | 0.25 | Wrap du Container avec `MediaQuery(data: ..)`. |
| 5 fixtures JSON | 0.25 | Réalistes, non triviales. |
| Tests widget + test exclusion release build | 0.25 | Le test release est important mais court. |
| Hot reload integration + cache invalidation BDUI | 0.25 | Petit câblage, mais à mesurer < 300ms. |
| **Total** | **3** | Fibonacci 3 — petit, outillage. |

**Rationale :** C'est de l'outillage dev. La complexité réelle est dans les détails (file watcher cross-plateforme, exclusion release build) plutôt que dans la logique. Ne pas sous-estimer le path/line dans `SandboxErrorView` — c'est ce qui rend la sandbox **vraiment utile**, sinon les devs vont déboguer à l'aveugle. Et triple-verrou release exclusion est non-négociable. 3 points est le bon prix.

---

## Notes additionnelles

- **Dogfooding interne :** Carlos doit utiliser cette sandbox **tous les jours** pour itérer sur les templates IA. Si elle est lente ou peu ergonomique, elle ne sera pas utilisée — donc pas mégoter sur la qualité UX dev.
- **Démo investisseur :** la sandbox est l'outil pour démontrer "data-driven UI" en live. Quand un investisseur demande "comment ça marche concrètement ?", on ouvre la sandbox, on modifie un JSON, on save, le screen change. Wow effect garanti.
- **Future Phase 2 — Sandbox web standalone :** pourrait évoluer vers un editeur JSON web hostant le BDUIEngine via Flutter Web. Permettrait aux non-devs (designers, partenaires intégrateurs) de prototyper. Backlog Phase 2.
- **Logo Scalario / branding :** non concerné (outil dev interne).

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
