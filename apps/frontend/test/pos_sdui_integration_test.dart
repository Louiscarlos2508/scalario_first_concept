import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_renderer.dart';
import 'package:frontend/core/sdui/sdui_widget_registry.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_notifier.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Wraps SduiRenderer in a SizedBox(width) so LayoutBuilder receives
/// accurate constraints regardless of the test surface size.
Widget _buildRendererAt(double width, SduiLayout layout) {
  return ProviderScope(
    overrides: [cartProvider.overrideWith((ref) => CartNotifier())],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: SduiRenderer(layout: layout)),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SduiWidgetRegistry.reset();
    SduiWidgetRegistry.register('product_grid', (_) => const Text('ProductGrid'));
    SduiWidgetRegistry.register('cart_panel', (_) => const Text('CartPanel'));
  });

  tearDown(() => SduiWidgetRegistry.reset());

  // ── AC4: Tablet — horizontal_split ────────────────────────────────────────

  group('Tablet layout (AC4) — horizontal_split', () {
    testWidgets('800dp wide renders product_grid and cart_panel side-by-side',
        (tester) async {
      await tester.pumpWidget(
        _buildRendererAt(800, SduiLayout.retailPosDefault()),
      );
      await tester.pump();

      expect(find.text('ProductGrid'), findsOneWidget);
      expect(find.text('CartPanel'), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  // ── AC5: Phone — stacked_with_fab_cart ────────────────────────────────────

  group('Phone layout (AC5) — stacked_with_fab_cart', () {
    testWidgets('400dp wide renders product_grid with FAB cart badge',
        (tester) async {
      await tester.pumpWidget(
        _buildRendererAt(400, SduiLayout.retailPosDefault()),
      );
      await tester.pump();

      expect(find.text('ProductGrid'), findsOneWidget);
      expect(find.text('CartPanel'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB badge tooltip shows 0 items for empty cart',
        (tester) async {
      await tester.pumpWidget(
        _buildRendererAt(400, SduiLayout.retailPosDefault()),
      );
      await tester.pump();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.tooltip, contains('0'));
    });
  });

  // ── AC3: Offline fallback ─────────────────────────────────────────────────

  group('Offline fallback (AC3)', () {
    testWidgets(
        'loading state uses retailPosDefault — no blank screen while fetching',
        (tester) async {
      // PosScreen delegates to SduiLayout.retailPosDefault() when the layout
      // provider is still loading. We verify the fallback layout renders
      // correctly via SduiRenderer directly (avoids SessionLockWrapper's
      // async SharedPreferences dependency).
      await tester.pumpWidget(
        _buildRendererAt(800, SduiLayout.retailPosDefault()),
      );
      await tester.pump();

      expect(find.text('ProductGrid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
