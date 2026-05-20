import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/bdui/validation/bdui_type.dart';
import 'package:scalario/core/bdui/validation/bdui_validator.dart';
import 'package:scalario/core/bdui/validation/schema_validator.dart';
import 'package:scalario/core/bdui/validation/validation_result.dart';

/// Resolve path relative to the project root (where catalog/schemas/ lives).
/// Flutter test runner's CWD is apps/flutter/, so we go up 2 levels.
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

Map<String, dynamic> _loadSchema(String name) {
  final path = '${_projectRoot()}/catalog/schemas/$name.schema.json';
  final file = File(path);
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Map<String, dynamic> _loadExample(String category, String name) {
  final path = '${_projectRoot()}/catalog/schemas/examples/$category/$name.json';
  final file = File(path);
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Map<String, dynamic> _validScreenMinimal() => <String, dynamic>{
  'screen': 'dashboard',
  'schema_version': '1.0.0',
  'layout': 'dashboard',
  'zones': <String, dynamic>{
    'main': <Map<String, dynamic>>[
      <String, dynamic>{'type': 'KPICard', 'props': <String, dynamic>{}},
    ],
  },
};

Map<String, dynamic> _missingScreen() => <String, dynamic>{
  'schema_version': '1.0.0',
  'layout': 'dashboard',
  'zones': <String, dynamic>{},
};

Map<String, dynamic> _missingLayout() => <String, dynamic>{
  'screen': 'demo',
  'schema_version': '1.0.0',
  'zones': <String, dynamic>{},
};

Map<String, dynamic> _badSchemaVersion() => <String, dynamic>{
  'screen': 'demo',
  'schema_version': '2.0.0',
  'layout': 'dashboard',
  'zones': <String, dynamic>{},
};

Map<String, dynamic> _unknownLayout() => <String, dynamic>{
  'screen': 'demo',
  'schema_version': '1.0.0',
  'layout': 'carousel',
  'zones': <String, dynamic>{},
};

Map<String, dynamic> _missingZones() => <String, dynamic>{
  'screen': 'demo',
  'schema_version': '1.0.0',
  'layout': 'dashboard',
};

Map<String, dynamic> _extraProperty() => <String, dynamic>{
  'screen': 'demo',
  'schema_version': '1.0.0',
  'layout': 'dashboard',
  'zones': <String, dynamic>{},
  'unexpected_field': true,
};

void main() {
  late SchemaValidator screenSchema;
  late SchemaValidator componentSchema;

  setUp(() {
    screenSchema = SchemaValidator.fromMap(_loadSchema('screen-config'));
    componentSchema = SchemaValidator.fromMap(_loadSchema('component-config'));
  });

  group('BduiValidator — unit', () {
    setUp(() async {
      BduiValidator.reset();
      await BduiValidator.initFromMaps({
        BduiType.screenConfig: _loadSchema('screen-config'),
        BduiType.componentConfig: _loadSchema('component-config'),
        BduiType.moduleConfig: _loadSchema('module-config'),
        BduiType.workflow: _loadSchema('workflow'),
      });
    });

    tearDown(() {
      BduiValidator.reset();
    });

    // AC-04: Singleton pattern
    test('AC-04 — is a singleton, throws if not initialized', () {
      BduiValidator.reset();
      expect(() => BduiValidator.I, throwsA(isA<BduiValidatorNotInitialized>()));
    });

    test('AC-04 — init() creates singleton accessible via I', () async {
      BduiValidator.reset();
      await BduiValidator.initFromMaps({
        BduiType.screenConfig: _loadSchema('screen-config'),
      });
      expect(BduiValidator.I, isA<BduiValidator>());
    });

    // AC-05: validate returns ValidationResult
    test('AC-05 — validate returns Valid for correct screen', () {
      final result = BduiValidator.I.validate(_validScreenMinimal(), BduiType.screenConfig);
      expect(result, isA<Valid>());
    });

    // AC-17: Validate accepts valid_minimal payload
    test('AC-17 — accepts valid minimal screen payload', () {
      final result = BduiValidator.I.validate(_validScreenMinimal(), BduiType.screenConfig);
      expect(result, isA<Valid>());
    });

    // AC-18: Rejects payload with missing "screen"
    test('AC-18 — rejects payload missing "screen"', () {
      final result = BduiValidator.I.validate(_missingScreen(), BduiType.screenConfig);
      expect(result, isA<Invalid>());
      final invalid = result as Invalid;
      expect(invalid.errors.any((e) => e.path.contains('screen')), isTrue);
    });

    test('rejects payload missing "layout"', () {
      final result = BduiValidator.I.validate(_missingLayout(), BduiType.screenConfig);
      expect(result, isA<Invalid>());
    });

    test('rejects wrong schema_version', () {
      final result = BduiValidator.I.validate(_badSchemaVersion(), BduiType.screenConfig);
      expect(result, isA<Invalid>());
    });

    test('rejects unknown layout enum', () {
      final result = BduiValidator.I.validate(_unknownLayout(), BduiType.screenConfig);
      expect(result, isA<Invalid>());
      final invalid = result as Invalid;
      expect(invalid.errors.any((e) => e.keyword == 'enum'), isTrue);
    });

    test('rejects missing zones', () {
      final result = BduiValidator.I.validate(_missingZones(), BduiType.screenConfig);
      expect(result, isA<Invalid>());
    });

    test('rejects unexpected additional properties', () {
      final result = BduiValidator.I.validate(_extraProperty(), BduiType.screenConfig);
      expect(result, isA<Invalid>());
    });

    // ValidationError shape (AC-07)
    test('AC-07 — ValidationError has path, message, keyword', () {
      final result = BduiValidator.I.validate(_missingScreen(), BduiType.screenConfig);
      final invalid = result as Invalid;
      expect(invalid.errors.first.path, isA<String>());
      expect(invalid.errors.first.message, isA<String>());
      expect(invalid.errors.first.keyword, isA<String>());
    });

    // Large payload rejection: 1 MB limit is checked at serialization boundary
  });

  group('SchemaValidator — unit', () {
    // AC-17: valid_minimal.json (from catalog examples)
    test('AC-17 — valid_minimal component config passes', () {
      final example = _loadExample('component-config', 'valid_minimal');
      final result = componentSchema.validate(example);
      expect(result, isA<Valid>());
    });

    test('valid_complete component config passes', () {
      final example = _loadExample('component-config', 'valid_complete');
      final result = componentSchema.validate(example);
      expect(result, isA<Valid>());
    });

    test('valid_dashboard screen config passes', () {
      final example = _loadExample('screen-config', 'valid_dashboard');
      final result = screenSchema.validate(example);
      expect(result, isA<Valid>());
    });

    test('valid_form screen config passes', () {
      final example = _loadExample('screen-config', 'valid_form');
      final result = screenSchema.validate(example);
      expect(result, isA<Valid>());
    });

    // Invalid examples
    test('invalid_unknown_layout is rejected', () {
      final example = _loadExample('screen-config', 'invalid_unknown_layout');
      final result = screenSchema.validate(example);
      expect(result, isA<Invalid>());
    });

    test('invalid_missing_type component is rejected', () {
      BduiValidator.reset();
      final example = _loadExample('component-config', 'invalid_missing_type');
      final result = componentSchema.validate(example);
      expect(result, isA<Invalid>());
    });
  });

  // AC-21: Cross-validator coherence test
  group('AC-21 — Cross-validator coherence (Zod NestJS ↔ Flutter)', () {
    setUp(() async {
      BduiValidator.reset();
      await BduiValidator.initFromMaps({
        BduiType.screenConfig: _loadSchema('screen-config'),
        BduiType.componentConfig: _loadSchema('component-config'),
        BduiType.moduleConfig: _loadSchema('module-config'),
        BduiType.workflow: _loadSchema('workflow'),
      });
    });

    tearDown(() {
      BduiValidator.reset();
    });

    for (final entry in {
      'screen-config/valid_dashboard': BduiType.screenConfig,
      'screen-config/valid_form': BduiType.screenConfig,
      'component-config/valid_minimal': BduiType.componentConfig,
      'component-config/valid_complete': BduiType.componentConfig,
      'component-config/valid_with_rule': BduiType.componentConfig,
      'module-config/valid_minimal': BduiType.moduleConfig,
      'module-config/valid_complete': BduiType.moduleConfig,
      'workflow/valid_simple': BduiType.workflow,
      'workflow/valid_complete': BduiType.workflow,
    }.entries) {
      test('validates ${entry.key}', () {
        final parts = entry.key.split('/');
        final example = _loadExample(parts[0], parts[1]);
        final result = BduiValidator.I.validate(example, entry.value);
        expect(result, isA<Valid>(), reason: '${entry.key} should be valid');
      });
    }

    for (final entry in {
      'screen-config/invalid_unknown_layout': BduiType.screenConfig,
      'component-config/invalid_missing_type': BduiType.componentConfig,
      'module-config/invalid_bad_id_pattern': BduiType.moduleConfig,
      'workflow/invalid_no_wf_prefix': BduiType.workflow,
    }.entries) {
      test('rejects ${entry.key}', () {
        final parts = entry.key.split('/');
        final example = _loadExample(parts[0], parts[1]);
        final result = BduiValidator.I.validate(example, entry.value);
        expect(result, isA<Invalid>(), reason: '${entry.key} should be invalid');
      });
    }
  });
}
