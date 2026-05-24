import 'dart:convert' show jsonDecode;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

import 'package:scalario/core/offline/dao/conflict_dao.dart';
import 'package:scalario/core/offline/dao/local_data_dao.dart';
import 'package:scalario/core/offline/dao/sync_queue_dao.dart';
import 'package:scalario/core/offline/database.dart';
import 'package:scalario/core/offline/sync/conflict_resolver.dart';
import 'package:scalario/core/offline/sync/sync_api_client.dart';

/// In-memory fake of [SyncApiClient] that records calls without I/O.
class _FakeApiClient implements SyncApiClient {
  final List<_RecordedCall> calls = [];

  @override
  Future<BatchSyncResponse> postMutations({
    required String tenantSlug,
    required List<SyncMutationPayload> mutations,
  }) async {
    calls.add(_RecordedCall(tenantSlug, mutations));
    return BatchSyncResponse(
      results: [
        for (final m in mutations)
          SyncResultItem(mutationId: m.mutationId, status: 'success'),
      ],
    );
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordedCall {
  _RecordedCall(this.tenantSlug, this.mutations);
  final String tenantSlug;
  final List<SyncMutationPayload> mutations;
}

/// Deterministic UUID generator for assertion stability.
class _SequentialUuid extends Uuid {
  _SequentialUuid();
  int _next = 1;

  @override
  String v4({V4Options? config, Map<String, dynamic>? options}) => 'gen-${_next++}';
}

void main() {
  late ScalarioDatabase db;
  late ConflictDao conflictDao;
  late SyncQueueDao queueDao;
  late LocalDataDao localDataDao;
  late _FakeApiClient api;
  late ConflictResolver resolver;

  Future<void> seedPendingMutation(String mutationId, String tenantId) async {
    await db.into(db.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            mutationId: mutationId,
            tenantId: tenantId,
            moduleId: 'module_ventes',
            action: 'crud.update',
            payloadJson: '{"id":"entity-1","name":"Client value"}',
            idempotencyKey: 'idem-$mutationId',
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  setUp(() {
    db = ScalarioDatabase(executor: NativeDatabase.memory());
    conflictDao = ConflictDao(db);
    queueDao = SyncQueueDao(db);
    localDataDao = LocalDataDao(db);
    api = _FakeApiClient();
    resolver = ConflictResolver(
      conflictDao: conflictDao,
      queueDao: queueDao,
      localDataDao: localDataDao,
      apiClient: api,
      uuid: _SequentialUuid(),
    );
  });

  tearDown(() async => db.close());

  group('ConflictStrategy.fromString', () {
    test('parses the three documented values + default fallback', () {
      expect(ConflictStrategy.fromString('server_wins'), ConflictStrategy.serverWins);
      expect(ConflictStrategy.fromString('client_wins'), ConflictStrategy.clientWins);
      expect(ConflictStrategy.fromString('manual'), ConflictStrategy.manual);
      expect(ConflictStrategy.fromString(null), ConflictStrategy.serverWins);
      expect(ConflictStrategy.fromString('unknown'), ConflictStrategy.serverWins);
    });
  });

  group('AC-07 — server_wins', () {
    test('overwrites local_data with server_state and marks mutation success', () async {
      await seedPendingMutation('m-1', 'tenant-1');

      final outcome = await resolver.resolve(
        mutationId: 'm-1',
        tenantId: 'tenant-1',
        moduleId: 'module_ventes',
        entityType: 'Vente',
        entityId: 'entity-1',
        conflictData: {
          'server_state': {'id': 'entity-1', 'name': 'Server value', 'price': 12.0},
          'client_state': {'id': 'entity-1', 'name': 'Client value', 'price': 10.0},
        },
        strategy: ConflictStrategy.serverWins,
      );

      expect(outcome, ConflictResolutionOutcome.resolvedServerWins);

      final localRow = await db
          .customSelect(
            'SELECT * FROM local_data WHERE id = ?',
            variables: [Variable.withString('entity-1')],
          )
          .getSingleOrNull();
      expect(localRow, isNotNull);
      final json =
          jsonDecode(localRow!.data['data_json'] as String) as Map<String, dynamic>;
      expect(json['name'], 'Server value');
      expect(json['price'], 12.0);

      final queueRow = await db
          .customSelect(
            'SELECT status FROM sync_queue_items WHERE mutation_id = ?',
            variables: [Variable.withString('m-1')],
          )
          .getSingle();
      expect(queueRow.data['status'], 'success');

      // No API call for server_wins.
      expect(api.calls, isEmpty);
    });

    test('handles missing server_state gracefully (no local write)', () async {
      await seedPendingMutation('m-2', 'tenant-1');
      final outcome = await resolver.resolve(
        mutationId: 'm-2',
        tenantId: 'tenant-1',
        moduleId: 'module_ventes',
        entityType: 'Vente',
        entityId: 'entity-2',
        conflictData: {
          'client_state': {'id': 'entity-2'},
        },
        strategy: ConflictStrategy.serverWins,
      );
      expect(outcome, ConflictResolutionOutcome.resolvedServerWins);
    });
  });

  group('AC-08 — client_wins', () {
    test('replays the mutation with force:true and marks success', () async {
      await seedPendingMutation('m-3', 'tenant-1');

      final outcome = await resolver.resolve(
        mutationId: 'm-3',
        tenantId: 'tenant-1',
        moduleId: 'module_ventes',
        entityType: 'Vente',
        entityId: 'entity-3',
        conflictData: {
          'server_state': {'id': 'entity-3', 'name': 'Server'},
          'client_state': {'id': 'entity-3', 'name': 'Client'},
        },
        strategy: ConflictStrategy.clientWins,
      );

      expect(outcome, ConflictResolutionOutcome.resolvedClientWinsReplayed);
      expect(api.calls, hasLength(1));
      final replayedMutation = api.calls.first.mutations.first;
      expect(replayedMutation.payload['force'], true);
      expect(replayedMutation.payload['name'], 'Client');
      // New idempotency key (not the original mutation_id).
      expect(replayedMutation.mutationId, isNot('m-3'));
    });
  });

  group('AC-09 — manual', () {
    test('inserts a conflict row and keeps mutation in conflict status', () async {
      await seedPendingMutation('m-4', 'tenant-1');
      // Mark as conflict to mirror the worker's classification step.
      await queueDao.markConflict('m-4', error: 'pre-existing 409 marker');

      final outcome = await resolver.resolve(
        mutationId: 'm-4',
        tenantId: 'tenant-1',
        moduleId: 'module_pertes',
        entityType: 'Perte',
        entityId: 'entity-4',
        conflictData: {
          'server_state': {'qty': 8},
          'client_state': {'qty': 10},
        },
        strategy: ConflictStrategy.manual,
      );

      expect(outcome, ConflictResolutionOutcome.pendingManualReview);

      final conflicts = await conflictDao.getAll('m-4');
      expect(conflicts, hasLength(1));
      expect(conflicts.first.resolution, 'manual_pending');
      expect(conflicts.first.localStateJson, contains('10'));
      expect(conflicts.first.serverStateJson, contains('8'));

      // Mutation is still in conflict status (manual review pending).
      final queueRow = await db
          .customSelect(
            'SELECT status FROM sync_queue_items WHERE mutation_id = ?',
            variables: [Variable.withString('m-4')],
          )
          .getSingle();
      expect(queueRow.data['status'], 'conflict');
    });
  });

  group('AC-20 — sequential resolution of multiple conflicts on the same entity', () {
    test('two manual conflicts on the same entity produce two rows', () async {
      await seedPendingMutation('m-5', 'tenant-1');
      await seedPendingMutation('m-6', 'tenant-1');

      await resolver.resolve(
        mutationId: 'm-5',
        tenantId: 'tenant-1',
        moduleId: 'module_pertes',
        entityType: 'Perte',
        entityId: 'shared-entity',
        conflictData: {
          'client_state': {'v': 1},
          'server_state': {'v': 2},
        },
        strategy: ConflictStrategy.manual,
      );
      await resolver.resolve(
        mutationId: 'm-6',
        tenantId: 'tenant-1',
        moduleId: 'module_pertes',
        entityType: 'Perte',
        entityId: 'shared-entity',
        conflictData: {
          'client_state': {'v': 3},
          'server_state': {'v': 4},
        },
        strategy: ConflictStrategy.manual,
      );

      final total =
          await db.customSelect('SELECT COUNT(*) AS c FROM conflicts').getSingle();
      expect(total.data['c'], 2);
    });
  });
}
