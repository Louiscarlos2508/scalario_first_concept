import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'bdui_type.dart';
import 'schema_validator.dart';
import 'validation_result.dart';

class BduiValidatorNotInitialized implements Exception {
  @override
  String toString() =>
      'BduiValidatorNotInitialized: Call BduiValidator.init() in main() before use.';
}

class BduiValidator {
  BduiValidator._();

  static BduiValidator? _instance;

  static BduiValidator get I {
    if (_instance == null) throw BduiValidatorNotInitialized();
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  static const int _maxPayloadBytes = 1 * 1024 * 1024;

  @visibleForTesting
  static void reset({BduiValidator? replacement}) {
    _instance = replacement;
  }

  final Map<BduiType, SchemaValidator> _schemas = {};

  static final Map<BduiType, String> _schemaPaths = {
    BduiType.componentConfig: 'assets/bdui-schemas/component-config.schema.json',
    BduiType.screenConfig: 'assets/bdui-schemas/screen-config.schema.json',
    BduiType.moduleConfig: 'assets/bdui-schemas/module-config.schema.json',
    BduiType.workflow: 'assets/bdui-schemas/workflow.schema.json',
  };

  static Future<void> init() async {
    final validator = BduiValidator._();
    for (final entry in _schemaPaths.entries) {
      final type = entry.key;
      final path = entry.value;
      try {
        validator._schemas[type] = await SchemaValidator.load(path);
      } catch (e) {
        developer.log(
          'Failed to load schema $path: $e',
          name: 'BduiValidator',
          level: 1000,
        );
        rethrow;
      }
    }
    _instance = validator;
  }

  static Future<void> initFromMaps(Map<BduiType, Map<String, dynamic>> schemaMaps) async {
    final validator = BduiValidator._();
    for (final entry in schemaMaps.entries) {
      validator._schemas[entry.key] = SchemaValidator.fromMap(entry.value);
    }
    _instance = validator;
  }

  ValidationResult validate(Object? json, BduiType type) {
    final schema = _schemas[type];
    if (schema == null) {
      return Invalid([
        ValidationError(
          path: '',
          message: 'Type de schéma inconnu : $type',
          keyword: 'internal',
        ),
      ]);
    }

    if (json is String) {
      try {
        final size = utf8.encode(json).length;
        if (size > _maxPayloadBytes) {
          return const Invalid([]);
        }
      } catch (_) {}
    }

    return schema.validate(json);
  }
}
