import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/engine/bdui_engine/bdui_engine.dart';
import 'package:scalario/engine/bdui_engine/bdui_engine_config.dart';
import 'package:scalario/engine/bdui_engine/data_source_resolver.dart';
import 'package:scalario/engine/bdui_engine/json_schema_validator.dart';
import 'package:scalario/engine/bdui_engine/user_context_provider.dart';
import 'package:scalario/engine/component_registry/component_registry.dart';
import 'package:scalario/engine/component_registry/registry_bootstrap.dart';
import 'package:scalario/engine/error_boundary/bdui_error_boundary.dart';
import 'package:scalario/engine/layout_resolver/layout_resolver.dart';
import 'package:scalario/engine/rule_evaluator/rule_evaluator.dart';

class _RoleProvider implements UserContextProvider {
  _RoleProvider(this.role);
  String role;
  @override
  UserContext get current => UserContext(
        userId: 'u',
        tenantId: 't',
        roles: <String>{role},
      );
}

BDUIEngine _buildEngine({
  required DataSourceResolver resolver,
  required UserContextProvider userCtx,
  int cacheSize = 20,
}) {
  final ComponentRegistry registry = ComponentRegistry();
  RegistryBootstrap.registerPhase1(registry);
  return BDUIEngine(
    registry: registry,
    evaluator: const RuleEvaluator(),
    layoutResolver: LayoutResolver(registry: registry),
    dataResolver: resolver,
    userContextProvider: userCtx,
    validator: const StructuralScreenValidator(),
    config: BDUIEngineConfig(screenCacheSize: cacheSize),
  );
}

Map<String, dynamic> _dashboard({
  List<Map<String, dynamic>>? kpis,
  List<Map<String, dynamic>>? main,
}) =>
    <String, dynamic>{
      'screen': 'demo',
      'schema_version': '1.0.0',
      'layout': 'dashboard',
      'zones': <String, dynamic>{
        'kpis': ?kpis,
        'main': ?main,
      },
    };

void main() {
  testWidgets('loadScreen caches parsed ScreenConfig (hit on 2nd call)',
      (WidgetTester tester) async {
    int loadCount = 0;
    final InMemoryDataSourceResolver resolver = InMemoryDataSourceResolver();
    resolver.registerScreen('demo', _dashboard());
    final BDUIEngine engine = _buildEngine(
      resolver: _CountingResolver(resolver, () => loadCount++),
      userCtx: _RoleProvider('OWNER'),
    );

    final ScreenConfig a = await engine.loadScreen('demo');
    final ScreenConfig b = await engine.loadScreen('demo');
    expect(identical(a, b), isTrue);
    expect(loadCount, 1);
  });

  testWidgets('loadScreen surfaces validation errors',
      (WidgetTester tester) async {
    final InMemoryDataSourceResolver resolver = InMemoryDataSourceResolver();
    resolver.registerScreen('bad', <String, dynamic>{'screen': 'bad'});
    final BDUIEngine engine = _buildEngine(
      resolver: resolver,
      userCtx: _RoleProvider('OWNER'),
    );
    expect(
      () => engine.loadScreen('bad'),
      throwsA(isA<BDUIValidationException>()),
    );
  });

  testWidgets('DataSourceResolver injects "_data" into props',
      (WidgetTester tester) async {
    final InMemoryDataSourceResolver resolver = InMemoryDataSourceResolver();
    resolver.registerScreen('demo', <String, dynamic>{
      'screen': 'demo',
      'schema_version': '1.0.0',
      'layout': 'dashboard',
      'zones': <String, dynamic>{
        'kpis': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'KPICard',
            'id': 'k1',
            'props': <String, dynamic>{'label': 'L', 'value': 'V'},
            'source': <String, dynamic>{'id': 'kpi_d'},
          },
        ],
      },
    });
    resolver.registerDataSource('kpi_d', <String, dynamic>{'foo': 1});

    final BDUIEngine engine = _buildEngine(
      resolver: resolver,
      userCtx: _RoleProvider('OWNER'),
    );
    final ScreenConfig screen = await engine.loadScreen('demo');
    expect(screen.zones.kpis!.single.props['_data'], <String, dynamic>{'foo': 1});
  });

  testWidgets('render filters components hidden by visible_if',
      (WidgetTester tester) async {
    final InMemoryDataSourceResolver resolver = InMemoryDataSourceResolver();
    resolver.registerScreen('demo', _dashboard(
      kpis: <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'KPICard',
          'id': 'public',
          'props': <String, dynamic>{'label': 'Public', 'value': '1'},
        },
        <String, dynamic>{
          'type': 'KPICard',
          'id': 'owner',
          'props': <String, dynamic>{'label': 'Owner', 'value': '2'},
          'visible_if': <String, dynamic>{
            'role': <String>['OWNER'],
          },
        },
      ],
    ));

    final _RoleProvider provider = _RoleProvider('CASHIER');
    final BDUIEngine engine =
        _buildEngine(resolver: resolver, userCtx: provider);
    final ScreenConfig screen = await engine.loadScreen('demo');

    await tester.pumpWidget(
      MaterialApp(
        theme: ScalarioTheme.light(),
        home: Builder(builder: (ctx) => engine.render(screen, ctx)),
      ),
    );
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Owner'), findsNothing);

    // Now switch role to OWNER and re-render via fresh widget — both visible.
    provider.role = 'OWNER';
    await tester.pumpWidget(
      MaterialApp(
        theme: ScalarioTheme.light(),
        home: Builder(builder: (ctx) => engine.render(screen, ctx)),
      ),
    );
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
  });

  testWidgets('render wraps the tree in a BDUIErrorBoundary',
      (WidgetTester tester) async {
    final InMemoryDataSourceResolver resolver = InMemoryDataSourceResolver();
    resolver.registerScreen('demo', _dashboard());
    final BDUIEngine engine = _buildEngine(
      resolver: resolver,
      userCtx: _RoleProvider('OWNER'),
    );
    final ScreenConfig screen = await engine.loadScreen('demo');
    await tester.pumpWidget(
      MaterialApp(
        theme: ScalarioTheme.light(),
        home: Builder(builder: (ctx) => engine.render(screen, ctx)),
      ),
    );
    expect(find.byType(BDUIErrorBoundary), findsOneWidget);
  });

  testWidgets('invalidate clears the cache', (WidgetTester tester) async {
    int loadCount = 0;
    final InMemoryDataSourceResolver resolver = InMemoryDataSourceResolver();
    resolver.registerScreen('demo', _dashboard());
    final BDUIEngine engine = _buildEngine(
      resolver: _CountingResolver(resolver, () => loadCount++),
      userCtx: _RoleProvider('OWNER'),
    );
    await engine.loadScreen('demo');
    engine.invalidate();
    await engine.loadScreen('demo');
    expect(loadCount, 2);
  });
}

/// Wraps an [InMemoryDataSourceResolver] to count `loadScreenJson` calls.
class _CountingResolver implements DataSourceResolver {
  _CountingResolver(this._inner, this._onLoad);
  final InMemoryDataSourceResolver _inner;
  final void Function() _onLoad;

  @override
  Future<Map<String, dynamic>> loadScreenJson(String screenId) {
    _onLoad();
    return _inner.loadScreenJson(screenId);
  }

  @override
  Future<Object?> resolveDataSource(Map<String, dynamic> source) =>
      _inner.resolveDataSource(source);
}
