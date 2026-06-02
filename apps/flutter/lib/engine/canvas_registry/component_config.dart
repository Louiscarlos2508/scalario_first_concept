import 'props/props_factory.dart';
import 'props/typed_props.dart';
import 'bdui_action.dart';

class ComponentConfig {
  const ComponentConfig({
    required this.type,
    this.variant = 'default',
    this.id,
    this.props = const <String, dynamic>{},
    this.visibleIf,
    this.source,
    this.validation,
    this.actions,
    this.children,
    this.i18nKey,
  });

  factory ComponentConfig.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> toStringMap(dynamic raw) {
      if (raw == null) return <String, dynamic>{};
      if (raw is Map<String, dynamic>) return raw;
      return (raw as Map<dynamic, dynamic>).cast<String, dynamic>();
    }

    List<Map<String, dynamic>>? toActionList(dynamic raw) {
      if (raw == null) return null;
      return (raw as List<dynamic>).map((e) {
        if (e is Map<String, dynamic>) return e;
        return (e as Map<dynamic, dynamic>).cast<String, dynamic>();
      }).toList();
    }

    List<ComponentConfig>? toChildrenList(dynamic raw) {
      if (raw == null) return null;
      return (raw as List<dynamic>).map((e) {
        if (e is Map<String, dynamic>) {
          return ComponentConfig.fromJson(e);
        }
        return ComponentConfig.fromJson(
          (e as Map<dynamic, dynamic>).cast<String, dynamic>(),
        );
      }).toList();
    }

    return ComponentConfig(
      type: json['type'] as String? ?? '',
      variant: json['variant'] is String ? json['variant'] as String : 'default',
      id: json['id'] as String?,
      props: toStringMap(json['props']),
      visibleIf: json['visible_if'] == null ? null : toStringMap(json['visible_if']),
      source: json['source'] == null ? null : toStringMap(json['source']),
      validation: (json['validation'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      actions: toActionList(json['actions']),
      children: toChildrenList(json['children']),
      i18nKey: json['i18n_key'] as String?,
    );
  }

  final String type;
  final String variant;
  final String? id;
  final Map<String, dynamic> props;
  final Map<String, dynamic>? visibleIf;
  final Map<String, dynamic>? source;
  final List<Map<String, dynamic>>? validation;
  final List<Map<String, dynamic>>? actions;
  final List<ComponentConfig>? children;
  final String? i18nKey;

  TypedProps get typedProps => PropsFactory.resolve(type, props);

  List<BduiAction> get parsedActions {
    if (actions == null || actions!.isEmpty) return [];
    return actions!.map((a) => BduiAction.fromJson(a)).whereType<BduiAction>().toList();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        if (variant != 'default') 'variant': variant,
        if (id != null) 'id': id,
        if (props.isNotEmpty) 'props': props,
        if (visibleIf != null) 'visible_if': visibleIf,
        if (source != null) 'source': source,
        if (validation != null) 'validation': validation,
        if (actions != null) 'actions': actions,
        if (children != null) 'children': children!.map((c) => c.toJson()).toList(),
        if (i18nKey != null) 'i18n_key': i18nKey,
      };

  ComponentConfig copyWith({
    String? type,
    String? variant,
    String? id,
    Map<String, dynamic>? props,
    Map<String, dynamic>? visibleIf,
    Map<String, dynamic>? source,
    List<Map<String, dynamic>>? validation,
    List<Map<String, dynamic>>? actions,
    List<ComponentConfig>? children,
    String? i18nKey,
  }) {
    return ComponentConfig(
      type: type ?? this.type,
      variant: variant ?? this.variant,
      id: id ?? this.id,
      props: props ?? this.props,
      visibleIf: visibleIf ?? this.visibleIf,
      source: source ?? this.source,
      validation: validation ?? this.validation,
      actions: actions ?? this.actions,
      children: children ?? this.children,
      i18nKey: i18nKey ?? this.i18nKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          variant == other.variant &&
          id == other.id;

  @override
  int get hashCode => Object.hash(type, variant, id);

  @override
  String toString() => 'ComponentConfig(type: $type, variant: $variant, id: $id)';
}