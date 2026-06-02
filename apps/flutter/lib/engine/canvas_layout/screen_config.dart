import '../canvas_registry/component_config.dart';
import '../canvas_registry/screen_layout.dart';

class ScreenConfig {
  const ScreenConfig({
    required this.screen,
    required this.schemaVersion,
    this.layoutObj,
    this.title,
    this.zones = const {},
    this.data,
    this.rules,
    this.states,
    this.i18n,
  });

  factory ScreenConfig.fromJson(Map<String, dynamic> json) {
    Map<String, List<ComponentConfig>> parseZones(dynamic raw) {
      if (raw == null || raw is! Map) return {};
      final map = <String, List<ComponentConfig>>{};
      for (final entry in (raw as Map<String, dynamic>).entries) {
        final val = entry.value;
        if (val is List) {
          map[entry.key] = val
              .map((e) => ComponentConfig.fromJson(e as Map<String, dynamic>))
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