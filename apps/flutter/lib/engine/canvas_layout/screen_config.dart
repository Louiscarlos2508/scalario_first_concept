import '../canvas_registry/component_config.dart';
import '../canvas_registry/screen_appbar.dart';
import '../canvas_registry/screen_layout.dart';

class ScreenConfig {
  const ScreenConfig({
    required this.screen,
    required this.schemaVersion,
    this.layoutObj,
    this.title,
    this.appbar,
    this.templates = const {},
    this.zones = const {},
    this.data,
    this.rules,
    this.states,
    this.i18n,
  });

  factory ScreenConfig.fromJson(Map<String, dynamic> json) {
    // 1. Parse templates
    final templates = <String, ComponentConfig>{};
    if (json['templates'] is Map<String, dynamic>) {
      for (final entry in (json['templates'] as Map<String, dynamic>).entries) {
        templates[entry.key] = ComponentConfig.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    // Fonction de résolution locale qui intercepte le type 'template'
    ComponentConfig parseComponent(Map<String, dynamic> e) {
      if (e['type'] == 'template' && e['template_id'] != null) {
        final templateId = e['template_id'] as String;
        final template = templates[templateId];
        if (template != null) {
          // Merge template props with instance props
          final mergedProps = Map<String, dynamic>.from(template.props);
          if (e['props'] is Map) {
            mergedProps.addAll((e['props'] as Map).cast<String, dynamic>());
          }
          
          return template.copyWith(
            id: e['id'] as String?,
            props: mergedProps,
            visibleIf: e['visible_if'] != null ? (e['visible_if'] as Map).cast<String, dynamic>() : null,
            // You can also merge other overrides if needed
          );
        }
      }
      return ComponentConfig.fromJson(e, templates);
    }

    Map<String, List<ComponentConfig>> parseZones(dynamic raw) {
      if (raw == null || raw is! Map) return {};
      final map = <String, List<ComponentConfig>>{};
      for (final entry in (raw as Map<String, dynamic>).entries) {
        final val = entry.value;
        if (val is List) {
          map[entry.key] = val
              .map((e) => parseComponent(e as Map<String, dynamic>))
              .toList();
        }
      }
      return map;
    }

    final layoutRaw = json['layout'];
    ScreenLayout? layoutObj;
    if (layoutRaw is Map<String, dynamic>) {
      layoutObj = ScreenLayout.fromJson(layoutRaw);
    }

    return ScreenConfig(
      screen: json['screen'] as String? ?? '',
      schemaVersion: json['schema_version'] as String? ?? '2.0.0',
      layoutObj: layoutObj,
      title: json['title'] as String?,
      appbar: AppbarConfig.maybeFromJson(json['appbar'] as Map<String, dynamic>?),
      templates: templates,
      zones: parseZones(json['zones']),
      data: json['data'] as Map<String, dynamic>?,
      rules: json['rules'] as List<dynamic>?,
      states: json['states'] as Map<String, dynamic>?,
      i18n: json['i18n'] as Map<String, dynamic>?,
    );
  }

  final String screen;
  final String schemaVersion;
  final ScreenLayout? layoutObj;
  final String? title;
  final AppbarConfig? appbar;
  final Map<String, ComponentConfig> templates;
  final Map<String, List<ComponentConfig>> zones;
  final Map<String, dynamic>? data;
  final List<dynamic>? rules;
  final Map<String, dynamic>? states;
  final Map<String, dynamic>? i18n;

  String get layout => layoutObj?.layout ?? 'dashboard';

  List<ComponentConfig> zone(String name) => zones[name] ?? [];

  List<ComponentConfig>? get kpis => zones['kpis'];
  List<ComponentConfig>? get main => zones['main'];
  List<ComponentConfig>? get aside => zones['aside'];
  List<ComponentConfig>? get actions => zones['actions'];
  List<ComponentConfig>? get header => zones['header'];
  List<ComponentConfig>? get sidebar => zones['sidebar'];
  List<ComponentConfig>? get form => zones['form'];
  List<ComponentConfig>? get cart => zones['cart'];
  List<ComponentConfig>? get productGrid => zones['product_grid'];
  List<ComponentConfig>? get filters => zones['filters'];
  List<ComponentConfig>? get list => zones['list'];
  List<ComponentConfig>? get content => zones['content'];
  List<ComponentConfig>? get sheet => zones['sheet'];

  Map<String, dynamic>? get scaffoldConfig => null;
}