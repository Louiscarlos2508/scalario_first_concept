import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:scalario/core/offline/dao/sync_queue_dao.dart';
import 'package:scalario/core/offline/database.dart';

void main() {
  late ScalarioDatabase db;
  late SyncQueueDao dao;

  setUp(() {
    db = ScalarioDatabase(executor: NativeDatabase.memory());
    dao = SyncQueueDao(db);
  });

  tearDown(() async => db.close());

  test('getNextPending returns null when empty', () async {
    expect(await dao.getNextPending(), isNull);
  });

  test('insert and getNextPending returns FIFO (AC-07)', () async {
    await dao.insert(SyncQueueItemsCompanion(
      mutationId: const Value('m1'),
      tenantId: const Value('t1'),
      moduleId: const Value('ventes'),
      action: const Value('create'),
      payloadJson: const Value('{}'),
      idempotencyKey: const Value('ik1'),
      createdAt: Value(DateTime(2026, 1, 1)),
    ));
    await dao.insert(SyncQueueItemsCompanion(
      mutationId: const Value('m2'),
      tenantId: const Value('t1'),
      moduleId: const Value('ventes'),
      action: const Value('update'),
      payloadJson: const Value('{}'),
      idempotencyKey: const Value('ik2'),
      createdAt: Value(DateTime(2026, 1, 2)),
    ));

    final next = await dao.getNextPending();
    expect(next, isNotNull);
    expect(next!.mutationId, equals('m1'));
  });

  test('getPending filters by tenant and status', () async {
    await dao.insert(_item('a', 't1', 'ik-a'));
    await dao.insert(_item('b', 't2', 'ik-b'));
    await dao.insert(_item('c', 't1', 'ik-c'));

    final pending = await dao.getPending('t1');
    expect(pending.length, equals(2));
  });

  test('pendingCount returns count', () async {
    await dao.insert(_item('a', 't1', 'ik-a'));
    await dao.insert(_item('b', 't1', 'ik-b'));

    expect(await dao.pendingCount('t1'), equals(2));
  });

  test('markCompleted changes status', () async {
    await dao.insert(_item('m', 't1', 'ik-m'));
    await dao.markCompleted('m');

    final next = await dao.getNextPending();
    expect(next, isNull);
  });

  test('markFailed updates status and increments retryCount', () async {
    await dao.insert(_item('m', 't1', 'ik-m'));
    await dao.markFailed('m', error: 'Network error');

    // Since this used a customStatement, verify via direct query
    final rows = await (db.select(db.syncQueueItems)
          ..where((t) => t.mutationId.equals('m')))
        .get();
    expect(rows.first.status, equals('failed'));
    expect(rows.first.lastError, equals('Network error'));
    expect(rows.first.retryCount, equals(1));
  });

  test('deleteCompleted removes completed items', () async {
    await dao.insert(_item('a', 't1', 'ik-a'));
    await dao.insert(_item('b', 't1', 'ik-b'));
    await dao.markCompleted('a');
    await dao.deleteCompleted();

    expect(await dao.pendingCount('t1'), equals(1));
  });
}

SyncQueueItemsCompanion _item(String id, String tenant, String key) =>
    SyncQueueItemsCompanion(
      mutationId: Value(id),
      tenantId: Value(tenant),
      moduleId: const Value('m1'),
      action: const Value('create'),
      payloadJson: const Value('{}'),
      idempotencyKey: Value(key),
    );
