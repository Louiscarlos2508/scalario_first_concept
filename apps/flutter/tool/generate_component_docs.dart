// dart run tool/generate_component_docs.dart
//
// Générateur de documentation des schémas de composants BDUI.
// Lit les définitions depuis component_schemas.dart et produit :
//   1. docs/component_schemas.md  — documentation lisible
//   2. docs/component_schemas.json — JSON Schema pour IDE autocompletion

import 'dart:convert';
import 'dart:io';

class _Prop {
  final String name;
  final String type;
  final String required;
  final String description;
  _Prop({
    required this.name,
    required this.type,
    required this.required,
    this.description = '',
  });
}

class _Schema {
  final String type;
  final List<_Prop> props;
  final String description;
  _Schema({required this.type, required this.props, this.description = ''});
}

void main() {
  final basePath = Directory.current.path;
  final docsDir = Directory('$basePath/docs');
  if (!docsDir.existsSync()) docsDir.createSync();

  final schemasFile = File('$basePath/lib/engine/canvas_registry/component_schemas.dart');
  if (!schemasFile.existsSync()) {
    stderr.writeln('ERROR: component_schemas.dart not found at $basePath');
    exit(1);
  }

  final content = schemasFile.readAsStringSync();
  final schemas = _extractSchemas(content);
  _generateDocs(schemas, basePath);
}

List<_Schema> _extractSchemas(String content) {
  final schemas = <_Schema>[];
  final typeRegex = RegExp(r"type:\s*'([^']+)'");
  final propRegex = RegExp(
    r"PropDefinition\(\s*name:\s*'([^']+)'\s*,\s*type:\s*PropType\.(\w+)",
  );
  final descRegex = RegExp(r"description:\s*'([^']*)'");

  String currentType = '';
  final currentProps = <_Prop>[];
  String currentDescription = '';
  var inSchema = false;
  var braceDepth = 0;

  for (final line in content.split('\n')) {
    final trimmed = line.trim();

    if (!inSchema && trimmed.contains('ComponentSchema(')) {
      currentType = '';
      currentProps.clear();
      currentDescription = '';
      inSchema = true;
      braceDepth = 1 + '('.allMatches(trimmed.split('ComponentSchema(')[1]).length;
      continue;
    }

    if (!inSchema) continue;

    braceDepth += '('.allMatches(trimmed).length;
    braceDepth -= ')'.allMatches(trimmed).length;

    if (currentType.isEmpty) {
      final typeMatch = typeRegex.firstMatch(trimmed);
      if (typeMatch != null) {
        currentType = typeMatch.group(1)!;
      }
    }

    if (trimmed.startsWith('PropDefinition(')) {
      final match = propRegex.firstMatch(trimmed);
      if (match != null) {
        final isRequired = trimmed.contains('required: true') || trimmed.contains('required:true');
        final descMatch = descRegex.firstMatch(trimmed);
        currentProps.add(_Prop(
          name: match.group(1)!,
          type: match.group(2)!,
          required: isRequired ? 'yes' : 'no',
          description: descMatch?.group(1) ?? '',
        ));
      }
    }

    if (currentDescription.isEmpty && trimmed.startsWith('description:')) {
      final descMatch = descRegex.firstMatch(trimmed);
      if (descMatch != null) {
        currentDescription = descMatch.group(1)!;
      }
    }

    if (braceDepth <= 0 && currentType.isNotEmpty) {
      schemas.add(_Schema(
        type: currentType,
        props: List.from(currentProps),
        description: currentDescription,
      ));
      inSchema = false;
    }
  }

  return schemas;
}

void _generateDocs(List<_Schema> schemas, String basePath) {
  // --- Markdown ---
  final md = StringBuffer();
  md.writeln('# Schémas de Composants BDUI Scalario');
  md.writeln();
  md.writeln('Généré depuis `lib/engine/canvas_registry/component_schemas.dart`.');
  md.writeln();
  md.writeln('## Types de Propriétés');
  md.writeln();
  md.writeln('| Type | Description |');
  md.writeln('|------|-------------|');
  md.writeln('| `string` | Texte |');
  md.writeln('| `number` | Valeur numérique |');
  md.writeln('| `bool` | Booléen |');
  md.writeln('| `list` | Liste/tableau |');
  md.writeln('| `object` | Map/objet JSON |');
  md.writeln('| `path` | Chemin de source de données (ex: `_data.user.name`) |');
  md.writeln('| `action` | Action BDUI (navigation, etc.) |');
  md.writeln('| `dynamic` | Type indéterministe |');
  md.writeln();

  for (final s in schemas) {
    md.writeln('## ${s.type}');
    md.writeln();
    if (s.description.isNotEmpty) {
      md.writeln('${s.description}.');
      md.writeln();
    }
    if (s.props.isEmpty) {
      md.writeln('_Aucune propriété._');
      md.writeln();
    } else {
      md.writeln('| Propriété | Type | Requis | Description |');
      md.writeln('|-----------|------|--------|-------------|');
      for (final p in s.props) {
        md.writeln('| `${p.name}` | `${p.type}` | ${p.required} | ${p.description} |');
      }
      md.writeln();
    }
  }

  md.writeln('---');
  md.writeln('Généré automatiquement par `tool/generate_component_docs.dart`.');

  final mdPath = '$basePath/docs/component_schemas.md';
  File(mdPath).writeAsStringSync(md.toString());
  print('Documentation générée: $mdPath');

  // --- JSON Schema ---
  final properties = <String, dynamic>{};
  for (final s in schemas) {
    final jsonProps = <String, dynamic>{};
    for (final p in s.props) {
      final entry = <String, dynamic>{
        'type': _jsonSchemaType(p.type),
        'description': p.description,
      };
      if (p.required == 'yes') {
        entry['optional'] = false;
      }
      jsonProps[p.name] = entry;
    }
    properties[s.type] = <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'type': <String, dynamic>{'const': s.type},
        'props': <String, dynamic>{
          'type': 'object',
          'properties': jsonProps,
        },
        'id': <String, dynamic>{'type': 'string'},
        'variant': <String, dynamic>{'type': 'string'},
        'children': <String, dynamic>{
          'type': 'array',
          'items': <String, dynamic>{'type': 'object'},
        },
      },
      'required': <String>['type'],
    };
  }

  final jsonSchema = {
    '\$schema': 'https://json-schema.org/draft/2020-12/schema',
    'title': 'Scalario BDUI Component Schema',
    'description': 'Schémas de validation des composants BDUI Scalario',
    'oneOf': [
      {'type': 'object', 'properties': properties},
    ],
  };

  final jsonPath = '$basePath/docs/component_schemas.json';
  File(jsonPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(jsonSchema),
  );
  print('JSON Schema généré: $jsonPath');
  print('${schemas.length} schémas extraits.');
}

String _jsonSchemaType(String propType) {
  switch (propType) {
    case 'string':
    case 'path':
    case 'action':
      return 'string';
    case 'number':
      return 'number';
    case 'bool':
      return 'boolean';
    case 'list':
      return 'array';
    case 'object':
    case 'dynamic':
      return 'object';
    default:
      return 'string';
  }
}
