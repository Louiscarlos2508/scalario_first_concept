import '../canvas_registry/component_config.dart';
import '../canvas_registry/scalario_canvas_registry.dart';
import '../canvas_layout/screen_config.dart';
import 'a2ui_component.dart';
import 'a2ui_message.dart';

/// Traduit les composants A2UI v0.9 (flat list, adjacency model) en
/// ComponentConfig Scalario (arbre, zones).
///
/// La flat list A2UI est résolue en arbre via les refs `children`.
/// Les data bindings (paths) sont traduits en sources Scalario.
class A2UIComponentTranslator {
  A2UIComponentTranslator(this.registry);

  ScalarioCanvasRegistry registry;

  void updateRegistry(ScalarioCanvasRegistry newRegistry) {
    registry = newRegistry;
  }

  /// Traduit un message [UpdateComponents] en [ScreenConfig].
  ///
  /// 1. Résout la flat list en arbre (adjacency list → tree)
  /// 2. Mappe les noms de composants A2UI → types Scalario
  /// 3. Traduit les data bindings
  /// 4. Distribue dans les zones (kpis / main / aside / actions)
  ScreenConfig translate(
    UpdateComponents msg,
    String layout,
    String title,
  ) {
    final map = <String, A2UIComponent>{};
    for (final c in msg.components) {
      map[c.id] = c;
    }

    final root = map['root'];
    final children = <ComponentConfig>[];
    if (root != null) {
      if (root.children != null) {
        for (final childId in root.children!) {
          final child = map[childId];
          if (child != null) {
            children.add(_translateComponent(child, map));
          }
        }
      } else {
        children.add(_translateComponent(root, map));
      }
    } else {
      for (final c in msg.components) {
        if (c.id != 'root') {
          children.add(_translateComponent(c, map));
        }
      }
    }

    final zones = _distributeZones(children);

    return ScreenConfig(
      screen: msg.surfaceId,
      schemaVersion: '1.1.0',
      layout: layout,
      title: title,
      zones: zones,
    );
  }

  /// Traduit un composant A2UI récursivement en ComponentConfig Scalario.
  ComponentConfig _translateComponent(
    A2UIComponent a2ui,
    Map<String, A2UIComponent> allComponents,
  ) {
    final scalarioType = _mapType(a2ui.component);
    final props = <String, dynamic>{};

    // Copie toutes les props A2UI, en traduisant les data bindings
    for (final entry in a2ui.props.entries) {
      if (entry.key == 'id' ||
          entry.key == 'component' ||
          entry.key == 'children' ||
          entry.key == 'action') {
        continue;
      }
      props[entry.key] = _resolveValue(entry.value);
    }

    // Traduit les children
    List<ComponentConfig>? translatedChildren;
    if (a2ui.children != null && a2ui.children!.isNotEmpty) {
      translatedChildren = [];
      for (final childId in a2ui.children!) {
        final child = allComponents[childId];
        if (child != null) {
          translatedChildren.add(_translateComponent(child, allComponents));
        }
      }
      if (translatedChildren.isEmpty) translatedChildren = null;
    }

    // Traduit l'action A2UI en action Scalario
    List<Map<String, dynamic>>? actions;
    if (a2ui.action != null) {
      final event = a2ui.action!['event'] as Map<String, dynamic>?;
      if (event != null) {
        actions = <Map<String, dynamic>>[
          <String, dynamic>{
            'engine': 'flow',
            'action': event['name'] ?? a2ui.action!['name'],
            'props': event['context'] ?? <String, dynamic>{},
          }
        ];
      }
    }

    return ComponentConfig(
      type: scalarioType,
      variant: a2ui.variant ?? 'default',
      id: a2ui.id,
      props: props,
      actions: actions,
      children: translatedChildren,
    );
  }

  /// Résout une valeur A2UI (literal, DataBinding ou FunctionCall).
  dynamic _resolveValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      // DataBinding: { "path": "/ventes/ca" }
      if (value.containsKey('path')) {
        return {'_a2ui_path': value['path']};
      }
      // FunctionCall: { "call": "formatCurrency", "args": {...} }
      if (value.containsKey('call')) {
        return {'_a2ui_call': value['call'], '_a2ui_args': value['args']};
      }
      // Literal string: { "literalString": "hello" }
      if (value.containsKey('literalString')) {
        return value['literalString'];
      }
    }
    return value;
  }

  /// Distribue les composants dans les zones Scalario.
  ScreenZones _distributeZones(List<ComponentConfig> components) {
    final kpis = <ComponentConfig>[];
    final main = <ComponentConfig>[];
    final aside = <ComponentConfig>[];
    final actions = <ComponentConfig>[];

    for (final c in components) {
      if (_isKPI(c)) {
        kpis.add(c);
      } else if (_isAction(c)) {
        actions.add(c);
      } else if (_isAside(c)) {
        aside.add(c);
      } else {
        main.add(c);
      }
    }

    return ScreenZones(
      kpis: kpis.isNotEmpty ? kpis : null,
      main: main.isNotEmpty ? main : null,
      aside: aside.isNotEmpty ? aside : null,
      actions: actions.isNotEmpty ? actions : null,
    );
  }

  bool _isKPI(ComponentConfig c) =>
      c.type == 'KPICard' ||
      c.type == 'StatsCard' ||
      c.type == 'ChartBar' ||
      c.type == 'ChartPie';

  bool _isAction(ComponentConfig c) =>
      c.type == 'Button' ||
      c.type == 'FAB' ||
      c.type == 'ActionButton' ||
      c.type == 'ScalarioButton';

  bool _isAside(ComponentConfig c) =>
      c.type == 'FormSection' && c.variant == 'aside';

  /// Mappe les noms de composants A2UI (Basic Catalog) vers les types Scalario.
  String _mapType(String a2uiType) {
    switch (a2uiType) {
      // Scalario-specific
      case 'KPICard':
      case 'StatsCard':
      case 'DataTable':
      case 'ChartBar':
      case 'ChartPie':
      case 'AlertBanner':
      case 'SyncStatusBar':
      case 'DocumentPreview':
      case 'MouvementItem':
      case 'TicketPreview':
      case 'FormSection':
      case 'FormWidget':
      case 'ScalarioButton':
      case 'ActionButton':
      case 'StateWrapper':
      case 'PullToRefresh':
        return a2uiType;

      // A2UI Basic → Scalario
      case 'Text':
        return 'Text';
      case 'Button':
        return 'Button';
      case 'Image':
        return 'Image';
      case 'Card':
        return 'Card';
      case 'Row':
        return 'Row';
      case 'Column':
        return 'Column';
      case 'List':
        return 'DataTable';
      case 'Divider':
        return 'Divider';
      case 'Tabs':
        return 'Tabs';
      case 'TextField':
        return 'FormWidget';
      case 'CheckBox':
        return 'FormWidget';
      case 'ChoicePicker':
        return 'FormWidget';
      case 'Slider':
        return 'FormWidget';
      case 'DateTimeInput':
        return 'FormWidget';
      case 'Modal':
        return 'SheetDialog';
      case 'Icon':
        return 'Icon';
      case 'Video':
        return 'Video';
      case 'AudioPlayer':
        return 'AudioPlayer';
      case 'FAB':
        return 'FAB';

      // Layout
      case 'AppBar':
        return 'AppBar';
      case 'BottomNav':
        return 'BottomNav';
      case 'Grid':
        return 'Grid';
      case 'Scaffold':
        return 'Scaffold';
      case 'Slots':
        return 'Slots';
      case 'Stack':
        return 'Stack';

      default:
        return a2uiType;
    }
  }
}



