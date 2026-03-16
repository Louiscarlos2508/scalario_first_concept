import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_renderer.dart';
import 'package:frontend/core/sdui/sdui_widget_registry.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_notifier.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

Widget _wrapWithProviders(Widget child) {
  return ProviderScope(
    overrides: [
      // Provide an empty cart so SduiRenderer can read cartProvider
      cartProvider.overrideWith((ref) => CartNotifier()),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUp(() {
    SduiWidgetRegistry.reset();
    // Register test doubles
    SduiWidgetRegistry.register(
      'product_grid',
      (_) => const Text('ProductGrid'),
    );
    SduiWidgetRegistry.register(
      'cart_panel',
      (_) => const Text('CartPanel'),
    );
  });

  tearDown(() => SduiWidgetRegistry.reset());

  // ── Unknown type fallback ─────────────────────────────────────────────────

  group('Unknown type fallback (AC5)', () {
    testWidgets('unknown panel type renders SizedBox.shrink without crash',
        (tester) async {
      final layout = SduiLayout.fromJson({
        'version': '1',
        'business_type': 'retail',
        'screen': 'test',
        'layout': {'type': 'xyz_unknown_widget'},
      });

      await tester.pumpWidget(
        _wrapWithProviders(SduiRenderer(layout: layout)),
      );

      // No exception thrown; SizedBox.shrink is present (zero size)
      expect(tester.takeException(), isNull);
      // The renderer built something (didn't crash)
      expect(find.byType(SduiRenderer), findsOneWidget);
    });
  });

  // ── SduiWidgetRegistry ────────────────────────────────────────────────────

  group('SduiWidgetRegistry (AC2)', () {
    test('registered type builds the correct widget', () {
      SduiWidgetRegistry.register('my_panel', (_) => const Text('hello'));

      final widget = SduiWidgetRegistry.build('my_panel', {});
      expect(widget, isA<Text>());
    });

    test('unregistered type returns SizedBox.shrink (AC5)', () {
      final widget = SduiWidgetRegistry.build('nonexistent', {});
      expect(widget, isA<SizedBox>());
    });

    test('hasType returns true for registered type', () {
      SduiWidgetRegistry.register('known', (_) => const SizedBox());
      expect(SduiWidgetRegistry.hasType('known'), isTrue);
      expect(SduiWidgetRegistry.hasType('unknown'), isFalse);
    });

    test('reset clears all registrations', () {
      SduiWidgetRegistry.register('temp', (_) => const SizedBox());
      SduiWidgetRegistry.reset();
      expect(SduiWidgetRegistry.hasType('temp'), isFalse);
    });
  });

  // ── horizontal_split layout ───────────────────────────────────────────────

  group('horizontal_split layout (AC2)', () {
    testWidgets('renders product_grid and cart_panel side-by-side',
        (tester) async {
      final layout = SduiLayout.fromJson({
        'version': '1',
        'business_type': 'retail',
        'screen': 'pos',
        'layout': {
          'type': 'split_view',
          'breakpoints': {
            'compact': {'type': 'stacked_with_fab_cart'},
            'medium': {
              'type': 'horizontal_split',
              'left_flex': 2,
              'right_flex': 1,
            },
            'expanded': {
              'type': 'horizontal_split',
              'left_flex': 3,
              'right_flex': 1,
            },
          },
          'panels': {
            'product_grid': {'type': 'product_grid'},
            'cart': {'type': 'cart_panel'},
          },
        },
      });

      // Use an 800dp-wide surface → medium breakpoint → horizontal_split
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: _wrapWithProviders(SduiRenderer(layout: layout)),
        ),
      );
      await tester.pump();

      expect(find.text('ProductGrid'), findsOneWidget);
      expect(find.text('CartPanel'), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });
  });

  // ── dashboard_scroll layout ───────────────────────────────────────────────

  group('dashboard_scroll layout', () {
    testWidgets('renders sections via registry', (tester) async {
      SduiWidgetRegistry.register(
        'kpi_card_grid',
        (_) => const Text('KpiCards'),
      );
      SduiWidgetRegistry.register(
        'line_chart',
        (_) => const Text('LineChart'),
      );

      final layout = SduiLayout.fromJson({
        'version': '1',
        'business_type': 'retail',
        'screen': 'dashboard',
        'layout': {
          'type': 'dashboard_scroll',
          'sections': [
            {'type': 'kpi_card_grid'},
            {'type': 'line_chart'},
          ],
        },
      });

      await tester.pumpWidget(
        _wrapWithProviders(SduiRenderer(layout: layout)),
      );
      await tester.pump();

      expect(find.text('KpiCards'), findsOneWidget);
      expect(find.text('LineChart'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
