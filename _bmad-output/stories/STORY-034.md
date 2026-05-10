# STORY-034 : Sync Queue Locale Drift

**Epic :** EPIC-006 — Offline-First & Sync
**Priorité :** Must Have
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-033 (Drift setup + table `sync_queue`), STORY-022 (ModuleEngine endpoints), STORY-036 (Idempotence côté serveur)

---

## User Story

> **En tant qu'**utilisatrice offline (Blandine, après une coupure réseau de 4h sur le marché),
> **je veux** que toutes mes actions enregistrées hors-ligne (ventes, ajustements stock, partages) partent automatiquement dans l'ordre exact où je les ai effectuées dès que la connectivité revient,
> **so that** je n'ai aucune mutation perdue, aucun doublon créé, et aucune action manuelle de re-sync à faire — la sync est invisible.

---

## Description

### Background

STORY-033 a posé la table `sync_queue_items` dans Drift mais sans moteur. Cette story crée le moteur : l'élément qui consomme la queue et envoie les mutations au backend NestJS dans le bon ordre, avec retry, backoff, et garantie d'ordre chronologique.

C'est la pièce centrale de l'offline-first. Le PRD §FR-056 + l'architecture §Composant 8 imposent :

1. Toute action utilisateur produit une `SyncMutation` écrite immédiatement dans Drift (zéro réseau bloquant).
2. Un worker observe la connectivité (`connectivity_plus`) — quand le réseau revient, il vide la queue dans l'ordre `created_at ASC`.
3. Chaque mutation envoyée porte son `Idempotency-Key` (UUID v4 généré côté client) — le serveur dédoublonne (STORY-036).
4. Erreurs réseau transitoires → retry avec backoff exponentiel.
5. Erreur 4xx (validation, autorisation) → mutation passe en `error`, surfacée dans l'UI (STORY-037).
6. Erreur 409 (conflit) → STORY-035 prend le relais.

L'enjeu critique : **garantir l'ordre chronologique**. Si Blandine vend 3kg de tomates puis annule la dernière vente, l'inversion d'ordre côté serveur produirait un stock incohérent. La queue doit être strictement FIFO par tenant.

### Scope

**In scope :**

- Service `SyncQueueWorker` (Dart) tournant dans un isolate dédié ou via `WorkManager` (Android) / `BGTaskScheduler` (iOS).
- API publique `SyncQueue` exposée à toute l'app : `enqueue(moduleId, action, payload) → mutationId`. Génère un UUID v4 client, écrit en Drift, retourne immédiatement.
- Detection connectivité via `connectivity_plus` — événements `onConnectivityChanged`. Sur reconnexion → trigger queue drain.
- Drainer batch : envoie jusqu'à 20 mutations par appel `POST /api/v1/{tenant}/sync/mutations` (architecture §Endpoints sync). Strict ORDER BY created_at ASC.
- Backoff exponentiel : 1s → 4s → 16s → 64s → 256s → max 30min. `retry_count` incrémenté à chaque échec, `next_retry_at` mis à jour.
- Statuts mutation : `pending` (jamais envoyée) → `sending` (en vol) → `success` | `error` | `conflict`. Architecture §Composant 8.
- Reprise après kill process : au démarrage app, scanner les `sending` et les remettre en `pending` (l'isolate est mort, le serveur a peut-être traité ou pas — l'idempotence garantit zéro doublon).
- Hooks lifecycle : worker se met en pause quand l'app est en background (battery), reprend en foreground.
- Métriques télémétrie : nombre de mutations en queue, latence moyenne sync, taux d'échec.
- Tests unitaires + tests d'intégration : 5 mutations offline → reconnexion → toutes envoyées dans l'ordre + statuts mis à jour.

**Out of scope :**

- Conflict resolution (409) → STORY-035.
- Idempotence côté NestJS → STORY-036.
- UI affichage du statut → STORY-037.
- Sync bidirectionnelle (pull serveur → client) → géré séparément via ETag sur `cached_layouts` (STORY-008/033) et refresh background des `local_data` (story future).

### User Flow

1. Blandine offline tape "Vente : 3kg tomates 1500 FCFA".
2. UI appelle `syncQueue.enqueue(moduleId: 'sales', action: 'create_sale', payload: {...})`. Retourne immédiatement avec un `mutationId`.
3. La vente est aussi écrite dans `local_data` avec `syncStatus = 'pending_sync'` — le screen affiche la vente immédiatement (lecture optimiste).
4. 30 minutes plus tard, le réseau revient. `connectivity_plus` émet `connected`.
5. `SyncQueueWorker` se réveille, lit `sync_queue WHERE status='pending' OR (status='error' AND next_retry_at <= now)` ORDER BY created_at ASC LIMIT 20.
6. Pour chaque batch : POST sync/mutations avec idempotency keys. Selon réponse : marque chaque mutation `success` / `conflict` / `error`.
7. La SyncStatusBar (STORY-037) passe de "Hors ligne" → "Synchronisation…" → "Synchronisé" en quelques secondes.

---

## Acceptance Criteria

### API publique

- [ ] AC-01 — Service `SyncQueue` (Riverpod provider) expose `Future<String> enqueue({required String moduleId, required String action, required Map<String, dynamic> payload})`. Génère UUID v4 (`uuid` package), écrit en Drift, retourne en < 20ms (mesure).
- [ ] AC-02 — `enqueue` est non-bloquante : ne fait JAMAIS de fetch HTTP. Garantit que l'UI ne dépend pas du réseau.
- [ ] AC-03 — Tout appel `enqueue` produit aussi une mise à jour `local_data.syncStatus = 'pending_sync'` et `localUpdatedAt = now()` pour la cohérence read.

### Worker & connectivité

- [ ] AC-04 — Service `SyncQueueWorker` initialisé au boot de l'app (après le bootstrap STORY-033 réussi). Souscrit à `Connectivity().onConnectivityChanged`.
- [ ] AC-05 — Sur événement `connected` (mobile, wifi, ethernet) : déclenche `_drain()`. Sur `none` : marque mode offline, ne fait rien.
- [ ] AC-06 — Drain en mode "batch jusqu'à épuisement" : SELECT 20 → POST → boucle tant qu'il reste des `pending` ET réseau OK.
- [ ] AC-07 — Mutex local : un seul drain à la fois (`_isDraining` flag). Empêche concurrence si plusieurs events connectivité arrivent en rafale.
- [ ] AC-08 — En foreground : drain immédiat sur reconnexion. En background Android : `WorkManager` avec contrainte `NetworkType.CONNECTED` + `requiresBatteryNotLow=true`. Sur iOS : `BGTaskScheduler` background fetch (best effort).

### Ordre chronologique

- [ ] AC-09 — La requête de drain est strictement `ORDER BY created_at ASC, mutationId ASC` (tie-breaker UUID pour stabilité). Aucun cas où une mutation plus récente part avant une plus ancienne du même tenant.
- [ ] AC-10 — Test E2E : 5 actions séquentielles offline `t1, t2, t3, t4, t5` → reconnexion → vérifier que les 5 entrées `sync_mutations` côté serveur ont `created_at` (serveur) dans le même ordre que `created_at` (client) — via timestamps clients envoyés en payload.

### Statuts & transitions

- [ ] AC-11 — Transitions valides uniquement : `pending → sending → (success | error | conflict)`. Toute autre transition est un bug → assertion + log.
- [ ] AC-12 — Avant POST batch, marque les 20 mutations `sending`. Après réponse : applique le statut individuel par mutation (le serveur retourne `{ results: [{mutationId, status, ...}] }`, architecture §Endpoints sync).
- [ ] AC-13 — Au démarrage de l'app, exécuter `UPDATE sync_queue SET status='pending' WHERE status='sending'` — récupère les mutations laissées en l'air par un kill process. Idempotence côté serveur garantit zéro doublon (STORY-036).

### Retry & backoff

- [ ] AC-14 — Sur erreur réseau (timeout, DNS, 5xx) : `retry_count++`, `next_retry_at = now + 2^retry_count secondes` (cappé à 1800s = 30min), `status='error'`, `last_error='...'`.
- [ ] AC-15 — Le drain ignore les `error` dont `next_retry_at > now`. Quand `next_retry_at <= now`, la mutation re-devient éligible et est re-tentée (status passe `error → sending`).
- [ ] AC-16 — Erreur 4xx non-409 (400 validation, 401/403 auth) : status final `error` permanent (pas de retry auto). L'utilisateur voit dans l'UI (STORY-037) → action manuelle (réauth ou correction).
- [ ] AC-17 — Erreur 409 conflit : status `conflict`. Données serveur attachées dans `last_error` (JSON serialisé). STORY-035 prend le relais pour la résolution.

### Lifecycle & batterie

- [ ] AC-18 — Le worker se met en pause quand l'app passe en background ET qu'aucun WorkManager/BGTask n'est éligible (cas iOS strict). Reprise immédiate au foreground.
- [ ] AC-19 — Pas de polling actif sans event : 0 wakeup réseau si pas de mutation `pending` ET pas de reconnexion. Vérifié via Battery Historian Android sur 1h idle.

### Tests

- [ ] AC-20 — Tests unitaires `apps/flutter/test/core/offline/sync_queue_worker_test.dart` ≥ 85% coverage. Cas : 5 mutations FIFO, retry exponentiel (mock clock), 409 conflit, kill process simulé, reconnexion.
- [ ] AC-21 — Test d'intégration E2E avec mock NestJS : Blandine fait 10 actions offline (réseau coupé via `MockClient`) → reconnexion → toutes sont POSTées dans l'ordre + tous statuts deviennent `success` en < 5s.
- [ ] AC-22 — Bench : drain 100 mutations en < 3s sur Snapdragon 680 avec backend mock à 50ms latence (= 20 batchs séquentiels).

---

## Technical Notes

### Composants concernés

- **Nouveau :** `apps/flutter/lib/core/offline/sync_queue_worker.dart`, `sync_queue_service.dart`, `sync_api_client.dart`.
- **Backend touché :** `POST /api/v1/{tenant}/sync/mutations` (existe déjà dans architecture §Endpoints sync, validation contractuelle ici).
- **Packages :** `connectivity_plus`, `uuid`, `workmanager` (Android), `dio` (HTTP avec interceptor JWT).

### Structure de fichiers

```
apps/flutter/
├── lib/
│   └── core/
│       └── offline/
│           ├── sync_queue_service.dart        # API publique (enqueue)
│           ├── sync_queue_worker.dart         # Worker drain
│           ├── sync_api_client.dart           # HTTP client dédié sync
│           ├── connectivity_listener.dart     # wrapper connectivity_plus
│           └── retry_policy.dart              # backoff exponentiel
├── test/
│   └── core/
│       └── offline/
│           ├── sync_queue_worker_test.dart
│           ├── retry_policy_test.dart
│           └── sync_e2e_test.dart
```

### Code skeleton — SyncQueueService

```dart
// apps/flutter/lib/core/offline/sync_queue_service.dart
import 'package:uuid/uuid.dart';

class SyncQueueService {
  final SyncQueueDao _dao;
  final LocalDataDao _localData;
  final Clock _clock;
  static const _uuid = Uuid();

  SyncQueueService(this._dao, this._localData, this._clock);

  Future<String> enqueue({
    required String tenantId,
    required String moduleId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final mutationId = _uuid.v4();
    await _dao.insert(SyncQueueItemsCompanion.insert(
      mutationId: mutationId,
      tenantId: tenantId,
      moduleId: moduleId,
      action: action,
      payloadJson: jsonEncode(payload),
      idempotencyKey: mutationId,
      createdAt: _clock.now(),
    ));
    return mutationId;
  }
}
```

### Code skeleton — Worker drain

```dart
// apps/flutter/lib/core/offline/sync_queue_worker.dart
class SyncQueueWorker {
  final SyncQueueDao _dao;
  final SyncApiClient _api;
  final Connectivity _connectivity;
  bool _isDraining = false;

  Future<void> start() async {
    _connectivity.onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        unawaited(_drain());
      }
    });
    // Recovery au boot : sending → pending
    await _dao.recoverInFlight();
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_isDraining) return;
    _isDraining = true;
    try {
      while (true) {
        final batch = await _dao.fetchEligible(limit: 20);
        if (batch.isEmpty) break;
        await _dao.markSending(batch);
        final results = await _api.postMutations(batch);
        await _applyResults(batch, results);
      }
    } finally {
      _isDraining = false;
    }
  }
}
```

### Skeleton — backend NestJS endpoint

```typescript
// apps/backend/src/sync/sync.controller.ts
@Post(':tenant/sync/mutations')
@UseGuards(JwtAuthGuard, RbacGuard)
async postMutations(
  @Param('tenant') tenant: string,
  @Body() body: { mutations: ClientMutationDto[] },
): Promise<{ results: SyncResult[] }> {
  const results = await this.syncEngine.processBatch(tenant, body.mutations);
  return { results };
}
```

### Backoff policy

```dart
Duration nextBackoff(int retryCount) {
  final seconds = math.min(math.pow(2, retryCount).toInt(), 1800);
  return Duration(seconds: seconds);
}
// 0→1s, 1→2s, 2→4s, 3→8s, …, 11→1800s (cap 30min)
```

### PRD ↔ DS — Aucun conflit

Pas d'UI ici. Le composant `SyncStatusBar` est consommé en STORY-037.

### Sécurité

- `Idempotency-Key` UUID v4 = 122 bits aléatoires → collision astronomique.
- JWT lu depuis `flutter_secure_storage` à chaque batch (refresh si expiré via interceptor Dio).
- Pas de logging des payloads en prod (peuvent contenir données métier sensibles).

### Edge cases

- **Coupure pendant un batch en vol** : marque batch `sending`, mais HTTP fail → recovery au boot remet `pending`. L'idempotence serveur garantit que les mutations déjà traitées renverront le résultat caché → re-sync sans doublon.
- **Réseau "fantôme" (connecté mais 0 débit)** : timeout Dio à 30s → erreur réseau classique → retry exponentiel.
- **Tenant change pendant la sync** (multi-account, hors scope Phase 1) : worker partitionne par `tenant_id` actif. Hors scope ici, mais structure préservée pour Phase 2.
- **Batch partiellement réussi côté serveur** (mutation 3 sur 20 conflit) : le serveur retourne 200 avec `results[]` mixé. Worker applique le statut individuel par mutation. Garanti par contrat NestJS.
- **Horloge client en avance/retard** : `created_at` client est notre seul ordre garanti côté queue. Le serveur n'utilise pas ce timestamp pour ordonner, juste pour audit. OK.

---

## Dependencies

**Prérequis :**

- STORY-033 (Drift setup + table sync_queue) — direct.
- STORY-022 (ModuleEngine endpoints) — pour avoir des actions à enqueuer.
- STORY-036 (Idempotence serveur) — sans elle, le worker peut créer des doublons en cas de retry. Doit être livré dans le même sprint.

**Stories bloquées :**

- STORY-035 (Conflict Resolution) — direct, le worker détecte les 409.
- STORY-037 (Sync Status UI) — direct, lit les compteurs queue.

**Externes :**

- `connectivity_plus`, `uuid`, `workmanager`, `dio` — packages publics pub.dev.

---

## Definition of Done

- [ ] Code commité sur `feat/story-034-sync-queue-worker`.
- [ ] `flutter analyze` zéro warning.
- [ ] Tests ≥ 85% coverage sur `lib/core/offline/sync_queue_*`.
- [ ] Test E2E 10 mutations offline → reconnexion → toutes en `success` documenté dans PR.
- [ ] Bench drain 100 mutations < 3s sur Snapdragon 680 documenté.
- [ ] Verification battery : 0 wakeup en idle 1h documentée (Battery Historian).
- [ ] PR review (Carlos + `/codex review`).
- [ ] PR mergée sur `main`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| `SyncQueueService.enqueue` + DAO writes | 0.5 | Simple, mais critique zéro-bloquant. |
| `SyncQueueWorker` drain + mutex | 1.0 | Boucle batch, recovery boot, ordre FIFO. |
| `SyncApiClient` + Dio interceptor JWT | 0.5 | HTTP + parse contract `SyncResult`. |
| `RetryPolicy` backoff exponentiel + tests | 0.5 | 1s→1800s capped. |
| Connectivity listener + foreground/background | 0.5 | connectivity_plus + lifecycle observer. |
| WorkManager Android + BGTask iOS | 0.75 | Plateforme-spécifique, fragile. |
| Tests unitaires + E2E mock backend | 1.0 | Mock clock, mock client, FIFO E2E. |
| Métriques télémétrie + battery validation | 0.25 | Counter Prometheus client + Battery Historian. |
| **Total** | **5** | Fibonacci 5 — backend offline est la zone à risques. |

---

## Notes additionnelles

- **Cas Blandine concret** : 4h offline = ~30-50 ventes en queue. Drain = 2-3 batchs de 20, < 5s totaux. Acceptable même en 3G dégradé.
- **Lien Phase 2 (CRDT)** : la queue actuelle reste compatible CRDT — il suffira d'ajouter un Vector Clock dans le payload côté client + résolution server-side. Pas de refonte.
- **Logo Scalario** : non concerné.
- **i18n** : messages d'erreur loggés en EN (techniques). Les messages utilisateur (STORY-037) sont i18n.

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
