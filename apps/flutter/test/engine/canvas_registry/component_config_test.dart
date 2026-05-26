import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_registry/component_config.dart';
import 'package:scalario/engine/canvas_registry/scalario_canvas_resolver.dart';

String _projectRoot() {
  final dir = Directory.current.path;
  if (dir.endsWith('apps/flutter')) {
    return '$dir/../..';
  }
  if (dir.endsWith('scalario')) {
    return dir;
  }
  return '$dir/../../..';
}

Map<String, dynamic> _loadExample(String name) {
  final path =
      '${_projectRoot()}/catalog/schemas/examples/component-config/$name.json';
  final file = File(path);
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('ComponentConfig.fromJson — v1.1.0 parsing', () {
    test('parses valid_with_variant_default', () {
      final json = _loadExample('valid_with_variant_default');
      final config = ComponentConfig.fromJson(json);

      expect(config.type, 'KPICard');
      expect(config.variant, 'default');
      expect(config.props['label'], 'CA du jour');
    });

    test('parses valid_with_variant_auto', () {
      final json = _loadExample('valid_with_variant_auto');
      final config = ComponentConfig.fromJson(json);

      expect(config.type, 'KPICard');
      expect(config.variant, 'auto');
      expect(config.id, 'ca-du-jour');
    });

    test('parses valid_with_actions (pipeline 2 steps)', () {
      final json = _loadExample('valid_with_actions');
      final config = ComponentConfig.fromJson(json);

      expect(config.type, 'Button');
      expect(config.variant, 'default');
      expect(config.actions, isNotNull);
      expect(config.actions!.length, 2);
      expect(config.actions![0]['registry'], 'vault');
      expect(config.actions![0]['fn'], 'save_entity');
      expect(config.actions![0]['output'], 'saved_vente');
      expect(config.actions![1]['registry'], 'canvas');
      expect(config.actions![1]['fn'], 'navigate');
    });

    test('parses valid_with_children_nested (recursive composition)', () {
      final json = _loadExample('valid_with_children_nested');
      final config = ComponentConfig.fromJson(json);

      expect(config.type, 'Section');
      expect(config.variant, 'default');
      expect(config.children, isNotNull);
      expect(config.children!.length, 2);

      final row = config.children![0];
      expect(row.type, 'Row');
      expect(row.children, isNotNull);
      expect(row.children!.length, 2);
      expect(row.children![0].type, 'KPICard');
      expect(row.children![0].variant, 'compact');

      final table = config.children![1];
      expect(table.type, 'DataTable');
    });

    test('parses valid_minimal v1.0.0 backward compat (variant defaults)', () {
      final json = _loadExample('valid_minimal');
      final config = ComponentConfig.fromJson(json);

      expect(config.type, 'KPICard');
      expect(config.variant, 'default');
      expect(config.props, isEmpty);
    });

    test('parses valid_complete v1.0.0 backward compat', () {
      final json = _loadExample('valid_complete');
      final config = ComponentConfig.fromJson(json);

      expect(config.type, 'DataTable');
      expect(config.variant, 'default');
      expect(config.id, 'products-table');
      expect(config.visibleIf, isNotNull);
      expect(config.source, isNotNull);
      expect(config.validation, isNotNull);
      expect(config.i18nKey, 'components.products_table');
    });

    test('rejects invalid variant — still parses as number coerced to null variant', () {
      // Dart is permissive — variant: 123 becomes null → defaults to 'default'
      final json = _loadExample('invalid_variant_number');
      final config = ComponentConfig.fromJson(json);

      // variant coercion: 123 as String? → null → default
      expect(config.variant, 'default');
    });

    test('toJson round-trip preserves all v1.1.0 fields', () {
      final json = _loadExample('valid_with_actions');
      final config = ComponentConfig.fromJson(json);
      final out = config.toJson();

      expect(out['type'], 'Button');
      expect(out['actions'], isNotNull);
      expect((out['actions'] as List).length, 2);
    });

    test('toJson omits variant when default', () {
      final config = ComponentConfig(type: 'Button', variant: 'default');
      final out = config.toJson();

      expect(out['variant'], isNull);
    });
  });

  group('ComponentConfig.copyWith', () {
    test('copyWith updates variant', () {
      final config = ComponentConfig(type: 'KPICard', variant: 'default');
      final updated = config.copyWith(variant: 'compact');

      expect(updated.variant, 'compact');
      expect(updated.type, 'KPICard');
    });

    test('copyWith adds actions', () {
      final config = ComponentConfig(type: 'Button');
      final actions = [
        <String, dynamic>{'registry': 'canvas', 'fn': 'navigate'},
      ];
      final updated = config.copyWith(actions: actions);

      expect(updated.actions, equals(actions));
      expect(updated.type, 'Button');
    });
  });

  group('ScalarioCanvasResolver.resolveVariant', () {
    test('returns variant as-is when not auto', () {
      expect(ScalarioCanvasResolver.resolveVariant('compact'), 'compact');
      expect(ScalarioCanvasResolver.resolveVariant('hero'), 'hero');
      expect(ScalarioCanvasResolver.resolveVariant('default'), 'default');
    });

    test('auto without screenWidth → default (default size 800 > 600)', () {
      expect(ScalarioCanvasResolver.resolveVariant('auto'), 'default');
    });

    test('auto on small screen → compact', () {
      expect(
        ScalarioCanvasResolver.resolveVariant('auto', screenWidth: 320),
        'compact',
      );
      expect(
        ScalarioCanvasResolver.resolveVariant('auto', screenWidth: 400),
        'compact',
      );
    });

    test('auto on large screen → default', () {
      expect(
        ScalarioCanvasResolver.resolveVariant('auto', screenWidth: 1024),
        'default',
      );
      expect(
        ScalarioCanvasResolver.resolveVariant('auto', screenWidth: 1200),
        'default',
      );
    });

    test('auto with per-component hook — KPICard compact < 600', () {
      ScalarioCanvasResolver.registerHook('KPICard', (ctx) {
        if (ctx.screenWidth < 600) return 'compact';
        if (ctx.screenWidth >= 900) return 'hero';
        return 'default';
      });

      expect(
        ScalarioCanvasResolver.resolveVariant('auto', component: 'KPICard', screenWidth: 360),
        'compact',
      );
      expect(
        ScalarioCanvasResolver.resolveVariant('auto', component: 'KPICard', screenWidth: 1024),
        'hero',
      );

      ScalarioCanvasResolver.unregisterHook('KPICard');
    });

    test('auto on normal screen → default', () {
      expect(
        ScalarioCanvasResolver.resolveVariant('auto', screenWidth: 500),
        'compact',
      );
    });
  });

  group('ComponentConfig equality', () {
    test('two configs with same type+variant+id are equal', () {
      final a = ComponentConfig(type: 'KPICard', variant: 'compact', id: 'k1');
      final b = ComponentConfig(type: 'KPICard', variant: 'compact', id: 'k1');
      expect(a, equals(b));
    });

    test('two configs with different variant are not equal', () {
      final a = ComponentConfig(type: 'KPICard', variant: 'default');
      final b = ComponentConfig(type: 'KPICard', variant: 'compact');
      expect(a, isNot(equals(b)));
    });
  });
}
