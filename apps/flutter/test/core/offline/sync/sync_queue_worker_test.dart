import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:scalario/core/offline/database.dart';
import 'package:scalario/core/offline/dao/sync_queue_dao.dart';
import 'package:scalario/core/offline/sync/connectivity_listener.dart';
import 'package:scalario/core/offline/sync/retry_policy.dart';
import 'package:scalario/core/offline/sync/sync_api_client.dart';
import 'package:scalario/core/offline/sync/sync_queue_worker.dart';

import '../../../test_utils/fake_connectivity.dart';
import '../../../test_utils/fake_sync_api_client.dart';

void main() {
  late ScalarioDatabase db;
  late SyncQueueDao dao;
  late FakeConnectivity fakeConnectivity;
  late FakeSyncApiClient fakeApi;

  setUp(() {
    db = ScalarioDatabase(executor: NativeDatabase.memory());
    dao = SyncQueueDao(db);
    fakeConnectivity = FakeConnectivity();
    fakeApi = FakeSyncApiClient();
  });

  tearDown(() async {
    fakeConnectivity.dispose();
    fakeApi.dispose();
    await db.close();
  });

  // ignore: no_leading_underscores_for_local_identifiers
  SyncQueueWorker _createWorker(String tenantSlug) => SyncQueueWorker(
        queueDao: dao,
        apiClient: fakeApi,
        connectivityListener: ConnectivityListener(
          connectivity: fakeConnectivity.connectivity,
        ),
        tenantSlug: tenantSlug,
        retryPolicy: const _FakeRetryPolicy(),
      );

  group('FIFO ordering', () {
    test('drain sends mutations in created_at order', () async {
      await dao.insert(_companion('m1', 't1', at: DateTime(2026, 1, 1)));
      await dao.insert(_companion('m2', 't1', at: DateTime(2026, 1, 2)));
      await dao.insert(_companion('m3', 't1', at: DateTime(2026, 1, 3)));

      fakeApi.response = BatchSyncResponse(results: [
        _success('m1'),
        _success('m2'),
        _success('m3'),
      ]);

      final worker = _createWorker('t1');
      unawaited(worker.start());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(fakeApi.receivedMutations.length, 3);
      expect(fakeApi.receivedMutations[0].mutationId, 'm1');
      expect(fakeApi.receivedMutations[1].mutationId, 'm2');
      expect(fakeApi.receivedMutations[2].mutationId, 'm3');

      worker.dispose();
    });
  });

  group('Status transitions', () {
    test('pending → success after drain', () async {
      await dao.insert(_companion('m1', 't1'));

      fakeApi.response = BatchSyncResponse(results: [_success('m1')]);

      final worker = _createWorker('t1');
      unawaited(worker.start());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final items = await dao.fetchEligible(
        tenantId: 't1',
        now: DateTime(2026),
      );
      expect(items.isEmpty, isTrue);

      worker.dispose();
    });
  });

  group('Kill process recovery', () {
    test('sending → pending on startup', () async {
      await dao.insert(_companion('m1', 't1'));
      await dao.markSending(['m1']);

      final stuck = await dao.fetchEligible(
        tenantId: 't1',
        now: DateTime(2026),
      );
      expect(stuck.isEmpty, isTrue);

      await dao.recoverInFlight(tenantId: 't1');

      final recovered = await dao.fetchEligible(
        tenantId: 't1',
        now: DateTime(2026),
      );
      expect(recovered.length, 1);
      expect(recovered.first.mutationId, 'm1');
      expect(recovered.first.status, 'pending');
    });
  });

  group('Error handling', () {
    test('retryable error → backoff', () async {
      await dao.insert(_companion('m1', 't1'));
      fakeApi.shouldThrow =
          const SyncApiError(message: 'Network down', isRetryable: true);

      final worker = _createWorker('t1');
      unawaited(worker.start());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final eligible = await dao.fetchEligible(
        tenantId: 't1',
        now: DateTime(2026),
      );
      expect(eligible.isEmpty, isTrue);

      worker.dispose();
    });

    test('client error 4xx → permanent error', () async {
      await dao.insert(_companion('m1', 't1'));
      fakeApi.shouldThrow = const SyncApiError(
        message: 'Bad request',
        statusCode: 400,
        isRetryable: false,
      );

      final worker = _createWorker('t1');
      unawaited(worker.start());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      worker.dispose();
    });

    test('conflict 409 → status = conflict', () async {
      await dao.insert(_companion('m1', 't1'));
      fakeApi.shouldThrow = const SyncApiError(
        message: 'Conflict',
        statusCode: 409,
        isRetryable: false,
      );

      final worker = _createWorker('t1');
      unawaited(worker.start());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      worker.dispose();
    });
  });

  group('Connectivity listener', () {
    test('drain triggers on connectivity restored', () async {
      await dao.insert(_companion('m1', 't1'));

      fakeApi.response = BatchSyncResponse(results: [_success('m1')]);

      final worker = _createWorker('t1');
      unawaited(worker.start());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      fakeConnectivity.emitConnected();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final pending = await dao.fetchEligible(
        tenantId: 't1',
        now: DateTime(2026),
      );
      expect(pending.isEmpty, isTrue);

      worker.dispose();
    });
  });

  group('Mutex', () {
    test('single drain processes all mutations', () async {
      await dao.insert(_companion('m1', 't1'));
      await dao.insert(_companion('m2', 't1'));

      fakeApi.response = BatchSyncResponse(results: [
        _success('m1'),
        _success('m2'),
      ]);

      final worker = _createWorker('t1');
      unawaited(worker.start());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(fakeApi.receivedMutations.length, 2);

      worker.dispose();
    });
  });
}

SyncQueueItemsCompanion _companion(
  String id,
  String tenantId, {
  DateTime? at,
  String status = 'pending',
}) =>
    SyncQueueItemsCompanion(
      mutationId: Value(id),
      tenantId: Value(tenantId),
      moduleId: const Value('ventes'),
      action: const Value('create'),
      payloadJson: const Value('{}'),
      idempotencyKey: Value(id),
      createdAt: Value(at ?? DateTime(2026, 1, 1)),
      status: Value(status),
    );

SyncResultItem _success(String id) => SyncResultItem(
      mutationId: id,
      status: 'success',
    );

class _FakeRetryPolicy implements RetryPolicy {
  const _FakeRetryPolicy();

  @override
  Duration nextBackoff(int retryCount) => const Duration(seconds: 1);
}
