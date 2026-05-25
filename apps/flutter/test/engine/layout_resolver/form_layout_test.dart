import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_registry/scalario_canvas_registry.dart';
import 'package:scalario/engine/canvas_layout/layouts/form_layout.dart';
import 'package:scalario/engine/canvas_layout/screen_config.dart';

import 'helpers.dart';

void main() {
  late ScalarioCanvasRegistry registry;

  setUp(() => registry = buildStubRegistry());

  // ── Mobile ──────────────────────────────────────────────────────────────────

  testWidgets('form mobile — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      FormLayout(config: formConfig(), registry: registry),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('form mobile — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      FormLayout(config: formConfig(), registry: registry),
      width: 390,
    );
    await expectLater(
      find.byType(FormLayout),
      matchesGoldenFile('goldens/form_mobile.png'),
    );
  });

  // ── Tablet ──────────────────────────────────────────────────────────────────

  testWidgets('form tablet — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      FormLayout(config: formConfig(), registry: registry),
      width: 800,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('form tablet — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      FormLayout(config: formConfig(), registry: registry),
      width: 800,
    );
    await expectLater(
      find.byType(FormLayout),
      matchesGoldenFile('goldens/form_tablet.png'),
    );
  });

  // ── Desktop ─────────────────────────────────────────────────────────────────

  testWidgets('form desktop — rend sans crash', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      FormLayout(config: formConfig(), registry: registry),
      width: 1440,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('form desktop — golden', (WidgetTester tester) async {
    await pumpWithSize(
      tester,
      FormLayout(config: formConfig(), registry: registry),
      width: 1440,
    );
    await expectLater(
      find.byType(FormLayout),
      matchesGoldenFile('goldens/form_desktop.png'),
    );
  });

  // ── Zone vide ───────────────────────────────────────────────────────────────

  testWidgets('AC-23 — main null → pas de crash', (WidgetTester tester) async {
    const ScreenConfig config = ScreenConfig(
      screen: 'test',
      schemaVersion: '1.0.0',
      layout: 'form',
    );
    await pumpWithSize(
      tester,
      FormLayout(config: config, registry: registry),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });
}
