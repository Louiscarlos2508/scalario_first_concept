/// Modèle d'un composant A2UI v0.9 — flat list, ID-based.
///
/// ```json
/// {
///   "id": "ca_jour",
///   "component": "KPICard",
///   "variant": "compact",
///   "text": "CA Jour",
///   "value": { "path": "/kpi/ca" },
///   "children": ["child1", "child2"]
/// }
/// ```
class A2UIComponent {
  const A2UIComponent({
    required this.id,
    required this.component,
    this.variant,
    this.text,
    this.value,
    this.children,
    this.action,
    this.props = const {},
  });

  factory A2UIComponent.fromJson(Map<String, dynamic> json) {
    return A2UIComponent(
      id: json['id'] as String,
      component: json['component'] as String,
      variant: json['variant'] as String?,
      text: json['text'] as String?,
      value: json['value'],
      children: json['children'] != null
          ? (json['children'] as List<dynamic>).cast<String>()
          : null,
      action: json['action'] != null
          ? Map<String, dynamic>.from(json['action'] as Map)
          : null,
      props: json,
    );
  }

  final String id;
  final String component;
  final String? variant;
  final String? text;
  final dynamic value;
  final List<String>? children;
  final Map<String, dynamic>? action;
  final Map<String, dynamic> props;

  Map<String, dynamic> toJson() => {
        'id': id,
        'component': component,
        if (variant != null) 'variant': variant,
        if (text != null) 'text': text,
        if (value != null) 'value': value,
        if (children != null) 'children': children,
        if (action != null) 'action': action,
      };
}

/// Data model A2UI — stocké comme un arbre de valeurs accessible par path.
class A2UIDataModel {
  A2UIDataModel([Map<String, dynamic>? initial])
      : _data = initial ?? <String, dynamic>{};

  final Map<String, dynamic> _data;

  dynamic resolve(String path) {
    if (!path.startsWith('/')) return null;
    final parts = path.split('/').skip(1);
    dynamic current = _data;
    for (final part in parts) {
      if (current is! Map<String, dynamic>) return null;
      current = current[part];
    }
    return current;
  }

  void update(String path, dynamic value) {
    if (!path.startsWith('/')) return;
    final parts = path.split('/').skip(1).toList();
    if (parts.isEmpty) {
      if (value is Map<String, dynamic>) {
        _data.addAll(value);
      }
      return;
    }
    dynamic current = _data;
    for (var i = 0; i < parts.length - 1; i++) {
      current = (current as Map<String, dynamic>)
          .putIfAbsent(parts[i], () => <String, dynamic>{});
    }
    if (value == null) {
      (current as Map<String, dynamic>).remove(parts.last);
    } else {
      (current as Map<String, dynamic>)[parts.last] = value;
    }
  }

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_data);
}
