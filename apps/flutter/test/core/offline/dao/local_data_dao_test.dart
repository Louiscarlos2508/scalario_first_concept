import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:scalario/core/vault/dao/local_data_dao.dart';
import 'package:scalario/core/vault/database.dart';

void main() {
  late ScalarioDatabase db;
  late LocalDataDao dao;

  setUp(() {
    db = ScalarioDatabase(executor: NativeDatabase.memory());
    dao = LocalDataDao(db);
  });

  tearDown(() async => db.close());

  test('getById returns null for unknown id', () async {
    expect(await dao.getById('nope'), isNull);
  });

  test('upsert and getById (AC-06)', () async {
    await dao.upsertCompanion(LocalDataCompanion(
      id: const Value('r-1'),
      tenantId: const Value('t1'),
      moduleId: const Value('ventes'),
      entityType: const Value('product'),
      dataJson: const Value('{"name":"Banane"}'),
      syncStatus: const Value('synced'),
    ));

    final record = await dao.getById('r-1');
    expect(record, isNotNull);
    expect(record!.moduleId, equals('ventes'));
    expect(record.dataJson, contains('Banane'));
  });

  test('getByModule filters by tenant and module', () async {
    await _insert(dao, 'r1', 't1', 'ventes', 'p', 'synced');
    await _insert(dao, 'r2', 't1', 'ventes', 'p', 'synced');
    await _insert(dao, 'r3', 't1', 'achats', 'p', 'synced');

    final ventes = await dao.getByModule('t1', 'ventes');
    expect(ventes.length, equals(2));

    final ventesProduct =
        await dao.getByModule('t1', 'ventes', entityType: 'p');
    expect(ventesProduct.length, equals(2));
  });

  test('getPendingSync returns only pending_sync records', () async {
    await _insert(dao, 'r1', 't1', 'm1', 'e1', 'synced');
    await _insert(dao, 'r2', 't1', 'm1', 'e1', 'pending_sync');
    await _insert(dao, 'r3', 't1', 'm1', 'e1', 'local_only');

    final pending = await dao.getPendingSync('t1');
    expect(pending.length, equals(1));
    expect(pending.first.id, equals('r2'));
  });

  test('totalRowsForTenant counts correctly', () async {
    await _insert(dao, 'a1', 't1', 'm', 'e', 'synced');
    await _insert(dao, 'a2', 't1', 'm', 'e', 'synced');
    await _insert(dao, 'a3', 't2', 'm', 'e', 'synced');

    expect(await dao.totalRowsForTenant('t1'), equals(2));
  });

  test('deleteById removes record', () async {
    await _insert(dao, 'd1', 't1', 'm', 'e', 'synced');
    await dao.deleteById('d1');
    expect(await dao.getById('d1'), isNull);
  });

  test('deleteAll clears everything', () async {
    await _insert(dao, 'x', 't1', 'm', 'e', 'synced');
    await dao.deleteAll();
    expect(await dao.totalRowsForTenant('t1'), equals(0));
  });
}

Future<void> _insert(
  LocalDataDao dao,
  String id,
  String tenant,
  String module,
  String entity,
  String status,
) async {
  await dao.upsertCompanion(LocalDataCompanion(
    id: Value(id),
    tenantId: Value(tenant),
    moduleId: Value(module),
    entityType: Value(entity),
    dataJson: const Value('{}'),
    syncStatus: Value(status),
  ));
}
