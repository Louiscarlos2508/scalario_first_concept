import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:scalario/core/vault/dao/tenant_config_dao.dart';
import 'package:scalario/core/vault/database.dart';

void main() {
  late ScalarioDatabase db;
  late TenantConfigDao dao;

  setUp(() {
    db = ScalarioDatabase(executor: NativeDatabase.memory());
    dao = TenantConfigDao(db);
  });

  tearDown(() async => db.close());

  test('getActive returns null when empty', () async {
    expect(await dao.getActive(), isNull);
  });

  test('upsert then getActive returns config (AC-04)', () async {
    await dao.upsert(TenantConfigsCompanion(
      tenantId: const Value('t-1'),
      slug: const Value('my-tenant'),
      configJson: const Value('{"lang":"fr"}'),
      cacheLimitMb: const Value(500),
    ));

    final config = await dao.getActive();
    expect(config, isNotNull);
    expect(config!.slug, equals('my-tenant'));
    expect(config.cacheLimitMb, equals(500));
  });

  test('upsert replaces previous config', () async {
    await dao.upsert(TenantConfigsCompanion(
      tenantId: const Value('t-1'),
      slug: const Value('v1'),
      configJson: const Value('{}'),
    ));
    await dao.upsert(TenantConfigsCompanion(
      tenantId: const Value('t-1'),
      slug: const Value('v2'),
      configJson: const Value('{"v":2}'),
    ));

    final config = await dao.getActive();
    expect(config!.slug, equals('v2'));
  });

  test('deleteAll clears config', () async {
    await dao.upsert(TenantConfigsCompanion(
      tenantId: const Value('t-1'),
      slug: const Value('x'),
      configJson: const Value('{}'),
    ));
    await dao.deleteAll();
    expect(await dao.getActive(), isNull);
  });
}
