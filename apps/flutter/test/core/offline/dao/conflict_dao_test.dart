import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:scalario/core/vault/dao/conflict_dao.dart';
import 'package:scalario/core/vault/database.dart';

void main() {
  late ScalarioDatabase db;
  late ConflictDao dao;

  setUp(() {
    db = ScalarioDatabase(executor: NativeDatabase.memory());
    dao = ConflictDao(db);
  });

  tearDown(() async => db.close());

  test('getById returns null for unknown', () async {
    expect(await dao.getById('nope'), isNull);
  });

  test('insert and getById (AC-08)', () async {
    await dao.insert(ConflictsCompanion(
      id: const Value('c-1'),
      mutationId: const Value('m-1'),
      localStateJson: const Value('{"qty":10}'),
      serverStateJson: const Value('{"qty":5}'),
    ));

    final c = await dao.getById('c-1');
    expect(c, isNotNull);
    expect(c!.localStateJson, contains('10'));
  });

  test('getAll returns conflicts for mutation', () async {
    await dao.insert(ConflictsCompanion(
        id: const Value('c1'), mutationId: const Value('m1'),
        localStateJson: const Value('{}'), serverStateJson: const Value('{}')));
    await dao.insert(ConflictsCompanion(
        id: const Value('c2'), mutationId: const Value('m1'),
        localStateJson: const Value('{}'), serverStateJson: const Value('{}')));
    await dao.insert(ConflictsCompanion(
        id: const Value('c3'), mutationId: const Value('m2'),
        localStateJson: const Value('{}'), serverStateJson: const Value('{}')));

    expect((await dao.getAll('m1')).length, equals(2));
    expect((await dao.getAll('m2')).length, equals(1));
  });

  test('markResolved sets resolvedAt and resolution', () async {
    await dao.insert(ConflictsCompanion(
      id: const Value('c-x'),
      mutationId: const Value('m-x'),
      localStateJson: const Value('{}'),
      serverStateJson: const Value('{}'),
    ));
    await dao.markResolved('c-x', resolution: 'client_wins');

    final resolved = await dao.getById('c-x');
    expect(resolved!.resolvedAt, isNotNull);
    expect(resolved.resolution, equals('client_wins'));
  });

  test('deleteResolved removes resolved conflicts', () async {
    await dao.insert(ConflictsCompanion(
        id: const Value('c1'), mutationId: const Value('m1'),
        localStateJson: const Value('{}'), serverStateJson: const Value('{}')));
    await dao.insert(ConflictsCompanion(
        id: const Value('c2'), mutationId: const Value('m1'),
        localStateJson: const Value('{}'), serverStateJson: const Value('{}')));
    await dao.markResolved('c1', resolution: 'server_wins');
    await dao.deleteResolved();

    expect((await dao.getAll('m1')).length, equals(1));
  });
}
