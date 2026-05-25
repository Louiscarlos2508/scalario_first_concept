import 'dart:convert' show jsonEncode;
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../vault/dao/conflict_dao.dart';
import '../vault/dao/local_data_dao.dart';
import '../vault/dao/sync_queue_dao.dart';
import '../vault/database.dart';
import 'sync_api_client.dart';

/// STORY-035 — conflict resolution strategies declared per module.
enum ConflictStrategy {
  /// Server state wins. Local data is overwritten with the server payload
  /// and the mutation is marked success (overridden). Default.
  serverWins,

  /// Client re-sends the same payload with `force: true` to bypass the
  /// optimistic-concurrency check on the server. Restricted to roles
  /// with `sync.force_override` permission (Owner by default).
  clientWins,

  /// A row is inserted into the local [Conflicts] table for human review.
  /// The mutation stays in `conflict` status until the review UI
  /// (STORY-037) calls [ConflictDao.markResolved].
  manual;

  static ConflictStrategy fromString(String? raw) {
    switch (raw) {
      case 'client_wins':
        return ConflictStrategy.clientWins;
      case 'manual':
        return ConflictStrategy.manual;
      case 'server_wins':
      default:
        return ConflictStrategy.serverWins;
    }
  }
}

/// Outcome of [ScalarioSyncConflictResolver.resolve]. Useful for tests + the
/// SyncStatusBar that reports counts (STORY-037).
enum ConflictResolutionOutcome {
  resolvedServerWins,
  resolvedClientWinsReplayed,
  pendingManualReview,
}

/// STORY-035 — applies a per-module conflict resolution strategy to a
/// mutation that the server returned as `409 Conflict`. Called by the
/// ScalarioSyncWorker when [SyncApiClient] surfaces a conflict (status =
/// `conflict` in the batch response). Phase 1: 3 strategies; no CRDT.
class ScalarioSyncConflictResolver {
  ScalarioSyncConflictResolver({
    required ConflictDao conflictDao,
    required SyncQueueDao queueDao,
    required LocalDataDao localDataDao,
    required SyncApiClient apiClient,
    Uuid? uuid,
  })  : _conflicts = conflictDao,
        _queue = queueDao,
        _localData = localDataDao,
        _api = apiClient,
        _uuid = uuid ?? const Uuid();

  final ConflictDao _conflicts;
  final SyncQueueDao _queue;
  final LocalDataDao _localData;
  final SyncApiClient _api;
  final Uuid _uuid;

  /// Resolves a 409 conflict for [mutationId] using [strategy], with the
  /// server-supplied [conflictData] payload `{server_state, client_state}`.
  /// Returns the outcome so the worker can update its counters.
  Future<ConflictResolutionOutcome> resolve({
    required String mutationId,
    required String tenantId,
    required String moduleId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> conflictData,
    required ConflictStrategy strategy,
  }) async {
    final serverState = conflictData['server_state'] as Map<String, dynamic>?;
    final clientState = conflictData['client_state'] as Map<String, dynamic>?;

    switch (strategy) {
      case ConflictStrategy.serverWins:
        if (serverState != null) {
          await _localData.upsert(LocalDataRecord(
            id: entityId,
            tenantId: tenantId,
            moduleId: moduleId,
            entityType: entityType,
            dataJson: jsonEncode(serverState),
            baseUpdatedAt: DateTime.now(),
            localUpdatedAt: DateTime.now(),
            syncStatus: 'synced',
          ));
        }
        await _queue.markSuccess(mutationId);
        developer.log(
          'conflict.resolved.server_wins mutation=$mutationId entity=$entityId',
          name: 'Scalario.Offline.Conflict',
        );
        return ConflictResolutionOutcome.resolvedServerWins;

      case ConflictStrategy.clientWins:
        // Re-send the mutation with force: true. The CrudUpdateHandler
        // skips the base_updated_at check when payload.force === true
        // (STORY-035 AC-08, see apps/nestjs/.../crud-update.handler.ts).
        if (clientState != null) {
          final newKey = _uuid.v4();
          await _api.postMutations(
            tenantSlug: tenantId,
            mutations: [
              SyncMutationPayload(
                mutationId: newKey,
                moduleId: moduleId,
                action: 'crud.update',
                payload: {...clientState, 'force': true},
              ),
            ],
          );
        }
        await _queue.markSuccess(mutationId);
        developer.log(
          'conflict.resolved.client_wins mutation=$mutationId entity=$entityId',
          name: 'Scalario.Offline.Conflict',
        );
        return ConflictResolutionOutcome.resolvedClientWinsReplayed;

      case ConflictStrategy.manual:
        await _conflicts.insert(
          ConflictsCompanion.insert(
            id: _uuid.v4(),
            mutationId: mutationId,
            localStateJson: jsonEncode(clientState ?? <String, dynamic>{}),
            serverStateJson: jsonEncode(serverState ?? <String, dynamic>{}),
            detectedAt: Value(DateTime.now()),
            resolution: const Value('manual_pending'),
          ),
        );
        // Mutation stays in `conflict` status. The review UI (STORY-037)
        // flips it to success/error after the user picks a side.
        developer.log(
          'conflict.queued.manual mutation=$mutationId entity=$entityId — awaiting user review',
          name: 'Scalario.Offline.Conflict',
        );
        return ConflictResolutionOutcome.pendingManualReview;
    }
  }
}
