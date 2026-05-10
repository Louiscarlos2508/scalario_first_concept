import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/component_registry/component_registry.dart';
import 'package:scalario/engine/layout_resolver/layouts/list_layout.dart';
import 'package:scalario/engine/layout_resolver/screen_config.dart';

import 'helpers.dart';

void main() {
  late ComponentRegistry registry;

  setUp(() => registry = buildStubRegistry());

  // ── Mobile ──────────────────────────────────────────────────────────────────

  testWidgets('list mobile — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      ListLayout(config: listConfig(), registry: registry),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('list mobile — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      ListLayout(config: listConfig(), registry: registry),
      width: 390,
    );
    await expectLater(
      find.byType(ListLayout),
      matchesGoldenFile('goldens/list_mobile.png'),
    );
  });

  // ── Tablet ──────────────────────────────────────────────────────────────────

  testWidgets('list tablet — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      ListLayout(config: listConfig(), registry: registry),
      width: 800,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('list tablet — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      ListLayout(config: listConfig(), registry: registry),
      width: 800,
    );
    await expectLater(
      find.byType(ListLayout),
      matchesGoldenFile('goldens/list_tablet.png'),
    );
  });

  // ── Desktop ─────────────────────────────────────────────────────────────────

  testWidgets('list desktop — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      ListLayout(config: listConfig(), registry: registry),
      width: 1440,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('list desktop — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      ListLayout(config: listConfig(), registry: registry),
      width: 1440,
    );
    await expectLater(
      find.byType(ListLayout),
      matchesGoldenFile('goldens/list_desktop.png'),
    );
  });

  // ── Zone vide ───────────────────────────────────────────────────────────────

  testWidgets('AC-23 — main null → SizedBox.shrink, pas de crash',
      (WidgetTester tester) async {
    const ScreenConfig config = ScreenConfig(
      screen: 'test',
      schemaVersion: '1.0.0',
      layout: 'list',
    );
    await pumpWithSize(
      tester,
      ListLayout(config: config, registry: registry),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });
}
