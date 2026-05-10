import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/feedback/alert_banner.dart';
import 'package:scalario/engine/component_registry/component_registry.dart';
import 'package:scalario/engine/layout_resolver/layout_resolver.dart';

import 'helpers.dart';

void main() {
  late ComponentRegistry registry;

  setUp(() => registry = buildStubRegistry());

  // AC-27 — layout 'foobar' → UnknownLayout rendu
  testWidgets('AC-27 — layout inconnu → UnknownLayout rend DashboardLayout',
      (WidgetTester tester) async {
    final LayoutResolver resolver = LayoutResolver(registry: registry);

    await pumpWithSize(
      tester,
      Builder(
        builder: (context) => resolver.resolve(
          'foobar',
          dashboardConfig(),
          context,
        ),
      ),
      width: 390,
    );

    expect(find.byType(UnknownLayout), findsOneWidget);
    expect(find.byType(DashboardLayout), findsOneWidget);
  });

  // AC-22 — AlertBanner info affiché dans UnknownLayout
  testWidgets('AC-22 — UnknownLayout affiche AlertBanner info',
      (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      UnknownLayout(
        layoutType: 'xyz',
        config: dashboardConfig(),
        registry: registry,
      ),
      width: 390,
    );

    expect(find.byType(AlertBanner), findsOneWidget);
    // Vérifie le message
    expect(
      find.textContaining('xyz'),
      findsOneWidget,
    );
    expect(
      find.textContaining('dashboard'),
      findsOneWidget,
    );
  });

  // AC-22 — AlertBanner est de type info
  testWidgets('AC-22 — AlertBanner est de type info', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      UnknownLayout(
        layoutType: 'unknown_type',
        config: dashboardConfig(),
        registry: registry,
      ),
      width: 390,
    );

    final AlertBanner banner = tester.widget<AlertBanner>(
      find.byType(AlertBanner),
    );
    expect(banner.type, AlertType.info);
  });

  // Layouts connus ne retournent pas UnknownLayout
  testWidgets('layouts connus ne passent pas par UnknownLayout',
      (WidgetTester tester) async {
    final LayoutResolver resolver = LayoutResolver(registry: registry);

    for (final String layout in <String>['dashboard', 'list', 'form', 'detail']) {
      final config = dashboardConfig();
      await pumpWithSize(
        tester,
        Builder(builder: (ctx) => resolver.resolve(layout, config, ctx)),
        width: 390,
      );
      expect(
        find.byType(UnknownLayout),
        findsNothing,
        reason: 'layout "$layout" ne doit pas produire UnknownLayout',
      );
    }
  });
}
