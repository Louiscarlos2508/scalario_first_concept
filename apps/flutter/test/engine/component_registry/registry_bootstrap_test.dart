import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/engine/component_registry/component_config.dart';
import 'package:scalario/engine/component_registry/component_registry.dart';
import 'package:scalario/engine/component_registry/registry_bootstrap.dart';

void main() {
  late ComponentRegistry registry;

  setUp(() {
    registry = ComponentRegistry();
    RegistryBootstrap.registerPhase1(registry);
  });

  group('RegistryBootstrap.registerPhase1', () {
    test('registers at least 11 entries (7 canonical + aliases)', () {
      expect(registry.registeredTypes.length, greaterThanOrEqualTo(11));
    });

    final canonicalTypes = [
      'KPICard',
      'DataTable',
      'ChartWidget',
      'AlertBanner',
      'ActionButton',
      'FormWidget',
      'MouvementItem',
    ];

    for (final type in canonicalTypes) {
      test('canonical type "$type" is registered', () {
        expect(registry.isRegistered(type), isTrue,
            reason: '$type should be registered by Phase 1');
      });
    }

    final aliasTypes = [
      'ChartBar',
      'FAB',
      'FormSection',
      'TicketPreview',
    ];

    for (final alias in aliasTypes) {
      test('alias "$alias" is registered', () {
        expect(registry.isRegistered(alias), isTrue,
            reason: '$alias alias should be registered');
      });
    }

    test('registeredTypes is sorted alphabetically', () {
      final types = registry.registeredTypes;
      final sorted = [...types]..sort();
      expect(types, equals(sorted));
    });
  });

  group('Phase 1 builders — nominal render', () {
    testWidgets('KPICard renders from valid props', (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'KPICard',
        'props': {'label': 'CA', 'value': '5 000', 'unit': 'FCFA'},
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('CA'), findsOneWidget);
    });

    testWidgets('AlertBanner renders from valid props', (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'AlertBanner',
        'props': {'type': 'info', 'message': 'Synchronisation OK'},
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Synchronisation OK'), findsOneWidget);
    });

    testWidgets('MouvementItem renders from valid props', (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'MouvementItem',
        'props': {'title': 'Vente Riz 5kg', 'subtitle': '14:22'},
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Vente Riz 5kg'), findsOneWidget);
    });

    testWidgets('FormWidget renders from valid props', (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'FormWidget',
        'props': {'title': 'Déclaration perte'},
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('DataTable renders from valid props', (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'DataTable',
        'props': {
          'columns': [
            {'key': 'article', 'label': 'Article'},
            {'key': 'montant', 'label': 'Montant', 'align': 'right'},
          ],
          'rows': [
            {'article': 'Riz 5kg', 'montant': '4 500'},
          ],
        },
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('ChartWidget renders from valid props', (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'ChartWidget',
        'props': {
          'title': 'Ventes 7j',
          'data': [
            {'label': 'Lun', 'value': 32000},
            {'label': 'Mar', 'value': 41500},
          ],
        },
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('ActionButton renders from valid props', (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'ActionButton',
        'props': {'icon_code_point': 57676, 'label': 'Vendre'},
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 1 builders — empty/null props', () {
    testWidgets('KPICard with empty props falls back gracefully', (tester) async {
      const config = ComponentConfig(
        type: 'KPICard',
        props: <String, dynamic>{},
      );

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('AlertBanner with empty props falls back gracefully',
        (tester) async {
      const config = ComponentConfig(
        type: 'AlertBanner',
        props: <String, dynamic>{},
      );

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('Alias builders', () {
    testWidgets('FAB alias resolves same widget as ActionButton', (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'FAB',
        'props': {'icon_code_point': 57676, 'label': 'Ajouter'},
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('FormSection alias resolves same widget as FormWidget',
        (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'FormSection',
        'props': {'title': 'Section test'},
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('ChartBar alias resolves same widget as ChartWidget',
        (tester) async {
      final config = ComponentConfig.fromJson({
        'type': 'ChartBar',
        'props': {
          'title': 'Graphe',
          'data': [
            {'label': 'A', 'value': 10},
          ],
        },
      });

      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) => registry.build(config, ctx)),
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('JSON fixture — retail_dashboard_minimal.json', () {
    test('parses 7 ComponentConfigs without error', () {
      final String raw = File(
        'test/engine/component_registry/fixtures/retail_dashboard_minimal.json',
      ).readAsStringSync();

      final Map<String, dynamic> json =
          (jsonDecode(raw) as Map<dynamic, dynamic>)
              .cast<String, dynamic>();
      final Map<String, dynamic> zones =
          (json['zones'] as Map<dynamic, dynamic>).cast<String, dynamic>();

      final allConfigs = <ComponentConfig>[];
      for (final zone in zones.values) {
        for (final item in zone as List<dynamic>) {
          final Map<String, dynamic> itemMap =
              (item as Map<dynamic, dynamic>).cast<String, dynamic>();
          allConfigs.add(ComponentConfig.fromJson(itemMap));
        }
      }

      expect(allConfigs.length, 8); // 2 KPICards + AlertBanner + ChartWidget + ActionButton + MouvementItem + FormWidget + DataTable

      for (final config in allConfigs) {
        expect(config.type, isNotEmpty);
        expect(registry.isRegistered(config.type), isTrue,
            reason: '${config.type} from fixture should be registered');
      }
    });
  });
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ScalarioTheme.light(),
      darkTheme: ScalarioTheme.dark(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
