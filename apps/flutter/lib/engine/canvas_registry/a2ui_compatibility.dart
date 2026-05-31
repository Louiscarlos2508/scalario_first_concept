/// Table de compatibilité A2UI → Scalario.
///
/// Mappe les noms de composants A2UI (versionnés) vers les types
/// Scalario correspondants, permettant la rétrocompatibilité des
/// configurations BDUI.
abstract final class A2UICompatibility {
  A2UICompatibility._();

  /// Mappage v0.8 → Scalario
  static const Map<String, String> v0_8 = {
    'a2ui:heading': 'Heading',
    'a2ui:text': 'Text',
    'a2ui:card': 'Card',
    'a2ui:grid': 'Grid',
    'a2ui:row': 'Row',
    'a2ui:column': 'Column',
    'a2ui:button': 'Button',
    'a2ui:input': 'Input',
    'a2ui:slider': 'Slider',
    'a2ui:toggle': 'Toggle',
    'a2ui:checkbox': 'Checkbox',
    'a2ui:dropdown': 'Dropdown',
    'a2ui:tabs': 'Tabs',
    'a2ui:badge': 'Badge',
    'a2ui:media': 'Media',
    'a2ui:accordion': 'Accordion',
    'a2ui:stack': 'Stack',
    'a2ui:scaffold': 'Scaffold',
  };

  /// Mappage v0.9 → Scalario
  static const Map<String, String> v0_9 = {...v0_8};

  /// Mappage v1.0 → Scalario
  static const Map<String, String> v1_0 = {...v0_9};

  /// Tous les alias versionnés.
  static Map<String, String> get allVersioned {
    final map = <String, String>{};
    for (final entry in v0_8.entries) {
      map['${entry.key}_v0.8'] = entry.value;
    }
    for (final entry in v0_9.entries) {
      map['${entry.key}_v0.9'] = entry.value;
    }
    for (final entry in v1_0.entries) {
      map['${entry.key}_v1.0'] = entry.value;
    }
    return map;
  }

  /// Résout un type A2UI (versionné ou non) vers un type Scalario.
  /// Retourne `null` si aucun mappage trouvé.
  static String? resolve(String a2uiType) {
    if (allVersioned.containsKey(a2uiType)) {
      return allVersioned[a2uiType];
    }
    // Essayer sans version (nom nu)
    final base = a2uiType.replaceAll(RegExp(r'_v\d+\.\d+$'), '');
    for (final map in [v1_0, v0_9, v0_8]) {
      if (map.containsKey(base)) return map[base];
    }
    return null;
  }

  /// Génère le catalogue A2UI complet.
  static Map<String, List<String>> generateCatalog() {
    final catalog = <String, List<String>>{};
    final all = allVersioned;
    for (final entry in all.entries) {
      catalog.putIfAbsent(entry.value, () => []);
      catalog[entry.value]!.add(entry.key);
    }
    return catalog;
  }
}
