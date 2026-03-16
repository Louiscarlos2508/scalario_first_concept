import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';

void main() {
  group('SduiLayout.fromJson', () {
    test('parses all fields correctly (AC1)', () {
      final json = {
        'version': '1',
        'business_type': 'retail',
        'screen': 'pos',
        'layout': {'type': 'split_view'},
      };

      final layout = SduiLayout.fromJson(json);

      expect(layout.version, '1');
      expect(layout.businessType, 'retail');
      expect(layout.screen, 'pos');
      expect(layout.layout['type'], 'split_view');
    });

    test('uses defaults for missing fields (AC1)', () {
      final layout = SduiLayout.fromJson({});

      expect(layout.version, '1');
      expect(layout.businessType, 'retail');
      expect(layout.screen, '');
      expect(layout.layout, isEmpty);
    });

    test('parses dashboard layout with sections (AC1)', () {
      final json = {
        'version': '1',
        'business_type': 'retail',
        'screen': 'dashboard',
        'layout': {
          'type': 'dashboard_scroll',
          'sections': [
            {'type': 'kpi_card_grid', 'cards': []},
          ],
        },
      };

      final layout = SduiLayout.fromJson(json);

      expect(layout.screen, 'dashboard');
      final sections =
          layout.layout['sections'] as List<dynamic>;
      expect(sections, hasLength(1));
      expect(sections[0]['type'], 'kpi_card_grid');
    });
  });

  group('SduiLayout.toJson', () {
    test('round-trips through JSON correctly (AC1)', () {
      final original = SduiLayout.fromJson({
        'version': '1',
        'business_type': 'retail',
        'screen': 'pos',
        'layout': {'type': 'split_view'},
      });

      final json = original.toJson();
      final roundTripped = SduiLayout.fromJson(json);

      expect(roundTripped.version, original.version);
      expect(roundTripped.businessType, original.businessType);
      expect(roundTripped.screen, original.screen);
      expect(roundTripped.layout, original.layout);
    });

    test('toJsonString produces valid JSON (AC1)', () {
      final layout = SduiLayout.retailPosDefault();
      final jsonStr = layout.toJsonString();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['version'], '1');
      expect(decoded['business_type'], 'retail');
      expect(decoded['screen'], 'pos');
    });
  });

  group('SduiLayout.retailPosDefault', () {
    test('returns retail/pos layout with split_view (AC1)', () {
      final layout = SduiLayout.retailPosDefault();

      expect(layout.version, '1');
      expect(layout.businessType, 'retail');
      expect(layout.screen, 'pos');
      expect(layout.layout['type'], 'split_view');
    });

    test('contains compact/medium/expanded breakpoints (AC1)', () {
      final layout = SduiLayout.retailPosDefault();
      final breakpoints =
          layout.layout['breakpoints'] as Map<String, dynamic>;

      expect(breakpoints['compact']['type'], 'stacked_with_fab_cart');
      expect(breakpoints['medium']['type'], 'horizontal_split');
      expect(breakpoints['medium']['left_flex'], 2);
      expect(breakpoints['expanded']['type'], 'horizontal_split');
      expect(breakpoints['expanded']['left_flex'], 3);
    });

    test('contains product_grid and cart panels (AC1)', () {
      final layout = SduiLayout.retailPosDefault();
      final panels = layout.layout['panels'] as Map<String, dynamic>;

      expect(panels['product_grid']['type'], 'product_grid');
      expect(panels['cart']['type'], 'cart_panel');
      final paymentMethods =
          panels['cart']['payment_methods'] as List<dynamic>;
      expect(paymentMethods,
          containsAll(['CASH', 'MOBILE_MONEY', 'CARD', 'CREDIT', 'SPLIT']));
    });
  });
}
