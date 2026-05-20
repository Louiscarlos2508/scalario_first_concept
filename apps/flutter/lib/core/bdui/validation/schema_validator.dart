import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'validation_result.dart';

class SchemaValidator {
  final Map<String, dynamic> _schemaMap;

  SchemaValidator._(this._schemaMap);

  static const int _maxPayloadBytes = 1 * 1024 * 1024;

  static Future<SchemaValidator> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final schema = jsonDecode(raw) as Map<String, dynamic>;
    return SchemaValidator._(schema);
  }

  static SchemaValidator fromMap(Map<String, dynamic> schema) {
    return SchemaValidator._(schema);
  }

  ValidationResult validate(Object? instance) {
    final errors = <ValidationError>[];
    _validateSchema(instance, _schemaMap, '', errors);
    if (errors.isEmpty) return const Valid();
    return Invalid(errors);
  }

  void _validateSchema(
    Object? instance,
    Map<String, dynamic> schema,
    String path,
    List<ValidationError> errors,
  ) {
    if (instance is String && instance.length > _maxPayloadBytes) {
      errors.add(ValidationError(
        path: path,
        message: 'Payload trop volumineux (max ${_maxPayloadBytes ~/ 1024} KB)',
        keyword: 'maxLength',
      ));
      return;
    }

    final schemaType = schema['type'] as String?;
    if (schemaType != null) {
      _validateType(instance, schemaType, path, schema, errors);
    }

    final schemaConst = schema['const'];
    if (schemaConst != null) {
      if (instance != schemaConst) {
        errors.add(ValidationError(
          path: path,
          message: 'Doit être égal à "$schemaConst"',
          keyword: 'const',
        ));
      }
    }

    final schemaEnum = schema['enum'] as List<dynamic>?;
    if (schemaEnum != null && instance != null) {
      if (!schemaEnum.any((e) => e == instance)) {
        errors.add(ValidationError(
          path: path,
          message: 'Doit être l\'une des valeurs : ${schemaEnum.join(", ")}',
          keyword: 'enum',
        ));
      }
    }

    final minLength = schema['minLength'] as int?;
    if (minLength != null && instance is String && instance.length < minLength) {
      errors.add(ValidationError(
        path: path,
        message: 'Longueur minimale : $minLength caractères',
        keyword: 'minLength',
      ));
    }

    final pattern = schema['pattern'] as String?;
    if (pattern != null && instance is String) {
      final regex = RegExp(pattern);
      if (!regex.hasMatch(instance)) {
        errors.add(ValidationError(
          path: path,
          message: 'Ne correspond pas au format attendu',
          keyword: 'pattern',
        ));
      }
    }

    if (instance is Map<String, dynamic>) {
      final required = schema['required'] as List<dynamic>?;
      if (required != null) {
        for (final field in required) {
          final fieldName = field as String;
          if (!instance.containsKey(fieldName)) {
            errors.add(ValidationError(
              path: '$path${path.isEmpty ? "" : "."}$fieldName',
              message: 'Champ obligatoire manquant : "$fieldName"',
              keyword: 'required',
            ));
          }
        }
      }

      final properties = schema['properties'] as Map<String, dynamic>?;
      if (properties != null) {
        for (final entry in properties.entries) {
          final propName = entry.key;
          final propSchema = entry.value as Map<String, dynamic>;
          final propPath = path.isEmpty ? propName : '$path.$propName';
          if (instance.containsKey(propName)) {
            _validateSchema(instance[propName], propSchema, propPath, errors);
          }
        }
      }

      final additionalProps = schema['additionalProperties'];
      if (additionalProps == false) {
        final allowedProps = <String>{
          if (properties != null) ...properties.keys,
          if (required != null) ...required.cast<String>(),
        };
        for (final key in instance.keys) {
          if (!allowedProps.contains(key)) {
            errors.add(ValidationError(
              path: '$path${path.isEmpty ? "" : "."}$key',
              message: 'Propriété inattendue : "$key"',
              keyword: 'additionalProperties',
            ));
          }
        }
      }
    }

    if (instance is List) {
      final itemsSchema = schema['items'] as Map<String, dynamic>?;
      if (itemsSchema != null) {
        if (itemsSchema.containsKey('\$ref')) {
          return;
        }
        for (var i = 0; i < instance.length; i++) {
          _validateSchema(instance[i], itemsSchema, '$path[$i]', errors);
        }
      }
    }

    final oneOf = schema['oneOf'] as List<dynamic>?;
    if (oneOf != null) {
      int matchCount = 0;
      for (final subSchema in oneOf) {
        final subErrors = <ValidationError>[];
        _validateSchema(instance, subSchema as Map<String, dynamic>, path, subErrors);
        if (subErrors.isEmpty) matchCount++;
      }
      if (matchCount != 1) {
        errors.add(ValidationError(
          path: path,
          message: 'Doit correspondre à exactement une variante',
          keyword: 'oneOf',
        ));
      }
    }

    final defaultVal = schema['default'];
    if (defaultVal != null && instance == null) {
      return;
    }
  }

  void _validateType(
    Object? instance,
    String expectedType,
    String path,
    Map<String, dynamic> schema,
    List<ValidationError> errors,
  ) {
    final typeCheck = _typeChecker(expectedType);
    if (!typeCheck(instance)) {
      final typeName = instance.runtimeType.toString();
      errors.add(ValidationError(
        path: path,
        message: 'Type attendu : $expectedType, reçu : $typeName',
        keyword: 'type',
      ));
    }
  }

  bool Function(Object?) _typeChecker(String type) {
    switch (type) {
      case 'string':
        return (o) => o is String;
      case 'number':
        return (o) => o is num;
      case 'integer':
        return (o) => o is int;
      case 'boolean':
        return (o) => o is bool;
      case 'object':
        return (o) => o is Map<String, dynamic>;
      case 'array':
        return (o) => o is List;
      case 'null':
        return (o) => o == null;
      default:
        return (_) => true;
    }
  }
}
