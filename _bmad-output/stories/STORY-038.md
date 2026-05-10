# STORY-038 : Drift Web Offline + PWA

**Epic :** EPIC-006 — Offline-First & Sync
**Priorité :** Should Have
**Story Points :** 5
**Status :** Deferred-PostGate0
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** null (post-Gate 0 — non planifié Phase 1 MVP)
**Dependencies :** STORY-012 (Flutter Web bootstrap), STORY-033 (Drift schema mobile), STORY-034 (sync worker), STORY-035 (conflict resolution), STORY-037 (sync UI)

---

## User Story

> **En tant qu'**utilisateur web admin (Carlos lui-même, ou un Manager qui ouvre le dashboard depuis un navigateur de bureau),
> **je veux** que l'app Flutter Web continue de fonctionner en mode dégradé hors ligne — config + données lisibles depuis IndexedDB, mutations mises en queue — et que la PWA installable couvre les assets critiques,
> **so that** une coupure réseau pendant une session admin ne bloque pas mon travail (lecture, navigation, saisie).

---

## Description

### Status — Déféré post-Gate 0

> **Cette story est explicitement déférée hors du périmètre Phase 1 MVP (Gate 0).** Le PRD §FR-052 la classe Should Have. Le sprint plan (`sprint-plan-scalario-2026-05-09.md` lignes 771-786 + 1098 + 1136) confirme : Blandine = Android mobile, le web admin n'a pas besoin d'offline en Phase 1. La story est documentée ici pour clarté du backlog post-Gate 0 et continuité de l'EPIC-006.

**Raison du report :**

- Blandine (persona principale Phase 1) = Android mobile uniquement — STORY-033 à STORY-037 couvrent 100% de son besoin.
- Le web admin (Carlos, Owners, Managers) sera utilisé majoritairement en bureau avec connexion stable.
- Drift Web (IndexedDB via `drift_web`) ajoute de la complexité (sqlite-wasm, Service Worker, quotas IndexedDB 5-10MB par défaut) qui n'apporte rien à Blandine.
- Risque IndexedDB quota (architecture §R-002) à mitiger en Phase 2 quand on ouvrira l'admin web mobile (responsive).

**Activation post-Gate 0 :** dès la fin Gate 0 confirmée (STORY-053), cette story rentre en planning Phase 2 — point d'entrée naturel quand un Owner demande un usage mobile-web (cas réel UEMOA).

### Background

L'architecture (`architecture-scalario-2026-05-09.md` §1279) a anticipé le cross-platform :

> Drift mobile (SQLite) + Drift web (IndexedDB via `drift_web`). Même API, même schema, même requêtes.

L'avantage est qu'aucune logique métier n'est à réécrire — juste le binding executor (mobile = `NativeDatabase`, web = `WasmDatabase` ou `WebDatabase`). Le `LocalStore`, `SyncQueueWorker`, `ConflictResolver`, `SyncStatusController` sont 100% réutilisables.

La PWA (Progressive Web App) ajoute : Service Worker pour cacher les assets Flutter (le bundle JS/wasm + manifests + index.html), `manifest.json` installable. `flutter build web --pwa-strategy=offline-first` produit ce setup automatiquement.

### Scope (post-Gate 0)

**In scope (quand activée) :**

- Bootstrap conditionnel `database.dart` : `kIsWeb ? WasmDatabase.open(...) : NativeDatabase(...)`. Même `ScalarioDatabase` class, même schemaVersion, même DAOs.
- Backend SQLite WASM (`sqlite3.wasm` chargé via `drift_wasm` ou `package:sqlite3` web bindings). Stocké dans IndexedDB via OPFS (Origin Private File System) si supporté, fallback IndexedDB classique.
- Quota IndexedDB : détection via `navigator.storage.estimate()`. Si proche du quota (>80%), prompt utilisateur "Stockage local presque plein — voulez-vous vider le cache layouts ?".
- Cache LRU `cached_layouts` ré-utilisé (STORY-033). Limite défaut web : 50MB (vs 500MB mobile — IndexedDB est plus contraint).
- Service Worker généré par `flutter build web --pwa-strategy=offline-first`. Customisé : précache du shell Flutter (main.dart.js, .wasm, fonts) + stratégie `cache-first` pour les assets, `network-first` pour les API calls.
- `manifest.json` : icône Scalario (192px, 512px), `display: standalone`, theme color `#2980B9`, start_url `/`.
- SyncStatusBar (STORY-037) déjà rendu identique sur web grâce à BDUI — aucun travail UI supplémentaire.
- Connectivité Web : `dart:html.window.onOnline / onOffline` pour le `connectivity_plus` web equivalent.
- Tests E2E web : Playwright/Selenium → simuler offline (Chrome DevTools Network throttling) → vérifier app fonctionne en read + queue.

**Out of scope :**

- Notifications push web (Firebase Cloud Messaging Web) — Phase 3.
- Background Sync API (browser native) — Phase 3.
- File upload offline (queue de fichiers) — Phase 3.
- iOS Safari PWA full support — connu limité (Apple), best-effort.

### User Flow (post-Gate 0)

1. Owner Aïcha installe la PWA depuis Chrome (`Add to Home Screen`).
2. Au premier login, le bootstrap (STORY-033) écrit dans IndexedDB.
3. Aïcha consulte les KPIs depuis le café à 11h — coupure WiFi.
4. La SyncStatusBar passe à "Hors ligne — données locales à jour".
5. Elle continue à naviguer, voir les KPIs cachés, saisir un commentaire (queue).
6. WiFi revient — sync auto. Aïcha n'a rien remarqué.

---

## Acceptance Criteria

### Drift Web bootstrap

- [ ] AC-01 — `apps/flutter/lib/core/offline/database.dart` détecte `kIsWeb` et utilise `WasmDatabase.open(databaseName: 'scalario_db')` sur web. Même `ScalarioDatabase` class, même schemaVersion 1.
- [ ] AC-02 — Web : SQLite WASM chargé via `drift_wasm` package. Backend storage IndexedDB OPFS si supporté, sinon IndexedDB classique. Détection automatique.
- [ ] AC-03 — Le boot web peut prendre jusqu'à 1.5s (download wasm + init) — splash screen Flutter affiché. Mobile boot inchangé.

### Schéma & DAO

- [ ] AC-04 — Tous les DAOs (TenantConfig, CachedLayouts, LocalData, SyncQueue, Conflicts) fonctionnent identiquement sur web (lecture, écriture, transactions, streams). Vérifié par tests partagés `database_test.dart` exécutés via `flutter test --platform=chrome`.
- [ ] AC-05 — Les migrations v1 (et futures) appliquées identiquement sur web — pas de divergence schema.

### Quota IndexedDB

- [ ] AC-06 — Détection quota via `navigator.storage.estimate()` au boot. Si `usage / quota > 0.8` → toast warning "Stockage local presque plein".
- [ ] AC-07 — Limite cache `cached_layouts` ramenée à 50MB par défaut sur web (lue depuis `tenant_config.cache_limit_mb_web` si défini, sinon 50).
- [ ] AC-08 — Si quota atteint → suppression LRU agressive (jusqu'à 50% du quota libéré). Si toujours bloquant → prompt utilisateur "Vider toutes les données locales (re-login requis)".

### Service Worker & PWA

- [ ] AC-09 — `flutter build web --pwa-strategy=offline-first` produit un `flutter_service_worker.js` qui précache le shell Flutter (main.dart.js, fonts Inter/Roboto Mono, manifest, icônes).
- [ ] AC-10 — Stratégie cache : `cache-first` pour `*.js`, `*.wasm`, `*.png`, `*.svg`, `*.woff2`. `network-first` avec timeout 3s pour `/api/*`.
- [ ] AC-11 — `manifest.json` exposé : `name='Scalario'`, `short_name='Scalario'`, `display='standalone'`, `theme_color='#2980B9'`, `background_color='#F8F9F9'`, icônes 192/512.
- [ ] AC-12 — Lighthouse PWA score ≥ 90 (HTTPS, manifest, SW, installable).

### Connectivité web

- [ ] AC-13 — `connectivity_plus` retourne le bon état sur web (`window.onOnline / onOffline` listeners). Vérifié dans `SyncStatusController`.
- [ ] AC-14 — Bascule online ↔ offline simulée via Chrome DevTools → la SyncStatusBar (STORY-037) réagit correctement.

### Sync identique mobile

- [ ] AC-15 — Le `SyncQueueWorker` (STORY-034) tourne tel quel sur web. Pas de WorkManager (web-specific) — drain s'effectue uniquement quand l'onglet est ouvert + online (acceptable Phase 2).
- [ ] AC-16 — Le `ConflictResolver` (STORY-035) tourne identique. Strategies `server_wins / client_wins / manual` opérationnelles.
- [ ] AC-17 — La `SyncStatusBar` (STORY-037) rendue identique sur web. Badge app icon NON disponible (limitation web — fallback : badge dans favicon via `flutter_app_badger` web mock + warning console).

### Tests E2E

- [ ] AC-18 — Test Playwright : login web → bootstrap → couper réseau (page.context().setOffline(true)) → naviguer 3 screens → vérifier rendu. Reconnecter → vérifier sync drain.
- [ ] AC-19 — Test : recharger la page offline → app démarre depuis IndexedDB + Service Worker → écran d'accueil visible.
- [ ] AC-20 — Test : conflict E2E web (mutation offline + edit serveur) → reconnexion → conflict résolu correctement.

### Limites & docs

- [ ] AC-21 — README `apps/flutter/web/README.md` documente : limites iOS Safari, quotas IndexedDB par navigateur, comportement onglet fermé (queue ne drain pas).
- [ ] AC-22 — Bench Lighthouse documenté : First Contentful Paint < 2s, Time to Interactive < 4s sur Chrome bureau (post-cache).

---

## Technical Notes

### Composants concernés

- **Modifié :** `apps/flutter/lib/core/offline/database.dart` (executor conditionnel).
- **Nouveau :** `apps/flutter/web/manifest.json`, `apps/flutter/web/icons/Icon-{192,512}.png`, `apps/flutter/web/index.html` (script Service Worker registration).
- **Service Worker :** auto-généré par Flutter `pwa-strategy=offline-first`.

### Code skeleton — DB executor conditionnel

```dart
// apps/flutter/lib/core/offline/database.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/wasm.dart';

QueryExecutor _openExecutor() {
  if (kIsWeb) {
    return DatabaseConnection.delayed(Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'scalario_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      );
      return result.resolvedExecutor;
    }));
  }
  return NativeDatabase.createInBackground(_dbFile());
}
```

### Code skeleton — Service Worker stratégie

```javascript
// apps/flutter/web/sw_extension.js (custom additions)
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (url.pathname.startsWith('/api/')) {
    // network-first avec fallback cache pour API
    event.respondWith(
      fetch(event.request).catch(() => caches.match(event.request))
    );
  }
});
```

### Manifest

```json
{
  "name": "Scalario",
  "short_name": "Scalario",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#2980B9",
  "background_color": "#F8F9F9",
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

### PRD ↔ DS — Aucun conflit

UI identique mobile (même BDUI, même DS).

### Limitations connues

| Limitation | Navigateur | Mitigation |
|---|---|---|
| Quota IndexedDB ~5-10MB par défaut | Tous | `navigator.storage.persist()` pour passer à 50%+ disk. Demande perm. |
| Pas de Background Sync (sans iOS) | iOS Safari | Drain seulement onglet actif. Acceptable Phase 2. |
| Pas de Push Notifications | iOS Safari < 16.4 | Phase 3. |
| Service Worker scope strict | Tous | OK avec Flutter par défaut. |
| WebView (Cordova / Capacitor) | N/A | Pas concerné — Flutter Web standalone. |

### Sécurité

- HTTPS obligatoire pour Service Worker + PWA install (déjà requis pour Scalario prod).
- IndexedDB est origin-scoped → tenant isolation respecté (mais multi-user-même-tenant sur même browser : déconnexion vide IndexedDB côté UI — wipe explicite).
- SQLite WASM ne permet pas SQLCipher facilement → données moins chiffrées au repos sur web. Mitigation : pas de stockage de tokens dans Drift web (déjà `flutter_secure_storage` web = `localStorage` chiffré ? — vérifier package). Phase 3 : web crypto API pour chiffrer JSON sensible.

### Edge cases

- **Onglet fermé pendant sync** : queue reste dans IndexedDB. Réouverture → drain reprend.
- **Mode incognito** : IndexedDB vidé en fermant la fenêtre. Acceptable (utilisateur le sait).
- **Deux onglets ouverts** : Drift WASM single-writer — coordination via BroadcastChannel. drift_web gère ça nativement (Phase 1 de cette story = vérifier).
- **Update PWA** : nouvelle version → Service Worker propose update au prochain reload. Stratégie : auto-update sans prompt + skipWaiting.
- **iOS Safari PWA install** : "Add to Home Screen" manuel uniquement, pas de prompt natif. Documenté README.

---

## Dependencies

**Prérequis :**

- STORY-012 (Flutter Web bootstrap) — direct.
- STORY-033 (Drift schema + DAOs) — réutilisés tels quels.
- STORY-034, STORY-035, STORY-037 — fonctionnent sur web sans modif.

**Stories bloquées :** aucune en Phase 1 (déférée).

**Externes :**

- `drift_web` ou `drift_wasm` package.
- `sqlite3.wasm` artifact (provenant de `package:sqlite3` ou téléchargé via build).

---

## Definition of Done

(Applicables quand la story sera activée post-Gate 0)

- [ ] Code commité sur `feat/story-038-drift-web-pwa`.
- [ ] `flutter build web --pwa-strategy=offline-first` produit un build sans warning.
- [ ] Lighthouse PWA ≥ 90.
- [ ] Tests Playwright E2E offline + reconnexion verts.
- [ ] Manifeste PWA installable testé Chrome desktop + Android Chrome.
- [ ] Bench Time-to-Interactive < 4s documenté.
- [ ] README web limites navigateurs documenté.
- [ ] PR review (Carlos + `/codex review`).
- [ ] PR mergée sur `main`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Drift Web executor conditionnel + WASM bootstrap | 1.0 | Setup `drift_wasm`, sqlite3.wasm, OPFS detection. |
| Service Worker custom + manifest PWA | 1.0 | flutter build pwa-strategy + custom fetch handler. |
| Quota IndexedDB detection + LRU agressif | 0.5 | navigator.storage.estimate + cleaner. |
| connectivity_plus web binding + check | 0.25 | wrapper window.onOnline. |
| Tests Playwright E2E offline + sync | 1.25 | Page offline + reload + drain. |
| Tests partagés DAO sur platform=chrome | 0.5 | Réutilise tests STORY-033. |
| Bench Lighthouse + tuning | 0.25 | First Contentful Paint, TTI. |
| Documentation README limites + iOS Safari | 0.25 | Markdown + curl examples. |
| **Total** | **5** | Fibonacci 5 — beaucoup de "compatibilité navigateur" qui ronge. |

---

## Notes additionnelles

- **Pourquoi déférée** : décision produit Phase 1 — Blandine est mobile, l'admin web sera utilisé sur connexions stables. Activer cette story sans valeur claire = budget Phase 2 utilisé sans ROI mesurable.
- **Réactivation** : trigger naturel = retour terrain post-Gate 0 où un Owner demande explicitement le mode offline web (cas typique : Owner qui passe entre 2 sites avec wifi public irrégulier, ou tablette utilisée comme terminal de point de vente secondaire).
- **Architecture clean** : la story prouve que la stratégie cross-platform de Drift (architecture §Tech stack) tient — quasi 0 modif logique métier nécessaire. C'est un dividende du choix Drift sur Isar acté en STORY-033.
- **Logo Scalario** : icônes PWA = monogramme `Sc` sur fond `primary-500`, conformes à la règle (mémoire user). Pas de wordmark dans favicon/icônes app — la règle "jamais les deux ensemble" s'applique aussi ici.
- **i18n** : strings PWA install ("Installer Scalario") = STORY-042.
- **Quota navigateur — chiffres concrets** : Chrome desktop alloue jusqu'à 60% du free disk en quota total IndexedDB ; Firefox 50% ; Safari iOS limite à 1GB par origine sans persist permission. La story prend pour cible 50MB pour rester dans la zone confortable de tous les navigateurs sans nécessiter `navigator.storage.persist()` au premier login.
- **Comparaison mobile vs web** : à l'activation, prévoir un test parallèle mobile-vs-web sur les 4 scénarios offline (read, write+queue, conflict, drain reconnexion). Toute divergence = bug d'abstraction Drift à fixer en amont avant release Phase 2.

### Risques connus (à ré-évaluer post-Gate 0)

| Risque | Impact | Probabilité | Mitigation |
|---|---|---|---|
| Drift WASM single-writer cross-onglets | Contention | Moyen | drift_web BroadcastChannel — vérifier au démarrage. |
| iOS Safari PWA partial | UX dégradée Safari | Élevé | Documenté, fallback Chrome iOS recommandé. |
| Quota IndexedDB saturé | Bloquant | Faible | LRU + prompt + persist permission. |
| Bundle size Flutter Web > 5MB | TTI lent | Moyen | Tree-shaking + deferred load + bench Lighthouse continue. |
| Service Worker stale cache après deploy | Version obsolète chez user | Moyen | Stratégie `skipWaiting + clientsClaim` avec banner update. |

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`) — explicitement marquée Deferred-PostGate0
- TBD : Activation décidée

**Actual Effort :** TBD (post-activation)

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
