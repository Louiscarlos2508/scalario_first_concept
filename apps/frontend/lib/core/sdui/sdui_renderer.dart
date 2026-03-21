import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_widget_registry.dart';
import 'package:frontend/core/theme/app_breakpoints.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

/// Converts a [SduiLayout] into a Flutter widget tree.
///
/// Layout types handled internally:
/// - `split_view` — LayoutBuilder adapting to kCompact / kMedium breakpoints
/// - `horizontal_split` — Row with left_flex / right_flex
/// - `stacked_with_fab_cart` — full-screen product grid + FAB cart badge
/// - `dashboard_scroll` — scrollable Column of sections
///
/// Panel types (product_grid, cart_panel, …) are delegated to [SduiWidgetRegistry].
class SduiRenderer extends ConsumerWidget {
  final SduiLayout layout;

  /// Called when the FAB cart badge is tapped in `stacked_with_fab_cart` layout.
  /// Typically navigates to a fullscreen cart view. No-op if null.
  final VoidCallback? onCartFabPressed;

  const SduiRenderer({
    super.key,
    required this.layout,
    this.onCartFabPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildLayout(context, ref, layout.layout);
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> layoutDef,
  ) {
    final type = layoutDef['type'] as String? ?? '';
    return switch (type) {
      'split_view' => _buildSplitView(context, ref, layoutDef),
      'dashboard_scroll' => _buildDashboardScroll(context, ref, layoutDef),
      _ => SduiWidgetRegistry.build(type, layoutDef),
    };
  }

  // ── split_view ────────────────────────────────────────────────────────────

  Widget _buildSplitView(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> layoutDef,
  ) {
    final breakpoints =
        layoutDef['breakpoints'] as Map<String, dynamic>? ?? {};
    final panels = layoutDef['panels'] as Map<String, dynamic>? ?? {};

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final Map<String, dynamic> subLayout;

        if (width < kCompact) {
          subLayout =
              breakpoints['compact'] as Map<String, dynamic>? ?? {};
        } else if (width < kMedium) {
          subLayout =
              breakpoints['medium'] as Map<String, dynamic>? ?? {};
        } else {
          subLayout =
              breakpoints['expanded'] as Map<String, dynamic>? ?? {};
        }

        return _buildSubLayout(context, ref, subLayout, panels);
      },
    );
  }

  Widget _buildSubLayout(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> subLayout,
    Map<String, dynamic> panels,
  ) {
    final type = subLayout['type'] as String? ?? '';
    return switch (type) {
      'stacked_with_fab_cart' =>
        _buildStackedWithFabCart(context, ref, panels, onCartFabPressed),
      'horizontal_split' => _buildHorizontalSplit(subLayout, panels),
      _ => const SizedBox.shrink(),
    };
  }

  // ── horizontal_split ──────────────────────────────────────────────────────

  Widget _buildHorizontalSplit(
    Map<String, dynamic> subLayout,
    Map<String, dynamic> panels,
  ) {
    final leftFlex = subLayout['left_flex'] as int? ?? 2;
    final rightFlex = subLayout['right_flex'] as int? ?? 1;

    final productGridDef = panels['product_grid'] as Map<String, dynamic>? ??
        {'type': 'product_grid'};
    final cartDef =
        panels['cart'] as Map<String, dynamic>? ?? {'type': 'cart_panel'};

    return Row(
      children: [
        Expanded(
          flex: leftFlex,
          child: SduiWidgetRegistry.build(
            productGridDef['type'] as String? ?? 'product_grid',
            productGridDef,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: rightFlex,
          child: SduiWidgetRegistry.build(
            cartDef['type'] as String? ?? 'cart_panel',
            cartDef,
          ),
        ),
      ],
    );
  }

  // ── stacked_with_fab_cart (compact) ───────────────────────────────────────

  Widget _buildStackedWithFabCart(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> panels,
    VoidCallback? onCartFabPressed,
  ) {
    final productGridDef = panels['product_grid'] as Map<String, dynamic>? ??
        {'type': 'product_grid'};

    final cartState = ref.watch(cartProvider);
    final itemCount =
        cartState.items.fold<double>(0.0, (sum, i) => sum + i.quantity).round();

    return Stack(
      children: [
        SduiWidgetRegistry.build(
          productGridDef['type'] as String? ?? 'product_grid',
          productGridDef,
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: null,
            onPressed: onCartFabPressed,
            tooltip: 'Cart ($itemCount items)',
            child: Badge(
              label: Text('$itemCount'),
              isLabelVisible: itemCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
          ),
        ),
      ],
    );
  }

  // ── dashboard_scroll ──────────────────────────────────────────────────────

  Widget _buildDashboardScroll(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> layoutDef,
  ) {
    final sections = layoutDef['sections'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections.map<Widget>((section) {
          final sectionMap = section as Map<String, dynamic>;
          final type = sectionMap['type'] as String? ?? '';
          return SduiWidgetRegistry.build(type, sectionMap);
        }).toList(),
      ),
    );
  }
}
