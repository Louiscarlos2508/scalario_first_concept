import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_registry/component_config.dart';
import 'package:scalario/engine/canvas_registry/scalario_canvas_registry.dart';
import 'package:scalario/engine/canvas_registry/unknown_component.dart';

void main() {
  late ScalarioCanvasRegistry registry;

  setUp(() {
    registry = ScalarioCanvasRegistry();
  });

  group('register + isRegistered', () {
    test('registers a type and isRegistered returns true', () {
      registry.register('TestWidget', (c, ctx) => const SizedBox());
      expect(registry.isRegistered('TestWidget'), isTrue);
    });

    test('unregistered type returns false', () {
      expect(registry.isRegistered('Ghost'), isFalse);
    });

    test('second register overrides silently — no exception', () {
      registry.register('Dup', (c, ctx) => const Text('first'));
      expect(
        () => registry.register('Dup', (c, ctx) => const Text('second')),
        returnsNormally,
      );
    });

    testWidgets('second register — latest builder wins', (tester) async {
      registry.register('Dup', (c, ctx) => const Text('first'));
      registry.register('Dup', (c, ctx) => const Text('second'));

      const config = ComponentConfig(type: 'Dup', props: <String, dynamic>{});

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(
          builder: (ctx) => registry.build(config, ctx),
        ))),
      );

      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
    });
  });

  group('unregister', () {
    test('unregister removes the type', () {
      registry.register('ToRemove', (c, ctx) => const SizedBox());
      registry.unregister('ToRemove');
      expect(registry.isRegistered('ToRemove'), isFalse);
    });

    test('unregister on unknown type does nothing', () {
      expect(() => registry.unregister('Never'), returnsNormally);
    });
  });

  group('registeredTypes', () {
    test('returns alphabetically sorted list', () {
      registry.register('Zebra', (c, ctx) => const SizedBox());
      registry.register('Alpha', (c, ctx) => const SizedBox());
      registry.register('Mango', (c, ctx) => const SizedBox());

      expect(registry.registeredTypes, equals(['Alpha', 'Mango', 'Zebra']));
    });

    test('empty registry returns empty list', () {
      expect(registry.registeredTypes, isEmpty);
    });
  });

  group('build — known type', () {
    testWidgets('returns builder output wrapped in ErrorBoundary', (tester) async {
      registry.register('Box', (c, ctx) => const SizedBox.shrink());
      const config = ComponentConfig(type: 'Box', props: <String, dynamic>{});

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(
          builder: (ctx) => registry.build(config, ctx),
        ))),
      );

      // The widget should render without error.
      expect(tester.takeException(), isNull);
    });
  });

  group('build — unknown type', () {
    testWidgets('unknown type renders UnknownComponent, does not throw',
        (tester) async {
      const config = ComponentConfig(type: 'DoesNotExist', props: <String, dynamic>{});

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(
          builder: (ctx) => registry.build(config, ctx),
        ))),
      );

      expect(find.byType(UnknownComponent), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown type shows type name in UI', (tester) async {
      const config = ComponentConfig(type: 'DoesNotExist', props: <String, dynamic>{});

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(
          builder: (ctx) => registry.build(config, ctx),
        ))),
      );

      expect(find.textContaining('DoesNotExist'), findsOneWidget);
    });

    testWidgets('empty type string renders without crash', (tester) async {
      const config = ComponentConfig(type: '', props: <String, dynamic>{});

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(
          builder: (ctx) => registry.build(config, ctx),
        ))),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(UnknownComponent), findsOneWidget);
    });

    testWidgets('null props — UnknownComponent still renders', (tester) async {
      // Passing empty props (null guard in ComponentConfig.fromJson)
      final config = ComponentConfig.fromJson({'type': 'Missing'});

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(
          builder: (ctx) => registry.build(config, ctx),
        ))),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('ComponentConfig', () {
    test('fromJson parses all fields', () {
      final json = {
        'type': 'KPICard',
        'id': 'kpi_ca',
        'props': {'label': 'CA', 'value': '5000'},
        'visible_if': {'role': 'OWNER'},
        'i18n_key': 'kpi.ca',
      };
      final config = ComponentConfig.fromJson(json);

      expect(config.type, 'KPICard');
      expect(config.id, 'kpi_ca');
      expect(config.props['label'], 'CA');
      expect(config.visibleIf, {'role': 'OWNER'});
      expect(config.i18nKey, 'kpi.ca');
    });

    test('fromJson with missing type returns empty type', () {
      final config = ComponentConfig.fromJson({'props': {}});
      expect(config.type, '');
    });

    test('fromJson with missing props returns empty map', () {
      final config = ComponentConfig.fromJson({'type': 'KPICard'});
      expect(config.props, isEmpty);
    });

    test('copyWith overrides only specified fields', () {
      const original = ComponentConfig(
        type: 'KPICard',
        id: 'abc',
        props: {'label': 'CA'},
      );
      final copy = original.copyWith(type: 'DataTable');

      expect(copy.type, 'DataTable');
      expect(copy.id, 'abc');
      expect(copy.props, {'label': 'CA'});
    });

    test('toJson round-trips fromJson', () {
      final json = {
        'type': 'AlertBanner',
        'id': 'alert_1',
        'props': {'message': 'Test', 'type': 'warning'},
      };
      final config = ComponentConfig.fromJson(json);
      final exported = config.toJson();

      expect(exported['type'], 'AlertBanner');
      expect(exported['id'], 'alert_1');
      expect(
        (exported['props'] as Map<String, dynamic>)['message'],
        'Test',
      );
    });

    test('fromJson parses validation list', () {
      final config = ComponentConfig.fromJson({
        'type': 'FormWidget',
        'validation': [
          {'rule': 'required'},
          {'rule': 'minLength', 'value': 3},
        ],
      });
      expect(config.validation, hasLength(2));
    });

    test('copyWith replaces all optional fields', () {
      const original = ComponentConfig(
        type: 'KPICard',
        id: 'k1',
        props: <String, dynamic>{'label': 'CA'},
      );
      final copy = original.copyWith(
        type: 'AlertBanner',
        id: 'a1',
        props: <String, dynamic>{'message': 'Hello'},
        visibleIf: <String, dynamic>{'role': 'OWNER'},
        i18nKey: 'banner.key',
      );

      expect(copy.type, 'AlertBanner');
      expect(copy.id, 'a1');
      expect(copy.props['message'], 'Hello');
      expect(copy.visibleIf, {'role': 'OWNER'});
      expect(copy.i18nKey, 'banner.key');
    });

    test('equality — same type+id are equal', () {
      const a = ComponentConfig(type: 'KPI', id: 'k1', props: <String, dynamic>{});
      const b = ComponentConfig(type: 'KPI', id: 'k1', props: <String, dynamic>{'x': 1});
      expect(a, equals(b));
    });

    test('equality — different type are not equal', () {
      const a = ComponentConfig(type: 'KPI', id: 'k1', props: <String, dynamic>{});
      const b = ComponentConfig(type: 'Banner', id: 'k1', props: <String, dynamic>{});
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      const a = ComponentConfig(type: 'KPI', id: 'k1', props: <String, dynamic>{});
      const b = ComponentConfig(type: 'KPI', id: 'k1', props: <String, dynamic>{});
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes type and id', () {
      const config = ComponentConfig(type: 'KPICard', id: 'k1', props: <String, dynamic>{});
      expect(config.toString(), contains('KPICard'));
      expect(config.toString(), contains('k1'));
    });
  });
}
