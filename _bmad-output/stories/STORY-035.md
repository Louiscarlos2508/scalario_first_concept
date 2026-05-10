# STORY-035 : Conflict Resolution Phase 1

**Epic :** EPIC-006 — Offline-First & Sync
**Priorité :** Must Have
**Story Points :** 5
**Status :** Defined
**Assigned To :** Unassigned
**Created :** 2026-05-10
**Sprint :** 4 (2026-06-23 → 2026-07-04)
**Dependencies :** STORY-033 (table `conflicts`), STORY-034 (worker remonte les 409), STORY-036 (idempotence serveur), STORY-037 (UI conflict review)

---

## User Story

> **En tant qu'**utilisatrice (Manager Ibrahim, Owner Aïcha) sur des données qui ont été modifiées simultanément par moi en offline et par un collègue online,
> **je veux** que les conflits soient résolus automatiquement quand c'est sans risque (last-write-wins simple) et présentés clairement quand c'est ambigu (queue de revue manuelle),
> **so that** je ne perds jamais de données importantes silencieusement, et je ne suis pas non plus dérangée pour des conflits triviaux.

---

## Description

### Background

L'architecture §Composant 8 + PRD §FR-057 définit la stratégie Phase 1 : **server_wins + conflict queue manuelle pour cas ambigus** — explicitement PAS de CRDT (FR-036, Phase 2). La règle simple : si le serveur a une version plus récente que la base sur laquelle le client a édité, il y a conflit.

Détection serveur : à chaque mutation reçue, NestJS compare `payload.base_updated_at` (timestamp serveur de la version sur laquelle le client a édité) avec `entity.updated_at` actuel. Si `entity.updated_at > base_updated_at` → conflit.

Réponse serveur : `409 Conflict` + body `{ server_state, client_state, conflict_strategy }`. Le `conflict_strategy` est lu depuis le `module_config.conflict_strategy` (architecture §Composant 8).

Côté client (cette story) :

1. STORY-034 a déjà classé la mutation en `conflict` dans `sync_queue`.
2. Cette story prend cette mutation, applique la stratégie déclarée, et soit résout automatiquement (`server_wins`, `client_wins`), soit pousse en `conflicts` table avec status `manual_pending` (pour l'UI STORY-037).

C'est la story qui ferme la boucle de cohérence Phase 1.

### Scope

**In scope :**

- Backend NestJS : détection conflit dans `SyncEngine.processMutation()` — comparaison `base_updated_at`. Réponse `409` standardisée.
- Backend : exposer endpoint `POST /api/v1/{tenant}/sync/conflicts/:id/resolve` (architecture §Endpoints sync) pour résolution manuelle (`{choice: 'client_wins' | 'server_wins', mergedPayload?: any}`).
- Backend : table `sync_mutations.conflict_data` JSONB stocke `{server, client}` à la détection (déjà dans architecture §Sync mutations schema).
- Client Flutter : `ConflictResolver` (Dart) — branché en sortie du `SyncQueueWorker` quand status=`conflict`.
- Client : 3 stratégies supportées (architecture §Composant 8 tableau) :
  - `server_wins` (défaut) : écrase `local_data` avec server payload, marque mutation `success` (overrided), log audit local.
  - `client_wins` : ré-envoie la mutation avec flag `force=true`. Serveur écrase. Documenté risqué.
  - `manual` : pousse une ligne dans `conflicts` table → UI (STORY-037) la liste → utilisateur autorisé choisit → POST resolve.
- Module config field `conflict_strategy` lu depuis `tenant_config.configJson.modules[moduleId].conflict_strategy`.
- Audit local : chaque résolution écrite dans `local_data` avec un commentaire `_resolved_by: 'server_wins'` etc., pour traçabilité.
- Tests : E2E client+server avec scénarios `server_wins`, `manual`, `client_wins`.

**Out of scope :**

- CRDT Vector Clocks → FR-036 Phase 2 (deferred).
- Notification push aux autres utilisateurs lors de conflits → Phase 2.
- Visualisation diff field-by-field dans l'UI → STORY-037 (UI), peut être limitée à JSON brut côté UI Phase 1.
- Stratégies custom par champ (`field-level merge`) → Phase 2.

### User Flow

**Cas A — server_wins automatique (90% des cas) :**

1. Blandine offline 1h. Pendant ce temps, Carlos (admin) corrige le prix du même produit côté backend.
2. Blandine vend ce produit offline → mutation `update_product_price` enqueuée.
3. Reconnexion → SyncQueueWorker POST → 409 `{server_state, client_state}`.
4. ConflictResolver lit `module_config.products.conflict_strategy = 'server_wins'`.
5. Écrase `local_data.products[id]` avec `server_state`. Marque mutation `success` (avec flag `overridden`).
6. SyncStatusBar affiche brièvement "1 conflit résolu auto" → revient à "Synchronisé".

**Cas B — manual (cas ambigus, ex: stock_movement avec quantités divergentes) :**

1. Blandine ajuste stock offline `tomates: 10kg restants`. Backend a déjà reçu un autre ajustement à 8kg.
2. Mutation → 409 → `module_config.stock_movements.conflict_strategy = 'manual'`.
3. ConflictResolver crée une ligne `conflicts` avec `localStateJson`, `serverStateJson`, `resolution = 'manual_pending'`.
4. SyncStatusBar (STORY-037) affiche un badge "1 conflit en attente".
5. Owner Aïcha (rôle autorisé) tap → écran `ConflictReviewScreen` → voit JSON local vs serveur → choisit "Garder ma version" / "Garder serveur".
6. Client POST `/sync/conflicts/:id/resolve` → backend applique le choix → mutation finale `success`.

---

## Acceptance Criteria

### Détection serveur

- [ ] AC-01 — Backend `SyncEngine.processMutation()` lit l'entité ciblée par la mutation (`localData[entityId]`), compare `entity.updated_at` (Postgres) avec `payload.base_updated_at` (envoyé par le client). Si `entity.updated_at > base_updated_at` ET les deux états diffèrent → conflit.
- [ ] AC-02 — Si conflit : retourne `{status: 'conflict', server_state, client_state, conflict_strategy}` dans le batch result. Stocke aussi en DB dans `sync_mutations.conflict_data`.
- [ ] AC-03 — Si pas de conflit : applique la mutation normalement (status `success`).
- [ ] AC-04 — `base_updated_at` est un champ obligatoire dans le payload de toute mutation update/delete (ajouté côté client par STORY-034 lecture de `local_data.baseUpdatedAt`). POST create n'a jamais de conflit (pas de version antérieure).

### Stratégies & module config

- [ ] AC-05 — `module_config.json` accepte le field `conflict_strategy: "server_wins" | "client_wins" | "manual"`. Default `"server_wins"` si absent. Validé par Zod schema partagé (STORY-014/041).
- [ ] AC-06 — Côté client, `ConflictResolver.resolve(mutation, conflictData)` lit la stratégie depuis `tenantConfig.modules[mutation.moduleId].conflict_strategy`.
- [ ] AC-07 — Si la stratégie est `server_wins` : écrase `local_data` avec server_state, marque mutation `success` (avec drapeau `overridden=true`), log local audit.
- [ ] AC-08 — Si la stratégie est `client_wins` : enqueue à nouveau la mutation avec header `X-Sync-Force: true` + nouveau idempotency key. Backend écrase server_state. Si l'override échoue (autre conflit) → fallback `manual`.
- [ ] AC-09 — Si la stratégie est `manual` : INSERT dans `conflicts` (table Drift) avec `localStateJson`, `serverStateJson`, `mutationId`, `detectedAt = now`, `resolution = 'manual_pending'`. Mutation reste en status `conflict` jusqu'à résolution.

### Résolution manuelle

- [ ] AC-10 — Endpoint backend `POST /api/v1/{tenant}/sync/conflicts/:mutationId/resolve` body `{ choice: 'client' | 'server' | 'merge', mergedPayload?: any }`. Vérifie ABAC : seuls les rôles avec permission `sync.resolve_conflict` peuvent appeler.
- [ ] AC-11 — Si `choice='server'` : marque mutation `success` côté DB (entity reste avec server_state). Si `choice='client'` : applique `client_state` à l'entité. Si `choice='merge'` : applique `mergedPayload` (Phase 1 : juste accepter, pas de validation deep).
- [ ] AC-12 — Côté client : `ConflictDao.resolve(conflictId, choice)` POST l'endpoint → met à jour `conflicts.resolution = 'server_wins' | 'client_wins' | 'manual_resolved'` + `resolvedAt = now` + applique `local_data` selon le choix.
- [ ] AC-13 — Si la résolution échoue (réseau coupe pendant le POST) : retry exponentiel comme une mutation classique. Le conflit reste `manual_pending` localement.

### Audit & traçabilité

- [ ] AC-14 — Chaque résolution (auto ou manuelle) écrit une ligne dans `audit_logs` côté serveur avec `action='conflict_resolved'`, `payload={mutationId, strategy, choice, resolvedBy}` (architecture §Audit logs).
- [ ] AC-15 — Côté client, table `local_data` mise à jour porte un champ JSON `_meta._resolved_by` pour traçabilité (peut être affiché dans une vue debug, hors scope UI standard).

### Tests

- [ ] AC-16 — Test backend unitaire : 409 retourné quand `entity.updated_at > base_updated_at` ET payload diffère. Pas de 409 quand identique (no-op).
- [ ] AC-17 — Test E2E `server_wins` : mutation offline + edit serveur entre temps → reconnexion → server_state appliqué localement, mutation `success`, AUCUN conflit visible UI.
- [ ] AC-18 — Test E2E `manual` : mutation offline + edit serveur → reconnexion → conflict apparaît dans `conflicts` table avec status `manual_pending`. POST resolve → conflict `manual_resolved`, mutation `success`.
- [ ] AC-19 — Test E2E `client_wins` : mutation offline + edit serveur → reconnexion → client force-replay → server_state écrasé par client_state (vérifié via SELECT post-sync).
- [ ] AC-20 — Test edge : 2 conflits pour la même entité en file → résolution séquentielle propre, pas de race condition (mutex côté ConflictResolver).
- [ ] AC-21 — Couverture ≥ 80% sur `apps/flutter/lib/core/offline/conflict_resolver*` ET `apps/backend/src/sync/sync.service.ts` parties conflit.

---

## Technical Notes

### Composants concernés

- **Backend NestJS :** `apps/backend/src/sync/sync.service.ts`, `sync.controller.ts`, `dto/conflict.dto.ts`.
- **Client Flutter :** `apps/flutter/lib/core/offline/conflict_resolver.dart`, `conflict_dao.dart` (existe déjà STORY-033, étendu ici).
- **Shared contracts :** `packages/shared-contracts/src/sync.ts` — types `ConflictData`, `ResolveChoice`.

### Code skeleton — backend détection conflit

```typescript
// apps/backend/src/sync/sync.service.ts
async processMutation(
  tenantId: string,
  mut: ClientMutationDto,
): Promise<SyncResult> {
  // Idempotence (STORY-036) check d'abord
  const cached = await this.idempotency.lookup(mut.idempotencyKey);
  if (cached) return cached;

  if (mut.action === 'update' || mut.action === 'delete') {
    const entity = await this.entities.findById(tenantId, mut.entityId);
    if (entity && entity.updated_at > new Date(mut.base_updated_at)) {
      const conflictData = {
        server_state: entity.data,
        client_state: mut.payload,
        conflict_strategy: this.getModuleStrategy(mut.moduleId),
      };
      await this.recordConflict(tenantId, mut, conflictData);
      return { mutationId: mut.mutationId, status: 'conflict', ...conflictData };
    }
  }

  await this.applyMutation(tenantId, mut);
  return { mutationId: mut.mutationId, status: 'success' };
}
```

### Code skeleton — client ConflictResolver

```dart
// apps/flutter/lib/core/offline/conflict_resolver.dart
class ConflictResolver {
  final LocalDataDao _localData;
  final ConflictDao _conflicts;
  final SyncQueueDao _queue;
  final TenantConfigDao _config;
  final SyncApiClient _api;

  Future<void> resolve({
    required String mutationId,
    required Map<String, dynamic> conflictData,
  }) async {
    final mutation = await _queue.findById(mutationId);
    final strategy = (await _config.read())
        .modules[mutation.moduleId]
        ?.conflictStrategy ?? 'server_wins';

    switch (strategy) {
      case 'server_wins':
        await _localData.upsertFromServer(
          mutation.tenantId,
          mutation.moduleId,
          conflictData['server_state'] as Map<String, dynamic>,
        );
        await _queue.markSuccess(mutationId, overridden: true);
        break;

      case 'client_wins':
        final newKey = const Uuid().v4();
        await _api.postMutationsForce([mutation], idempotencyKey: newKey);
        await _queue.markSuccess(mutationId);
        break;

      case 'manual':
        await _conflicts.insert(ConflictsCompanion.insert(
          id: const Uuid().v4(),
          mutationId: mutationId,
          localStateJson: jsonEncode(conflictData['client_state']),
          serverStateJson: jsonEncode(conflictData['server_state']),
          detectedAt: DateTime.now(),
          resolution: const Value('manual_pending'),
        ));
        // mutation reste en `conflict`, attendra l'action utilisateur
        break;
    }
  }
}
```

### Schéma `conflicts` (déjà créé STORY-033, rappel)

```dart
class Conflicts extends Table {
  TextColumn get id => text()();
  TextColumn get mutationId => text().references(SyncQueueItems, #mutationId)();
  TextColumn get localStateJson => text()();
  TextColumn get serverStateJson => text()();
  DateTimeColumn get detectedAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolution => text().nullable()(); // server_wins | client_wins | manual_resolved | manual_pending

  @override
  Set<Column> get primaryKey => {id};
}
```

### Endpoint backend resolve

```typescript
// apps/backend/src/sync/sync.controller.ts
@Post(':tenant/sync/conflicts/:mutationId/resolve')
@UseGuards(JwtAuthGuard, RbacGuard, AbacGuard)
@CheckAbility('sync.resolve_conflict')
async resolveConflict(
  @Param('tenant') tenant: string,
  @Param('mutationId') mutationId: string,
  @Body() body: { choice: 'client' | 'server' | 'merge'; mergedPayload?: any },
) {
  return this.syncService.resolveManual(tenant, mutationId, body);
}
```

### PRD ↔ DS — Aucun conflit visuel

Cette story est principalement logique. La présentation est gérée par STORY-037. Néanmoins : la spec DS (`components/01-feedback.md` SyncStatusBar) ne définit pas de couleur "rouge" pour les conflits — elle utilise `warning` (ambre) pour les états problématiques, pas danger. La task hint mentionnait "red badge with count" — **le DS gagne** : badge ambre avec compteur, pas rouge. Documenté ici pour STORY-037.

### Sécurité

- `client_wins` exige le header `X-Sync-Force: true` côté backend, qui exige permission ABAC `sync.force_override` (rôle Owner uniquement par défaut). Évite qu'un Manager force des écritures sur des entités sensibles (prix, paie).
- Endpoint `/sync/conflicts/:id/resolve` exige permission `sync.resolve_conflict` (Owner + Manager).
- Audit log obligatoire pour toute résolution : auditabilité conformité.

### Edge cases

- **Conflit en cascade** : la résolution provoque un nouveau conflit (rare). Re-itérer max 3 fois, puis fallback `manual`.
- **Mutation `delete` vs entité déjà supprimée serveur** : pas un conflit, idempotent → `success`.
- **Schéma changé entre offline et online** (ex: nouveau field obligatoire). Hors scope strict — couvert par migration JSON config tenant (STORY-008/041) qui rejette les configs incompatibles avant.
- **Client `manual_pending` mais utilisateur supprime le compte** : conflit reste en local jusqu'à wipe DB. Acceptable.
- **Horloges désynchronisées (client en avance de 5min)** : on compare timestamps serveur vs serveur (`base_updated_at` est lu depuis serveur lors du premier fetch). Pas vulnérable à la dérive horloge client.

---

## Dependencies

**Prérequis :**

- STORY-033 (table `conflicts` créée) — direct.
- STORY-034 (worker remonte les 409 status) — direct.
- STORY-036 (idempotence serveur, X-Sync-Force) — backend doit l'avoir avant.
- STORY-022 (ModuleEngine + entities table) — pour avoir des entités à conflicter.
- STORY-014 (catalog Zod schema) — pour valider `conflict_strategy` dans module config.

**Stories bloquées :**

- STORY-037 (Sync Status UI) — direct, affiche badge conflits + écran review.

**Externes :** aucune.

---

## Definition of Done

- [ ] Code commité sur `feat/story-035-conflict-resolution`.
- [ ] `flutter analyze` + `pnpm lint` zéro warning.
- [ ] Tests ≥ 80% coverage (backend `sync.service.ts` parties conflict + client `conflict_resolver*`).
- [ ] 4 scénarios E2E documentés dans la PR (server_wins auto, client_wins force, manual flow complet, conflit cascade).
- [ ] Audit log vérifié : `SELECT * FROM audit_logs WHERE action='conflict_resolved'` retourne les bonnes entrées après les tests.
- [ ] PR review (Carlos + `/codex review`).
- [ ] PR mergée sur `main`.

---

## Story Points Breakdown

| Tâche | Points | Détail |
|-------|--------|--------|
| Backend détection conflit dans SyncEngine | 0.75 | Comparaison timestamps + insertion `conflict_data`. |
| Backend endpoint `/sync/conflicts/:id/resolve` + ABAC | 0.5 | Controller + service + guard. |
| Module config `conflict_strategy` + validation Zod | 0.25 | Petite extension shared-contracts. |
| Client `ConflictResolver` 3 stratégies | 1.0 | server_wins / client_wins / manual. |
| Client `ConflictDao.resolve` + retry | 0.5 | POST resolve + retry exponentiel. |
| Audit log `conflict_resolved` côté serveur | 0.25 | Insert dans audit_logs + tests. |
| Tests E2E (4 scénarios) | 1.25 | Mock backend + Drift in-memory + assertions complètes. |
| Edge cases (cascade, delete-on-deleted) | 0.5 | Tests + handling. |
| **Total** | **5** | Fibonacci 5 — beaucoup de cas, mais logique centrale simple (pas de CRDT). |

---

## Notes additionnelles

- **Phase 2 CRDT** : la structure actuelle (`conflict_strategy` per module) reste valide. CRDT remplacera juste l'option `server_wins` par `crdt_merge` pour les modules qui l'activent.
- **Logo Scalario** : non concerné.
- **i18n** : strings UI conflict review = STORY-037 + STORY-042.
- **Stratégie défaut serveur_wins** : OK pour 95% des modules retail (produits, prix, ventes). Les 5% restants (stock_movements, payments) seront flagués `manual` dans le template `retail_fresh_produce.json` (STORY-039).

---

## Progress Tracking

**Status History :**
- 2026-05-10 : Created (Carlos / Scrum Master via `/bmad:create-story`)

**Actual Effort :** TBD

---

**Generated via BMAD Method v6 — `/bmad:create-story`**
