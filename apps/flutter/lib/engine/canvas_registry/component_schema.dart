/// Stratégie de validation des schémas de composants
enum SchemaValidationMode {
  /// Lance une exception au premier échec — utilisé en dev/qualif
  strict,

  /// Log les erreurs mais continue le rendu — utilisé en production
  lenient,
}

/// Types supportés pour les props d'un composant BDUI
enum PropType {
  string,
  number,
  bool,
  list,
  object,
  path,
  action,
  dynamic,
}

/// Définition d'une propriété d'un composant BDUI
class PropDefinition {
  final String name;
  final PropType type;
  final bool required;
  final dynamic defaultValue;
  final String? description;
  final List<dynamic>? allowedValues;

  const PropDefinition({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.description,
    this.allowedValues,
  });
}

/// Schéma déclaratif d'un composant BDUI
class ComponentSchema {
  final String type;
  final List<PropDefinition> props;
  final int? minChildren;
  final int? maxChildren;
  final String? description;

  const ComponentSchema({
    required this.type,
    required this.props,
    this.minChildren,
    this.maxChildren,
    this.description,
  });

  List<String> get requiredProps =>
      props.where((p) => p.required).map((p) => p.name).toList();

  PropDefinition? prop(String name) {
    for (final p in props) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// Erreur de validation d'un composant
class SchemaValidationError {
  final String componentId;
  final String type;
  final String? field;
  final String message;

  const SchemaValidationError({
    required this.componentId,
    required this.type,
    this.field,
    required this.message,
  });

  @override
  String toString() =>
      '[Validation] <$type#${componentId.isNotEmpty ? componentId : '?'}> '
      '${field != null ? '$field: ' : ''}$message';

  Map<String, dynamic> toJson() => {
    'componentId': componentId,
    'type': type,
    if (field != null) 'field': field,
    'message': message,
  };
}
