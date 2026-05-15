import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/bdui_engine/data_source_resolver.dart';

void main() {
  group('InMemoryDataSourceResolver', () {
    test('loadScreenJson returns registered screen', () async {
      final resolver = InMemoryDataSourceResolver(
        screens: <String, Map<String, dynamic>>{
          'demo': <String, dynamic>{'screen': 'demo'},
        },
      );
      final Map<String, dynamic> result = await resolver.loadScreenJson('demo');
      expect(result['screen'], 'demo');
    });

    test('loadScreenJson throws on unknown screen', () async {
      final resolver = InMemoryDataSourceResolver();
      expect(
        () => resolver.loadScreenJson('missing'),
        throwsA(isA<DataSourceNotFoundException>()),
      );
    });

    test('resolveDataSource returns registered value or null', () async {
      final resolver = InMemoryDataSourceResolver(
        dataSources: <String, Object?>{'kpi_ventes': 42},
      );
      final value = await resolver.resolveDataSource(
        <String, dynamic>{'id': 'kpi_ventes'},
      );
      expect(value, 42);

      final missing = await resolver.resolveDataSource(
        <String, dynamic>{'id': 'unknown'},
      );
      expect(missing, isNull);
    });

    test('resolveDataSource returns null when source has no id', () async {
      final resolver = InMemoryDataSourceResolver();
      final value =
          await resolver.resolveDataSource(<String, dynamic>{'type': 'fixture'});
      expect(value, isNull);
    });

    test('register methods mutate the resolver', () async {
      final resolver = InMemoryDataSourceResolver();
      resolver.registerScreen('x', <String, dynamic>{'screen': 'x'});
      resolver.registerDataSource('d', 'value');
      expect((await resolver.loadScreenJson('x'))['screen'], 'x');
      expect(
        await resolver.resolveDataSource(<String, dynamic>{'id': 'd'}),
        'value',
      );
    });
  });
}
