import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_registry/component_config.dart';
import 'package:scalario/engine/canvas_registry/component_schema.dart';
import 'package:scalario/engine/canvas_registry/component_schemas.dart';
import 'package:scalario/engine/canvas_registry/registry_bootstrap.dart';
import 'package:scalario/engine/canvas_registry/scalario_canvas_registry.dart';

String _projectRoot() {
  final dir = Directory.current.path;
  if (dir.endsWith('apps/flutter')) return dir;
  if (dir.endsWith('scalario')) return '$dir/apps/flutter';
  return '$dir/apps/flutter';
}

/// Parse un fichier sandbox et extrait tous les ComponentConfig.
/// Gère les formats Scalario et A2UI.
List<ComponentConfig> _extractComponents(String path) {
  final raw = jsonDecode(File(path).readAsStringSync());

  // Format A2UI : liste de messages
  if (raw is List) {
    final components = <ComponentConfig>[];
    for (final msg in raw) {
      if (msg is Map && msg['updateComponents'] is Map) {
        final updateComponents = msg['updateComponents'] as Map;
        final list = updateComponents['components'] as List? ?? [];
        for (final c in list) {
          if (c is Map) {
            components.add(_toComponentConfig(c as Map<String, dynamic>));
          }
        }
      }
    }
    return components;
  }

  // Format Scalario : ScreenConfig avec zones
  if (raw is Map) {
    final zones = raw['zones'] as Map? ?? {};
    final components = <ComponentConfig>[];
    for (final zoneName in ['kpis', 'main', 'aside', 'actions']) {
      final zone = zones[zoneName] as List?;
      if (zone == null) continue;
      for (final c in zone) {
        if (c is Map) {
          components.add(_toComponentConfig(c as Map<String, dynamic>));
        }
      }
    }
    return components;
  }

  return [];
}

ComponentConfig _toComponentConfig(Map<String, dynamic> json) {
  // Les fichiers A2UI utilisent 'component' au lieu de 'type'
  if (json['type'] == null && json['component'] != null) {
    json = Map<String, dynamic>.from(json);
    json['type'] = json['component'] as String;
  }
  return ComponentConfig.fromJson(json);
}

void main() {
  late ScalarioCanvasRegistry registry;

  setUp(() {
    registry = ScalarioCanvasRegistry();
    // Enregistrer tous les builders avec leurs schémas
    for (final schema in ComponentSchemas.all.values) {
      registry.register(schema.type, (c, ctx) => const SizedBox(width: 0, height: 0), schema: schema);
    }
    // Alias A2UI → Scalario
    RegistryBootstrap.registerAliases(registry);
    // Scalario aliases (same widget, different name)
    registry.registerAlias('ChartWidget', 'ChartBar');
    registry.registerAlias('Button', 'Button');
    registry.registerAlias('ActionButton', 'FAB');
    registry.registerAlias('FormWidget', 'FormSection');
    registry.registerAlias('TextInput', 'Input');
    registry.registerAlias('NumberInput', 'Input');
    registry.registerAlias('Select', 'Dropdown');
    registry.registerAlias('Switch', 'Toggle');
    registry.registerAlias('MouvementItem', 'ListTile');
    registry.registerAlias('TicketPreview', 'ListTile');
  });

  group('SchemaValidation — sandbox files', () {
    final sandboxDir = '${_projectRoot()}/assets/sandbox';
    print('Sandbox dir: $sandboxDir');

    test('retail_dashboard.json validates without errors', () {
      final components = _extractComponents('$sandboxDir/retail_dashboard.json');
      expect(components, isNotEmpty);

      for (final c in components) {
        final errors = registry.validate(c);
        expect(errors, isEmpty, reason: '${c.type}#${c.id}: ${errors.map((e) => e.message).join('; ')}');
      }
    });

    test('simple_form.json validates without errors', () {
      final components = _extractComponents('$sandboxDir/simple_form.json');
      expect(components, isNotEmpty);

      for (final c in components) {
        final errors = registry.validate(c);
        expect(errors, isEmpty, reason: '${c.type}#${c.id}: ${errors.map((e) => e.message).join('; ')}');
      }
    });

    test('empty_screen.json validates without errors', () {
      final components = _extractComponents('$sandboxDir/empty_screen.json');
      // Peut être vide — ce n'est pas une erreur
      for (final c in components) {
        final errors = registry.validate(c);
        expect(errors, isEmpty, reason: '${c.type}#${c.id}: ${errors.map((e) => e.message).join('; ')}');
      }
    });
  });

  group('SchemaValidation — unit', () {
    test('valid config with required props passes', () {
      final schema = ComponentSchemas.alertBanner;
      final config = ComponentConfig(
        type: 'AlertBanner',
        props: {
          'type': 'success',
          'message': 'Operation completed',
        },
      );

      final errors = registry.validate(config, mode: SchemaValidationMode.strict);
      expect(errors, isEmpty);
    });

    test('missing required prop returns error', () {
      final config = ComponentConfig(
        type: 'AlertBanner',
        props: {'type': 'success'}, // message is required
      );

      final errors = registry.validate(config);
      expect(errors, hasLength(1));
      expect(errors[0].field, 'message');
      expect(errors[0].message, contains('Required'));
    });

    test('disallowed value returns error', () {
      final config = ComponentConfig(
        type: 'AlertBanner',
        props: {
          'type': 'invalid_type',
          'message': 'test',
        },
      );

      final errors = registry.validate(config);
      expect(errors, hasLength(1));
      expect(errors[0].message, contains('not allowed'));
    });

    test('strict mode throws exception', () {
      final config = ComponentConfig(
        type: 'AlertBanner',
        props: {},
      );

      expect(
        () => registry.validate(config, mode: SchemaValidationMode.strict),
        throwsA(isA<SchemaValidationException>()),
      );
    });

    test('lenient mode returns errors without throwing', () {
      final config = ComponentConfig(
        type: 'AlertBanner',
        props: {},
      );

      final errors = registry.validate(config, mode: SchemaValidationMode.lenient);
      expect(errors, hasLength(2)); // type + message required
    });

    test('gauge validates numeric props', () {
      final config = ComponentConfig(
        type: 'Gauge',
        props: {
          'value': 75,
          'label': 'Completion',
          'min': 0,
          'max': 100,
        },
      );

      final errors = registry.validate(config);
      expect(errors, isEmpty);
    });

    test('gauge with missing value returns error', () {
      final config = ComponentConfig(
        type: 'Gauge',
        props: {'label': 'Completion'},
      );

      final errors = registry.validate(config);
      expect(errors, hasLength(1));
      expect(errors[0].field, 'value');
    });

    test('unknown type returns no errors (no schema)', () {
      final config = ComponentConfig(type: 'UnknownType', props: {});

      final errors = registry.validate(config);
      expect(errors, isEmpty);
    });
  });

  group('SchemaValidation — children bounds', () {
    test('kpi card with no children passes (maxChildren: 0)', () {
      final config = ComponentConfig(type: 'KPICard', props: {'value': '100'});

      final errors = registry.validate(config);
      expect(errors, isEmpty);
    });

    test('kpi card with children fails (maxChildren: 0)', () {
      final config = ComponentConfig(
        type: 'KPICard',
        props: {'value': '100'},
        children: [ComponentConfig(type: 'Text', props: {'text': 'child'})],
      );

      final errors = registry.validate(config);
      expect(errors, isNotEmpty);
    });
  });

  group('SchemaValidation — records errors on registry', () {
    test('recordValidationErrors stores and retrieves errors', () {
      registry.recordValidationErrors('screen1', [
        const SchemaValidationError(
          componentId: 'c1',
          type: 'Button',
          field: 'label',
          message: 'Required property "label" is missing',
        ),
      ]);

      final errors = registry.lastValidationErrors('screen1');
      expect(errors, hasLength(1));
      expect(errors[0].field, 'label');

      expect(registry.screensWithErrors, contains('screen1'));
    });

    test('screensWithErrors excludes screens without errors', () {
      registry.recordValidationErrors('clean_screen', []);
      expect(registry.screensWithErrors, isEmpty);
    });
  });

  group('A2UICompatibility — alias resolution', () {
    test('Scalario aliases resolve to correct schemas', () {
      // Les alias (ChartWidget, Button, etc.) pointent vers les bons builders
      expect(registry.isRegistered('ChartWidget'), isTrue);
      expect(registry.isRegistered('Button'), isTrue);
      expect(registry.isRegistered('FAB'), isTrue);
      expect(registry.isRegistered('FormWidget'), isTrue);
      expect(registry.isRegistered('TextInput'), isTrue);
      expect(registry.isRegistered('NumberInput'), isTrue);
      expect(registry.isRegistered('Select'), isTrue);
      expect(registry.isRegistered('Switch'), isTrue);
      expect(registry.isRegistered('MouvementItem'), isTrue);
      expect(registry.isRegistered('TicketPreview'), isTrue);
    });

    test('A2UI versioned aliases resolve via registry', () {
      // Vérifier que les alias A2UI du bootstrap sont enregistrés
      expect(registry.isRegistered('a2ui:heading_v0.8'), isTrue);
      expect(registry.isRegistered('a2ui:text_v1.0'), isTrue);
      expect(registry.isRegistered('a2ui:scaffold_v0.9'), isTrue);
    });
  });
}
