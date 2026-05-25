import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_registry/component_config.dart';
import 'package:scalario/engine/canvas_registry/scalario_canvas_registry.dart';
import 'package:scalario/engine/canvas_layout/layouts/dashboard_layout.dart';
import 'package:scalario/engine/canvas_layout/screen_config.dart';

import 'helpers.dart';

void main() {
  late ScalarioCanvasRegistry registry;

  setUp(() => registry = buildStubRegistry());

  // ── Mobile ──────────────────────────────────────────────────────────────────

  testWidgets('dashboard mobile — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DashboardLayout(config: dashboardConfig(), registry: registry),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard mobile — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DashboardLayout(config: dashboardConfig(), registry: registry),
      width: 390,
    );
    await expectLater(
      find.byType(DashboardLayout),
      matchesGoldenFile('goldens/dashboard_mobile.png'),
    );
  });

  // ── Tablet ──────────────────────────────────────────────────────────────────

  testWidgets('dashboard tablet — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DashboardLayout(config: dashboardConfig(), registry: registry),
      width: 800,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard tablet — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DashboardLayout(config: dashboardConfig(), registry: registry),
      width: 800,
    );
    await expectLater(
      find.byType(DashboardLayout),
      matchesGoldenFile('goldens/dashboard_tablet.png'),
    );
  });

  // ── Desktop ─────────────────────────────────────────────────────────────────

  testWidgets('dashboard desktop — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DashboardLayout(config: dashboardConfig(), registry: registry),
      width: 1440,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard desktop — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DashboardLayout(config: dashboardConfig(), registry: registry),
      width: 1440,
    );
    await expectLater(
      find.byType(DashboardLayout),
      matchesGoldenFile('goldens/dashboard_desktop.png'),
    );
  });

  // ── FAB ─────────────────────────────────────────────────────────────────────

  testWidgets('dashboard — FAB rendu en Align bottomRight', (WidgetTester tester) async {
    final ScreenConfig config = dashboardConfig(
      actions: <ComponentConfig>[
        const ComponentConfig(
          type: 'ActionButton',
          id: 'fab1',
          props: <String, dynamic>{'variant': 'floating', 'label': 'Add'},
        ),
      ],
    );
    await pumpWithSize(
      tester,
      DashboardLayout(config: config, registry: registry),
      width: 390,
    );
    expect(
      find.descendant(
        of: find.byType(Align),
        matching: find.byType(Container),
      ),
      findsWidgets,
    );
  });

  // ── Zone vide ───────────────────────────────────────────────────────────────

  testWidgets('AC-23 — zone kpis null → pas de crash, pas d\'espace réservé',
      (WidgetTester tester) async {
    final ScreenConfig config = ScreenConfig(
      screen: 'test',
      schemaVersion: '1.0.0',
      layout: 'dashboard',
      zones: ScreenZones(
        main: stubComponents('DataTable', 1),
      ),
    );
    await pumpWithSize(
      tester,
      DashboardLayout(config: config, registry: registry),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('AC-23 — toutes zones nulles → rend sans crash',
      (WidgetTester tester) async {
    const ScreenConfig config = ScreenConfig(
      screen: 'test',
      schemaVersion: '1.0.0',
      layout: 'dashboard',
    );
    await pumpWithSize(
      tester,
      DashboardLayout(config: config, registry: registry),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });
}
