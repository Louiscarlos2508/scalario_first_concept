import '../component_registry/component_config.dart';

/// Zones d'un screen BDUI — contrat partagé (architecture ligne 977-984).
///
/// Zone mapping par layout :
/// - dashboard : kpis (sub-grid), main, actions (FAB + inline)
/// - list      : main (liste), aside (filtres), kpis ignoré
/// - form      : main (sections), aside (aide desktop), actions (sticky bas)
/// - detail    : kpis (header), main (body / tabs), aside (nav desktop), actions
class ScreenZones {
  const ScreenZones({
    this.kpis,
    this.main,
    this.aside,
    this.actions,
  });

  factory ScreenZones.fromJson(Map<String, dynamic> json) {
    List<ComponentConfig>? parseZone(dynamic raw) {
      if (raw == null) return null;
      final list = raw as List<dynamic>;
      if (list.isEmpty) return null;
      return list
          .map((e) => ComponentConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ScreenZones(
      kpis: parseZone(json['kpis']),
      main: parseZone(json['main']),
      aside: parseZone(json['aside']),
      actions: parseZone(json['actions']),
    );
  }

  final List<ComponentConfig>? kpis;
  final List<ComponentConfig>? main;
  final List<ComponentConfig>? aside;
  final List<ComponentConfig>? actions;
}

/// Config d'un screen BDUI — value object immutable.
///
/// Mappé sur `ScreenConfig` du JSON Schema partagé (STORY-023).
class ScreenConfig {
  const ScreenConfig({
    required this.screen,
    required this.schemaVersion,
    required this.layout,
    this.title,
    this.i18nKey,
    this.zones = const ScreenZones(),
  });

  factory ScreenConfig.fromJson(Map<String, dynamic> json) {
    return ScreenConfig(
      screen: json['screen'] as String? ?? '',
      schemaVersion: json['schema_version'] as String? ?? '1.0.0',
      layout: json['layout'] as String? ?? 'dashboard',
      title: json['title'] as String?,
      i18nKey: json['i18n_key'] as String?,
      zones: json['zones'] != null
          ? ScreenZones.fromJson(json['zones'] as Map<String, dynamic>)
          : const ScreenZones(),
    );
  }

  final String screen;
  final String schemaVersion;
  final String layout;
  final String? title;
  final String? i18nKey;
  final ScreenZones zones;
}
