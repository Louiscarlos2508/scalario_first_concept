import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/component_registry/component_registry.dart';
import 'package:scalario/engine/layout_resolver/layouts/detail_layout.dart';
import 'package:scalario/engine/layout_resolver/screen_config.dart';

import 'helpers.dart';

void main() {
  late ComponentRegistry registry;

  setUp(() => registry = buildStubRegistry());

  // ── Mobile ──────────────────────────────────────────────────────────────────

  testWidgets('detail mobile — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DetailLayout(config: detailConfig(), registry: registry),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail mobile — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DetailLayout(config: detailConfig(), registry: registry),
      width: 390,
    );
    await expectLater(
      find.byType(DetailLayout),
      matchesGoldenFile('goldens/detail_mobile.png'),
    );
  });

  // ── Tablet ──────────────────────────────────────────────────────────────────

  testWidgets('detail tablet — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DetailLayout(config: detailConfig(), registry: registry),
      width: 800,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail tablet — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DetailLayout(config: detailConfig(), registry: registry),
      width: 800,
    );
    await expectLater(
      find.byType(DetailLayout),
      matchesGoldenFile('goldens/detail_tablet.png'),
    );
  });

  // ── Desktop ─────────────────────────────────────────────────────────────────

  testWidgets('detail desktop — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DetailLayout(config: detailConfig(), registry: registry),
      width: 1440,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail desktop — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      DetailLayout(config: detailConfig(), registry: registry),
      width: 1440,
    );
    await expectLater(
      find.byType(DetailLayout),
      matchesGoldenFile('goldens/detail_desktop.png'),
    );
  });

  // ── Zone vide ───────────────────────────────────────────────────────────────

  testWidgets('AC-23 — toutes zones nulles → pas de crash',
      (WidgetTester tester) async {
    const ScreenConfig config = ScreenConfig(
      screen: 'test',
      schemaVersion: '1.0.0',
      layout: 'detail',
    );
    await pumpWithSize(
      tester,
      DetailLayout(config: config, registry: registry),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });
}
