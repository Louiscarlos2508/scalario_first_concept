# STORY-037 : Sync Status UI — Data-driven

**Epic :** EPIC-006 — Offline-First & Sync
**Priorité :** Must Have
**Story Points :** 3
**Status :** done
**Assigned To :** Carlos
**Created :** 2026-05-10
**Completed :** 2026-05-24
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-003 (composant `SyncStatusBar` du DS), STORY-008 (BDUIEngine), STORY-034 (queue état lisible), STORY-035 (conflicts table lisible)

---

## User Story

> **En tant qu'**utilisatrice de Scalario (Blandine, Ibrahim, Aïcha) qui peut perdre le réseau plusieurs fois par jour,
> **je veux** voir en permanence et de manière discrète si mes données sont synchronisées, en cours de sync, hors ligne, ou en conflit en attente de revue,
> **so that** je sache toujours dans quel état je travaille — sans alarme intrusive, sans modal bloquant — et je puisse résoudre les conflits depuis une UI claire.

---

## Description

### Background

Le composant DS `SyncStatusBar` (28px de haut, position bottom — `design-process/D-Design-System/components/01-feedback.md`) est déjà spécifié visuellement par STORY-003. Cette story le **branche** au pipeline réel : il consomme l'état de la queue (STORY-034) et de la conflict queue (STORY-035), expose un écran de revue des conflits, et est rendu **par le BDUIEngine depuis JSON** — pas hardcodé dans une page.

Le PRD §FR-058 + l'architecture §Composant 8 imposent :

1. La barre est rendue depuis le JSON tenant (config.layouts.global.sync_bar = {...}). Position et style configurables sans recompile.
2. 4 états visuels : "À jour" (success-500 vert discret), "Sync en cours…" (primary-500 bleu animé), "Hors ligne — données locales à jour" (neutral-500, jamais rouge), "X conflits en attente" (warning-500 ambre + badge compteur).
3. Tap sur la barre → expand : liste des mutations en attente avec timestamp + module + statut.
4. Tap sur "X conflits en attente" → écran `ConflictReviewScreen` (Phase 1 simple : JSON local vs serveur côte à côte + boutons "Garder local" / "Garder serveur").
5. Badge sur l'icône app (Android + iOS) si conflits en attente.

C'est la story qui rend l'offline-first **visible** pour l'utilisateur. Sans elle, Blandine ne saurait pas qu'elle a 12 mutations en attente.

### Scope

**In scope :**

- Widget Flutter `SyncStatusBar` (sous le composant DS de STORY-003) câblé sur un `SyncStatusController` Riverpod qui combine 3 sources : `connectivity_plus` (offline ?), `SyncQueueDao.streamCount()` (mutations en cours ?), `ConflictDao.streamPendingCount()` (conflits ?).
- 4 états calculés (priorité décroissante) :
  1. **conflicts_pending** : si `conflicts.count > 0` → "{N} conflit(s) en attente" (warning-500 + badge).
  2. **offline** : si `connectivity == none` → "Hors ligne — données locales à jour" (neutral-500).
  3. **syncing** : si `queue.count > 0` ET online → "Synchronisation… ({N} restantes)" (primary-500 animé).
  4. **synced** (default) : "À jour — il y a {Xmin}" (success-500 discret).
- BDUI rendering : la barre est définie dans le tenant config sous `layouts.global.sync_bar` :
  ```json
  {
    "type": "SyncStatusBar",
    "props": { "position": "bottom", "expandable": true },
    "source": { "kind": "sync_status_stream" }
  }
  ```
  Le `BDUIEngine` (STORY-008) résout `type=SyncStatusBar` via `ComponentRegistry`. Pas de hardcode dans `MainScaffold`.
- Tap → animation expand vers une carte (max 60% screen height) : liste des 20 dernières mutations queue + section "Conflits en attente" (si > 0) avec lien tap → `ConflictReviewScreen`.
- `ConflictReviewScreen` (route `/sync/conflicts`) : liste des conflits, tap → détail JSON local vs serveur côte à côte (Phase 1 simple : `JsonViewer` widget), boutons "Garder ma version" / "Garder serveur". Appelle `ConflictDao.resolve()` (STORY-035).
- Badge app icon Android (FlutterAppBadger ou `flutter_app_badger`) + iOS (UNUserNotificationCenter setBadge) avec count = `conflicts.count`.
- i18n strings (FR baseline) — pour `STORY-042` future. Phase 1 : strings hardcodées FR avec TODO.
- Tests widget : 4 états vérifiés en snapshot (golden tests) en Light + Dark.

**Out of scope :**

- Diff field-by-field UI (Phase 2 — pour l'instant JSON brut).
- Notifications push externes lors d'un conflit → Phase 2.
- Animation "Lottie" pour l'icône syncing → Phase 2 (Phase 1 : rotation simple Flutter).
- Détail mutation par mutation avec retry manuel → Phase 2 (Phase 1 : voir + comprendre, pas d'action retry manuelle).

### User Flow

**Flow 1 — Travail offline normal (Blandine) :**

1. Réseau coupe à 9h32. La barre passe de "À jour — il y a 2 min" (vert) → "Hors ligne — données locales à jour" (neutre gris).
2. Blandine continue à vendre. La barre reste neutre. Pas d'alerte.
3. À 10h05, le réseau revient. La barre passe à "Synchronisation… (8 restantes)" (bleu, icône qui tourne).
4. 6 secondes plus tard : "À jour — il y a 1s" (vert).

**Flow 2 — Conflit (Aïcha Owner) :**

1. Aïcha voit la barre en bas : "1 conflit en attente" (ambre, badge "1").
2. Tap → expand : section "Conflits" → "Stock tomates — local 10kg vs serveur 8kg".
3. Tap → `ConflictReviewScreen` détail. Voit JSON local vs serveur. Tap "Garder ma version".
4. Backend POST resolve. Barre passe à "Synchronisation…" puis "À jour".

---

## Acceptance Criteria

### Branchement Controller

- [ ] AC-01 — `SyncStatusController` (Riverpod `StreamProvider`) combine 3 streams : `Connectivity().onConnectivityChanged`, `SyncQueueDao.watchPendingCount()`, `ConflictDao.watchPendingCount()`. Réémet à chaque changement.
- [ ] AC-02 — Calcul de l'état effectif (priorité conflicts > offline > syncing > synced). Algorithme déterministe + testé unitairement.
- [ ] AC-03 — `lastSyncedAt` lu depuis `SyncQueueDao.lastSuccessAt()` (latest `processedAt` d'une mutation `success`).

### Rendu BDUI

- [ ] AC-04 — `ComponentRegistry` (STORY-005/008) enregistre `'SyncStatusBar': (c, ctx) => SyncStatusBar.fromConfig(c, ctx)`.
- [ ] AC-05 — Le tenant config JSON (`tenant_config.configJson.layouts.global.sync_bar`) est lu par le BDUIEngine au boot. Si absent : fallback default `{type:'SyncStatusBar', props:{position:'bottom', expandable:true}}`.
- [ ] AC-06 — Position `bottom` : la barre est insérée au-dessus de `BottomNav` (STORY-003 layout — `ux-rules/layout.md` ordre fixé).
- [ ] AC-07 — Hauteur exacte 28px (token `ScalarioSpacing.syncBarHeight` de STORY-001).

### États visuels (4)

- [ ] AC-08 — État `synced` : fond `bgCard` (light) / dark équivalent, texte `bodyMedium` couleur `success-500`, icône puce verte. Texte : "Synchronisé — il y a {Xmin}". Si `< 1min` → "à l'instant".
- [ ] AC-09 — État `syncing` : icône rotation 360° infinie 1.5s, couleur `primary-500`, texte `bodyMedium` "Synchronisation… ({N} restantes)".
- [ ] AC-10 — État `offline` : icône cercle vide `[○]`, couleur `neutral-500` (DS interdit le rouge — `ux-rules/principles.md`), texte "Hors ligne — données locales à jour". **Confirmé : pas rouge** (PRD ↔ DS, DS gagne — voir Tech Notes).
- [ ] AC-11 — État `conflicts_pending` : icône triangle `[⚠]`, couleur `warning-500`, texte "{N} conflit(s) en attente — toucher pour résoudre". Badge orange compteur visible. **Pas rouge** (DS rule).
- [ ] AC-12 — Transition entre états : fade 200ms (token `ScalarioMotion.fast`). Pas de teleport.

### Expand & detail panel

- [ ] AC-13 — Tap sur la barre quand `expandable=true` ouvre une carte modal-bottom-sheet (Material `showModalBottomSheet`) avec hauteur max 60% screen.
- [ ] AC-14 — Contenu carte : section "Mutations en attente" (liste `local_data` triée par `localUpdatedAt DESC`, top 20) avec `[module] [action] [timestamp relatif]`. Section "Conflits en attente" si > 0 (cliquable → `ConflictReviewScreen`).
- [ ] AC-15 — Si carte ouverte ET réseau revient pendant : auto-update du contenu (stream subscription).

### ConflictReviewScreen

- [ ] AC-16 — Route `/sync/conflicts` enregistrée. Accessible via tap dans la barre OU directement depuis l'écran admin.
- [ ] AC-17 — Liste des conflits `manual_pending` (depuis `ConflictDao.streamPending()`). Carte par conflit : module, entityId, detectedAt.
- [ ] AC-18 — Tap → écran détail : 2 colonnes (mobile : 2 cartes empilées) "Local" / "Serveur" avec JSON viewer simple (texte monospace `bodyMono`). Boutons CTA bottom : `[Garder ma version] [Garder serveur]` (token `interactive*` du DS).
- [ ] AC-19 — Tap CTA → `ConflictDao.resolve(id, choice)` (STORY-035). Snackbar succès "Conflit résolu" → retour à la liste. Si liste vide → retour MainScreen.
- [ ] AC-20 — ABAC : si l'utilisateur n'a pas la permission `sync.resolve_conflict` → CTA disabled + tooltip "Demander à un Owner". Lecture autorisée pour tous.

### Badge app icon

- [ ] AC-21 — Si `conflicts.count > 0` : badge sur l'icône app (Android via `flutter_app_badger`, iOS via UNUserNotificationCenter). Mis à jour à chaque changement du count. Disparaît à 0.
- [ ] AC-22 — Pas de badge pour mutations en queue (= comportement normal, pas une alerte).

### Tests

- [ ] AC-23 — Golden tests (Light + Dark) pour les 4 états dans `apps/flutter/test/components/sync_status_bar/`. Référence : convention showcase `_<feature>_showcase.dart` (STORY-004).
- [ ] AC-24 — Test widget `SyncStatusController` : 4 cas d'inputs (offline+0+0, online+5+0, online+0+2, online+0+0) → assertions sur état effectif.
- [ ] AC-25 — Test E2E `ConflictReviewScreen` : créer 2 conflits manuels en mémoire → naviguer → tap "Garder serveur" → conflict résolu → liste vide.

---

## Technical Notes

### Composants concernés

- **DS :** `SyncStatusBar` (déjà spécifié dans `design-process/D-Design-System/components/01-feedback.md`). Implémentation Flutter dans `apps/flutter/lib/components/feedback/sync_status_bar.dart` (créé par STORY-003, branché ici).
- **Nouveau :** `apps/flutter/lib/features/sync/sync_status_controller.dart`, `conflict_review_screen.dart`.
- **Reuse :** `LocalStore` (STORY-033), `ConflictDao` (STORY-035), `BDUIEngine.componentRegistry` (STORY-008).

### Structure de fichiers

```
apps/flutter/
├── lib/
│   ├── components/
│   │   └── feedback/
│   │       ├── sync_status_bar.dart                # widget DS (créé STORY-003, ext ici)
│   │       └── _sync_status_bar_showcase.dart      # golden tests Light + Dark
│   └── features/
│       └── sync/
│           ├── sync_status_controller.dart         # Riverpod StreamProvider
│           ├── sync_status_state.dart              # sealed class state
│           ├── conflict_review_screen.dart
│           ├── conflict_detail_screen.dart
│           └── widgets/
│               ├── pending_mutations_list.dart
│               └── json_diff_viewer.dart
└── test/
    ├── components/feedback/
    │   └── sync_status_bar_golden_test.dart
    └── features/sync/
        ├── sync_status_controller_test.dart
        └── conflict_review_e2e_test.dart
```

### Code skeleton — Controller

```dart
// apps/flutter/lib/features/sync/sync_status_controller.dart
sealed class SyncStatusState {}
class Synced extends SyncStatusState { final DateTime? lastAt; Synced(this.lastAt); }
class Syncing extends SyncStatusState { final int pending; Syncing(this.pending); }
class Offline extends SyncStatusState {}
class ConflictsPending extends SyncStatusState { final int count; ConflictsPending(this.count); }

final syncStatusProvider = StreamProvider<SyncStatusState>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  final queueCount = ref.watch(queueCountStreamProvider);
  final conflictsCount = ref.watch(conflictsCountStreamProvider);
  final lastSyncedAt = ref.watch(lastSyncedAtProvider);

  return Rx.combineLatest4(connectivity, queueCount, conflictsCount, lastSyncedAt,
    (conn, qc, cc, last) {
      if (cc > 0) return ConflictsPending(cc);
      if (conn == ConnectivityResult.none) return Offline();
      if (qc > 0) return Syncing(qc);
      return Synced(last);
    },
  );
});
```

### Code skeleton — fromConfig BDUI

```dart
// apps/flutter/lib/components/feedback/sync_status_bar.dart
class SyncStatusBar extends ConsumerWidget {
  final bool expandable;
  const SyncStatusBar({required this.expandable, super.key});

  factory SyncStatusBar.fromConfig(ComponentConfig c, BDUIContext ctx) {
    return SyncStatusBar(
      expandable: c.props['expandable'] as bool? ?? true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStatusProvider);
    return state.when(
      data: (s) => _Bar(state: s, expandable: expandable),
      loading: () => const SizedBox(height: 28),
      error: (_, __) => const SizedBox(height: 28),
    );
  }
}
```

### Tenant config JSON exemple

```json
{
  "layouts": {
    "global": {
      "sync_bar": {
        "type": "SyncStatusBar",
        "props": { "position": "bottom", "expandable": true }
      }
    }
  }
}
```

### PRD ↔ DS — Conflit résolu

- PRD §FR-058 + sprint plan note "conflicts (red badge)" → **DS gagne** (`design-process/D-Design-System/ux-rules/principles.md` ligne 46 : "Pas d'AlertBanner rouge pour offline — seulement SyncStatusBar ambre").
- Décision documentée : conflits = **warning-500 ambre**, pas danger-500 rouge. Cohérent avec la philosophie "offline n'est pas une erreur, conflit non plus — c'est un fait à résoudre".
- Cette décision est appliquée dans AC-10 et AC-11.

### Performance

- Streams Drift sont basés sur les triggers SQLite — pas de polling. Coût quasi nul.
- Anim `syncing` rotation : `RotationTransition` Flutter natif, GPU-accelerated.
- Modal-bottom-sheet : list view virtualisée si > 20 items (limit 20 imposé AC-14).

### Sécurité

- ABAC `sync.resolve_conflict` checked sur le CTA (AC-20). Action serveur re-vérifie (defense-in-depth).
- Pas de logging de payloads JSON dans les events télémétrie.

### Edge cases

- **Stream Drift error** : sealed `Error` state → barre invisible (SizedBox 28px). Pas de crash.
- **Bascule rapide online ↔ offline** (réseau yo-yo) : debounce 500ms sur `connectivity` pour éviter clignotement.
- **Conflits + offline simultanés** : priorité conflicts (l'utilisateur doit savoir qu'il a quelque chose à faire). Sous-titre ajouté : "Hors ligne — résolution dès reconnexion".
- **0 mutations + offline** : "Hors ligne — données locales à jour" (rassurant).
- **Tenant config sans `sync_bar`** : fallback default — barre toujours visible.

---

## Dependencies

**Prérequis :**

- STORY-001 (tokens DS) — couleurs, typo, spacing.
- STORY-002 (ThemeData + sémantiques sync).
- STORY-003 (composant `SyncStatusBar` créé visuellement) — direct.
- STORY-008 (BDUIEngine + ComponentRegistry) — pour le rendu data-driven.
- STORY-034 (sync queue avec streamCount) — direct.
- STORY-035 (conflict resolver + dao) — direct.

**Stories bloquées :**

- Aucune directement. Mais EPIC-007 (template `retail_fresh_produce.json`) doit déclarer `sync_bar` dans le tenant config.

**Externes :**

- `flutter_app_badger`, `connectivity_plus`, `rxdart` — packages publics pub.dev.

---

## Definition of Done

- [ ] Code commité sur `feat/story-037-sync-status-ui`.
- [ ] `flutter analyze` zéro warning.
- [ ] Golden tests verts (Light + Dark, 4 états) — diff visuel approuvé.
- [ ] Coverage ≥ 80% sur `lib/features/sync/`.
- [ ] Test E2E ConflictReview vert.
- [ ] BDUI rendering vérifié : un tenant config JSON test produit la barre + comportement attendu.
- [ ] Badge app icon vérifié sur device physique Android + simulateur iOS.
- [ ] PR review (Carlos + `/codex review` + `/design-review` car UI).
- [ ] PR mergée sur `main`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `SyncStatusController` Riverpod stream combiné | 0.5 | Rx combineLatest4. |
| Branchement `SyncStatusBar` (BDUI fromConfig + 4 états visuels) | 0.5 | Réutilise STORY-003. |
| Modal-bottom-sheet expand + liste mutations | 0.5 | List + scroll + tap conflicts. |
| `ConflictReviewScreen` + `ConflictDetailScreen` | 0.75 | List + 2-col JSON viewer + CTAs. |
| Badge app icon Android + iOS | 0.25 | `flutter_app_badger` + iOS perms. |
| Golden tests 4 états Light + Dark | 0.25 | 8 goldens. |
| Test E2E ConflictReview | 0.25 | Drift in-memory + navigation. |
| **Total** | **3** | Fibonacci 3 — UI moyen, mais réutilise composant DS. |

---

## Notes additionnelles

- **Convention showcase** : `_sync_status_bar_showcase.dart` avec `@Preview Light+Dark` + `main()` standalone (mémoire user — feedback Santera).
- **Logo Scalario** : non concerné.
- **i18n** : strings FR pour Phase 1 (`Synchronisé`, `Hors ligne — données locales à jour`, etc.). TODO STORY-042 pour EN.
- **Accessibility** : barres ont `Semantics` label dynamique (lu par TalkBack/VoiceOver) — ex "Synchronisé, dernier sync il y a 2 minutes". Important pour conformité.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
