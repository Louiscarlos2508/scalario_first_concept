import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/bdui/validation/bdui_type.dart';
import 'package:scalario/core/bdui/validation/bdui_validator.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/engine/bdui_engine/bdui_engine.dart';
import 'package:scalario/engine/bdui_engine/bdui_engine_config.dart';
import 'package:scalario/engine/bdui_engine/bdui_invalid_payload_exception.dart';
import 'package:scalario/engine/bdui_engine/data_source_resolver.dart';
import 'package:scalario/engine/bdui_engine/json_schema_validator.dart';
import 'package:scalario/engine/bdui_engine/user_context_provider.dart';
import 'package:scalario/engine/component_registry/component_registry.dart';
import 'package:scalario/engine/component_registry/registry_bootstrap.dart';
import 'package:scalario/engine/layout_resolver/layout_resolver.dart';
import 'package:scalario/engine/rule_evaluator/rule_evaluator.dart';

Map<String, dynamic> _invalidPayload() => <String, dynamic>{
  'screen': 123,
  'schema_version': '1.0.0',
  'layout': 'dashboard',
  'zones': <String, dynamic>{'main': <Map<String, dynamic>>[]},
};

Map<String, dynamic> _validPayload() => <String, dynamic>{
  'screen': 'demo',
  'schema_version': '1.0.0',
  'layout': 'dashboard',
  'zones': <String, dynamic>{
    'main': <Map<String, dynamic>>[
      <String, dynamic>{'type': 'KPICard', 'props': <String, dynamic>{}},
    ],
  },
};

void main() {
  late BDUIEngine engine;

  setUp(() async {
    BduiValidator.reset();
    await BduiValidator.initFromMaps({
      BduiType.screenConfig: {
        r'$schema': 'https://json-schema.org/draft/2020-12/schema',
        'type': 'object',
        'properties': {
          'screen': {'type': 'string'},
          'schema_version': {'const': '1.0.0'},
          'layout': {'enum': ['dashboard', 'list', 'form', 'detail']},
          'zones': {'type': 'object'},
        },
        'required': ['screen', 'schema_version', 'layout', 'zones'],
        'additionalProperties': false,
      },
    });

    final registry = ComponentRegistry();
    RegistryBootstrap.registerPhase1(registry);
    engine = BDUIEngine(
      registry: registry,
      evaluator: const RuleEvaluator(),
      layoutResolver: LayoutResolver(registry: registry),
      dataResolver: InMemoryDataSourceResolver(),
      userContextProvider: const _DemoUserCtx(),
      validator: const StructuralScreenValidator(),
      config: BDUIEngineConfig(screenCacheSize: 20, enableTimeline: false),
    );
  });

  tearDown(() {
    BduiValidator.reset();
  });

  // AC-20: Mock ApiClient returns broken JSON → app shows FallbackScreen
  testWidgets('AC-20 — renderRaw returns FallbackScreen for invalid JSON',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ScalarioTheme.light(),
      home: Builder(builder: (ctx) {
        return engine.renderRaw(_invalidPayload(), ctx);
      }),
    ));

    expect(
      find.text("Cet écran n'a pas pu être chargé.\nNous avons enregistré le problème."),
      findsOneWidget,
    );
  });

  testWidgets('renderRaw renders normally for valid JSON', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ScalarioTheme.light(),
      home: Builder(builder: (ctx) {
        return engine.renderRaw(_validPayload(), ctx);
      }),
    ));

    expect(find.text("Cet écran n'a pas pu être chargé.\nNous avons enregistré le problème."),
        findsNothing);
  });

  test('loadScreen throws BduiInvalidPayloadException for invalid JSON', () async {
    final resolver = InMemoryDataSourceResolver();
    resolver.registerScreen('bad_json', _invalidPayload());

    final localEngine = BDUIEngine(
      registry: engine.registry,
      evaluator: engine.evaluator,
      layoutResolver: engine.layoutResolver,
      dataResolver: resolver,
      userContextProvider: const _DemoUserCtx(),
      validator: const StructuralScreenValidator(),
      config: BDUIEngineConfig(screenCacheSize: 20, enableTimeline: false),
    );

    expect(
      () => localEngine.loadScreen('bad_json'),
      throwsA(isA<BduiInvalidPayloadException>()),
    );
  });

  test('loadScreen succeeds for valid JSON', () async {
    final resolver = InMemoryDataSourceResolver();
    resolver.registerScreen('valid_json', _validPayload());

    final localEngine = BDUIEngine(
      registry: engine.registry,
      evaluator: engine.evaluator,
      layoutResolver: engine.layoutResolver,
      dataResolver: resolver,
      userContextProvider: const _DemoUserCtx(),
      validator: const StructuralScreenValidator(),
      config: BDUIEngineConfig(screenCacheSize: 20, enableTimeline: false),
    );

    final config = await localEngine.loadScreen('valid_json');
    expect(config.screen, 'demo');
  });

  // AC-19: BDUIEngine.render returns FallbackScreen for invalid payload
  testWidgets('AC-19 — renderRaw never throws for invalid JSON', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ScalarioTheme.light(),
      home: Builder(builder: (ctx) {
        return engine.renderRaw(_invalidPayload(), ctx);
      }),
    ));

    // No exception remontée — FallbackScreen affiché proprement
    expect(tester.takeException(), isNull);
  });
}

class _DemoUserCtx implements UserContextProvider {
  const _DemoUserCtx();

  @override
  UserContext get current => const UserContext(
    userId: 'test-user',
    tenantId: 'test-tenant',
    roles: {'OWNER'},
  );
}
