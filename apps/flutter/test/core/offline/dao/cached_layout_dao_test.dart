import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:scalario/core/vault/dao/cached_layout_dao.dart';
import 'package:scalario/core/vault/database.dart';

void main() {
  late ScalarioDatabase db;
  late CachedLayoutDao dao;

  setUp(() {
    db = ScalarioDatabase(executor: NativeDatabase.memory());
    dao = CachedLayoutDao(db);
  });

  tearDown(() async => db.close());

  test('getByScreenId returns null when empty', () async {
    expect(await dao.getByScreenId('unknown'), isNull);
  });

  test('upsert and getByScreenId (AC-05, AC-19)', () async {
    await dao.upsert(CachedLayoutsCompanion(
      screenId: const Value('dashboard'),
      tenantId: const Value('t1'),
      layoutJson: const Value('{"zones":["kpi","chart"]}'),
      etag: const Value('"abc123"'),
      bytesSize: const Value(100),
    ));

    final layout = await dao.getByScreenId('dashboard');
    expect(layout, isNotNull);
    expect(layout!.layoutJson, contains('kpi'));
    expect(layout.etag, equals('"abc123"'));
    expect(layout.bytesSize, equals(100));
  });

  test('getLruOrdered returns layouts sorted by lastFetchAt ASC', () async {
    await _insert(dao, 'a', DateTime(2026, 1, 1));
    await _insert(dao, 'b', DateTime(2026, 1, 3));
    await _insert(dao, 'c', DateTime(2026, 1, 2));

    final lru = await dao.getLruOrdered('t1');
    expect(lru.map((l) => l.screenId).toList(), equals(['a', 'c', 'b']));
  });

  test('totalBytesForTenant sums byteSize', () async {
    await dao.upsert(CachedLayoutsCompanion(
      screenId: const Value('a'), tenantId: const Value('t1'),
      layoutJson: const Value('x'), bytesSize: const Value(100),
    ));
    await dao.upsert(CachedLayoutsCompanion(
      screenId: const Value('b'), tenantId: const Value('t1'),
      layoutJson: const Value('x'), bytesSize: const Value(50),
    ));

    expect(await dao.totalBytesForTenant('t1'), equals(150));
  });

  test('deleteByScreenId removes entry', () async {
    await dao.upsert(CachedLayoutsCompanion(
      screenId: const Value('x'), tenantId: const Value('t1'),
      layoutJson: const Value('{}'),
    ));
    await dao.deleteByScreenId('x');
    expect(await dao.getByScreenId('x'), isNull);
  });

  test('getByTenant filters by tenant', () async {
    await dao.upsert(CachedLayoutsCompanion(
        screenId: const Value('a'), tenantId: const Value('t1'),
        layoutJson: const Value('{}')));
    await dao.upsert(CachedLayoutsCompanion(
        screenId: const Value('b'), tenantId: const Value('t2'),
        layoutJson: const Value('{}')));

    expect((await dao.getByTenant('t1')).length, equals(1));
  });
}

Future<void> _insert(
  CachedLayoutDao dao,
  String id,
  DateTime fetchAt,
) async {
  await dao.upsert(CachedLayoutsCompanion(
    screenId: Value(id),
    tenantId: const Value('t1'),
    layoutJson: const Value('{}'),
    lastFetchAt: Value(fetchAt),
  ));
}
