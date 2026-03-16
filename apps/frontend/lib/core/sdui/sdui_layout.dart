import 'dart:convert';

/// Top-level SDUI layout envelope.
///
/// JSON shape (from docs/sdui-schema.md):
/// ```json
/// { "version": "1", "business_type": "retail", "screen": "pos", "layout": { ... } }
/// ```
class SduiLayout {
  final String version;
  final String businessType;
  final String screen;
  final Map<String, dynamic> layout;

  const SduiLayout({
    required this.version,
    required this.businessType,
    required this.screen,
    required this.layout,
  });

  factory SduiLayout.fromJson(Map<String, dynamic> json) {
    return SduiLayout(
      version: json['version'] as String? ?? '1',
      businessType: json['business_type'] as String? ?? 'retail',
      screen: json['screen'] as String? ?? '',
      layout: (json['layout'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'business_type': businessType,
        'screen': screen,
        'layout': layout,
      };

  String toJsonString() => jsonEncode(toJson());

  /// Default retail dashboard layout — used as offline fallback (Story 15-1).
  /// Mirrors `apps/backend/src/sdui/layouts/retail.dashboard.json`.
  factory SduiLayout.dashboardDefault() {
    return const SduiLayout(
      version: '1',
      businessType: 'retail',
      screen: 'dashboard',
      layout: {
        'type': 'dashboard_scroll',
        'sections': [
          {
            'type': 'kpi_card_grid',
            'cards': [
              {'icon': 'attach_money', 'label': 'Ventes du jour', 'value_provider': 'daily_revenue'},
              {'icon': 'receipt_long', 'label': 'Transactions', 'value_provider': 'daily_transactions'},
              {'icon': 'people', 'label': 'Clients actifs', 'value_provider': 'active_customers'},
              {'icon': 'inventory_2', 'label': 'Stock faible', 'value_provider': 'low_stock_count'},
            ],
          },
          {
            'type': 'line_chart',
            'title': 'Ventes des 7 derniers jours',
            'data_provider': 'weekly_sales_series',
          },
          {
            'type': 'terminal_status_list',
            'title': 'État des caisses',
          },
        ],
      },
    );
  }

  /// Default retail POS layout — used as offline fallback (Story 10-5).
  /// Mirrors `apps/backend/src/sdui/layouts/retail.pos.json`.
  factory SduiLayout.retailPosDefault() {
    return const SduiLayout(
      version: '1',
      businessType: 'retail',
      screen: 'pos',
      layout: {
        'type': 'split_view',
        'breakpoints': {
          'compact': {'type': 'stacked_with_fab_cart'},
          'medium': {'type': 'horizontal_split', 'left_flex': 2, 'right_flex': 1},
          'expanded': {'type': 'horizontal_split', 'left_flex': 3, 'right_flex': 1},
        },
        'panels': {
          'product_grid': {
            'type': 'product_grid',
            'columns': {'compact': 2, 'medium': 3, 'expanded': 5},
            'show_categories': true,
            'show_search': true,
          },
          'cart': {
            'type': 'cart_panel',
            'primary_action': {
              'type': 'filled_button',
              'label': 'ENCAISSER',
              'action': 'checkout',
              'min_height': 56,
            },
            'payment_methods': ['CASH', 'MOBILE_MONEY', 'CARD', 'CREDIT', 'SPLIT'],
          },
        },
      },
    );
  }
}
