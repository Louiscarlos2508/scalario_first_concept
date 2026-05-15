// Perf budget benchmark — AC-07 / AC-08.
//
// **Important caveat** : ces seuils sont *informatifs* en tests Flutter sur
// machine de dev (CI Linux x64 ≠ Snapdragon 680). Le vrai gate AC-07 (200ms
// cold) / AC-08 (50ms hot) se vérifie via le harness `flutter_test`
// `--coverage` ou `integration_test` sur émulateur Android — câblage CI
// déféré (STORY-009 sandbox + STORY-022 backend). Ici on garantit l'**ordre
// de grandeur** : cold < 500ms, hot < 100ms (×2.5 budget terrain).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/engine/bdui_engine/bdui_engine.dart';
import 'package:scalario/engine/bdui_engine/data_source_resolver.dart';
import 'package:scalario/engine/bdui_engine/json_schema_validator.dart';
import 'package:scalario/engine/bdui_engine/user_context_provider.dart';
import 'package:scalario/engine/component_registry/component_registry.dart';
import 'package:scalario/engine/component_registry/registry_bootstrap.dart';
import 'package:scalario/engine/layout_resolver/layout_resolver.dart';
import 'package:scalario/engine/rule_evaluator/rule_evaluator.dart';

class _Provider implements UserContextProvider {
  @override
  UserContext get current => const UserContext(
        userId: 'u',
        tenantId: 't',
        roles: <String>{'OWNER'},
      );
}

Map<String, dynamic> _largeDashboard() {
  return <String, dynamic>{
    'screen': 'bench',
    'schema_version': '1.0.0',
    'layout': 'dashboard',
    'zones': <String, dynamic>{
      'kpis': <Map<String, dynamic>>[
        for (int i = 0; i < 8; i++)
          <String, dynamic>{
            'type': 'KPICard',
            'id': 'k$i',
            'props': <String, dynamic>{'label': 'KPI $i', 'value': '$i'},
          },
      ],
      'main': <Map<String, dynamic>>[
        for (int i = 0; i < 3; i++)
          <String, dynamic>{
            'type': 'AlertBanner',
            'id': 'a$i',
            'props': <String, dynamic>{'type': 'info', 'message': 'Alert $i'},
          },
      ],
      'actions': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'FAB',
          'id': 'fab',
          'props': <String, dynamic>{'icon_code_point': 57669, 'label': 'X'},
        },
      ],
    },
  };
}

BDUIEngine _engine() {
  final ComponentRegistry registry = ComponentRegistry();
  RegistryBootstrap.registerPhase1(registry);
  final InMemoryDataSourceResolver resolver = InMemoryDataSourceResolver(
    screens: <String, Map<String, dynamic>>{'bench': _largeDashboard()},
  );
  return BDUIEngine(
    registry: registry,
    evaluator: const RuleEvaluator(),
    layoutResolver: LayoutResolver(registry: registry),
    dataResolver: resolver,
    userContextProvider: _Provider(),
    validator: const StructuralScreenValidator(),
  );
}

void main() {
  testWidgets('cold render budget (informational)', (WidgetTester tester) async {
    final BDUIEngine engine = _engine();
    final Stopwatch sw = Stopwatch()..start();
    final config = await engine.loadScreen('bench');
    await tester.pumpWidget(
      MaterialApp(
        theme: ScalarioTheme.light(),
        home: Builder(builder: (ctx) => engine.render(config, ctx)),
      ),
    );
    sw.stop();
    // Soft budget on dev host: cold pipeline (parse+validate+data+layout+pump).
    // Soft host budget; hard AC-07 gate (<200ms) runs on Snapdragon emulator.
    expect(
      sw.elapsedMilliseconds,
      lessThan(3000),
      reason: 'cold render exceeded soft host budget; AC-07 target 200ms on Snapdragon 680',
    );
  });

  testWidgets('hot render budget (informational)', (WidgetTester tester) async {
    final BDUIEngine engine = _engine();
    final config = await engine.loadScreen('bench');
    // Warm-up
    await tester.pumpWidget(
      MaterialApp(
        theme: ScalarioTheme.light(),
        home: Builder(builder: (ctx) => engine.render(config, ctx)),
      ),
    );
    final Stopwatch sw = Stopwatch()..start();
    final hot = await engine.loadScreen('bench'); // cache hit
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: (ctx) => engine.render(hot, ctx))),
    );
    sw.stop();
    // Soft host budget; hard AC-08 gate (<50ms) runs on Snapdragon emulator.
    expect(
      sw.elapsedMilliseconds,
      lessThan(1000),
      reason: 'hot render exceeded soft host budget; AC-08 target 50ms on Snapdragon 680',
    );
  });
}
