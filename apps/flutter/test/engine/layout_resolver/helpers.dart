import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/engine/canvas_registry/component_config.dart';
import 'package:scalario/engine/canvas_registry/scalario_canvas_registry.dart';
import 'package:scalario/engine/canvas_layout/screen_config.dart';

/// Stub registry — retourne un box coloré 60px de haut avec le type du composant.
ScalarioCanvasRegistry buildStubRegistry() {
  final ScalarioCanvasRegistry r = ScalarioCanvasRegistry();
  // Enregistre un builder générique qui rend un SizedBox étiqueté.
  const List<String> types = <String>[
    'KPICard',
    'DataTable',
    'ChartWidget',
    'AlertBanner',
    'ActionButton',
    'FAB',
    'FormWidget',
    'FormSection',
    'MouvementItem',
    'TicketPreview',
    'StubComponent',
  ];
  for (final String t in types) {
    r.register(t, (ComponentConfig c, BuildContext ctx) {
      return Container(
        height: 60,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Text(c.type, style: const TextStyle(fontSize: 12)),
      );
    });
  }
  return r;
}

/// Crée N composants stub de type [type].
List<ComponentConfig> stubComponents(String type, int count) {
  return List<ComponentConfig>.generate(
    count,
    (int i) => ComponentConfig(
      type: type,
      id: '${type}_$i',
      props: <String, dynamic>{'label': '$type $i'},
    ),
  );
}

/// ScreenConfig minimal avec zones pré-remplies.
ScreenConfig dashboardConfig({
  List<ComponentConfig>? kpis,
  List<ComponentConfig>? main,
  List<ComponentConfig>? actions,
}) {
  return ScreenConfig(
    screen: 'test_dashboard',
    schemaVersion: '1.0.0',
    layout: 'dashboard',
    zones: ScreenZones(
      kpis: kpis ?? stubComponents('KPICard', 4),
      main: main ?? stubComponents('DataTable', 1),
      actions: actions,
    ),
  );
}

ScreenConfig listConfig({
  List<ComponentConfig>? main,
  List<ComponentConfig>? aside,
}) {
  return ScreenConfig(
    screen: 'test_list',
    schemaVersion: '1.0.0',
    layout: 'list',
    zones: ScreenZones(
      main: main ?? stubComponents('MouvementItem', 5),
      aside: aside ?? stubComponents('StubComponent', 2),
    ),
  );
}

ScreenConfig formConfig({
  List<ComponentConfig>? main,
  List<ComponentConfig>? actions,
  List<ComponentConfig>? aside,
}) {
  return ScreenConfig(
    screen: 'test_form',
    schemaVersion: '1.0.0',
    layout: 'form',
    zones: ScreenZones(
      main: main ?? stubComponents('FormWidget', 3),
      actions: actions ?? stubComponents('ActionButton', 1),
      aside: aside,
    ),
  );
}

ScreenConfig detailConfig({
  List<ComponentConfig>? kpis,
  List<ComponentConfig>? main,
  List<ComponentConfig>? actions,
  List<ComponentConfig>? aside,
}) {
  return ScreenConfig(
    screen: 'test_detail',
    schemaVersion: '1.0.0',
    layout: 'detail',
    zones: ScreenZones(
      kpis: kpis ?? stubComponents('StubComponent', 1),
      main: main ?? stubComponents('DataTable', 1),
      actions: actions ?? stubComponents('ActionButton', 1),
      aside: aside,
    ),
  );
}

/// Pump un widget dans un MaterialApp Scalario avec une taille de surface fixe.
Future<void> pumpWithSize(
  WidgetTester tester,
  Widget widget, {
  required double width,
  double height = 800,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(body: widget),
    ),
  );
  await tester.pump();
}
